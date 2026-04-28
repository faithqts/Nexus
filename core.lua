Nexus = Nexus or {}
local NX = Nexus

NX.Constants = NX.Constants or {}
NX.Constants.VAULT_SPELL_ID = 449976
NX.Constants.VAULT_OFFSET_X = 0

NX.name = "Nexus"
NX.modules = NX.modules or {}

NexusDB = NexusDB or {}

local defaults = {
    common = {
        options = {
            quickReloadSlash = true,
            quickCdmSlash = true,
            quickWeakAurasCdmSlash = true,
            quickEditModeSlash = true,
            allowEscCloseCdmEditMode = true,
        },
    },

    settings = {
        panel = {
            moveSettingsPanel = true,
        },
        voicePack = {
            actor = "xalatath",
        },
    },

    media = {
        fonts = {
            addonFontPath = "Fonts\\FRIZQT__.TTF",
        },
    },

    dungeonsRaids = {
        greatVault = {
            enabled = false,
            anchorX = 0,
            anchorY = 0,
            positionUnlocked = false,
            fontSize = 48,
            flashing = true,
        },
    },

    automation = {
        achievementScreenshot = {
            enabled = false,
            delaySeconds = 1.5,
        },
        autoCombatLog = {
            enabled = false,
            stopDelaySeconds = 30,
        },
        cinematics = {
            autoSkip = false,
            quickSkip = false,
        },
    },

    combat = {
        crosshair = {
            show = false,
            size = 18,
            thickness = 2,
            color = "#FFFFFF",
            alpha = 1.0,
        },
        mouseCursor = {
            enabled = false,
            size = 32,
            alpha = 1.0,
            strata = "TOOLTIP",
            color = "#FFFFFF",
            hz = 120,
            texture = "circle.tga",
            animationsEnabled = false,
            pulsing = false,
            flashing = false,
            rotating = false,
            pulseSpeedHz = 2.2,
            flashSpeedHz = 4.0,
            rotateRps = 0.5,
        },
        assistedRotationOverlay = {
            enabled = false,
        },
        extraActionArtwork = {
            enabled = false,
        },
    },

    interface = {
        lowDurability = {
            enabled = false,
            anchorX = 0,
            anchorY = 0,
            positionUnlocked = false,
            fontSize = 48,
            threshold = 20,
            flashing = true,
            color = "#FFFF00",
        },
        motionSickness = {
            enabled = false,
        },
        skyridingEffects = {
            enabled = false,
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
            highlightedQuestMarkerStyle = "default",
        },
        minimap = {
            zoomoutEnabled = false,
            zoomoutDelaySeconds = 3,
            zoomoutTargetZoom = 0,
            enhancedResourceIconsEnabled = false,
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
    },

    system = {
        autoPlaceSpells = {
            enabled = false,
        },
        catalyst = {
            enabled = true,
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
        questTrackerState = {
            enabled = false,
            collapsed = nil,
        },
        auctionHouse = {
            currentExpansionOnly = false,
        },
    },

    professions = {
        simpleFirstCraftBonus = {
            enabled = true,
        },
        easyDisenchant = {
            enabled = false,
            preferElvUI = true,
            anchorSide = "LEFT",
            xOffset = 0,
            yOffset = -50,
            outsidePadding = 6,
            size = 38,
            iconZoom = 0.10,
            alpha = 1,
            frameStrata = "DIALOG",
            spellID = 13262,
            enchantingSkillLineID = 333,
            enchantingNameSpellID = 7411,
            border = {
                enabled = true,
                size = 1,
                offset = 1,
                color = { 0, 0, 0, 1 },
            },
        },
    },

    alerts = {
        bankWarboundItems = {
            enabled = false,
            textSize = 48,
            align = "CENTER",
            flashText = false,
            color = "#FFD133",
            anchorX = 0,
            anchorY = 300,
            positionUnlocked = false,
        },
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

    portals = {
        enabled = false,
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

    db.system = db.system or {}
    db.system.luaErrors = db.system.luaErrors or {}
    db.system.luaErrors.enabled = CV:GetBool("scriptErrors", db.system.luaErrors.enabled == true)

    db.system.tutorials = db.system.tutorials or {}
    local showTutorials = CV:GetBool("showTutorials", db.system.tutorials.disabled ~= true)
    db.system.tutorials.disabled = not showTutorials

    db.system.autoDismount = db.system.autoDismount or {}
    db.system.autoDismount.enabled = CV:GetBool("autoDismount", db.system.autoDismount.enabled ~= false)
    db.system.autoDismount.flying = CV:GetBool("autoDismountFlying", db.system.autoDismount.flying ~= false)

    db.system.autoPlaceSpells = db.system.autoPlaceSpells or {}
    db.system.autoPlaceSpells.enabled = CV:GetBool("AutoPushSpellToActionBar", db.system.autoPlaceSpells.enabled == true)

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

    db.dungeonsRaids = db.dungeonsRaids or {}
    db.dungeonsRaids.greatVault = db.dungeonsRaids.greatVault or {}
    local target = db.dungeonsRaids.greatVault

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

    db.media = db.media or {}
    db.media.fonts = db.media.fonts or {}

    if type(db.media.fonts.addonFontPath) == "string" and db.media.fonts.addonFontPath ~= "" then
        return
    end

    local candidates = {
        db.dungeonsRaids and db.dungeonsRaids.greatVault and db.dungeonsRaids.greatVault.fontPath,
        db.interface and db.interface.lowDurability and db.interface.lowDurability.fontPath,
        db.vault and db.vault.fontPath,
    }

    for _, path in ipairs(candidates) do
        if type(path) == "string" and path ~= "" then
            db.media.fonts.addonFontPath = path
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

    if NX.DB.settings.panel.moveSettingsPanel then
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
        if NX.MouseCursor and NX.MouseCursor.Init then
            NX.MouseCursor:Init()
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
        if NX.WaypointAutoPinTracking and NX.WaypointAutoPinTracking.Init then
            NX.WaypointAutoPinTracking:Init()
        end
        if NX.WaypointUnlimitedPinDistance and NX.WaypointUnlimitedPinDistance.Init then
            NX.WaypointUnlimitedPinDistance:Init()
        end
        if NX.WaypointHighlightQuestMarker and NX.WaypointHighlightQuestMarker.Init then
            NX.WaypointHighlightQuestMarker:Init()
        end

        if NX.AutoPlaceSpells and NX.AutoPlaceSpells.Init then
            NX.AutoPlaceSpells:Init()
        end
        if NX.Catalyst and NX.Catalyst.Init then
            NX.Catalyst:Init()
        end
        if NX.CVarStateSync and NX.CVarStateSync.Init then
            NX.CVarStateSync:Init()
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
        if NX.EasyDisenchant and NX.EasyDisenchant.Init then
            NX.EasyDisenchant:Init()
        end
        if NX.Minimap and NX.Minimap.Init then
            NX.Minimap:Init()
        end
        if NX.MinimapResourceIcons and NX.MinimapResourceIcons.Init then
            NX.MinimapResourceIcons:Init()
        end
        if NX.ClickableBuffs and NX.ClickableBuffs.Init then
            NX.ClickableBuffs:Init()
        end
        if NX.StatsPlus and NX.StatsPlus.Init then
            NX.StatsPlus:Init()
        end
        if NX.BankWarboundItems and NX.BankWarboundItems.Init then
            NX.BankWarboundItems:Init()
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
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

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
            print("|cffffd200Nexus:|r /nx mouse help")
            print("|cffffd200Nexus:|r /nx minimap help")
            print("|cffffd200Nexus:|r /nx resourceicons help")
            print("|cffffd200Nexus:|r /nx disenchant help")
            print("|cffffd200Nexus:|r /nx warbank help")
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
        if cmd == "disenchant" and NX.EasyDisenchant and NX.EasyDisenchant.HandleNxSlash then
            local handled = NX.EasyDisenchant:HandleNxSlash(rest)
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
        if cmd == "mouse" and NX.MouseCursor and NX.MouseCursor.HandleNxSlash then
            local handled = NX.MouseCursor:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if cmd == "minimap" and NX.Minimap and NX.Minimap.HandleNxSlash then
            local handled = NX.Minimap:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if (cmd == "resourceicons" or cmd == "resources") and NX.MinimapResourceIcons and NX.MinimapResourceIcons.HandleNxSlash then
            local handled = NX.MinimapResourceIcons:HandleNxSlash(rest)
            if handled then
                return
            end
        end
        if cmd == "warbank" and NX.BankWarboundItems and NX.BankWarboundItems.HandleNxSlash then
            local handled = NX.BankWarboundItems:HandleNxSlash(rest)
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


