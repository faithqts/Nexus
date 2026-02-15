local NX = Nexus
NX.Common = NX.Common or {}
local CM = NX.Common

CM._rlRegistered = CM._rlRegistered or false
CM._rlConflictWarned = CM._rlConflictWarned or false
CM._utilitySlashesRegistered = CM._utilitySlashesRegistered or false

local function FindSlashOwner(alias)
    if type(alias) ~= "string" or alias == "" then
        return nil
    end

    local needle = string.lower(alias)
    for key, value in pairs(_G) do
        if type(key) == "string"
            and type(value) == "string"
            and string.match(key, "^SLASH_.+%d+$")
            and string.lower(value) == needle then
            return key
        end
    end

    return nil
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

function CM:IsQuickReloadSlashAvailable()
    return self:GetQuickReloadSlashOwner() == nil
end

function CM:GetQuickReloadUnavailableTooltip()
    local owner = self:GetQuickReloadSlashOwnerDisplay() or self:GetQuickReloadSlashOwner()
    if owner then
        return string.format("Quick ReloadUI cannot be enabled because /rl is already registered by another addon.", owner)
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
            NX.DB.quickReloadSlash = false
        end
        if not self._rlConflictWarned then
            self._rlConflictWarned = true
            local ownerLabel = self:GetQuickReloadSlashOwnerDisplay() or owner
            print(string.format("|cffffd200Nexus:|r /rl is already registered by another addon. Quick ReloadUI not enabled.", ownerLabel))
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
        NX.DB.quickReloadSlash = false
    end

    if NX.DB.quickReloadSlash then
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
    return NX.DB.quickCdmSlash ~= false
end

function CM:IsQuickEditModeSlashEnabled()
    if not NX or not NX.DB then return true end
    return NX.DB.quickEditModeSlash ~= false
end

local function ForceClaimSlashAlias(alias)
    if type(alias) ~= "string" or alias == "" then
        return
    end

    local needle = string.lower(alias)
    for key, value in pairs(_G) do
        if type(key) == "string" and type(value) == "string" and string.match(key, "^SLASH_.+%d+$") then
            if string.lower(value) == needle then
                _G[key] = nil
            end
        end
    end
end

local function RegisterSlashAliases(baseName, aliases)
    local idx = 1

    for _, alias in ipairs(aliases) do
        ForceClaimSlashAlias(alias)
        _G[string.format("SLASH_%s%d", baseName, idx)] = alias
        idx = idx + 1
    end

    return idx > 1
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
    return NX.DB.allowEscCloseCdmEditMode ~= false
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

    local cdRegistered = RegisterSlashAliases("NEXUS_CD", { "/cd", "/cdm", "/wa" })
    if cdRegistered then
        SlashCmdList["NEXUS_CD"] = function()
            if CM and CM.IsQuickCdmSlashEnabled and not CM:IsQuickCdmSlashEnabled() then
                return
            end
            RunOutOfCombat(ToggleCooldownViewerSettings)
        end
    end

    local emRegistered = RegisterSlashAliases("NEXUS_EDITMODE", { "/em", "/edit", "/editmode", "/editmenu" })
    if emRegistered then
        SlashCmdList["NEXUS_EDITMODE"] = function()
            if CM and CM.IsQuickEditModeSlashEnabled and not CM:IsQuickEditModeSlashEnabled() then
                return
            end
            RunOutOfCombat(OpenEditModeManager)
        end
    end

    self._utilitySlashesRegistered = true
end

function CM:Init()
    self:RegisterUtilitySlashes()
    self:SyncEscCloseCdmEditMode()

    if self.LowDurability and self.LowDurability.Init then
        self.LowDurability:Init()
    end
end
