local NX = Nexus

NX.HideScreenshotStatus = NX.HideScreenshotStatus or {}

local M = NX.HideScreenshotStatus

function M:Apply()
    if not NX.DB or not NX.DB.system.hideScreenshotStatus then return end
    local enabled = NX.DB.system.hideScreenshotStatus.enabled == true

    local actionStatus = _G.ActionStatus
    if not actionStatus or not actionStatus.UnregisterEvent or not actionStatus.RegisterEvent then return end

    if enabled then
        actionStatus:UnregisterEvent("SCREENSHOT_STARTED")
        actionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
        actionStatus:UnregisterEvent("SCREENSHOT_FAILED")
        if actionStatus.Hide then actionStatus:Hide() end
        return
    end

    actionStatus:RegisterEvent("SCREENSHOT_STARTED")
    actionStatus:RegisterEvent("SCREENSHOT_SUCCEEDED")
    actionStatus:RegisterEvent("SCREENSHOT_FAILED")
end

function M:OnSettingsChanged()
    self:Apply()
end

function M:Init()
    C_Timer.After(0, function()
        self:Apply()
    end)
end

