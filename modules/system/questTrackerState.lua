local NX = Nexus
local CV = NX.CVars
local FN = NX.Functions

local function SetCVarBool(name, enabled)
    if FN and FN.SetCVarBool then
        FN:SetCVarBool(name, enabled)
        return
    end
    if CV and CV.SetBool then
        CV:SetBool(name, enabled)
    end
end

local function GetCVarBool(name, fallback)
    if FN and FN.GetCVarBool then
        return FN:GetCVarBool(name, fallback)
    end
    if CV and CV.GetBool then
        return CV:GetBool(name, fallback)
    end
    return fallback and true or false
end

NX.QuestTrackerState = NX.QuestTrackerState or {}
do
    local M = NX.QuestTrackerState
    local hooked
    local frame

    local function ApplyState()
        if not NX.DB or not NX.DB.system.questTrackerState or not NX.DB.system.questTrackerState.enabled then return end

        local tracker = _G.ObjectiveTrackerFrame
        if not tracker or not tracker.IsCollapsed or not tracker.SetCollapsed then return end

        local saved = NX.DB.system.questTrackerState.collapsed
        if saved == nil then
            NX.DB.system.questTrackerState.collapsed = tracker:IsCollapsed() and true or false
            return
        end

        if tracker:IsCollapsed() ~= saved then
            tracker:SetCollapsed(saved)
        end
    end

    local function EnsureHook()
        if hooked then return end
        local tracker = _G.ObjectiveTrackerFrame
        if not tracker or not hooksecurefunc then return end

        hooked = true
        hooksecurefunc(tracker, "SetCollapsed", function(_, collapsed)
            if NX.DB and NX.DB.system.questTrackerState and NX.DB.system.questTrackerState.enabled then
                NX.DB.system.questTrackerState.collapsed = collapsed and true or false
            end
        end)
    end

    function M:Apply()
        C_Timer.After(0, function()
            EnsureHook()
            ApplyState()
        end)
    end

    function M:OnSettingsChanged() self:Apply() end
    function M:Init()
        if not frame then
            frame = CreateFrame("Frame")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", function()
                self:Apply()
            end)
        end
        self:Apply()
    end
end


