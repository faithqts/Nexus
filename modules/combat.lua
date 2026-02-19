local NX = Nexus
NX.AutoCombatLog = NX.AutoCombatLog or {}
local CL = NX.AutoCombatLog

local function EnsureDB()
    NX.DB.autoCombatLog = NX.DB.autoCombatLog or {}
    local db = NX.DB.autoCombatLog
    if db.enabled == nil then db.enabled = false end
    if db.stopDelaySeconds == nil then db.stopDelaySeconds = 30 end
end

local function CanLog()
    return type(LoggingCombat) == "function"
end

local function InSupportedInstance()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "party" then return true end
    if instanceType == "raid" then return true end
    if instanceType == "arena" then return true end
    if instanceType == "pvp" then return true end
    return false
end

function CL:Start(reason)
    if not self._active then return end
    if not CanLog() then return end

    if self._stopTimer then
        self._stopTimer:Cancel()
        self._stopTimer = nil
    end

    if not LoggingCombat() then
        LoggingCombat(true)
    end
end

function CL:StopWithDelay(reason)
    if not self._active then return end
    if not CanLog() then return end
    if not LoggingCombat() then return end
    if self._stopTimer then return end

    local delay = tonumber(NX.DB.autoCombatLog.stopDelaySeconds) or 30
    if delay < 0 then delay = 0 end
    if delay > 60 then delay = 60 end
    self._stopTimer = C_Timer.NewTimer(delay, function()
        self._stopTimer = nil
        if not self._active then return end
        if not CanLog() then return end
        if LoggingCombat() then
            LoggingCombat(false)
        end
    end)
end

function CL:ZoneCheck()
    if not self._active then return end
    if InSupportedInstance() then
        self:Start("instance")
    else
        self:StopWithDelay("left instance")
    end
end

function CL:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:RegisterEvent("ENCOUNTER_START")
    self.frame:RegisterEvent("ENCOUNTER_END")
    self.frame:RegisterEvent("CHALLENGE_MODE_START")
    self.frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            self:ZoneCheck()
            return
        end
        if event == "ENCOUNTER_START" or event == "CHALLENGE_MODE_START" then
            self:Start(event)
            return
        end
        if event == "ENCOUNTER_END" or event == "CHALLENGE_MODE_COMPLETED" then
            self:StopWithDelay(event)
            return
        end
    end)

    self:ZoneCheck()
end

function CL:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._stopTimer then
        self._stopTimer:Cancel()
        self._stopTimer = nil
    end
end

function CL:ApplyConfig()
    EnsureDB()
    if NX.DB.autoCombatLog.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function CL:Init()
    EnsureDB()
    self:ApplyConfig()
end

function CL:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.Crosshair = NX.Crosshair or {}
local XH = NX.Crosshair

local TEX = "Interface/Buttons/WHITE8x8"

