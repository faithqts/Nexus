Nexus = Nexus or {}
local NX = Nexus

NX.Constants = NX.Constants or {}
NX.Constants.VAULT_SPELL_ID = 449976
NX.Constants.VAULT_OFFSET_X = 0

NX.name = "Nexus"
NX.modules = NX.modules or {}

NexusDB = NexusDB or {}

local defaults = {
    autoInsertKeystone = false,

    mythicPlus = {
        respondToKeys = false,
        keysResponderCooldownSeconds = 5,
        autoHideObjectives = false,
        objectiveTrackerRestoreDelaySeconds = 30,
    },

    tankMarker = 6,
    healerMarker = 4,

    markingStyle = "leader",

    quickReloadSlash = true,
    quickCdmSlash = true,
    quickEditModeSlash = true,
    allowEscCloseCdmEditMode = false,

    moveSettingsPanel = false,

    vault = {
        enabled  = false,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 48,
        offsetY  = 0,
        flashing = true,
    },

    crosshair = {
        show = false,
        size = 18,
        thickness = 2,
        color = "#FFFFFF",
        alpha = 1.0,
    },

    lowDurability = {
        enabled   = false,
        fontPath  = "Fonts\\FRIZQT__.TTF",
        fontSize  = 48,
        threshold = 20,
        flashing  = true,
        offsetY   = 0,
        color     = "#FFFF00",
    },

    motionSickness = {
        enabled = false,
    },

    skyridingEffects = {
        enabled = false,
    },

    achievementScreenshot = {
        enabled = false,
        delaySeconds = 1.5,
    },

    autoCombatLog = {
        enabled = false,
        stopDelaySeconds = 30,
    },

    alwaysSharpen = {
        enabled = false,
    },

    enhancedErrorText = {
        enabled = false,
        fontSize = 22,
        width = 800,
        height = 120,
        outline = true,
    },

    cleanObjectiveTracker = {
        enabled = false,
        hideBackground = true,
        hideTitle = true,
    },

    waypointTracking = {
        autoTrackMapPins = true,
        unlimitedMapPinDistance = false,
    },

    autoPlaceSpells = {
        enabled = false,
    },

    floatingCombatText = {
        hideOverPlayer = false,
        hideOverPet = false,
        showCombatDamage = false,
        showCombatHealing = false,
    },

    assistedRotationOverlay = {
        enabled = false,
    },

    extraActionArtwork = {
        enabled = false,
    },

    hideTalkingHead = {
        enabled = false,
    },

    luaErrors = {
        enabled = false,
    },

    tutorials = {
        disabled = false,
    },

    hideScreenshotStatus = {
        enabled = false,
    },

    deleteDialog = {
        enabled = false,
    },

    autoConfirmDialogs = {
        enabled = false,
        replaceEnchant = true,
        acceptSockets = true,
    },

    autoDismount = {
        enabled = false,
        flying = false,
    },

    cinematics = {
        autoSkip = false,
        quickSkip = false,
    },

    questTrackerState = {
        enabled = false,
        collapsed = nil,
    },

    auctionHouse = {
        currentExpansionOnly = false,
    },

}

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function InitDB()
    NexusDB = NexusDB or {}
    ApplyDefaults(NexusDB, defaults)
    NX.DB = NexusDB
end

NX.Core = NX.Core or {}
local C = NX.Core

C._settingsMovableInit = C._settingsMovableInit or false

local function GetSettingsPanel()
    if _G.SettingsPanel then return _G.SettingsPanel end
    return nil
end

function C:UpdateSettingsPanelMovable()
    if not NX.DB then return end

    local panel = GetSettingsPanel()
    if not panel then return end

    if NX.DB.moveSettingsPanel then
        panel:SetMovable(true)
        panel:EnableMouse(true)
        panel:RegisterForDrag("LeftButton")

        if not self._settingsMovableInit then
            self._settingsMovableInit = true
            panel:HookScript("OnDragStart", function(p)
                if p:IsMovable() then
                    p:StartMoving()
                end
            end)

            panel:HookScript("OnDragStop", function(p)
                p:StopMovingOrSizing()
                local point, _, relPoint, x, y = p:GetPoint(1)
                NX.DB.settingsPanelPoint = point
                NX.DB.settingsPanelRelPoint = relPoint
                NX.DB.settingsPanelX = x
                NX.DB.settingsPanelY = y
            end)
        end

        local point = NX.DB.settingsPanelPoint
        local relPoint = NX.DB.settingsPanelRelPoint
        local x = NX.DB.settingsPanelX
        local y = NX.DB.settingsPanelY

        if point and relPoint and x and y then
            panel:ClearAllPoints()
            panel:SetPoint(point, UIParent, relPoint, x, y)
        end
    else
        panel:StopMovingOrSizing()
        panel:SetMovable(false)
        panel:RegisterForDrag()
        panel:EnableMouse(true)
    end
end

local function RegisterModule(name, tbl)
    if not name or type(name) ~= "string" then return end
    if type(tbl) ~= "table" then return end
    NX.modules[name] = tbl
end

