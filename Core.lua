local addonName, addon = ...

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Initialize the display here, but NOT
        -- the experience session.
        addon:SafeCall("Display", function()
            addon:InitializeDisplay()
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...

        if isInitialLogin or isReloadingUi then
            addon:SafeCall("Experience", function()
                addon:InitializeExperience(isReloadingUi)
            end)
        end
    elseif event == "PLAYER_XP_UPDATE"
        or event == "PLAYER_LEVEL_UP" then
        addon:SafeCall("Experience", function()
            addon:UpdateExperience()
        end)
    elseif event == "PLAYER_LOGOUT" then
        addon:StopExperience()
    end
end)

SLASH_DOWNTIME1 = "/downtime"

SlashCmdList["DOWNTIME"] = function(message)
    message = (message or ""):lower()
    message = message:match("^%s*(.-)%s*$")

    if message == "lock" then
        addon:SafeCall("Commands", function()
            addon:SetDisplayLocked(true)
        end)
        return
    end

    if message == "unlock" then
        addon:SafeCall("Commands", function()
            addon:SetDisplayLocked(false)
        end)
        return
    end

    if message == "config" or message == "settings" then
        addon:SafeCall("Settings", function()
            addon:OpenSettings()
        end)
        return
    end

    if message == "resetsettings" then
        addon:SafeCall("Settings", function()
            addon:ResetDisplaySettings()
        end)
        return
    end

    if message == "reset" then
        addon:SafeCall("Commands", function()
            addon:ResetDisplayPosition()
            print("Downtime: Display position reset.")
        end)
        return
    end

    if message == "errors" then
        local errors = addon:GetErrors()

        if #errors == 0 then
            print("Downtime: No errors recorded.")
        else
            print("Downtime: " .. #errors .. " error(s) recorded.")

            for i, entry in ipairs(errors) do
                local summary = entry.message:match("^[^\r\n]*")
                print(string.format(
                    "#%d [%s] %s",
                    i,
                    entry.component,
                    summary or "Unknown error"
                ))
            end
        end
        return
    end

    if message == "testerror" then
        addon:SafeCall("Test", function()
            error("Intentional Downtime test error")
        end)
        print("Downtime: Test error triggered.")
        return
    end

    addon:SafeCall("Commands", function()
        local stats = addon:GetExperienceStats()

        print(string.format(
            "Downtime | XP: %d | XP/hour: %.0f | Since last XP: %.0fs",
            stats.totalXP,
            stats.xpPerHour,
            stats.sinceLastXP
        ))
    end)
end