local COLORS = {
    { hex = "#FF0000", name = "Red",                r = 255, g = 0,   b = 0   },
    { hex = "#FF8000", name = "Orange",             r = 255, g = 128, b = 0   },
    { hex = "#FFFF00", name = "Yellow",             r = 255, g = 255, b = 0   },
    { hex = "#80FF00", name = "Lime Green",         r = 128, g = 255, b = 0   },
    { hex = "#00FF00", name = "Green",              r = 0,   g = 255, b = 0   },
    { hex = "#00FF80", name = "Spring Green",       r = 0,   g = 255, b = 128 },
    { hex = "#00FFFF", name = "Cyan",               r = 0,   g = 255, b = 255 },
    { hex = "#0080FF", name = "Dodge Blue",         r = 0,   g = 128, b = 255 },
    { hex = "#0000FF", name = "Blue",               r = 0,   g = 0,   b = 255 },
    { hex = "#8000FF", name = "Purple",             r = 128, g = 0,   b = 255 },
    { hex = "#FF00FF", name = "Violet",             r = 255, g = 0,   b = 255 },
    { hex = "#FF0080", name = "Magenta",            r = 255, g = 0,   b = 128 },
    { hex = "#FF8888", name = "Coral",              r = 255, g = 136, b = 136 },
    { hex = "#FFCC88", name = "Light Salmon",       r = 255, g = 204, b = 136 },
    { hex = "#FFFF88", name = "Pale Yellow",        r = 255, g = 255, b = 136 },
    { hex = "#CCFF88", name = "Pale Green",         r = 204, g = 255, b = 136 },
    { hex = "#88FF88", name = "Pale Turquoise",     r = 136, g = 255, b = 136 },
    { hex = "#88FFCC", name = "Aquamarine",         r = 136, g = 255, b = 204 },
    { hex = "#88FFFF", name = "Light Cyan",         r = 136, g = 255, b = 255 },
    { hex = "#88CCFF", name = "Sky Blue",           r = 136, g = 204, b = 255 },
    { hex = "#8888FF", name = "Slate Blue",         r = 136, g = 136, b = 255 },
    { hex = "#CC88FF", name = "Medium Purple",      r = 204, g = 136, b = 255 },
    { hex = "#FF88FF", name = "Orchid",             r = 255, g = 136, b = 255 },
    { hex = "#FF88CC", name = "Light Pink",         r = 255, g = 136, b = 204 },

    { hex = "#FFBBBB", name = "Light Salmon Pink",  r = 255, g = 187, b = 187 },
    { hex = "#FFDDBB", name = "Peach",              r = 255, g = 221, b = 187 },
    { hex = "#FFFFBB", name = "Pale Yellow (Soft)", r = 255, g = 255, b = 187 },
    { hex = "#DDFFBB", name = "Pale Green (Soft)",  r = 221, g = 255, b = 187 },
    { hex = "#BBFFBB", name = "Pale Turquoise (Soft)", r = 187, g = 255, b = 187 },
    { hex = "#BBFFDD", name = "Light Sea Green",    r = 187, g = 255, b = 221 },
    { hex = "#BBFFFF", name = "Light Cyan (Soft)",  r = 187, g = 255, b = 255 },
    { hex = "#BBDDFF", name = "Light Sky Blue",     r = 187, g = 221, b = 255 },
    { hex = "#BBBBFF", name = "Light Steel Blue",   r = 187, g = 187, b = 255 },
    { hex = "#DDBBFF", name = "Lavender",           r = 221, g = 187, b = 255 },
    { hex = "#FFBBFF", name = "Light Pink (Soft)",  r = 255, g = 187, b = 255 },
    { hex = "#FFBBDD", name = "Misty Rose",         r = 255, g = 187, b = 221 },

    { hex = "#AA5555", name = "Indian Red",         r = 170, g = 85,  b = 85  },
    { hex = "#AA7755", name = "Copper",             r = 170, g = 119, b = 85  },
    { hex = "#AAAA55", name = "Olive Drab",         r = 170, g = 170, b = 85  },
    { hex = "#77AA55", name = "Dark Olive Green",   r = 119, g = 170, b = 85  },
    { hex = "#55AA55", name = "Forest Green",       r = 85,  g = 170, b = 85  },
    { hex = "#55AA77", name = "Cadet Blue",         r = 85,  g = 170, b = 119 },
    { hex = "#55AAAA", name = "Medium Aquamarine",  r = 85,  g = 170, b = 170 },
    { hex = "#5577AA", name = "Light Slate Gray",   r = 85,  g = 119, b = 170 },
    { hex = "#5555AA", name = "Medium Slate Blue",  r = 85,  g = 85,  b = 170 },
    { hex = "#7755AA", name = "Slate Blue (Deep)",  r = 119, g = 85,  b = 170 },
    { hex = "#AA55AA", name = "Medium Orchid",      r = 170, g = 85,  b = 170 },
    { hex = "#AA5577", name = "Rose",               r = 170, g = 85,  b = 119 },
}

local function Clamp(n, lo, hi)
    n = tonumber(n)
    if not n then return nil end
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

local function Clamp01(n)
    n = tonumber(n)
    if not n then return nil end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
end

local function NormalizeHex(hex)
    if type(hex) ~= "string" then return "#FFFFFF" end
    hex = hex:gsub("%s+", ""):upper()
    if not hex:match("^#") then hex = "#" .. hex end
    if #hex == 7 or #hex == 9 then return hex end
    return "#FFFFFF"
end

local function HexToRGB01(hex)
    hex = NormalizeHex(hex):gsub("#", "")

    if #hex == 6 then
        local r = tonumber(hex:sub(1,2), 16) or 255
        local g = tonumber(hex:sub(3,4), 16) or 255
        local b = tonumber(hex:sub(5,6), 16) or 255
        return r/255, g/255, b/255
    end
    if #hex == 8 then
        local r = tonumber(hex:sub(3,4), 16) or 255
        local g = tonumber(hex:sub(5,6), 16) or 255
        local b = tonumber(hex:sub(7,8), 16) or 255
        return r/255, g/255, b/255
    end
    return 1, 1, 1
end

