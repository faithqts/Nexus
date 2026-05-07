local NX = Nexus
NX.MinimapResourceIcons = NX.MinimapResourceIcons or {}

local M = NX.MinimapResourceIcons
local ADDON = tostring(NX.name or "Nexus")
local DEFAULT_BLIP_TEXTURE = "Interface\\AddOns\\" .. ADDON .. "\\media\\textures\\minimap\\default.blp"
local ENHANCED_BLIP_TEXTURE = "Interface\\AddOns\\" .. ADDON .. "\\media\\textures\\minimap\\enhanced.blp"
local RELOAD_POPUP_KEY = "NEXUS_RELOAD_ENHANCED_MINIMAP_ICONS"

local MODE_DEFAULT = "default"
local MODE_ENHANCED = "enhanced"

local MODE_TO_ATLAS = {
    [MODE_DEFAULT] = DEFAULT_BLIP_TEXTURE,
    [MODE_ENHANCED] = ENHANCED_BLIP_TEXTURE,
}

local MODE_LABEL = {
    [MODE_DEFAULT] = "Default",
    [MODE_ENHANCED] = "Enhanced",
}

local frame = nil

local function IsLegacyEnabled(value)
    if value == true or value == 1 then
        return true
    end

    if type(value) == "string" then
        local text = string.lower(string.match(value, "^%s*(.-)%s*$") or "")
        return text == "1" or text == "true"
    end

    return false
end

local function NormalizeMode(value)
    local text = string.lower(tostring(value or MODE_DEFAULT))
    text = string.match(text, "^%s*(.-)%s*$") or MODE_DEFAULT
    local compact = string.gsub(text, "[%s%+&%-_]", "")

    if text == MODE_ENHANCED
        or compact == "enhanced"
        or compact == "resources"
        or compact == "resource"
        or compact == "resourcesandchests"
        or compact == "resourceschests"
        or compact == "resourcechests"
        or compact == "both"
        or compact == "resourcesslayers"
        or compact == "resourceslayers"
        or compact == "resourceslayersrise"
        or compact == "slayers"
        or compact == "slayersrise"
        or compact == "allinone"
    then
        return MODE_ENHANCED
    end

    return MODE_DEFAULT
end

if StaticPopupDialogs and not StaticPopupDialogs[RELOAD_POPUP_KEY] then
    StaticPopupDialogs[RELOAD_POPUP_KEY] = {
        text = "Enhanced Minimap Icons requires a UI Reload.",
        button1 = "Reload Now",
        button2 = "Cancel",
        OnAccept = function()
            if ConsoleExec then
                ConsoleExec("reloadui")
            elseif C_UI and C_UI.Reload then
                C_UI.Reload()
            elseif ReloadUI then
                ReloadUI()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function M:EnsureDB()
    NX.DB.interface.minimap = NX.DB.interface.minimap or {}
    local db = NX.DB.interface.minimap

    if db.enhancedResourceIconsMode == nil then
        local legacyEnabled = IsLegacyEnabled(db.enhancedResourceIconsEnabled)
        db.enhancedResourceIconsMode = legacyEnabled and MODE_ENHANCED or MODE_DEFAULT
    end

    db.enhancedResourceIconsMode = NormalizeMode(db.enhancedResourceIconsMode)
    db.enhancedResourceIconsEnabled = db.enhancedResourceIconsMode ~= MODE_DEFAULT

    return db
end

function M:GetMode()
    local db = self:EnsureDB()
    return db.enhancedResourceIconsMode
end

function M:GetModeLabel(mode)
    mode = NormalizeMode(mode)
    return MODE_LABEL[mode] or MODE_LABEL[MODE_DEFAULT]
end

function M:ApplyAtlas(tex)
    if Minimap and Minimap.SetBlipTexture then
        Minimap:SetBlipTexture(tex)
    end
end

function M:ApplyDefaultAtlas()
    self:ApplyAtlas(DEFAULT_BLIP_TEXTURE)
end

function M:ApplyIfEnabled()
    local db = self:EnsureDB()
    local mode = NormalizeMode(db.enhancedResourceIconsMode)
    local atlas = MODE_TO_ATLAS[mode] or DEFAULT_BLIP_TEXTURE
    self:ApplyAtlas(atlas)
end

function M:ShowReloadPrompt()
    if StaticPopup_Show then
        StaticPopup_Show(RELOAD_POPUP_KEY)
    else
        print("|cffffd200Nexus:|r Enhanced Minimap Icons enabled. Please run /reload.")
    end
end

function M:SetMode(mode, showReloadPrompt)
    local db = self:EnsureDB()
    local oldMode = NormalizeMode(db.enhancedResourceIconsMode)
    local newMode = NormalizeMode(mode)

    db.enhancedResourceIconsMode = newMode
    db.enhancedResourceIconsEnabled = newMode ~= MODE_DEFAULT
    self:OnSettingsChanged()

    if showReloadPrompt and oldMode ~= newMode and newMode ~= MODE_DEFAULT then
        self:ShowReloadPrompt()
    end

    return newMode
end

function M:SetEnabled(enabled, showReloadPrompt)
    if enabled then
        return self:SetMode(MODE_ENHANCED, showReloadPrompt)
    end

    return self:SetMode(MODE_DEFAULT, showReloadPrompt)
end

function M:OnSettingsChanged()
    self:ApplyIfEnabled()
end

function M:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local compact = string.gsub(text, "[%s%+&%-_]", "")

    local db = self:EnsureDB()

    if text == "" or text == "toggle" then
        local nextMode = (NormalizeMode(db.enhancedResourceIconsMode) == MODE_DEFAULT) and MODE_ENHANCED or MODE_DEFAULT
        local mode = self:SetMode(nextMode, true)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons mode: " .. self:GetModeLabel(mode) .. ".")
        return true
    end

    if text == "on" or text == "enable" or text == "enabled" then
        local mode = self:SetMode(MODE_ENHANCED, true)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons mode: " .. self:GetModeLabel(mode) .. ".")
        return true
    end

    if text == MODE_ENHANCED
        or text == "resources"
        or text == "resource"
        or compact == "resourceschests"
        or compact == "resourcechests"
        or compact == "both"
        or compact == "resourcesslayers"
        or compact == "resourceslayers"
        or compact == "resourceslayersrise"
        or compact == "slayers"
        or compact == "slayersrise"
        or compact == "allinone"
    then
        local mode = self:SetMode(MODE_ENHANCED, true)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons mode: " .. self:GetModeLabel(mode) .. ".")
        return true
    end

    if text == "default" or text == "none" or text == "off" or text == "disable" or text == "disabled" then
        local mode = self:SetMode(MODE_DEFAULT, false)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons mode: " .. self:GetModeLabel(mode) .. ".")
        return true
    end

    if text == "status" then
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons mode: " .. self:GetModeLabel(db.enhancedResourceIconsMode) .. ".")
        return true
    end

    if text == "help" or text == "?" then
        print("|cffffd200Nexus:|r /nx resourceicons [default|enhanced|on|off|toggle|status]")
        print("|cffffd200Nexus:|r /nx minimap resources [default|enhanced|on|off|toggle|status]")
        return true
    end

    print("|cffffd200Nexus:|r Usage: /nx resourceicons [default|enhanced|on|off|toggle|status]")
    return true
end

function M:Init()
    self:EnsureDB()
    self:ApplyIfEnabled()

    if frame then
        return
    end

    frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
    frame:SetScript("OnEvent", function()
        M:ApplyIfEnabled()
    end)
end
