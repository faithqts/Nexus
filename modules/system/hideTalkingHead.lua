local NX = Nexus

NX.HideTalkingHead = NX.HideTalkingHead or {}

local M = NX.HideTalkingHead
local hooked

local function Apply()
    if not NX.DB or not NX.DB.system.hideTalkingHead then return end
    if not NX.DB.system.hideTalkingHead.enabled then return end

    local th = _G.TalkingHeadFrame
    if not th then return end

    th:Hide()

    if hooked or not th.HookScript then return end
    hooked = true

    if th.PlayCurrent then
        hooksecurefunc(th, "PlayCurrent", function(self)
            if NX.DB and NX.DB.system.hideTalkingHead and NX.DB.system.hideTalkingHead.enabled then
                self:Hide()
            end
        end)
        return
    end

    th:HookScript("OnShow", function(self)
        if NX.DB and NX.DB.system.hideTalkingHead and NX.DB.system.hideTalkingHead.enabled then
            self:Hide()
        end
    end)
end

function M:Apply()
    C_Timer.After(0, Apply)
end

function M:OnSettingsChanged()
    self:Apply()
end

function M:Init()
    self:Apply()
end

