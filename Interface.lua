local addonName, addon = ...

local display
local elapsedSinceUpdate = 0

local function FormatTime(seconds)
    if not seconds or seconds < 0 or seconds == math.huge then
        return "--:--"
    end

    seconds = math.floor(seconds)

    if seconds >= 3600 then
        return string.format(
            "%d:%02d:%02d",
            math.floor(seconds / 3600),
            math.floor(seconds / 60) % 60,
            seconds % 60
        )
    end

    return string.format(
        "%02d:%02d",
        math.floor(seconds / 60),
        seconds % 60
    )
end

local function CreateMetric(parent, label, x, y)
    local heading = parent:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    heading:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y or -25)
    heading:SetText(label)

    local value = parent:CreateFontString(
        nil, "OVERLAY", "GameFontHighlight"
    )
    value:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
    value:SetWidth(94)
    value:SetJustifyH("LEFT")
    value:SetText("--")

    return value
end

local function AnchorDisplay()
    display:ClearAllPoints()

    if DowntimeDB and DowntimeDB.detached then
        display:SetPoint(
            "CENTER",
            UIParent,
            "CENTER",
            DowntimeDB.x or 0,
            DowntimeDB.y or 0
        )
    elseif PlayerFrame then
        display:SetPoint(
            "BOTTOMLEFT",
            PlayerFrame,
            "TOPLEFT",
            0,
            8
        )
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

function addon:UpdateDisplay()
    if not display then
        return
    end

    local stats = self:GetExperienceStats()

    display.xpValue:SetText(
        string.format("%.0f", stats.xpPerHour)
    )

    display.lastXPValue:SetText(
        FormatTime(stats.sinceLastXP)
    )

    display.rolling5Value:SetText(string.format("%.0f", stats.rolling5 or 0))
    display.rolling15Value:SetText(string.format("%.0f", stats.rolling15 or 0))
    display.rolling30Value:SetText(string.format("%.0f", stats.rolling30 or 0))

    local xpPerHour = stats.xpPerHour

    if xpPerHour > 0 then
        local remainingXP =
            UnitXPMax("player") - UnitXP("player")

        local secondsToLevel =
            remainingXP / xpPerHour * 3600

        display.tnlValue:SetText(
            FormatTime(secondsToLevel)
        )
    else
        display.tnlValue:SetText("--:--")
    end
end

function addon:InitializeDisplay()
    if display then
        return
    end

    DowntimeDB = DowntimeDB or {}

    if DowntimeDB.locked == nil then
        DowntimeDB.locked = true
    end

    display = CreateFrame("Frame", nil, UIParent)
    display:SetSize(310, 116)
    display:SetFrameStrata("MEDIUM")
    display:SetMovable(true)
    display:EnableMouse(true)
    display:RegisterForDrag("LeftButton")
    display:SetClampedToScreen(true)

    local background = display:CreateTexture(
        nil, "BACKGROUND"
    )
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.06, 0.09, 0.88)

    local title = display:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    title:SetPoint("TOPLEFT", 10, -7)
    title:SetText("DOWNTIME")

    display.xpValue = CreateMetric(
        display, "XP / HOUR", 10
    )

    display.lastXPValue = CreateMetric(
        display, "LAST XP", 112
    )

    display.tnlValue = CreateMetric(
        display, "NEXT LEVEL", 214
    )

    local separator = display:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.35, 0.39, 0.45, 0.5)
    separator:SetPoint("TOPLEFT", display, "TOPLEFT", 10, -69)
    separator:SetPoint("TOPRIGHT", display, "TOPRIGHT", -10, -69)
    separator:SetHeight(1)

    display.rolling5Value = CreateMetric(display, "5 MIN XP/H", 10, -77)
    display.rolling15Value = CreateMetric(display, "15 MIN XP/H", 112, -77)
    display.rolling30Value = CreateMetric(display, "30 MIN XP/H", 214, -77)

    display:SetScript("OnDragStart", function(self)
        if DowntimeDB.locked then
            return
        end

        self:StartMoving()
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

        if elapsedSinceUpdate < 0.25 then
            return
        end

        elapsedSinceUpdate = 0

        addon:SafeCall("Display", function()
            addon:UpdateDisplay()
        end)
    end)

    AnchorDisplay()
    self:UpdateDisplay()
    display:Show()
end

function addon:SetDisplayLocked(locked)
    DowntimeDB = DowntimeDB or {}
    DowntimeDB.locked = locked

    print(
        "Downtime: Display " ..
        (locked and "locked." or "unlocked.")
    )
end