local function EnsureDB()
    if not NX.DB then return nil end
    NX.DB.crosshair = NX.DB.crosshair or {}
    return NX.DB.crosshair
end

local frame
local hTex, vTex

local function CreateUI()
    if frame then return end

    frame = CreateFrame("Frame", "NEXUSCrosshairFrame", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9999)
    frame:EnableMouse(false)
    frame:SetClampedToScreen(false)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(256, 256)

    hTex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    vTex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    hTex:SetTexture(TEX)
    vTex:SetTexture(TEX)
    hTex:SetBlendMode("BLEND")
    vTex:SetBlendMode("BLEND")
end

function XH:ApplyConfig()
    local db = EnsureDB()
    if not db then return end

    CreateUI()

    local show = db.show and true or false
    local size = Clamp(db.size, 0, 48) or 18
    local thickness = Clamp(db.thickness, 1, 10) or 2
    local alpha = Clamp01(db.alpha) or 1.0

    local color = NormalizeHex(db.color)
    local r, g, b = HexToRGB01(color)

    hTex:ClearAllPoints()
    hTex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    hTex:SetSize(size, thickness)
    hTex:SetVertexColor(r, g, b, alpha)

    vTex:ClearAllPoints()
    vTex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    vTex:SetSize(thickness, size)
    vTex:SetVertexColor(r, g, b, alpha)

    frame:SetShown(show)
end

function XH:OnSettingsChanged()
    self:ApplyConfig()
end

function XH:GetColorList()
    return COLORS
end

function XH:Init()
    EnsureDB()
    self:ApplyConfig()
end

local NX = Nexus
NX.FloatingCombatText = NX.FloatingCombatText or {}
local M = NX.FloatingCombatText
local CV = NX.CVars

local FCT_CVARS = {
    damageV2 = "floatingCombatTextCombatDamage_v2",
    healingV2 = "floatingCombatTextCombatHealing_v2",
    healingAbsorbSelfV2 = "floatingCombatTextCombatHealingAbsorbSelf_v2",
    healingAbsorbTargetV2 = "floatingCombatTextCombatHealingAbsorbTarget_v2",
    combatStateV2 = "floatingCombatTextCombatState_v2",
    comboPointsV2 = "floatingCombatTextComboPoints_v2",
    damageReductionV2 = "floatingCombatTextDamageReduction_v2",
    dodgeParryMissV2 = "floatingCombatTextDodgeParryMiss_v2",
    energyGainsV2 = "floatingCombatTextEnergyGains_v2",
    floatModeV2 = "floatingCombatTextFloatMode_v2",
    friendlyHealersV2 = "floatingCombatTextFriendlyHealers_v2",
    honorGainsV2 = "floatingCombatTextHonorGains_v2",
    lowManaHealthV2 = "floatingCombatTextLowManaHealth_v2",
    periodicEnergyGainsV2 = "floatingCombatTextPeriodicEnergyGains_v2",
    petMeleeV2 = "floatingCombatTextPetMeleeDamage_v2",
    petSpellV2 = "floatingCombatTextPetSpellDamage_v2",
}

local FCT_DB_TO_CVARS = {
    showCombatDamage = { FCT_CVARS.damageV2 },
    showCombatHealing = { FCT_CVARS.healingV2 },
    showHealingAbsorbSelf = { FCT_CVARS.healingAbsorbSelfV2 },
    showHealingAbsorbTarget = { FCT_CVARS.healingAbsorbTargetV2 },
    showCombatState = { FCT_CVARS.combatStateV2 },
    showComboPoints = { FCT_CVARS.comboPointsV2 },
    showDamageReduction = { FCT_CVARS.damageReductionV2 },
    showDodgeParryMiss = { FCT_CVARS.dodgeParryMissV2 },
    showEnergyGains = { FCT_CVARS.energyGainsV2 },
    showFloatMode = { FCT_CVARS.floatModeV2 },
    showFriendlyHealers = { FCT_CVARS.friendlyHealersV2 },
    showHonorGains = { FCT_CVARS.honorGainsV2 },
    showLowManaHealth = { FCT_CVARS.lowManaHealthV2 },
    showPeriodicEnergyGains = { FCT_CVARS.periodicEnergyGainsV2 },
    showPetMeleeDamage = { FCT_CVARS.petMeleeV2 },
    showPetSpellDamage = { FCT_CVARS.petSpellV2 },
}

local TRACKED_FCT_CVARS = {}
for _, cvars in pairs(FCT_DB_TO_CVARS) do
    for _, cvarName in ipairs(cvars) do
        TRACKED_FCT_CVARS[cvarName] = true
    end
