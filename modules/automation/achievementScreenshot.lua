local NX = Nexus
NX.AchievementScreenshot = NX.AchievementScreenshot or {}
local AS = NX.AchievementScreenshot

local function GetDefaultDelaySeconds()
    return NX.Defaults
        and NX.Defaults.automation
        and NX.Defaults.automation.achievementScreenshot
        and NX.Defaults.automation.achievementScreenshot.delaySeconds
        or 0.5
end

local function EnsureDB()
    NX.DB.automation.achievementScreenshot = NX.DB.automation.achievementScreenshot or {}
    local db = NX.DB.automation.achievementScreenshot
    if db.enabled == nil then db.enabled = false end
    if db.delaySeconds == nil then db.delaySeconds = GetDefaultDelaySeconds() end
end

function AS:Queue()
    if not self._active then return end
    self._queued = (self._queued or 0) + 1

    if self._processing then return end
    self._processing = true

    local function ProcessNext()
        if not self._active then
            self._processing = false
            self._queued = 0
            return
        end

        if (self._queued or 0) <= 0 then
            self._processing = false
            return
        end

        self._queued = self._queued - 1

        local delay = tonumber(NX.DB.automation.achievementScreenshot and NX.DB.automation.achievementScreenshot.delaySeconds) or GetDefaultDelaySeconds()
        if delay < 0 then delay = 0 end

        self._timer = C_Timer.NewTimer(delay, function()
            if not self._active then
                self._processing = false
                self._queued = 0
                return
            end

            Screenshot()
            self._timer = nil
            ProcessNext()
        end)
    end

    ProcessNext()
end

function AS:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("ACHIEVEMENT_EARNED")
    self.frame:SetScript("OnEvent", function(_, event)
        if event == "ACHIEVEMENT_EARNED" then
            self:Queue()
        end
    end)
end

function AS:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._timer then
        self._timer:Cancel()
        self._timer = nil
    end

    self._queued = 0
    self._processing = false
end

function AS:ApplyConfig()
    EnsureDB()
    if NX.DB.automation.achievementScreenshot.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function AS:Init()
    EnsureDB()
    self:ApplyConfig()
end

function AS:OnSettingsChanged()
    self:ApplyConfig()
end


