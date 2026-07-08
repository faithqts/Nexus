local NX = Nexus
local FN = NX.Functions

NX.AutoDismount = NX.AutoDismount or {}
do
    local M = NX.AutoDismount
    function M:Apply()
        if not NX.DB or not NX.DB.system.autoDismount then return end
        local cfg = NX.DB.system.autoDismount
        FN:SetCVarBool("autoDismount", cfg.enabled ~= false)
        FN:SetCVarBool("autoDismountFlying", cfg.flying ~= false)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end