end

local function ResolveCVarListByGameFirst(cvarList, fallback)
    local resolved = fallback and true or false

    if type(cvarList) ~= "table" then
        return resolved
    end

    local foundGameValue = false
    for _, cvarName in ipairs(cvarList) do
        local raw = CV and CV.GetRaw and CV:GetRaw(cvarName)
        if raw == "1" then
            if not foundGameValue then
                resolved = true
                foundGameValue = true
            end
        elseif raw == "0" then
            if not foundGameValue then
                resolved = false
                foundGameValue = true
            end
        else
            if CV and CV.SetBool then
                CV:SetBool(cvarName, resolved)
            end
        end
    end

    return resolved
end

local function ApplyCVarListFromDB(cvarList, value)
    if type(cvarList) ~= "table" then return end
    for _, cvarName in ipairs(cvarList) do
        if CV and CV.SetBool then
            CV:SetBool(cvarName, value)
        end
    end
end

local function EnsureDB()
    NX.DB.floatingCombatText = NX.DB.floatingCombatText or {}
    local cfg = NX.DB.floatingCombatText

    if cfg.hideOverPlayer == nil then cfg.hideOverPlayer = false end
    if cfg.hideOverPet == nil then cfg.hideOverPet = false end
    if cfg.showCombatDamage == nil then cfg.showCombatDamage = false end
    if cfg.showCombatHealing == nil then cfg.showCombatHealing = false end
    if cfg.showHealingAbsorbSelf == nil then cfg.showHealingAbsorbSelf = false end
    if cfg.showHealingAbsorbTarget == nil then cfg.showHealingAbsorbTarget = false end
    if cfg.showCombatState == nil then cfg.showCombatState = false end
    if cfg.showComboPoints == nil then cfg.showComboPoints = false end
    if cfg.showDamageReduction == nil then cfg.showDamageReduction = false end
    if cfg.showDodgeParryMiss == nil then cfg.showDodgeParryMiss = false end
    if cfg.showEnergyGains == nil then cfg.showEnergyGains = false end
    if cfg.showFloatMode == nil then cfg.showFloatMode = false end
    if cfg.showFriendlyHealers == nil then cfg.showFriendlyHealers = false end
    if cfg.showHonorGains == nil then cfg.showHonorGains = false end
    if cfg.showLowManaHealth == nil then cfg.showLowManaHealth = false end
    if cfg.showPeriodicEnergyGains == nil then cfg.showPeriodicEnergyGains = false end
    if cfg.showPetMeleeDamage == nil then cfg.showPetMeleeDamage = false end
    if cfg.showPetSpellDamage == nil then cfg.showPetSpellDamage = false end

    return cfg
end

local function SyncDBFromCVars()
    if not NX.DB then return end
    local cfg = EnsureDB()

    for dbKey, cvarList in pairs(FCT_DB_TO_CVARS) do
        cfg[dbKey] = ResolveCVarListByGameFirst(cvarList, cfg[dbKey])
    end
end

local function ApplyHitIndicators()
    if not NX.DB or not NX.DB.floatingCombatText then return end
    local cfg = NX.DB.floatingCombatText

    local okPlayer, playerHit = pcall(function()
        return _G.PlayerFrame
            and _G.PlayerFrame.PlayerFrameContent
            and _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
            and _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator
    end)
    if okPlayer and playerHit and playerHit.Hide and playerHit.Show then
        if cfg.hideOverPlayer then playerHit:Hide() else playerHit:Show() end
    end

    local petHit = _G.PetHitIndicator
    if petHit and petHit.Hide and petHit.Show then
        if cfg.hideOverPet then petHit:Hide() else petHit:Show() end
    end
end

function M:Apply()
    if not NX.DB then return end
    local cfg = EnsureDB()

    self._applyingCVars = true

    for dbKey, cvarList in pairs(FCT_DB_TO_CVARS) do
        ApplyCVarListFromDB(cvarList, cfg[dbKey])
    end

    self._applyingCVars = false

    C_Timer.After(0, ApplyHitIndicators)
end

function M:OnSettingsChanged() self:Apply() end

function M:Init()
    EnsureDB()

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("CVAR_UPDATE")
    self.frame:SetScript("OnEvent", function(_, _, cvarName)
        if not TRACKED_FCT_CVARS[cvarName] then return end
        if self._applyingCVars then return end

        SyncDBFromCVars()
        self:Apply()
    end)

    C_Timer.After(0, function()
        SyncDBFromCVars()
        self:Apply()
    end)
