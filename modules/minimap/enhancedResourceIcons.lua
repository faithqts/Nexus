local NX = Nexus
NX.MinimapResourceIcons = NX.MinimapResourceIcons or {}

local M = NX.MinimapResourceIcons
local ADDON = tostring(NX.name or "Nexus")
local DEFAULT_BLIP_TEXTURE = "Interface\\Minimap\\ObjectIcons"
local CUSTOM_ATLAS = "Interface\\AddOns\\" .. ADDON .. "\\media\\textures\\minimap\\AtlasReplacement"
local RELOAD_POPUP_KEY = "NEXUS_RELOAD_ENHANCED_MINIMAP_ICONS"

local frame = nil

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
    if db.enhancedResourceIconsEnabled == nil then db.enhancedResourceIconsEnabled = false end
    db.enhancedResourceIconsEnabled = db.enhancedResourceIconsEnabled and true or false
    return db
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
    if not db.enhancedResourceIconsEnabled then
        return
    end
    self:ApplyAtlas(CUSTOM_ATLAS)
end

function M:ShowReloadPrompt()
    if StaticPopup_Show then
        StaticPopup_Show(RELOAD_POPUP_KEY)
    else
        print("|cffffd200Nexus:|r Enhanced Minimap Icons enabled. Please run /reload.")
    end
end

function M:SetEnabled(enabled, showReloadPrompt)
    local db = self:EnsureDB()
    local oldValue = db.enhancedResourceIconsEnabled == true
    local newValue = enabled and true or false

    db.enhancedResourceIconsEnabled = newValue
    self:OnSettingsChanged()

    if showReloadPrompt and (not oldValue) and newValue then
        self:ShowReloadPrompt()
    end

    return newValue
end

function M:OnSettingsChanged()
    local db = self:EnsureDB()
    if db.enhancedResourceIconsEnabled then
        self:ApplyAtlas(CUSTOM_ATLAS)
    else
        self:ApplyDefaultAtlas()
    end
end

function M:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    local db = self:EnsureDB()

    if text == "" or text == "toggle" then
        local enabled = self:SetEnabled(not db.enhancedResourceIconsEnabled, true)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons " .. (enabled and "enabled." or "disabled."))
        return true
    end

    if text == "on" or text == "enable" or text == "enabled" then
        self:SetEnabled(true, true)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons enabled.")
        return true
    end

    if text == "off" or text == "disable" or text == "disabled" then
        self:SetEnabled(false, false)
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons disabled.")
        return true
    end

    if text == "status" then
        print("|cffffd200Nexus:|r Minimap Enhanced Resource Icons " .. (db.enhancedResourceIconsEnabled and "enabled." or "disabled."))
        return true
    end

    if text == "help" or text == "?" then
        print("|cffffd200Nexus:|r /nx resourceicons [on|off|toggle|status]")
        print("|cffffd200Nexus:|r /nx minimap resources [on|off|toggle|status]")
        return true
    end

    print("|cffffd200Nexus:|r Usage: /nx resourceicons [on|off|toggle|status]")
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
