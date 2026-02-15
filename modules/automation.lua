local NX = Nexus
NX.AchievementScreenshot = NX.AchievementScreenshot or {}
local AS = NX.AchievementScreenshot

local function EnsureDB()
    NX.DB.achievementScreenshot = NX.DB.achievementScreenshot or {}
    local db = NX.DB.achievementScreenshot
    if db.enabled == nil then db.enabled = false end
    if db.delaySeconds == nil then db.delaySeconds = 1.6 end
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

        local delay = tonumber(NX.DB.achievementScreenshot and NX.DB.achievementScreenshot.delaySeconds) or 1.6
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
    if NX.DB.achievementScreenshot.enabled then
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

local NX = Nexus
NX.Cinematics = NX.Cinematics or {}
local M = NX.Cinematics

local ef
local hooked

local function setupQuickSkipHooks()
    if hooked then return end
    if not _G.CinematicFrame or not _G.CinematicFrame.HookScript then return end

    _G.CinematicFrame:HookScript("OnKeyDown", function(_, key)
        if not (NX.DB and NX.DB.cinematics and NX.DB.cinematics.quickSkip) then return end
        if key == "ESCAPE" then
            if _G.CinematicFrame:IsShown() and _G.CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
                _G.CinematicFrame.closeDialog:Hide()
            end
        end
    end)

    _G.CinematicFrame:HookScript("OnKeyUp", function(_, key)
        if not (NX.DB and NX.DB.cinematics and NX.DB.cinematics.quickSkip) then return end
        if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
            if _G.CinematicFrame:IsShown() and _G.CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
                _G.CinematicFrameCloseDialogConfirmButton:Click()
            end
        end
    end)

    if _G.MovieFrame and _G.MovieFrame.HookScript then
        _G.MovieFrame:HookScript("OnKeyUp", function(_, key)
            if not (NX.DB and NX.DB.cinematics and NX.DB.cinematics.quickSkip) then return end
            if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
                if _G.MovieFrame:IsShown() and _G.MovieFrame.CloseDialog and _G.MovieFrame.CloseDialog.ConfirmButton then
                    _G.MovieFrame.CloseDialog.ConfirmButton:Click()
                end
            end
        end)
    end

    hooked = true
end

local function onEvent(_, event)
    if not NX.DB or not NX.DB.cinematics then return end
    local cfg = NX.DB.cinematics

    if cfg.autoSkip and cfg.quickSkip then

        cfg.quickSkip = false
    end

    if event == "CINEMATIC_START" then
        if cfg.autoSkip and not cfg.quickSkip then
            if _G.CinematicFrame and _G.CinematicFrame.isRealCinematic then
                StopCinematic()
            elseif CanCancelScene and CanCancelScene() then
                CancelScene()
            end
        end
    elseif event == "PLAY_MOVIE" then
        if cfg.autoSkip and not cfg.quickSkip then
            if _G.MovieFrame and _G.MovieFrame.Hide then _G.MovieFrame:Hide() end
        end
    end
end

function M:Apply()
    if not NX.DB or not NX.DB.cinematics then return end
    local cfg = NX.DB.cinematics

    if cfg.autoSkip and cfg.quickSkip then
        cfg.quickSkip = false
    end

    if cfg.quickSkip then
        C_Timer.After(0, setupQuickSkipHooks)
    end
end

function M:OnSettingsChanged() self:Apply() end

function M:Init()
    if not ef then
        ef = CreateFrame("Frame")
        ef:RegisterEvent("CINEMATIC_START")
        ef:RegisterEvent("PLAY_MOVIE")
        ef:SetScript("OnEvent", onEvent)
    end
    self:Apply()
end
