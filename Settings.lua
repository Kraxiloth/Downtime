local addonName, addon = ...

local defaults = {
    layout = "comfortable",
    opacity = 0.88,
    performanceColors = true,
    visible = {
        xp = true,
        last = true,
        tnl = true,
        rolling5 = true,
        rolling15 = true,
        rolling30 = true
    }
}

local order = { "xp", "last", "tnl", "rolling5", "rolling15", "rolling30" }
local names = {
    xp = "Session XP/hour",
    last = "Time since last XP",
    tnl = "Time to next level",
    rolling5 = "5-minute XP/hour",
    rolling15 = "15-minute XP/hour",
    rolling30 = "30-minute XP/hour"
}

function addon:InitializeSettings()
    DowntimeDB = DowntimeDB or {}
    local db = DowntimeDB
    if db.layout ~= "compact" and db.layout ~= "comfortable" then
        db.layout = defaults.layout
    end
    if type(db.opacity) ~= "number" then db.opacity = defaults.opacity end
    db.opacity = math.max(0.2, math.min(1, db.opacity))
    if type(db.performanceColors) ~= "boolean" then
        db.performanceColors = defaults.performanceColors
    end
    if type(db.visible) ~= "table" then db.visible = {} end
    for _, key in ipairs(order) do
        if type(db.visible[key]) ~= "boolean" then
            db.visible[key] = true
        end
    end
end

function addon:ResetDisplaySettings()
    self:InitializeSettings()
    DowntimeDB.layout = defaults.layout
    DowntimeDB.opacity = defaults.opacity
    DowntimeDB.performanceColors = defaults.performanceColors
    for _, key in ipairs(order) do
        DowntimeDB.visible[key] = true
    end
    if self.RefreshDisplayLayout then self:RefreshDisplayLayout() end
    if self.RefreshSettingsWindow then self:RefreshSettingsWindow() end
    print("Downtime: Display settings restored (position and session unchanged).")
end

local window
local checks = {}
local layoutButtons = {}
local opacityValue
local opacitySlider
local performanceCheck

function addon:RefreshSettingsWindow()
    if not window then return end
    self:InitializeSettings()
    for key, check in pairs(checks) do
        check:SetChecked(DowntimeDB.visible[key])
    end
    for mode, button in pairs(layoutButtons) do
        button:SetText((DowntimeDB.layout == mode and "|cff00ff88> " or "") ..
            (mode == "compact" and "Compact" or "Comfortable") .. "|r")
    end
    opacitySlider:SetValue(math.floor(DowntimeDB.opacity * 100 + 0.5))
    opacityValue:SetText(math.floor(DowntimeDB.opacity * 100 + 0.5) .. "%")
    if performanceCheck then
        performanceCheck:SetChecked(DowntimeDB.performanceColors)
    end
end

function addon:OpenSettings()
    self:InitializeSettings()
    if not window then
        window = CreateFrame("Frame", "DowntimeSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(345, 425)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetMovable(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window.TitleText:SetText("Downtime Settings")
        window:Hide()
        if UISpecialFrames then table.insert(UISpecialFrames, "DowntimeSettingsFrame") end

        local function Label(text, x, y)
            local label = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOPLEFT", window, "TOPLEFT", x, y)
            label:SetText(text)
            return label
        end

        Label("Visible metrics", 18, -38)
        for i, key in ipairs(order) do
            local check = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -52 - (i - 1) * 29)
            local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("LEFT", check, "RIGHT", 3, 0)
            text:SetText(names[key])
            check:SetScript("OnClick", function(self)
                DowntimeDB.visible[key] = self:GetChecked() and true or false
                addon:RefreshDisplayLayout()
            end)
            checks[key] = check
        end

        Label("Layout", 18, -235)
        for i, mode in ipairs({ "comfortable", "compact" }) do
            local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
            button:SetSize(140, 24)
            button:SetPoint("TOPLEFT", window, "TOPLEFT", 18 + (i - 1) * 150, -253)
            button:SetScript("OnClick", function()
                DowntimeDB.layout = mode
                addon:RefreshDisplayLayout()
                addon:RefreshSettingsWindow()
            end)
            layoutButtons[mode] = button
        end

        Label("Background opacity", 18, -292)
        opacityValue = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        opacityValue:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -292)

        opacitySlider = CreateFrame("Slider", "DowntimeOpacitySlider", window, "OptionsSliderTemplate")
        opacitySlider:SetPoint("TOP", window, "TOP", 0, -318)
        opacitySlider:SetWidth(260)
        opacitySlider:SetMinMaxValues(20, 100)
        opacitySlider:SetValueStep(1)
        if opacitySlider.SetObeyStepOnDrag then opacitySlider:SetObeyStepOnDrag(true) end
        _G[opacitySlider:GetName() .. "Low"]:SetText("20%")
        _G[opacitySlider:GetName() .. "High"]:SetText("100%")
        _G[opacitySlider:GetName() .. "Text"]:SetText("")
        opacitySlider:SetScript("OnValueChanged", function(self, value)
            local rounded = math.floor(value + 0.5)
            DowntimeDB.opacity = rounded / 100
            opacityValue:SetText(rounded .. "%")
            addon:RefreshDisplayLayout()
        end)

        performanceCheck = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
        performanceCheck:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -348)
        local performanceText = performanceCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        performanceText:SetPoint("LEFT", performanceCheck, "RIGHT", 3, 0)
        performanceText:SetText("Color rolling XP/hour by performance")
        performanceCheck:SetScript("OnClick", function(self)
            DowntimeDB.performanceColors = self:GetChecked() and true or false
            addon:RefreshDisplayLayout()
        end)

        local reset = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        reset:SetSize(155, 23)
        reset:SetPoint("BOTTOM", window, "BOTTOM", 0, 12)
        reset:SetText("Reset display settings")
        reset:SetScript("OnClick", function() addon:ResetDisplaySettings() end)
    end

    self:RefreshSettingsWindow()
    window:Show()
    window:Raise()
end
