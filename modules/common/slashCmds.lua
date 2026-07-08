local NX = Nexus
NX.Common = NX.Common or {}
local CM = NX.Common

CM._rlRegistered = CM._rlRegistered or false
CM._rlConflictWarned = CM._rlConflictWarned or false
CM._waRegistered = CM._waRegistered or false
CM._waConflictWarned = CM._waConflictWarned or false
CM._cdConflictWarned = CM._cdConflictWarned or false
CM._editConflictWarned = CM._editConflictWarned or false
CM._utilitySlashesRegistered = CM._utilitySlashesRegistered or false
CM._slashOwnerCache = CM._slashOwnerCache or {}

local SLASH_CACHE_MISS = false

local function FindSlashOwner(alias)
    if type(alias) ~= "string" or alias == "" then
        return nil
    end

    local needle = string.lower(alias)
    local cached = CM._slashOwnerCache[needle]
    if cached ~= nil then
        return cached or nil
    end

    for token in pairs(SlashCmdList or {}) do
        local index = 1
        while true do
            local key = string.format("SLASH_%s%d", token, index)
            local value = _G[key]
            if value == nil then
                break
            end
            if type(value) == "string" and string.lower(value) == needle then
                CM._slashOwnerCache[needle] = key
                return key
            end
            index = index + 1
        end
    end

    CM._slashOwnerCache[needle] = SLASH_CACHE_MISS
    return nil
end

local function ClearSlashOwnerCache()
    CM._slashOwnerCache = {}
end

local function GetSlashOwnerDisplay(owner)
    if type(owner) ~= "string" or owner == "" then
        return nil
    end

    local token = string.match(owner, "^SLASH_(.+)%d+$") or owner
    token = string.gsub(token, "_", "")

    local shortened = token
    shortened = string.gsub(shortened, "RELOADUI$", "")
    shortened = string.gsub(shortened, "RELOAD$", "")
    shortened = string.gsub(shortened, "RL$", "")

    if shortened == "" then
        shortened = token
    end

    return shortened
end

function CM:GetQuickReloadSlashOwner()
    local owner = FindSlashOwner("/rl")
    if not owner then
        return nil
    end

    if string.match(owner, "^SLASH_NEXUS_RL%d+$") then
        return nil
    end

    return owner
end

function CM:GetQuickReloadSlashOwnerDisplay()
    local owner = self:GetQuickReloadSlashOwner()
    if not owner then
        return nil
    end

    return GetSlashOwnerDisplay(owner)
end

function CM:IsQuickReloadSlashAvailable()
    return self:GetQuickReloadSlashOwner() == nil
end

function CM:GetQuickReloadUnavailableTooltip()
    local owner = self:GetQuickReloadSlashOwnerDisplay() or self:GetQuickReloadSlashOwner()
    if owner then
        return string.format("Quick ReloadUI cannot be enabled because /rl is already registered by %s.", owner)
    end
    return "Registers /rl to reload the UI (same as /console reloadui)."
end

local function DoReloadUI()
    if type(ReloadUI) == "function" then
        ReloadUI()
        return
    end
    if C_UI and type(C_UI.Reload) == "function" then
        C_UI.Reload()
        return
    end
    RunConsoleCommand("reloadui")
end

function CM:RegisterQuickReloadSlash()
    if self._rlRegistered then return end

    local owner = self:GetQuickReloadSlashOwner()
    if owner then
        if NX.DB then
            NX.DB.common.options.quickReloadSlash = false
        end
        if not self._rlConflictWarned then
            self._rlConflictWarned = true
            local ownerLabel = self:GetQuickReloadSlashOwnerDisplay() or owner
            print(string.format("|cffffd200Nexus:|r /rl is already registered by %s. Quick ReloadUI not enabled.", ownerLabel))
        end
        return
    end

    SLASH_NEXUS_RL1 = "/rl"
    SlashCmdList["NEXUS_RL"] = function()
        DoReloadUI()
    end

    self._rlRegistered = true
end

function CM:UnregisterQuickReloadSlash()
    if not self._rlRegistered then return end
    SlashCmdList["NEXUS_RL"] = function()
        print("|cffffd200Nexus:|r Quick ReloadUI (/rl) is disabled in settings.")
    end
end

function CM:SyncQuickReloadSlash()
    if not NX.DB then return end

    if not self:IsQuickReloadSlashAvailable() then
        NX.DB.common.options.quickReloadSlash = false
    end

    if NX.DB.common.options.quickReloadSlash then
        self:RegisterQuickReloadSlash()
    else
        self:UnregisterQuickReloadSlash()
    end
end

local function PrintCombatBlocked()
    print("|cffffd200Nexus:|r Slash command blocked in combat state.")
