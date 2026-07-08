local NX = Nexus
local FN = NX.Functions

local HIDE_HELPTIPS_CVAR = "hideHelptips"

local function EnsureHideHelpTipsCVarRegistered()
    local current = FN:GetCVarValue(HIDE_HELPTIPS_CVAR)
    if current ~= nil then
        return
    end

    if C_CVar and C_CVar.RegisterCVar then
        pcall(C_CVar.RegisterCVar, HIDE_HELPTIPS_CVAR, 1)
    end

    FN:SetCVarValue(HIDE_HELPTIPS_CVAR, 1)
end

NX.Tutorials = NX.Tutorials or {}
do
    local M = NX.Tutorials
    function M:Apply()
        if not NX.DB or not NX.DB.system.tutorials then return end

        EnsureHideHelpTipsCVarRegistered()

        local showTutorials = not (NX.DB.system.tutorials.disabled == true)
        FN:SetCVarBool("showTutorials", showTutorials)

        local hideMicroMenuPopups = NX.DB.system.tutorials.hideMicroMenuPopups == true
        if hideMicroMenuPopups then
            FN:SetCVarValue(HIDE_HELPTIPS_CVAR, 0)
        else
            FN:SetCVarValue(HIDE_HELPTIPS_CVAR, 1)
        end
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end
