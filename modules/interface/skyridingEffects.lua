local NX = Nexus
NX.SkyridingEffects = NX.SkyridingEffects or {}
local SE = NX.SkyridingEffects

local SETTING_NAME = "DisableAdvancedFlyingFullScreenEffects"

local function EnsureDB()
    NX.DB.interface.skyridingEffects = NX.DB.interface.skyridingEffects or {}
    if NX.DB.interface.skyridingEffects.enabled == nil then
        NX.DB.interface.skyridingEffects.enabled = true
    end
end

function SE:Apply()
    if not self._active then return end

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting and not setting.locked then

        setting:ApplyValue(true)
        return
    end

    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, SETTING_NAME, "1")
    end
end

function SE:Enable()
    if self._active then return end
    self._active = true

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting then
        self._prev = setting:GetValue()
    end

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("SETTINGS_LOADED")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
    end)

    self:Apply()
end

function SE:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting and self._prev ~= nil then
        setting:ApplyValue(self._prev)
    end
end

function SE:ApplyConfig()
    EnsureDB()
    if NX.DB.interface.skyridingEffects.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function SE:Init()
    EnsureDB()
    self:ApplyConfig()
end

function SE:OnSettingsChanged()
    self:ApplyConfig()
end


