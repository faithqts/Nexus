local NX = Nexus
NX.Cinematics = NX.Cinematics or {}
local M = NX.Cinematics

local ef
local hooked

local function setupQuickSkipHooks()
    if hooked then return end
    if not _G.CinematicFrame or not _G.CinematicFrame.HookScript then return end

    _G.CinematicFrame:HookScript("OnKeyDown", function(_, key)
        if not (NX.DB and NX.DB.automation.cinematics and NX.DB.automation.cinematics.quickSkip) then return end
        if key == "ESCAPE" then
            if _G.CinematicFrame:IsShown() and _G.CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
                _G.CinematicFrame.closeDialog:Hide()
            end
        end
    end)

    _G.CinematicFrame:HookScript("OnKeyUp", function(_, key)
        if not (NX.DB and NX.DB.automation.cinematics and NX.DB.automation.cinematics.quickSkip) then return end
        if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
            if _G.CinematicFrame:IsShown() and _G.CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
                _G.CinematicFrameCloseDialogConfirmButton:Click()
            end
        end
    end)

    if _G.MovieFrame and _G.MovieFrame.HookScript then
        _G.MovieFrame:HookScript("OnKeyUp", function(_, key)
            if not (NX.DB and NX.DB.automation.cinematics and NX.DB.automation.cinematics.quickSkip) then return end
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
    if not NX.DB or not NX.DB.automation.cinematics then return end
    local cfg = NX.DB.automation.cinematics

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
    if not NX.DB or not NX.DB.automation.cinematics then return end
    local cfg = NX.DB.automation.cinematics

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