end

local function RunOutOfCombat(fn)
    if InCombatLockdown and InCombatLockdown() then
        PrintCombatBlocked()
        return
    end
    fn()
end

local function PrintSlashDisabled(label)
    print(string.format("|cffffd200Nexus:|r %s is disabled in settings.", label))
end

function CM:IsQuickCdmSlashEnabled()
    if not NX or not NX.DB then return true end
    return NX.DB.common.options.quickCdmSlash ~= false
end

function CM:IsQuickWeakAurasCdmSlashEnabled()
    if not NX or not NX.DB then return true end
    return NX.DB.common.options.quickWeakAurasCdmSlash ~= false
end

function CM:GetWeakAurasCdmSlashOwner()
    local owner = FindSlashOwner("/wa")
    if not owner then
        return nil
    end

    if string.match(owner, "^SLASH_NEXUS_WA_CDM%d+$") or string.match(owner, "^SLASH_NEXUS_CD%d+$") then
        return nil
    end

    return owner
end

function CM:GetWeakAurasCdmSlashOwnerDisplay()
    local owner = self:GetWeakAurasCdmSlashOwner()
    if not owner then
        return nil
    end

    return GetSlashOwnerDisplay(owner)
end

function CM:IsWeakAurasCdmSlashAvailable()
    return self:GetWeakAurasCdmSlashOwner() == nil
end

function CM:GetWeakAurasCdmUnavailableTooltip()
    local owner = self:GetWeakAurasCdmSlashOwnerDisplay() or self:GetWeakAurasCdmSlashOwner()
    if owner then
        return string.format("WeakAuras CDM cannot be enabled because /wa is already registered by %s.", owner)
    end
    return "Registers /wa to open Cooldown Manager (CDM)."
end

function CM:IsQuickEditModeSlashEnabled()
    if not NX or not NX.DB then return true end
    return NX.DB.common.options.quickEditModeSlash ~= false
end

local function RegisterSlashAliases(baseName, aliases)
    local idx = 1

    for _, alias in ipairs(aliases) do
        _G[string.format("SLASH_%s%d", baseName, idx)] = alias
        idx = idx + 1
    end

    ClearSlashOwnerCache()
    return idx > 1
end

local function FindSlashAliasConflict(aliases, ownBaseName)
    local ownPattern = "^SLASH_" .. tostring(ownBaseName or "") .. "%d+$"
    for _, alias in ipairs(aliases) do
        local owner = FindSlashOwner(alias)
        if owner and not string.match(owner, ownPattern) then
            return alias, owner
        end
    end
    return nil, nil
end

local function EnsureEscClosable(frameOrName)
    local frameName = nil

    if type(frameOrName) == "string" then
        frameName = frameOrName
    elseif type(frameOrName) == "table" and frameOrName.GetName then
        frameName = frameOrName:GetName()
    end

    if type(frameName) ~= "string" or frameName == "" then
        return
    end

    UISpecialFrames = UISpecialFrames or {}
    for _, name in ipairs(UISpecialFrames) do
        if name == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function RemoveEscClosable(frameOrName)
    local frameName = nil

    if type(frameOrName) == "string" then
        frameName = frameOrName
    elseif type(frameOrName) == "table" and frameOrName.GetName then
        frameName = frameOrName:GetName()
    end

    if type(frameName) ~= "string" or frameName == "" then
        return
    end

    if type(UISpecialFrames) ~= "table" then
        return
    end

    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == frameName then
            table.remove(UISpecialFrames, i)
        end
    end
end

function CM:IsEscCloseCdmEditModeEnabled()
    if not NX or not NX.DB then return true end
    return NX.DB.common.options.allowEscCloseCdmEditMode ~= false
end

function CM:SyncEscCloseCdmEditMode()
    local names = {
        "CooldownViewerSettings",
        "EditModeManagerFrame",
        "EditModeSystemSettingsDialog",
    }

    if self:IsEscCloseCdmEditModeEnabled() then
        for _, frameName in ipairs(names) do
            EnsureEscClosable(frameName)
        end
    else
        for _, frameName in ipairs(names) do
            RemoveEscClosable(frameName)
        end
    end
end

local function ToggleCooldownViewerSettings()
    local frame = _G.CooldownViewerSettings
    if not frame then
        print("|cffffd200Nexus:|r CooldownViewerSettings is not available.")
        return
    end

    if CM and CM.IsEscCloseCdmEditModeEnabled and CM:IsEscCloseCdmEditModeEnabled() then
        EnsureEscClosable(frame)
    end

    if frame.SetShown and frame.IsShown then
        frame:SetShown(not frame:IsShown())
        return
    end

    if frame.IsShown and frame.Show and frame.Hide then
        if frame:IsShown() then frame:Hide() else frame:Show() end
        return
    end

    print("|cffffd200Nexus:|r CooldownViewerSettings cannot be toggled on this client.")