local function CallModule(method, ...)
    for _, mod in pairs(NX.modules) do
        if type(mod) == "table" and type(mod[method]) == "function" then
            pcall(mod[method], mod, ...)
        end
    end
end

if NX.MythicPlus then
    RegisterModule("MythicPlus", NX.MythicPlus)
end

if NX.Vault then
    RegisterModule("Vault", NX.Vault)
end

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        InitDB()

        C_Timer.After(0, function()
            C:UpdateSettingsPanelMovable()
        end)

        if NX.Settings and NX.Settings.Register then
            NX.Settings:Register()
        end

        if NX.Common and NX.Common.SyncQuickReloadSlash then
            NX.Common:SyncQuickReloadSlash()
        end

        if NX.Common and NX.Common.Init then
            NX.Common:Init()
        end

        if NX.Crosshair and NX.Crosshair.Init then
            NX.Crosshair:Init()
        end

        if NX.MythicPlus and NX.MythicPlus.Init then
            NX.MythicPlus:Init()
        end

        if NX.Vault and NX.Vault.Init then
            NX.Vault:Init()
        end

        if NX.MotionSickness and NX.MotionSickness.Init then
            NX.MotionSickness:Init()
        end
        if NX.SkyridingEffects and NX.SkyridingEffects.Init then
            NX.SkyridingEffects:Init()
        end
        if NX.AchievementScreenshot and NX.AchievementScreenshot.Init then
            NX.AchievementScreenshot:Init()
        end
        if NX.AutoCombatLog and NX.AutoCombatLog.Init then
            NX.AutoCombatLog:Init()
        end
        if NX.AlwaysSharpen and NX.AlwaysSharpen.Init then
            NX.AlwaysSharpen:Init()
        end
        if NX.EnhancedErrorText and NX.EnhancedErrorText.Init then
            NX.EnhancedErrorText:Init()
        end
        if NX.CleanObjectiveTracker and NX.CleanObjectiveTracker.Init then
            NX.CleanObjectiveTracker:Init()
        end
        if NX.WaypointTracking and NX.WaypointTracking.Init then
            NX.WaypointTracking:Init()
        end

        if NX.AutoPlaceSpells and NX.AutoPlaceSpells.Init then
            NX.AutoPlaceSpells:Init()
        end
        if NX.FloatingCombatText and NX.FloatingCombatText.Init then
            NX.FloatingCombatText:Init()
        end
        if NX.AssistedRotationOverlay and NX.AssistedRotationOverlay.Init then
            NX.AssistedRotationOverlay:Init()
        end
        if NX.ExtraActionArtwork and NX.ExtraActionArtwork.Init then
            NX.ExtraActionArtwork:Init()
        end
        if NX.HideTalkingHead and NX.HideTalkingHead.Init then
            NX.HideTalkingHead:Init()
        end
        if NX.LuaErrors and NX.LuaErrors.Init then
            NX.LuaErrors:Init()
        end
        if NX.Tutorials and NX.Tutorials.Init then
            NX.Tutorials:Init()
        end
        if NX.HideScreenshotStatus and NX.HideScreenshotStatus.Init then
            NX.HideScreenshotStatus:Init()
        end
        if NX.DeleteDialog and NX.DeleteDialog.Init then
            NX.DeleteDialog:Init()
        end
        if NX.AutoConfirmDialogs and NX.AutoConfirmDialogs.Init then
            NX.AutoConfirmDialogs:Init()
        end
        if NX.AutoDismount and NX.AutoDismount.Init then
            NX.AutoDismount:Init()
        end
        if NX.Cinematics and NX.Cinematics.Init then
            NX.Cinematics:Init()
        end
        if NX.QuestTrackerState and NX.QuestTrackerState.Init then
            NX.QuestTrackerState:Init()
        end
        if NX.AuctionHouse and NX.AuctionHouse.Init then
            NX.AuctionHouse:Init()
        end

        CallModule("OnEvent", event, ...)
        return
    end

    if event == "ADDON_LOADED" and ... == "Blizzard_Settings" then
        C_Timer.After(0, function()
            C:UpdateSettingsPanelMovable()
        end)
    end

    if NX.Functions and NX.Functions.HandleRestrictionEvent then
        if event == "ENCOUNTER_START"
            or event == "ENCOUNTER_END"
            or event == "CHALLENGE_MODE_START"
            or event == "CHALLENGE_MODE_COMPLETED"
            or event == "CHALLENGE_MODE_RESET" then
            NX.Functions:HandleRestrictionEvent(event, ...)
        end
    end

    CallModule("OnEvent", event, ...)
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")

frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")

frame:RegisterEvent("CHALLENGE_MODE_START")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("CHALLENGE_MODE_RESET")

frame:RegisterEvent("START_TIMER")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("ROLE_CHANGED_INFORM")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

SLASH_NEXUS1 = "/nex"
SLASH_NEXUS2 = "/nexus"

SlashCmdList["NEXUS"] = function()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd200Nexus:|r Slash command blocked in combat state.")
        return
    end

    if Nexus and Nexus.Settings and Nexus.Settings.Open then
        Nexus.Settings:Open()
    end
end
