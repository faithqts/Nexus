local NX = Nexus
local FN = NX.Functions

NX.AutoPlaceSpells = NX.AutoPlaceSpells or {}
do
    local M = NX.AutoPlaceSpells
    function M:Apply()
        if not NX.DB or not NX.DB.system.autoPlaceSpells then return end
        FN:SetCVarBool("AutoPushSpellToActionBar", NX.DB.system.autoPlaceSpells.enabled == true)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end


