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

NX.AutoPlaceSpells = NX.AutoPlaceSpells or {}
do
    local M = NX.AutoPlaceSpells
    function M:Apply()
        if not NX.DB or not NX.DB.system.autoPlaceSpells then return end
        SetCVarBool("AutoPushSpellToActionBar", NX.DB.system.autoPlaceSpells.enabled == true)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end


