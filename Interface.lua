local addonName, addon = ...

local display
local elapsedSinceUpdate = 0

local metrics = {
    { key = "xp",        label = "XP / HOUR" },
    { key = "last",      label = "LAST XP" },
    { key = "tnl",       label = "NEXT LEVEL" },
    { key = "rolling5",  label = "5 MIN XP/H" },
    { key = "rolling15", label = "15 MIN XP/H" },
    { key = "rolling30", label = "30 MIN XP/H" }
}

local function FormatTime(seconds)
    if not seconds or seconds < 0 or seconds == math.huge then return "--:--" end
    seconds = math.floor(seconds)
    if seconds >= 3600 then
        return string.format("%d:%02d:%02d", math.floor(seconds / 3600),
            math.floor(seconds / 60) % 60, seconds % 60)
    end
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function FormatNumber(value)
    local number = tostring(math.floor((value or 0) + 0.5))
    local formatted, changes = number, 0
    repeat
        formatted, changes = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until changes == 0
    return formatted
end

-- Interpolate rolling XP/hour colors against the session average.
-- The session average itself always remains white.
local function PerformanceColor(rolling, average, windowSeconds, elapsed)
    if not DowntimeDB.performanceColors or average <= 0
        or elapsed < windowSeconds then
        return 1, 1, 1
    end

    local ratio = rolling / average
    local stops = {
        { 0.50, 0.937, 0.267, 0.267 }, -- Red
        { 0.80, 0.976, 0.451, 0.086 }, -- Orange
        { 1.00, 1.000, 1.000, 1.000 }, -- White
        { 1.20, 0.290, 0.871, 0.502 }  -- Green
    }

    if ratio <= stops[1][1] then
        return stops[1][2], stops[1][3], stops[1][4]
    end

    for i = 2, #stops do
        local previous, current = stops[i - 1], stops[i]
        if ratio <= current[1] then
            local t = (ratio - previous[1]) / (current[1] - previous[1])
            return previous[2] + (current[2] - previous[2]) * t,
                previous[3] + (current[3] - previous[3]) * t,
                previous[4] + (current[4] - previous[4]) * t
        end
    end

    return stops[#stops][2], stops[#stops][3], stops[#stops][4]
end

local function AnchorDisplay()
    display:ClearAllPoints()
    if DowntimeDB and DowntimeDB.detached then
        display:SetPoint("CENTER", UIParent, "CENTER", DowntimeDB.x or 0, DowntimeDB.y or 0)
    elseif PlayerFrame then
        display:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 0, 8)
    else
        display:SetPoint("CENTER", UIParent, "CENTER")
    end
end

function addon:ResetDisplayPosition()
    DowntimeDB.detached = false
    DowntimeDB.x = nil
    DowntimeDB.y = nil
    AnchorDisplay()
end

function addon:RefreshDisplayLayout()
    if not display then return end
    self:InitializeSettings()

    local compact = DowntimeDB.layout == "compact"
    local rowHeight = compact and 32 or 44
    local columns = 3
    local count = 0
    local visible = DowntimeDB.visible

    for _, metric in ipairs(metrics) do
        local item = display.items[metric.key]
        if visible[metric.key] then
            local col = count % columns
            local row = math.floor(count / columns)
            local x = 10 + col * 102
            local y = -25 - row * rowHeight
            item.heading:ClearAllPoints()
            item.heading:SetPoint("TOPLEFT", display, "TOPLEFT", x, y)
            item.heading:Show()
            item.value:Show()
            count = count + 1
        else
            item.heading:Hide()
            item.value:Hide()
        end
    end

    local rows = math.ceil(count / columns)
    display:SetHeight(22 + rows * rowHeight + (rows > 0 and 6 or 0))
    display.background:SetColorTexture(0.04, 0.06, 0.09, DowntimeDB.opacity)

    -- When detached, preserve the stored center position as height changes.
    AnchorDisplay()
    self:UpdateDisplay()
end

function addon:UpdateDisplay()
    if not display then return end
    local stats = self:GetExperienceStats()
    local items = display.items
    items.xp.value:SetText(FormatNumber(stats.xpPerHour))
    items.last.value:SetText(FormatTime(stats.sinceLastXP))
    items.rolling5.value:SetText(FormatNumber(stats.rolling5))
    items.rolling15.value:SetText(FormatNumber(stats.rolling15))
    items.rolling30.value:SetText(FormatNumber(stats.rolling30))

    -- Only color a window after its full duration has been observed.
    -- This avoids misleading comparisons early in a session.
    for _, window in ipairs({
        { key = "rolling5",  seconds = 300 },
        { key = "rolling15", seconds = 900 },
        { key = "rolling30", seconds = 1800 }
    }) do
        local r, g, b = PerformanceColor(
            stats[window.key], stats.xpPerHour, window.seconds, stats.elapsed
        )
        items[window.key].value:SetTextColor(r, g, b)
    end

    if stats.xpPerHour > 0 then
        local remaining = UnitXPMax("player") - UnitXP("player")
        items.tnl.value:SetText(FormatTime(remaining / stats.xpPerHour * 3600))
    else
        items.tnl.value:SetText("--:--")
    end
end

function addon:InitializeDisplay()
    if display then return end
    self:InitializeSettings()
    if DowntimeDB.locked == nil then DowntimeDB.locked = true end

    display = CreateFrame("Frame", nil, UIParent)
    display:SetSize(310, 116)
    display:SetFrameStrata("MEDIUM")
    display:SetMovable(true)
    display:EnableMouse(true)
    display:RegisterForDrag("LeftButton")
    display:SetClampedToScreen(true)

    display.background = display:CreateTexture(nil, "BACKGROUND")
    display.background:SetAllPoints()

    local title = display:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 10, -7)
    title:SetText("DOWNTIME")

    display.items = {}
    for _, metric in ipairs(metrics) do
        local heading = display:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        heading:SetText(metric.label)
        local value = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        value:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
        value:SetWidth(94)
        value:SetJustifyH("LEFT")
        value:SetText("--")
        display.items[metric.key] = { heading = heading, value = value }
    end

    display:SetScript("OnDragStart", function(self)
        if not DowntimeDB.locked then self:StartMoving() end
    end)
    display:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if x and y and parentX and parentY then
            DowntimeDB.detached = true
            DowntimeDB.x = x - parentX
            DowntimeDB.y = y - parentY
            AnchorDisplay()
        end
    end)
    display:SetScript("OnUpdate", function(self, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed
        if elapsedSinceUpdate < 0.25 then return end
        elapsedSinceUpdate = 0
        addon:SafeCall("Display", function() addon:UpdateDisplay() end)
    end)

    self:RefreshDisplayLayout()
    display:Show()
end

function addon:SetDisplayLocked(locked)
    DowntimeDB = DowntimeDB or {}
    DowntimeDB.locked = locked
    print("Downtime: Display " .. (locked and "locked." or "unlocked."))
end
