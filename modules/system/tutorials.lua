local NX = Nexus
local CV = NX.CVars
local FN = NX.Functions

local HIDE_HELPTIPS_CVAR = "hideHelptips"

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

local function GetCVarValue(name)
    if FN and FN.GetCVarValue then
        return FN:GetCVarValue(name)
    end

    if C_CVar and C_CVar.GetCVar then
        local ok, value = pcall(C_CVar.GetCVar, name)
        if ok then
            return value
        end
    elseif GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok then
            return value
        end
    end

    return nil
end

local function SetCVarValue(name, value)
    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, name, value)
        return
    end

    if FN and FN.SetCVarValue then
        FN:SetCVarValue(name, value)
        return
    end

    if SetCVar then
        pcall(SetCVar, name, value)
    end
end

local function EnsureHideHelpTipsCVarRegistered()
    local current = GetCVarValue(HIDE_HELPTIPS_CVAR)
    if current ~= nil then
        return
    end

    if C_CVar and C_CVar.RegisterCVar then
        pcall(C_CVar.RegisterCVar, HIDE_HELPTIPS_CVAR, 1)
    end

    SetCVarValue(HIDE_HELPTIPS_CVAR, 1)
end

NX.Tutorials = NX.Tutorials or {}
do
    local M = NX.Tutorials
    function M:Apply()
        if not NX.DB or not NX.DB.system.tutorials then return end

        EnsureHideHelpTipsCVarRegistered()

        local showTutorials = not (NX.DB.system.tutorials.disabled == true)
        SetCVarBool("showTutorials", showTutorials)

        local hideMicroMenuPopups = NX.DB.system.tutorials.hideMicroMenuPopups == true
        if hideMicroMenuPopups then
            SetCVarValue(HIDE_HELPTIPS_CVAR, 0)
        else
            SetCVarValue(HIDE_HELPTIPS_CVAR, 1)
        end
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end
