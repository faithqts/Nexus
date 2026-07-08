local NX = Nexus
local FN = NX.Functions

NX.LuaErrors = NX.LuaErrors or {}
do
    local M = NX.LuaErrors
    function M:Apply()
        if not NX.DB or not NX.DB.system.luaErrors then return end
        FN:SetCVarBool("scriptErrors", NX.DB.system.luaErrors.enabled == true)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end


