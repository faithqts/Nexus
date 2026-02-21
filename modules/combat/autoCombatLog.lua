local NX = Nexus
NX.AutoCombatLog = NX.AutoCombatLog or {}
local CL = NX.AutoCombatLog

local function EnsureDB()
    NX.DB.automation.autoCombatLog = NX.DB.automation.autoCombatLog or {}
    local db = NX.DB.automation.autoCombatLog
    if db.enabled == nil then db.enabled = false end
    if db.stopDelaySeconds == nil then db.stopDelaySeconds = 30 end
end

local function CanLog()
    return type(LoggingCombat) == "function"
end

local function InSupportedInstance()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "party" then return true end
    if instanceType == "raid" then return true end
    if instanceType == "arena" then return true end
    if instanceType == "pvp" then return true end
    return false
end

function CL:Start(reason)
    if not self._active then return end
    if not CanLog() then return end

    if self._stopTimer then
        self._stopTimer:Cancel()
        self._stopTimer = nil
    end

    if not LoggingCombat() then
        LoggingCombat(true)
    end
end

function CL:StopWithDelay(reason)
    if not self._active then return end
    if not CanLog() then return end
    if not LoggingCombat() then return end
    if self._stopTimer then return end

    local delay = tonumber(NX.DB.automation.autoCombatLog.stopDelaySeconds) or 30
    if delay < 0 then delay = 0 end
    if delay > 60 then delay = 60 end
    self._stopTimer = C_Timer.NewTimer(delay, function()
        self._stopTimer = nil
        if not self._active then return end
        if not CanLog() then return end
        if LoggingCombat() then
            LoggingCombat(false)
        end
    end)
end

function CL:ZoneCheck()
    if not self._active then return end
    if InSupportedInstance() then
        self:Start("instance")
    else
        self:StopWithDelay("left instance")
    end
end

function CL:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:RegisterEvent("ENCOUNTER_START")
    self.frame:RegisterEvent("ENCOUNTER_END")
    self.frame:RegisterEvent("CHALLENGE_MODE_START")
    self.frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            self:ZoneCheck()
            return
        end
        if event == "ENCOUNTER_START" or event == "CHALLENGE_MODE_START" then
            self:Start(event)
            return
        end
        if event == "ENCOUNTER_END" or event == "CHALLENGE_MODE_COMPLETED" then
            self:StopWithDelay(event)
            return
        end
    end)

    self:ZoneCheck()
end

function CL:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._stopTimer then
        self._stopTimer:Cancel()
        self._stopTimer = nil
    end
end

function CL:ApplyConfig()
    EnsureDB()
    if NX.DB.automation.autoCombatLog.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function CL:Init()
    EnsureDB()
    self:ApplyConfig()
end

function CL:OnSettingsChanged()
    self:ApplyConfig()
end