end

local NX = Nexus

NX.AssistedRotationOverlay = NX.AssistedRotationOverlay or {}
NX.ExtraActionArtwork = NX.ExtraActionArtwork or {}

local ARO = NX.AssistedRotationOverlay
local EAA = NX.ExtraActionArtwork

local assistedCallbackOwner
local extraPending
local extraFrame

local function ForEachActionButton(fn)
    if type(fn) ~= "function" then return end
    if ActionBarButtonEvents and ActionBarButtonEvents.ForEachActionButton then
        pcall(ActionBarButtonEvents.ForEachActionButton, fn)
        return
    end

    local prefixes = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
    }

    for _, prefix in ipairs(prefixes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                pcall(fn, button)
            end
        end
    end
end

local function ApplyAssistedButton(button)
    if not button then return end
    local frame = button.AssistedCombatRotationFrame
    if not frame then return end

    if not frame.FQ_AssistedHideHooked and frame.HookScript then
        frame.FQ_AssistedHideHooked = true
        frame:HookScript("OnShow", function(self)
            if NX.DB and NX.DB.assistedRotationOverlay and NX.DB.assistedRotationOverlay.enabled then
                self:SetAlpha(0)
            elseif self.GetAlpha and self:GetAlpha() ~= 1 then
                self:SetAlpha(1)
            end
        end)
    end

    if NX.DB and NX.DB.assistedRotationOverlay and NX.DB.assistedRotationOverlay.enabled then
        frame:SetAlpha(0)
    else
        frame:SetAlpha(1)
    end
end

function ARO:Apply()
    if not NX.DB or not NX.DB.assistedRotationOverlay then return end

    if NX.DB.assistedRotationOverlay.enabled then
        if not assistedCallbackOwner and EventRegistry and EventRegistry.RegisterCallback then
            assistedCallbackOwner = {}
            EventRegistry:RegisterCallback(
                "ActionButton.OnAssistedCombatRotationFrameChanged",
                function(_, button, added)
                    if not (NX.DB and NX.DB.assistedRotationOverlay and NX.DB.assistedRotationOverlay.enabled) then return end
                    if added then
                        ApplyAssistedButton(button)
                    end
                end,
                assistedCallbackOwner
            )
        end
    elseif assistedCallbackOwner and EventRegistry and EventRegistry.UnregisterCallback then
        EventRegistry:UnregisterCallback("ActionButton.OnAssistedCombatRotationFrameChanged", assistedCallbackOwner)
        assistedCallbackOwner = nil
    end

    ForEachActionButton(ApplyAssistedButton)
end

function ARO:OnSettingsChanged()
    self:Apply()
end

function ARO:Init()
    self:Apply()
end

local function ApplyExtraActionArtworkNow()
    if not NX.DB or not NX.DB.extraActionArtwork then return end

    local hideArtwork = NX.DB.extraActionArtwork.enabled == true

    if InCombatLockdown and InCombatLockdown() then
        extraPending = true
        return
    end

    local extraActionButton = _G.ExtraActionButton1
    local extraStyle = extraActionButton and extraActionButton.style
    if extraStyle then
        if hideArtwork then
            extraStyle:SetAlpha(0)
            extraStyle:Hide()
        else
            extraStyle:SetAlpha(1)
            extraStyle:Show()
        end
    end

    local zoneAbilityFrame = _G.ZoneAbilityFrame
    local zoneStyle = zoneAbilityFrame and zoneAbilityFrame.Style
    if zoneStyle then
        if hideArtwork then
            zoneStyle:SetAlpha(0)
            zoneStyle:Hide()
        else
            zoneStyle:SetAlpha(1)
            zoneStyle:Show()
        end
    end

    local extraActionBarFrame = _G.ExtraActionBarFrame
    if extraActionBarFrame and extraActionBarFrame.EnableMouse then
        extraActionBarFrame:EnableMouse(not hideArtwork)
    end

    extraPending = nil
end

function EAA:Apply()
    C_Timer.After(0, ApplyExtraActionArtworkNow)
end

function EAA:OnSettingsChanged()
    self:Apply()
end

function EAA:Init()
    if not extraFrame then
        extraFrame = CreateFrame("Frame")
        extraFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        extraFrame:SetScript("OnEvent", function()
            if extraPending then
                C_Timer.After(0, ApplyExtraActionArtworkNow)
            end
        end)
    end

    self:Apply()
end