end

local function HandleQuickCdmSlash()
    if CM and CM.IsQuickCdmSlashEnabled and not CM:IsQuickCdmSlashEnabled() then
        return
    end
    RunOutOfCombat(ToggleCooldownViewerSettings)
end

local function OpenEditModeManager()
    local frame = _G.EditModeManagerFrame
    if not frame then
        print("|cffffd200Nexus:|r EditModeManagerFrame is not available.")
        return
    end

    if CM and CM.IsEscCloseCdmEditModeEnabled and CM:IsEscCloseCdmEditModeEnabled() then
        EnsureEscClosable(frame)
        EnsureEscClosable("EditModeSystemSettingsDialog")
    end

    if type(ShowUIPanel) == "function" then
        ShowUIPanel(frame)
        return
    end

    if frame.Show then
        frame:Show()
    end
end

function CM:RegisterUtilitySlashes()
    if self._utilitySlashesRegistered then return end

    local cdAliases = { "/cd", "/cdm" }
    local cdAlias, cdOwner = FindSlashAliasConflict(cdAliases, "NEXUS_CD")
    if cdAlias then
        if NX.DB then
            NX.DB.common.options.quickCdmSlash = false
        end
        if not self._cdConflictWarned then
            self._cdConflictWarned = true
            local ownerLabel = GetSlashOwnerDisplay(cdOwner) or cdOwner
            print(string.format("|cffffd200Nexus:|r %s is already registered by %s. Cooldown Manager slash aliases not enabled.", cdAlias, ownerLabel))
        end
    elseif RegisterSlashAliases("NEXUS_CD", cdAliases) then
        SlashCmdList["NEXUS_CD"] = HandleQuickCdmSlash
    end

    self:SyncWeakAurasCdmSlash()

    local editAliases = { "/em", "/edit", "/editmode", "/editmenu" }
    local editAlias, editOwner = FindSlashAliasConflict(editAliases, "NEXUS_EDITMODE")
    if editAlias then
        if NX.DB then
            NX.DB.common.options.quickEditModeSlash = false
        end
        if not self._editConflictWarned then
            self._editConflictWarned = true
            local ownerLabel = GetSlashOwnerDisplay(editOwner) or editOwner
            print(string.format("|cffffd200Nexus:|r %s is already registered by %s. Edit Mode slash aliases not enabled.", editAlias, ownerLabel))
        end
    elseif RegisterSlashAliases("NEXUS_EDITMODE", editAliases) then
        SlashCmdList["NEXUS_EDITMODE"] = function()
            if CM and CM.IsQuickEditModeSlashEnabled and not CM:IsQuickEditModeSlashEnabled() then
                return
            end
            RunOutOfCombat(OpenEditModeManager)
        end
    end

    self._utilitySlashesRegistered = true
end

function CM:RegisterWeakAurasCdmSlash()
    if self._waRegistered then return end

    local owner = self:GetWeakAurasCdmSlashOwner()
    if owner then
        if NX.DB then
            NX.DB.common.options.quickWeakAurasCdmSlash = false
        end
        if not self._waConflictWarned then
            self._waConflictWarned = true
            local ownerLabel = self:GetWeakAurasCdmSlashOwnerDisplay() or owner
            print(string.format("|cffffd200Nexus:|r /wa is already registered by another addon (%s). WeakAuras CDM not enabled.", ownerLabel))
        end
        return
    end

    RegisterSlashAliases("NEXUS_WA_CDM", { "/wa" })
    SlashCmdList["NEXUS_WA_CDM"] = HandleQuickCdmSlash
    self._waRegistered = true
end

function CM:UnregisterWeakAurasCdmSlash()
    if not self._waRegistered then return end
    SlashCmdList["NEXUS_WA_CDM"] = function()
        print("|cffffd200Nexus:|r WeakAuras CDM (/wa) is disabled in settings.")
    end
end

function CM:SyncWeakAurasCdmSlash()
    if not NX.DB then return end

    if not self:IsWeakAurasCdmSlashAvailable() then
        NX.DB.common.options.quickWeakAurasCdmSlash = false
    end

    if self:IsQuickWeakAurasCdmSlashEnabled() then
        self:RegisterWeakAurasCdmSlash()
    else
        self:UnregisterWeakAurasCdmSlash()
    end
end

function CM:Init()
    self:RegisterUtilitySlashes()
    self:SyncEscCloseCdmEditMode()

    if self.LowDurability and self.LowDurability.Init then
        self.LowDurability:Init()
    end
end

