local NX = Nexus

NX.AssistedRotationOverlay = NX.AssistedRotationOverlay or {}

local ARO = NX.AssistedRotationOverlay

local assistedCallbackOwner

local function ForEachActionButton(fn)
    if type(fn) ~= "function" then return end
    if ActionBarButtonEvents and ActionBarButtonEvents.ForEachActionButton then
        pcall(ActionBarButtonEvents.ForEachActionButton, fn)
        return
    end

    local prefixes = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
    }

    for _, prefix in ipairs(prefixes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                pcall(fn, button)
            end
        end
    end
end

local function ApplyAssistedButton(button)
    if not button then return end
    local frame = button.AssistedCombatRotationFrame
    if not frame then return end

    if not frame.FQ_AssistedHideHooked and frame.HookScript then
        frame.FQ_AssistedHideHooked = true
        frame:HookScript("OnShow", function(self)
            if NX.DB and NX.DB.combat.assistedRotationOverlay and NX.DB.combat.assistedRotationOverlay.enabled then
                self:SetAlpha(0)
            elseif self.GetAlpha and self:GetAlpha() ~= 1 then
                self:SetAlpha(1)
            end
        end)
    end

    if NX.DB and NX.DB.combat.assistedRotationOverlay and NX.DB.combat.assistedRotationOverlay.enabled then
        frame:SetAlpha(0)
    else
        frame:SetAlpha(1)
    end
end

function ARO:Apply()
    if not NX.DB or not NX.DB.combat.assistedRotationOverlay then return end

    if NX.DB.combat.assistedRotationOverlay.enabled then
        if not assistedCallbackOwner and EventRegistry and EventRegistry.RegisterCallback then
            assistedCallbackOwner = {}
            EventRegistry:RegisterCallback(
                "ActionButton.OnAssistedCombatRotationFrameChanged",
                function(_, button, added)
                    if not (NX.DB and NX.DB.combat.assistedRotationOverlay and NX.DB.combat.assistedRotationOverlay.enabled) then return end
                    if added then
                        ApplyAssistedButton(button)
                    end
                end,
                assistedCallbackOwner
            )
        end
    elseif assistedCallbackOwner and EventRegistry and EventRegistry.UnregisterCallback then
        EventRegistry:UnregisterCallback("ActionButton.OnAssistedCombatRotationFrameChanged", assistedCallbackOwner)
        assistedCallbackOwner = nil
    end

    ForEachActionButton(ApplyAssistedButton)
end

function ARO:OnSettingsChanged()
    self:Apply()
end

function ARO:Init()
    self:Apply()
end


