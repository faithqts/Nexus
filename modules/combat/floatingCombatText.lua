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
    NX.DB.combat.floatingCombatText = NX.DB.combat.floatingCombatText or {}
    local cfg = NX.DB.combat.floatingCombatText

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
    if not NX.DB or not NX.DB.combat.floatingCombatText then return end
    local cfg = NX.DB.combat.floatingCombatText

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


