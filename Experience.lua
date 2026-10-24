local addonName, addon = ...
addon = addon or {}

local session = nil
local initialized = false

local previousXP = nil
local previousXPMax = nil
local previousLevel = nil

local heartbeat = CreateFrame("Frame")
local accumulator = 0

local function PruneHistory()
    if not session or not session.xpHistory then
        return
    end

    local cutoff = session.elapsed - 1800
    local history = session.xpHistory

    local firstValid = 1

    while firstValid <= #history
        and history[firstValid].time <= cutoff do
        firstValid = firstValid + 1
    end

    if firstValid > 1 then
        local remaining = #history - firstValid + 1

        for i = 1, remaining do
            history[i] = history[i + firstValid - 1]
        end

        for i = remaining + 1, #history do
            history[i] = nil
        end
    end
end

local function NewSession()
    return {
        totalXP = 0,
        elapsed = 0,
        sinceLastXP = nil,
        xpHistory = {}
    }
end

function addon:InitializeExperience(isReloading)
    DowntimeCharacterDB = DowntimeCharacterDB or {}

    if isReloading
        and type(DowntimeCharacterDB.session) == "table"
    then
        session = DowntimeCharacterDB.session

        session.totalXP = session.totalXP or 0
        session.elapsed = session.elapsed or 0
    else
        session = NewSession()
        DowntimeCharacterDB.session = session
    end

    -- Establish a fresh XP baseline after loading.
    session.xpHistory = session.xpHistory or {}
    PruneHistory()
    previousXP = UnitXP("player")
    previousXPMax = UnitXPMax("player")
    previousLevel = UnitLevel("player")

    accumulator = 0
    initialized = true

    heartbeat:Show()
end

function addon:UpdateExperience()
    if not initialized then
        return
    end

    local currentXP = UnitXP("player")
    local currentXPMax = UnitXPMax("player")
    local currentLevel = UnitLevel("player")

    local gained = 0

    if currentLevel == previousLevel then
        gained = currentXP - previousXP
    elseif currentLevel == previousLevel + 1 then
        gained = previousXPMax - previousXP + currentXP
    else
        -- Unexpected level change.
        -- Rebaseline rather than invent XP.
        previousXP = currentXP
        previousXPMax = currentXPMax
        previousLevel = currentLevel
        return
    end

    if gained > 0 then
        session.totalXP = session.totalXP + gained
        session.sinceLastXP = 0

        local history = session.xpHistory

        history[#history + 1] = {
            time = session.elapsed,
            xp = gained
        }

        PruneHistory()
    end

    previousXP = currentXP
    previousXPMax = currentXPMax
    previousLevel = currentLevel
end

function addon:GetRollingXPPerHour(windowSeconds)
    if not initialized or not session then
        return 0
    end

    local duration = math.min(session.elapsed, windowSeconds)

    if duration <= 0 then
        return 0
    end

    local cutoff = session.elapsed - windowSeconds
    local gained = 0

    for _, entry in ipairs(session.xpHistory) do
        if entry.time > cutoff then
            gained = gained + entry.xp
        end
    end

    return gained / duration * 3600
end

function addon:GetExperienceStats()
    if not initialized then
        return {
            totalXP = 0,
            elapsed = 0,
            xpPerHour = 0,
            sinceLastXP = 0,
            rolling5 = 0,
            rolling15 = 0,
            rolling30 = 0
        }
    end

    local elapsed = session.elapsed

    return {
        totalXP = session.totalXP,
        elapsed = elapsed,

        xpPerHour = elapsed > 0
            and (session.totalXP / elapsed * 3600)
            or 0,

        sinceLastXP = session.sinceLastXP
            or elapsed,

        rolling5 = self:GetRollingXPPerHour(300),
        rolling15 = self:GetRollingXPPerHour(900),
        rolling30 = self:GetRollingXPPerHour(1800)
    }
end

heartbeat:Hide()

heartbeat:SetScript("OnUpdate", function(self, elapsed)
    if not initialized then
        return
    end

    accumulator = accumulator + elapsed

    if accumulator < 1 then
        return
    end

    local delta = accumulator
    accumulator = 0

    session.elapsed = session.elapsed + delta

    PruneHistory()

    if session.sinceLastXP ~= nil then
        session.sinceLastXP = session.sinceLastXP + delta
    end
end)

function addon:StopExperience()
    heartbeat:Hide()
    initialized = false
end
