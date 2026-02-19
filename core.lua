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

    addonFontPath = "Fonts\\FRIZQT__.TTF",

    greatVault = {
        enabled  = true,
        anchorX = 0,
        anchorY = 0,
        positionUnlocked = false,
        fontSize = 48,
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
        anchorX = 0,
        anchorY = 0,
        positionUnlocked = false,
        fontSize  = 48,
        threshold = 20,
        flashing  = true,
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
        offsetY = 0,
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
        highlightedQuestMarker = false,
    },

    autoPlaceSpells = {
        enabled = false,
    },

    floatingCombatText = {
        hideOverPlayer = false,
        hideOverPet = false,
        showCombatDamage = false,
        showCombatHealing = false,
        showHealingAbsorbSelf = false,
        showHealingAbsorbTarget = false,
        showCombatState = false,
        showComboPoints = false,
        showDamageReduction = false,
        showDodgeParryMiss = false,
        showEnergyGains = false,
        showFloatMode = false,
        showFriendlyHealers = false,
        showHonorGains = false,
        showLowManaHealth = false,
        showPeriodicEnergyGains = false,
        showPetMeleeDamage = false,
        showPetSpellDamage = false,
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

    simpleFirstCraftBonus = {
        enabled = false,
    },

    clickableBuffs = {
        enabled = false,
        anchorX = 0,
        anchorY = 0,
        iconSize = 48,
        textSize = 18,
        iconZoomPct = 15,
        flashMissing = false,
    },

    statsPlus = {
        enabled = false,
        anchorX = 0,
        anchorY = 0,
        positionUnlocked = false,
        style = "VERTICAL",
        textAlignment = "LEFT",
        textGrowthDirection = "DOWN",
        fontSize = 14,
        showPrimaryStat = true,
        showHaste = true,
        showMastery = true,
        showCriticalStrike = true,
        showVersatility = true,
        showArmor = true,
        showMeleeAvoidance = true,
    },

    cleanNamesInInstances = {
        enabled = false,

        inInstanceShowGuild = false,
        inInstanceShowTitle = false,
        inInstanceSize = 12,
        inInstanceMinAlpha = 1.0,
    },

    portals = {
        enabled = true,
        anchorX = 0,
        anchorY = -35,
        topRowMax = 8,
        topRowHeightPct = 80,
        perRow = 12,
        smallRowHeightPct = 80,
        spacing = 2,
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

NX.CVars = NX.CVars or {}
local CV = NX.CVars

function CV:GetRaw(name)
    if type(name) ~= "string" then return nil end

    local value
    if NX.Functions and NX.Functions.GetCVarValue then
        value = NX.Functions:GetCVarValue(name)
    elseif C_CVar and C_CVar.GetCVar then
        local ok, result = pcall(C_CVar.GetCVar, name)
        if ok then value = result end
    elseif GetCVar then
        local ok, result = pcall(GetCVar, name)
        if ok then value = result end
    end

    if value == "1" or value == "0" then
        return value
    end

    return nil
end

function CV:GetBool(name, fallback)
    local raw = self:GetRaw(name)
    if raw == "1" then return true end
    if raw == "0" then return false end
    return fallback and true or false
end

function CV:SetBool(name, enabled)
    if type(name) ~= "string" then return end
    if NX.Functions and NX.Functions.SetCVarBool then
        NX.Functions:SetCVarBool(name, enabled)
        return
    end
    local value = enabled and "1" or "0"
    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, name, value)
        return
    end
    if SetCVar then
        pcall(SetCVar, name, value)
    end
end

function CV:ReconcileBool(name, addonValue)
    local resolved = addonValue and true or false
    local raw = self:GetRaw(name)

    if raw == "1" or raw == "0" then
        local current = (raw == "1")
        if current ~= resolved then
            self:SetBool(name, resolved)
            return resolved
        end
        return current
    end

    self:SetBool(name, resolved)
    return resolved
end

local function SeedCVarBackedDefaults(db)
    if not db or db._cvarSeeded then return end

    db.luaErrors = db.luaErrors or {}
    db.luaErrors.enabled = CV:GetBool("scriptErrors", db.luaErrors.enabled == true)

    db.tutorials = db.tutorials or {}
    local showTutorials = CV:GetBool("showTutorials", db.tutorials.disabled ~= true)
    db.tutorials.disabled = not showTutorials

    db.autoDismount = db.autoDismount or {}
    db.autoDismount.enabled = CV:GetBool("autoDismount", db.autoDismount.enabled ~= false)
    db.autoDismount.flying = CV:GetBool("autoDismountFlying", db.autoDismount.flying ~= false)

    db.autoPlaceSpells = db.autoPlaceSpells or {}
    db.autoPlaceSpells.enabled = CV:GetBool("AutoPushSpellToActionBar", db.autoPlaceSpells.enabled == true)

    db.floatingCombatText = db.floatingCombatText or {}
    db.floatingCombatText.showCombatDamage = CV:GetBool(
        "floatingCombatTextCombatDamage_v2",
        db.floatingCombatText.showCombatDamage == true
    )
    db.floatingCombatText.showCombatHealing = CV:GetBool(
        "floatingCombatTextCombatHealing_v2",
        db.floatingCombatText.showCombatHealing == true
    )
    db.floatingCombatText.showHealingAbsorbSelf = CV:GetBool(
        "floatingCombatTextCombatHealingAbsorbSelf_v2",
        db.floatingCombatText.showHealingAbsorbSelf == true
    )
    db.floatingCombatText.showHealingAbsorbTarget = CV:GetBool(
        "floatingCombatTextCombatHealingAbsorbTarget_v2",
        db.floatingCombatText.showHealingAbsorbTarget == true
    )
    db.floatingCombatText.showCombatState = CV:GetBool(
        "floatingCombatTextCombatState_v2",
        db.floatingCombatText.showCombatState == true
    )
    db.floatingCombatText.showComboPoints = CV:GetBool(
        "floatingCombatTextComboPoints_v2",
        db.floatingCombatText.showComboPoints == true
    )
    db.floatingCombatText.showDamageReduction = CV:GetBool(
        "floatingCombatTextDamageReduction_v2",
        db.floatingCombatText.showDamageReduction == true
    )
    db.floatingCombatText.showDodgeParryMiss = CV:GetBool(
        "floatingCombatTextDodgeParryMiss_v2",
        db.floatingCombatText.showDodgeParryMiss == true
    )
    db.floatingCombatText.showEnergyGains = CV:GetBool(
        "floatingCombatTextEnergyGains_v2",
        db.floatingCombatText.showEnergyGains == true
    )
    db.floatingCombatText.showFloatMode = CV:GetBool(
        "floatingCombatTextFloatMode_v2",
        db.floatingCombatText.showFloatMode == true
    )
    db.floatingCombatText.showFriendlyHealers = CV:GetBool(
        "floatingCombatTextFriendlyHealers_v2",
        db.floatingCombatText.showFriendlyHealers == true
    )
    db.floatingCombatText.showHonorGains = CV:GetBool(
        "floatingCombatTextHonorGains_v2",
        db.floatingCombatText.showHonorGains == true
    )
    db.floatingCombatText.showLowManaHealth = CV:GetBool(
        "floatingCombatTextLowManaHealth_v2",
        db.floatingCombatText.showLowManaHealth == true
    )
    db.floatingCombatText.showPeriodicEnergyGains = CV:GetBool(
        "floatingCombatTextPeriodicEnergyGains_v2",
        db.floatingCombatText.showPeriodicEnergyGains == true
    )
    db.floatingCombatText.showPetMeleeDamage = CV:GetBool(
        "floatingCombatTextPetMeleeDamage_v2",
        db.floatingCombatText.showPetMeleeDamage == true
    )
    db.floatingCombatText.showPetSpellDamage = CV:GetBool(
        "floatingCombatTextPetSpellDamage_v2",
        db.floatingCombatText.showPetSpellDamage == true
    )

    db._cvarSeeded = true
end

local function MigrateLegacyGreatVault(db)
    if type(db) ~= "table" then
        return
    end

    local legacy = db.vault
    if type(legacy) ~= "table" then
        return
    end

    db.greatVault = db.greatVault or {}
    local target = db.greatVault

    if target.enabled == nil and legacy.enabled ~= nil then
        target.enabled = legacy.enabled and true or false
    end
    if target.anchorX == nil and legacy.anchorX ~= nil then
        target.anchorX = legacy.anchorX
    end
    if target.anchorY == nil then
        if legacy.anchorY ~= nil then
            target.anchorY = legacy.anchorY
        elseif legacy.offsetY ~= nil then
            target.anchorY = legacy.offsetY
        end
    end
    if target.fontSize == nil and legacy.fontSize ~= nil then
        target.fontSize = legacy.fontSize
    end
    if target.flashing == nil and legacy.flashing ~= nil then
        target.flashing = legacy.flashing and true or false
    end
end

local function MigrateLegacyAddonFont(db)
    if type(db) ~= "table" then
        return
    end

    if type(db.addonFontPath) == "string" and db.addonFontPath ~= "" then
        return
    end

    local candidates = {
        db.greatVault and db.greatVault.fontPath,
        db.lowDurability and db.lowDurability.fontPath,
        db.vault and db.vault.fontPath,
    }

    for _, path in ipairs(candidates) do
        if type(path) == "string" and path ~= "" then
            db.addonFontPath = path
            return
        end
    end
end

local function InitDB()
    NexusDB = NexusDB or {}
    MigrateLegacyGreatVault(NexusDB)
    MigrateLegacyAddonFont(NexusDB)
    ApplyDefaults(NexusDB, defaults)
    SeedCVarBackedDefaults(NexusDB)
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

        if NX.Portals and NX.Portals.Init then
            NX.Portals:Init()
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
        if NX.CatalystCharges and NX.CatalystCharges.Init then
            NX.CatalystCharges:Init()
        end

        if NX.AutoPlaceSpells and NX.AutoPlaceSpells.Init then
            NX.AutoPlaceSpells:Init()
        end
        if NX.CVarStateSync and NX.CVarStateSync.Init then
            NX.CVarStateSync:Init()
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
        if NX.SimpleFirstCraftBonus and NX.SimpleFirstCraftBonus.Init then
            NX.SimpleFirstCraftBonus:Init()
        end
        if NX.ClickableBuffs and NX.ClickableBuffs.Init then
            NX.ClickableBuffs:Init()
        end
        if NX.StatsPlus and NX.StatsPlus.Init then
            NX.StatsPlus:Init()
        end
        if NX.CleanNamesInInstances and NX.CleanNamesInInstances.Init then
            NX.CleanNamesInInstances:Init()
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

    if NX.Portals and NX.Portals.OnEvent then
        NX.Portals:OnEvent(event, ...)
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
frame:RegisterEvent("SPELLS_CHANGED")

SLASH_NEXUS1 = "/nx"
SLASH_NEXUS2 = "/nexus"

SlashCmdList["NEXUS"] = function(msg)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd200Nexus:|r Slash command blocked in combat state.")
        return
    end

    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text ~= "" then
        local cmd, rest = string.match(text, "^(%S+)%s*(.-)%s*$")
        if cmd == "help" or cmd == "?" then
            print("|cffffd200Nexus:|r /nx opens Settings")
            print("|cffffd200Nexus:|r /nx buffs help")
            print("|cffffd200Nexus:|r /nx stats help")
            print("|cffffd200Nexus:|r /nx vault help")
            print("|cffffd200Nexus:|r /nx durability help")
            return
        end
        if cmd == "durability" and NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.HandleNxSlash then
            local handled = NX.Common.LowDurability:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if cmd == "vault" and NX.Vault and NX.Vault.HandleNxSlash then
            local handled = NX.Vault:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if cmd == "buffs" and NX.ClickableBuffs and NX.ClickableBuffs.HandleNxSlash then
            local handled = NX.ClickableBuffs:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if cmd == "stats" and NX.StatsPlus and NX.StatsPlus.HandleNxSlash then
            local handled = NX.StatsPlus:HandleNxSlash(rest)
            if handled then
                return
            end
        end

        print("|cffffd200Nexus:|r Unknown /nx command. Use: /nx help")
        return
    end

    if Nexus and Nexus.Settings and Nexus.Settings.Open then
        Nexus.Settings:Open()
    end
end
