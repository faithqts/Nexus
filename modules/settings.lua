local NX = Nexus
NX.Settings = NX.Settings or {}
local S = NX.Settings

local function ApplyRightLabel(options, formatterFn)
    if not options then return end
    if not MinimalSliderWithSteppersMixin or not MinimalSliderWithSteppersMixin.Label then return end
    if not options.SetLabelFormatter then return end

    if formatterFn then
        pcall(function()
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatterFn)
        end)
    else
        pcall(function()
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end)
    end
end

local function AddSectionHeader(category, title)
    if Settings and Settings.CreateElementInitializer and Settings.RegisterInitializer then
        local ok, init = pcall(Settings.CreateElementInitializer, "SettingsListSectionHeaderTemplate", { name = title })
        if ok and init then
            pcall(Settings.RegisterInitializer, category, init)
            return init
        end
    end

    if Settings and Settings.CreateSectionHeader then
        local ok, control = pcall(Settings.CreateSectionHeader, category, title)
        if ok and control then
            return control
        end
    end

    if Settings and Settings.CreateControl then
        local ok, control = pcall(Settings.CreateControl, category, "SettingsListSectionHeaderTemplate", function(c)
            if c.Text and c.Text.SetText then
                c.Text:SetText(title)
            elseif c.Title and c.Title.SetText then
                c.Title:SetText(title)
            end
        end)
        if ok and control then
            return control
        end
    end

    if Settings and Settings.CreateText then
        pcall(Settings.CreateText, category, title)
    end
end

local function AddSpacer(category)
    if Settings and Settings.CreateSpacer then
        Settings.CreateSpacer(category)
    end
end

local function GetEnabledDisabledOptionsData()
    local c = Settings.CreateControlTextContainer()
    c:Add(true, "Enabled")
    c:Add(false, "Disabled")
    return c:GetData()
end

local function CreateEnabledDisabledDropdown(category, setting, tooltip)
    local init = Settings.CreateDropdown(category, setting, GetEnabledDisabledOptionsData, tooltip)
    init.reinitializeOnValueChanged = true
    return init
end

local MARKERS = {
    { value = nil, label = "None" },
    { value = 1, label = "Star" },
    { value = 2, label = "Circle" },
    { value = 3, label = "Diamond" },
    { value = 4, label = "Triangle" },
    { value = 5, label = "Moon" },
    { value = 6, label = "Square" },
    { value = 7, label = "Cross" },
    { value = 8, label = "Skull" },
}

local MARKING_STYLES = {
    { value = "leader", label = "Group Leader" },
    { value = "always", label = "Always" },
    { value = "never",  label = "Never" },
}

local function GetMarkerOptionsData(excludeMarker)
    local c = Settings.CreateControlTextContainer()
    c:Add(0, "None")
    for _, m in ipairs(MARKERS) do
        if m.value ~= nil then
            if excludeMarker == nil or m.value ~= excludeMarker then
                c:Add(m.value, m.label)
            end
        end
    end
    return c:GetData()
end

local function GetStyleOptionsData()
    local c = Settings.CreateControlTextContainer()
    for _, s in ipairs(MARKING_STYLES) do
        c:Add(s.value, s.label)
    end
    return c:GetData()
end

local function EnsureUniqMarkers()
    local t = NX.DB.tankMarker
    local h = NX.DB.healerMarker
    if t ~= nil and h ~= nil and t == h then
        NX.DB.healerMarker = nil
    end
end

local function CreateLandingPanel()
    local panel = CreateFrame("Frame")

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Nexus Settings")

    local body = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    body:SetWidth(620)
    body:SetJustifyH("LEFT")
    body:SetText(
        "This addon was created to preserve and replace functionality that was lost with the Midnight expansion. " ..
        "It brings over key functionality that was previously handled by WeakAuras and other addons that are no longer supported, " ..
        "providing an alternative that works within the current addon restricted environment."
    )
    body:SetTextColor(1, 1, 1, 1)

    local function CreateHeaderLine(anchor, text)
        local line = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
        line:SetWidth(620)
        line:SetJustifyH("LEFT")
        local fontPath, fontSize, fontFlags = line:GetFont()
        if fontPath and fontSize then
            line:SetFont(fontPath, fontSize + 2, fontFlags)
        end
        line:SetTextColor(1.0, 0.82, 0.0, 1)
        line:SetText(text)
        return line
    end

    local function CreateBodyLine(anchor, text)
        local line = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        line:SetWidth(620)
        line:SetJustifyH("LEFT")
        line:SetTextColor(1, 1, 1, 1)
        line:SetText(text)
        return line
    end

    local automationHeader = CreateHeaderLine(body, "Automation:")
    local automationBody = CreateBodyLine(automationHeader, "Achievement Screenshots, Cinematic Controls, Dialog Confirmations, and Tutorial Behavior.")

    local combatHeader = CreateHeaderLine(automationBody, "Combat:")
    local combatBody = CreateBodyLine(combatHeader, "Auto Dismount/Actionbar Behavior, Combat Logging Controls, and Crosshair Customization.")

    local dungeonsHeader = CreateHeaderLine(combatBody, "Dungeons & Raids:")
    local dungeonsBody = CreateBodyLine(dungeonsHeader, "Great Vault Loot Spec, Keystone Handling, Mythic+ Tools, and Objective Tracker Behavior.")

    local interfaceHeader = CreateHeaderLine(dungeonsBody, "Interface:")
    local interfaceBody = CreateBodyLine(interfaceHeader, "Low Durability Alerts, Screen Effect Toggles, Visual Clarity, and Waypoint Tracking.")

    local systemHeader = CreateHeaderLine(interfaceBody, "System:")
    CreateBodyLine(systemHeader, "Auction House Filter Defaults, Lua Error Visibility, Slash Command Management, and Window Behavior.")

    return panel
end

local function BuildLowDurabilityControls(category)
    do
        local function GetValue()
            return (NX.DB.lowDurability and NX.DB.lowDurability.enabled) and true or false
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            NX.DB.lowDurability.enabled = v and true or false

            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_ENABLED",
            Settings.VarType.Boolean,
            "Low Durability Warning",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Enable or disable the Low Durability warning.")
    end

    do
        local FRIZQT_PATH = "Fonts\\FRIZQT__.TTF"
        local FRIZQT_NAME = "FrizQT"

        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

        local function GetFontOptionsData()
            local c = Settings.CreateControlTextContainer()

            local seenPath = {}
            local entries = {}

            seenPath[FRIZQT_PATH] = true
            table.insert(entries, { path = FRIZQT_PATH, name = FRIZQT_NAME })

            if LSM then
                local names = LSM:List("font")
                table.sort(names)
                for _, name in ipairs(names) do
                    local path = LSM:Fetch("font", name)
                    if path and not seenPath[path] then
                        seenPath[path] = true
                        table.insert(entries, { path = path, name = name })
                    end
                end
            end

            for _, e in ipairs(entries) do
                c:Add(e.path, e.name)
            end

            return c:GetData()
        end

        local function GetValue()
            local p = NX.DB.lowDurability and NX.DB.lowDurability.fontPath
            if type(p) ~= "string" or p == "" then
                return FRIZQT_PATH
            end
            return p
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            if type(v) ~= "string" or v == "" then
                v = FRIZQT_PATH
            end

            NX.DB.lowDurability.fontPath = v
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_FONT",
            Settings.VarType.String,
            "Font",
            FRIZQT_PATH,
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetFontOptionsData, "Selects the font used for the Low Durability warning text.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return tonumber(NX.DB.lowDurability and NX.DB.lowDurability.fontSize) or 48
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            v = tonumber(v) or 48
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 128 then v = 128 end

            NX.DB.lowDurability.fontSize = v
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_FONTSIZE",
            Settings.VarType.Number,
            "Font Size",
            48,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 128, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Controls the font size of the Low Durability warning text.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.lowDurability and NX.DB.lowDurability.threshold) or 20
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            v = tonumber(v) or 20
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end

            NX.DB.lowDurability.threshold = v
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_THRESHOLD",
            Settings.VarType.Number,
            "Threshold",
            20,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 100, 1)
        ApplyRightLabel(options, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, setting, options, "Shows the warning if any equipped item is at or below this durability percent.")
    end

    do
        local function GetValue()
            return (NX.DB.lowDurability and NX.DB.lowDurability.flashing) and true or false
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            NX.DB.lowDurability.flashing = v and true or false
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_FLASHING",
            Settings.VarType.Boolean,
            "Flashing",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Make the warning text flash while low durability is detected.")
    end

    do
        local function GetScreenHeight()
            local h = UIParent and UIParent.GetHeight and UIParent:GetHeight()
            h = tonumber(h) or 1080
            return math.floor(h + 0.5)
        end

        local function Clamp(v, lo, hi)
            if v < lo then return lo end
            if v > hi then return hi end
            return v
        end

        local function GetValue()
            return tonumber(NX.DB.lowDurability and NX.DB.lowDurability.offsetY) or 0
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            local maxH = GetScreenHeight()
            v = tonumber(v) or 0
            v = math.floor(v + 0.5)
            v = Clamp(v, -maxH, maxH)

            NX.DB.lowDurability.offsetY = v
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local defaultMax = GetScreenHeight()

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_OFFSETY",
            Settings.VarType.Number,
            "Y Offset",
            0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(-defaultMax, defaultMax, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Controls the vertical position from screen center.")
    end

    do
        local function GetColorOptionsData()
            local c = Settings.CreateControlTextContainer()
            local list = (NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.GetColorList)
                and NX.Common.LowDurability:GetColorList()
                or {}

            for _, e in ipairs(list) do
                c:Add(e.hex, e.name)
            end
            return c:GetData()
        end

        local function GetValue()
            local v = NX.DB.lowDurability and NX.DB.lowDurability.color
            if type(v) ~= "string" or v == "" then
                return "#FFFF00"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.lowDurability = NX.DB.lowDurability or {}
            if type(v) ~= "string" or v == "" then
                v = "#FFFF00"
            end
            NX.DB.lowDurability.color = v
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_COLOR",
            Settings.VarType.String,
            "Color",
            "#FFFF00",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetColorOptionsData, "Selects the color used for the Low Durability warning text.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.IsPreviewActive
                and NX.Common.LowDurability:IsPreviewActive()
        end

        local function SetValue(v)
            local wantOn = v and true or false
            local isOn = (GetValue() == true)
            if wantOn ~= isOn then
                if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.TogglePreview then
                    NX.Common.LowDurability:TogglePreview()
                end
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_LOWDURABILITY_PREVIEW_TOGGLE",
            Settings.VarType.Boolean,
            "Preview Message",
            false,
            GetValue,
            SetValue
        )

        Settings.CreateCheckbox(
            category,
            setting,
            "Shows or hides a preview of the warning using your current settings."
        )
    end
end

local function BuildCommonControls(category)
    if Settings.CreateSectionHeader then
        Settings.CreateSectionHeader(category, "Common")
    end

    do
        local function GetValue()
            return (NX.DB and NX.DB.moveSettingsPanel) and true or false
        end

        local function SetValue(v)
            NX.DB.moveSettingsPanel = v and true or false
            if NX.Core and NX.Core.UpdateSettingsPanelMovable then
                NX.Core:UpdateSettingsPanelMovable()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOVE_SETTINGS_PANEL",
            Settings.VarType.Boolean,
            "Move Settings Window",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Allows the Blizzard Settings window to be dragged and remembers its position."
        )
    end

    do
        local function GetValue()
            if not NX.DB then return true end
            return NX.DB.allowEscCloseCdmEditMode ~= false
        end

        local function SetValue(v)
            NX.DB.allowEscCloseCdmEditMode = v and true or false
            if NX.Common and NX.Common.SyncEscCloseCdmEditMode then
                NX.Common:SyncEscCloseCdmEditMode()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ESC_CLOSE_CDM_EDITMODE",
            Settings.VarType.Boolean,
            "Allow Esc to close CDM and Edit Mode",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "When enabled, pressing Escape closes Cooldown Manager and Edit Mode windows."
        )
    end

end

local function BuildSlashCommandControls(category)
    if Settings.CreateSectionHeader then
        Settings.CreateSectionHeader(category, "Slash Commands")
    end

    do
        local function IsAvailable()
            if NX.Common and NX.Common.IsQuickReloadSlashAvailable then
                return NX.Common:IsQuickReloadSlashAvailable()
            end
            return true
        end

        if IsAvailable() then
            local function GetValue()
                return (NX.DB and NX.DB.quickReloadSlash) and true or false
            end

            local function SetValue(v)
                NX.DB.quickReloadSlash = v and true or false
                if NX.Common and NX.Common.SyncQuickReloadSlash then
                    NX.Common:SyncQuickReloadSlash()
                elseif NX.SlashCommands and NX.SlashCommands.SyncQuickReloadSlash then
                    NX.SlashCommands:SyncQuickReloadSlash()
                end
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_QUICK_RELOAD_SLASH",
                Settings.VarType.Boolean,
                "Quick ReloadUI (/rl)",
                true,
                GetValue,
                SetValue
            )

            local tooltip = "Registers /rl to reload the UI (same as /console reloadui)."
            if NX.Common and NX.Common.GetQuickReloadUnavailableTooltip then
                tooltip = NX.Common:GetQuickReloadUnavailableTooltip()
            end

            CreateEnabledDisabledDropdown(category, setting, tooltip)
        else
            if NX.DB then
                NX.DB.quickReloadSlash = false
            end

            local function GetValue()
                return "unavailable"
            end

            local function SetValue(_)
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_QUICK_RELOAD_SLASH_UNAVAILABLE",
                Settings.VarType.String,
                "Quick ReloadUI (/rl)",
                "unavailable",
                GetValue,
                SetValue
            )

            local function GetUnavailableOptionsData()
                local owner = (NX.Common and NX.Common.GetQuickReloadSlashOwnerDisplay and NX.Common:GetQuickReloadSlashOwnerDisplay())
                    or "another addon"
                local c = Settings.CreateControlTextContainer()
                c:Add("unavailable", string.format("|cffe73f3fUnavailable. (Registered by %s)|r", owner))
                return c:GetData()
            end

            local tooltip = "Quick ReloadUI cannot be enabled because /rl is already registered by another addon."
            if NX.Common and NX.Common.GetQuickReloadUnavailableTooltip then
                tooltip = NX.Common:GetQuickReloadUnavailableTooltip()
            end

            Settings.CreateDropdown(category, setting, GetUnavailableOptionsData, tooltip)
        end
    end

    do
        local function GetValue()
            if not NX.DB then return true end
            return NX.DB.quickCdmSlash ~= false
        end

        local function SetValue(v)
            NX.DB.quickCdmSlash = v and true or false
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_QUICK_CDM_SLASH",
            Settings.VarType.Boolean,
            "Enable Quick CDM",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Enables /cd, /cdm, and /wa. Command execution is blocked while in combat."
        )
    end

    do
        local function GetValue()
            if not NX.DB then return true end
            return NX.DB.quickEditModeSlash ~= false
        end

        local function SetValue(v)
            NX.DB.quickEditModeSlash = v and true or false
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_QUICK_EDITMODE_SLASH",
            Settings.VarType.Boolean,
            "Enable Quick Edit Mode",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Enables /em, /edit, /editmode, and /editmenu. Command execution is blocked while in combat."
        )
    end

end

local function BuildGreatVaultControls(category)
    local function IsPreviewActive()
        return NX.Vault and NX.Vault.IsPreviewActive and NX.Vault:IsPreviewActive()
    end

    local function TogglePreview()
        if not (NX.DB and NX.DB.vault and NX.DB.vault.enabled) then
            if NX.Vault and NX.Vault.StopPreview then
                NX.Vault:StopPreview()
            end
            return
        end
        if NX.Vault and NX.Vault.TogglePreview then
            NX.Vault:TogglePreview()
        end
    end

    do
        local function GetValue()
            return (NX.DB.vault and NX.DB.vault.enabled) and true or false
        end

        local function SetValue(v)
            NX.DB.vault.enabled = v and true or false
            if not NX.DB.vault.enabled and NX.Vault and NX.Vault.StopPreview then
                NX.Vault:StopPreview()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_ENABLED",
            Settings.VarType.Boolean,
            "Great Vault Module",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Enable or disable the Great Vault module entirely."
        )
    end

    do
        local FRIZQT_PATH = "Fonts\\FRIZQT__.TTF"
        local FRIZQT_NAME = "FrizQT"

        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

        local function GetFontOptionsData()
            local c = Settings.CreateControlTextContainer()

            local seenPath = {}
            local entries = {}

            seenPath[FRIZQT_PATH] = true
            table.insert(entries, { path = FRIZQT_PATH, name = FRIZQT_NAME })

            if LSM then
                local names = LSM:List("font")
                table.sort(names)
                for _, name in ipairs(names) do
                    local path = LSM:Fetch("font", name)
                    if path and not seenPath[path] then
                        seenPath[path] = true
                        table.insert(entries, { path = path, name = name })
                    end
                end
            end

            for _, e in ipairs(entries) do
                c:Add(e.path, e.name)
            end

            return c:GetData()
        end

        local function GetValue()
            local p = NX.DB.vault and NX.DB.vault.fontPath
            if type(p) ~= "string" or p == "" then
                return FRIZQT_PATH
            end
            return p
        end

        local function SetValue(v)
            if type(v) ~= "string" or v == "" then
                v = FRIZQT_PATH
            end
            NX.DB.vault.fontPath = v
            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_FONT",
            Settings.VarType.String,
            "Font",
            FRIZQT_PATH,
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetFontOptionsData, "Selects the font used for the Great Vault banner text.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return tonumber(NX.DB.vault and NX.DB.vault.fontSize) or 48
        end

        local function SetValue(v)
            v = tonumber(v) or 48
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 128 then v = 128 end

            NX.DB.vault.fontSize = v
            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_FONTSIZE",
            Settings.VarType.Number,
            "Font Size",
            48,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 128, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Controls the font size of the Great Vault banner text.")
    end

    do
        local function GetScreenHeight()
            local h = UIParent and UIParent.GetHeight and UIParent:GetHeight()
            h = tonumber(h) or 1080
            return math.floor(h + 0.5)
        end

        local function Clamp(v, lo, hi)
            if v < lo then return lo end
            if v > hi then return hi end
            return v
        end

        local function GetValue()
            return tonumber(NX.DB.vault and NX.DB.vault.offsetY) or 0
        end

        local function SetValue(v)
            local maxH = GetScreenHeight()
            v = tonumber(v) or 0
            v = math.floor(v + 0.5)
            v = Clamp(v, -maxH, maxH)

            NX.DB.vault.offsetY = v
            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
        end

        local defaultMax = GetScreenHeight()

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_OFFSETY",
            Settings.VarType.Number,
            "Offset Y",
            0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(-defaultMax, defaultMax, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(
            category,
            setting,
            options,
            "Controls the vertical position on the screen, measured from the screen center."
        )
    end

    do
        local function GetValue()
            return (NX.DB.vault and NX.DB.vault.flashing) and true or false
        end

        local function SetValue(v)
            NX.DB.vault.flashing = v and true or false
            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_FLASHING",
            Settings.VarType.Boolean,
            "Flashing",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Make the text flash when you are opening the Great Vault."
        )
    end

    do
        local function GetValue() return IsPreviewActive() end
        local function SetValue(v)
            local wantOn = v and true or false
            local isOn = IsPreviewActive()
            if wantOn ~= isOn then
                TogglePreview()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_PREVIEW_TOGGLE",
            Settings.VarType.Boolean,
            "Preview Message",
            false,
            GetValue,
            SetValue
        )

        Settings.CreateCheckbox(
            category,
            setting,
            "Shows or hides a preview of the Great Vault banner using your current settings."
        )
    end
end

local function BuildCrosshairControls(category)
    local function GetColorsOptionsData()
        local c = Settings.CreateControlTextContainer()
        local list = (NX.Crosshair and NX.Crosshair.GetColorList) and NX.Crosshair:GetColorList() or {}
        for _, e in ipairs(list) do
            c:Add(e.hex, e.name)
        end
        return c:GetData()
    end

    do
        local function GetValue()
            return (NX.DB.crosshair and NX.DB.crosshair.show) and true or false
        end

        local function SetValue(v)
            NX.DB.crosshair.show = v and true or false
            if NX.Crosshair and NX.Crosshair.OnSettingsChanged then
                NX.Crosshair:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CROSSHAIR_SHOW",
            Settings.VarType.Boolean,
            "Enable Crosshair",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Show or hide the crosshair.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.crosshair and NX.DB.crosshair.size) or 18
        end

        local function SetValue(v)
            v = tonumber(v) or 18
            v = math.floor(v + 0.5)
            if v < 4 then v = 4 end
            if v > 256 then v = 256 end
            NX.DB.crosshair.size = v
            if NX.Crosshair and NX.Crosshair.OnSettingsChanged then
                NX.Crosshair:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CROSSHAIR_SIZE",
            Settings.VarType.Number,
            "Size",
            18,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(4, 256, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Controls the overall size of the crosshair.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.crosshair and NX.DB.crosshair.thickness) or 2
        end

        local function SetValue(v)
            v = tonumber(v) or 2
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 32 then v = 32 end
            NX.DB.crosshair.thickness = v
            if NX.Crosshair and NX.Crosshair.OnSettingsChanged then
                NX.Crosshair:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CROSSHAIR_THICKNESS",
            Settings.VarType.Number,
            "Thickness",
            2,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 32, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Controls the thickness of the crosshair.")
    end

    do
        local function GetValue()
            return (NX.DB.crosshair and NX.DB.crosshair.color) or "#FFFFFF"
        end

        local function SetValue(v)
            if type(v) ~= "string" or v == "" then
                v = "#FFFFFF"
            end
            NX.DB.crosshair.color = v
            if NX.Crosshair and NX.Crosshair.OnSettingsChanged then
                NX.Crosshair:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CROSSHAIR_COLOR",
            Settings.VarType.String,
            "Color",
            "#FFFFFF",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetColorsOptionsData, "Color of the crosshair. Can be set to any hex color code, such as #RRGGBB or #RRGGBBAA.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            local a = tonumber(NX.DB.crosshair and NX.DB.crosshair.alpha)
            if not a then return 1.0 end
            if a < 0 then a = 0 end
            if a > 1 then a = 1 end
            return a
        end

        local function SetValue(v)
            v = tonumber(v)
            if not v then v = 1.0 end
            if v < 0 then v = 0 end
            if v > 1 then v = 1 end
            NX.DB.crosshair.alpha = v
            if NX.Crosshair and NX.Crosshair.OnSettingsChanged then
                NX.Crosshair:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CROSSHAIR_ALPHA",
            Settings.VarType.Number,
            "Alpha",
            1.0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 1, 0.01)
        ApplyRightLabel(options, function(v) return string.format("%.2f", v) end)
        Settings.CreateSlider(category, setting, options, "Controls the transparency of the crosshair.")
    end
end

local function BuildMythicPlusControls(category)
    do
        local function GetValue()
            return not not (NX.DB.mythicPlus and NX.DB.mythicPlus.respondToKeys)
        end

        local function SetValue(v)
            NX.DB.mythicPlus = NX.DB.mythicPlus or {}
            NX.DB.mythicPlus.respondToKeys = not not v
            if NX.MythicPlus and NX.MythicPlus.OnSettingsChanged then
                NX.MythicPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MPLUS_RESPOND_KEYS",
            Settings.VarType.Boolean,
            "Respond to !keys",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Replies in party chat with your keystone links when someone types !keys."
        )
    end

    do
        local function GetValue()
            return tonumber(NX.DB.mythicPlus and NX.DB.mythicPlus.keysResponderCooldownSeconds) or 5
        end

        local function SetValue(v)
            NX.DB.mythicPlus = NX.DB.mythicPlus or {}
            v = tonumber(v) or 5
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 10 then v = 10 end
            NX.DB.mythicPlus.keysResponderCooldownSeconds = v
            if NX.MythicPlus and NX.MythicPlus.OnSettingsChanged then
                NX.MythicPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MPLUS_KEYS_COOLDOWN",
            Settings.VarType.Number,
            "!keys Cooldown",
            5,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 10, 1)
        ApplyRightLabel(options, function(value) return string.format("%ds", value) end)
        Settings.CreateSlider(category, setting, options, "Controls the cooldown duration for responding to !keys in party chat, in seconds.")
    end

    do
        local function GetValue()
            return not not (NX.DB.mythicPlus and NX.DB.mythicPlus.autoHideObjectives)
        end

        local function SetValue(v)
            NX.DB.mythicPlus = NX.DB.mythicPlus or {}
            NX.DB.mythicPlus.autoHideObjectives = not not v
            if NX.MythicPlus and NX.MythicPlus.OnSettingsChanged then
                NX.MythicPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MPLUS_AUTOHIDE_OBJECTIVES",
            Settings.VarType.Boolean,
            "Auto Hide Objective Tracker",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Hides the Objective Tracker during Mythic+ runs and updates visibility on relevant instance events."
        )
    end

    do
        local function GetValue()
            return tonumber(NX.DB.mythicPlus and NX.DB.mythicPlus.objectiveTrackerRestoreDelaySeconds) or 30
        end

        local function SetValue(v)
            NX.DB.mythicPlus = NX.DB.mythicPlus or {}
            v = tonumber(v) or 30
            v = math.floor(v + 0.5)
            if v < 0 then v = 0 end
            if v > 120 then v = 120 end
            NX.DB.mythicPlus.objectiveTrackerRestoreDelaySeconds = v
            if NX.MythicPlus and NX.MythicPlus.OnSettingsChanged then
                NX.MythicPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MPLUS_OBJ_RESTORE_DELAY",
            Settings.VarType.Number,
            "Objective Tracker Restore Delay",
            30,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 120, 1)
        ApplyRightLabel(options, function(value) return string.format("%ds", value) end)
        Settings.CreateSlider(category, setting, options, "Controls how many seconds after a Mythic+ run ends, or after a player leaves the instance, before the Objective Tracker is shown again, if Auto Hide Objective Tracker is enabled.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "NEXUS_AUTO_INSERT_KEYSTONE",
            "autoInsertKeystone",
            NX.DB,
            Settings.VarType.Boolean,
            "Auto Insert Keystone",
            true
        )
        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Automatically inserts your keystone when the Mythic+ Keystone UI is opened."
        )
    end

    AddSectionHeader(category, "Mythic+ Auto Marking (Players)")

    do
        local function GetValue() return NX.DB.markingStyle or "leader" end
        local function SetValue(v) NX.DB.markingStyle = v end
        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MARKING_STYLE",
            Settings.VarType.String,
            "Marking Style",
            "leader",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            GetStyleOptionsData,
            "This will determine when Auto Marking the Tank and Healer should happen."
        )
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue() return NX.DB.tankMarker or 0 end
        local function SetValue(v)
            v = tonumber(v) or 0
            local newMarker = (v == 0) and nil or v

            NX.DB.tankMarker = newMarker
            if newMarker ~= nil and NX.DB.healerMarker == newMarker then
                NX.DB.healerMarker = nil
            end
            EnsureUniqMarkers()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_TANK_MARKER",
            Settings.VarType.Number,
            "Auto Mark Tank",
            0,
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            function() return GetMarkerOptionsData(NX.DB.healerMarker) end,
            "Automatically marks the tank during the Mythic+ Start Countdown."
        )
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue() return NX.DB.healerMarker or 0 end
        local function SetValue(v)
            v = tonumber(v) or 0
            local newMarker = (v == 0) and nil or v

            NX.DB.healerMarker = newMarker
            if newMarker ~= nil and NX.DB.tankMarker == newMarker then
                NX.DB.tankMarker = nil
            end
            EnsureUniqMarkers()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_HEALER_MARKER",
            Settings.VarType.Number,
            "Auto Mark Healer",
            0,
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            function() return GetMarkerOptionsData(NX.DB.tankMarker) end,
            "Automatically marks the healer during the Mythic+ Start Countdown."
        )
        init.reinitializeOnValueChanged = true
    end
end

local function BuildMotionSicknessControls(category)
    do
        local function GetValue()
            return not not (NX.DB.motionSickness and NX.DB.motionSickness.enabled)
        end

        local function SetValue(v)
            NX.DB.motionSickness = NX.DB.motionSickness or {}
            NX.DB.motionSickness.enabled = not not v
            if NX.MotionSickness and NX.MotionSickness.OnSettingsChanged then
                NX.MotionSickness:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOTION_SICKNESS_ENABLED",
            Settings.VarType.Boolean,
            "Disable Motion Sickness",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Disables the landscape darkening effect used by motion sickness mode.")
    end
end

local function BuildSkyridingEffectsControls(category)
    do
        local function GetValue()
            return not not (NX.DB.skyridingEffects and NX.DB.skyridingEffects.enabled)
        end

        local function SetValue(v)
            NX.DB.skyridingEffects = NX.DB.skyridingEffects or {}
            NX.DB.skyridingEffects.enabled = not not v
            if NX.SkyridingEffects and NX.SkyridingEffects.OnSettingsChanged then
                NX.SkyridingEffects:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_SKYRIDING_EFFECTS_ENABLED",
            Settings.VarType.Boolean,
            "Disable Skyriding Screen Effects",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Disables full screen visual effects while skyriding (advanced flying).")
    end
end

local function BuildAchievementScreenshotControls(category)
    do
        local function GetValue()
            return not not (NX.DB.achievementScreenshot and NX.DB.achievementScreenshot.enabled)
        end

        local function SetValue(v)
            NX.DB.achievementScreenshot = NX.DB.achievementScreenshot or {}
            NX.DB.achievementScreenshot.enabled = not not v
            if NX.AchievementScreenshot and NX.AchievementScreenshot.OnSettingsChanged then
                NX.AchievementScreenshot:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACH_SCREENSHOT_ENABLED",
            Settings.VarType.Boolean,
            "Screenshot on Achievement",
            false,
            GetValue,
            SetValue
        )
        CreateEnabledDisabledDropdown(category, setting, "Takes a screenshot when you earn an achievement.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.achievementScreenshot and NX.DB.achievementScreenshot.delaySeconds) or 1.6
        end

        local function SetValue(v)
            NX.DB.achievementScreenshot = NX.DB.achievementScreenshot or {}
            NX.DB.achievementScreenshot.delaySeconds = tonumber(v) or 1.6
            if NX.AchievementScreenshot and NX.AchievementScreenshot.OnSettingsChanged then
                NX.AchievementScreenshot:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACH_SCREENSHOT_DELAY",
            Settings.VarType.Number,
            "Delay",
            1.6,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 10, 0.1)
        ApplyRightLabel(options, function(value) return string.format("%.1fs", value) end)
        Settings.CreateSlider(category, setting, options, "Controls the delay before taking a screenshot after earning an achievement.")
    end

end

local function BuildAutoCombatLogControls(category)
    do
        local function GetValue()
            return not not (NX.DB.autoCombatLog and NX.DB.autoCombatLog.enabled)
        end

        local function SetValue(v)
            NX.DB.autoCombatLog = NX.DB.autoCombatLog or {}
            NX.DB.autoCombatLog.enabled = not not v
            if NX.AutoCombatLog and NX.AutoCombatLog.OnSettingsChanged then
                NX.AutoCombatLog:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_AUTO_COMBATLOG_ENABLED",
            Settings.VarType.Boolean,
            "Auto Combat Log",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Automatically starts combat logging in dungeons, raids, arenas, and battlegrounds plus encounter/challenge events.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.autoCombatLog and NX.DB.autoCombatLog.stopDelaySeconds) or 30
        end

        local function SetValue(v)
            NX.DB.autoCombatLog = NX.DB.autoCombatLog or {}
            NX.DB.autoCombatLog.stopDelaySeconds = tonumber(v) or 30
            if NX.AutoCombatLog and NX.AutoCombatLog.OnSettingsChanged then
                NX.AutoCombatLog:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_AUTO_COMBATLOG_STOPDELAY",
            Settings.VarType.Number,
            "Combat Log Stop Delay",
            30,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 60, 1)
        ApplyRightLabel(options, function(value) return string.format("%ds", value) end)
        Settings.CreateSlider(category, setting, options, "Controls how long to wait after combat ends before auto-disabling combat logging.")
    end
end

local function BuildAlwaysSharpenControls(category)
    do
        local function GetValue()
            return not not (NX.DB.alwaysSharpen and NX.DB.alwaysSharpen.enabled)
        end

        local function SetValue(v)
            NX.DB.alwaysSharpen = NX.DB.alwaysSharpen or {}
            NX.DB.alwaysSharpen.enabled = not not v
            if NX.AlwaysSharpen and NX.AlwaysSharpen.OnSettingsChanged then
                NX.AlwaysSharpen:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALWAYS_SHARPEN_ENABLED",
            Settings.VarType.Boolean,
            "Always Sharpen Graphics",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Forces ResampleAlwaysSharpen to stay enabled.")
    end
end

local function BuildEnhancedErrorTextControls(category)
    AddSectionHeader(category, "Objective & Error Text")

    do
        local function GetValue()
            return not not (NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.enabled)
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            NX.DB.enhancedErrorText.enabled = not not v
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_ENABLED",
            Settings.VarType.Boolean,
            "Enhanced Objective & Error Text",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Increases the size/space of UIErrorsFrame messages.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.fontSize) or 22
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            NX.DB.enhancedErrorText.fontSize = tonumber(v) or 22
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_FONTSIZE",
            Settings.VarType.Number,
            "Font Size",
            22,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(8, 72, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Controls the font size used for Enhanced Objective & Error Text.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.width) or 800
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            v = tonumber(v) or 800
            v = math.floor(v + 0.5)
            if v < 200 then v = 200 end
            if v > 2000 then v = 2000 end
            NX.DB.enhancedErrorText.width = v
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_WIDTH",
            Settings.VarType.Number,
            "Width",
            800,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(200, 2000, 10)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Controls the width of the Objective & Error text box.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.height) or 120
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            v = tonumber(v) or 120
            v = math.floor(v + 0.5)
            if v < 40 then v = 40 end
            if v > 400 then v = 400 end
            NX.DB.enhancedErrorText.height = v
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_HEIGHT",
            Settings.VarType.Number,
            "Height",
            120,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(40, 400, 5)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Controls the height of the Objective & Error text box.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.offsetY) or 0
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            v = tonumber(v) or 0
            v = math.floor(v + 0.5)
            if v < -600 then v = -600 end
            if v > 600 then v = 600 end
            NX.DB.enhancedErrorText.offsetY = v
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_OFFSETY",
            Settings.VarType.Number,
            "Y Offset",
            0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(-600, 600, 1)
        ApplyRightLabel(options, function(value) return string.format("%dpx", value) end)
        Settings.CreateSlider(category, setting, options, "Moves the Objective & Error text box up or down on the screen.")
    end

    do
        local function GetValue()
            return not not (NX.DB.enhancedErrorText and NX.DB.enhancedErrorText.outline)
        end

        local function SetValue(v)
            NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
            NX.DB.enhancedErrorText.outline = not not v
            if NX.EnhancedErrorText and NX.EnhancedErrorText.OnSettingsChanged then
                NX.EnhancedErrorText:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ENHANCED_ERRTEXT_OUTLINE",
            Settings.VarType.Boolean,
            "Outline",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Use OUTLINE font flags for UIErrorsFrame.")
    end
end

local function BuildCleanObjectiveTrackerControls(category)
    do
        local function GetValue()
            return not not (NX.DB.cleanObjectiveTracker and NX.DB.cleanObjectiveTracker.enabled)
        end

        local function SetValue(v)
            NX.DB.cleanObjectiveTracker = NX.DB.cleanObjectiveTracker or {}
            NX.DB.cleanObjectiveTracker.enabled = not not v
            if NX.CleanObjectiveTracker and NX.CleanObjectiveTracker.OnSettingsChanged then
                NX.CleanObjectiveTracker:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLEAN_OT_ENABLED",
            Settings.VarType.Boolean,
            "Clean Objective Tracker",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Hides the Objective Tracker header background/title.")
    end

    do
        local function GetValue()
            return not not (NX.DB.cleanObjectiveTracker and NX.DB.cleanObjectiveTracker.hideBackground)
        end

        local function SetValue(v)
            NX.DB.cleanObjectiveTracker = NX.DB.cleanObjectiveTracker or {}
            NX.DB.cleanObjectiveTracker.hideBackground = not not v
            if NX.CleanObjectiveTracker and NX.CleanObjectiveTracker.OnSettingsChanged then
                NX.CleanObjectiveTracker:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLEAN_OT_BG",
            Settings.VarType.Boolean,
            "Hide Background",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Hide the tracker header background.")
    end

    do
        local function GetValue()
            return not not (NX.DB.cleanObjectiveTracker and NX.DB.cleanObjectiveTracker.hideTitle)
        end

        local function SetValue(v)
            NX.DB.cleanObjectiveTracker = NX.DB.cleanObjectiveTracker or {}
            NX.DB.cleanObjectiveTracker.hideTitle = not not v
            if NX.CleanObjectiveTracker and NX.CleanObjectiveTracker.OnSettingsChanged then
                NX.CleanObjectiveTracker:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLEAN_OT_TITLE",
            Settings.VarType.Boolean,
            "Hide Title",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Hide the tracker header title text.")
    end
end

local function BuildAutoPlaceSpellsControls(category)
    local function GetValue()
        return not not (NX.DB.autoPlaceSpells and NX.DB.autoPlaceSpells.enabled)
    end

    local function SetValue(v)
        NX.DB.autoPlaceSpells = NX.DB.autoPlaceSpells or {}
        NX.DB.autoPlaceSpells.enabled = not not v
        if NX.AutoPlaceSpells and NX.AutoPlaceSpells.OnSettingsChanged then
            NX.AutoPlaceSpells:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_AUTOPLACE_SPELLS_ENABLED",
        Settings.VarType.Boolean,
        "Place New Spells on Actionbars",
        true,
        GetValue,
        SetValue
    )
    CreateEnabledDisabledDropdown(category, setting, "Controls the CVar AutoPushSpellToActionBar.")
end

local function BuildFloatingCombatTextControls(category)
    do
        local function GetValue() return not (not not (NX.DB.floatingCombatText and NX.DB.floatingCombatText.hideOverPlayer)) end
        local function SetValue(v)
            NX.DB.floatingCombatText = NX.DB.floatingCombatText or {}
            NX.DB.floatingCombatText.hideOverPlayer = not v
            if NX.FloatingCombatText and NX.FloatingCombatText.OnSettingsChanged then NX.FloatingCombatText:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_FCT_HIDE_OVER_PLAYER", Settings.VarType.Boolean, "Enable Player", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Shows damage/healing hit indicator text above your character.")
    end

    do
        local function GetValue() return not (not not (NX.DB.floatingCombatText and NX.DB.floatingCombatText.hideOverPet)) end
        local function SetValue(v)
            NX.DB.floatingCombatText = NX.DB.floatingCombatText or {}
            NX.DB.floatingCombatText.hideOverPet = not v
            if NX.FloatingCombatText and NX.FloatingCombatText.OnSettingsChanged then NX.FloatingCombatText:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_FCT_HIDE_OVER_PET", Settings.VarType.Boolean, "Enable Pet", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Shows damage/healing hit indicator text above your pet.")
    end

    local function MakeToggle(proxyKey, dbKey, label, tooltip)
        local function GetValue() return not not (NX.DB.floatingCombatText and NX.DB.floatingCombatText[dbKey]) end
        local function SetValue(v)
            NX.DB.floatingCombatText = NX.DB.floatingCombatText or {}
            NX.DB.floatingCombatText[dbKey] = not not v
            if NX.FloatingCombatText and NX.FloatingCombatText.OnSettingsChanged then NX.FloatingCombatText:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, proxyKey, Settings.VarType.Boolean, label, false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, tooltip)
    end

    MakeToggle("NEXUS_FCT_SHOW_DAMAGE", "showCombatDamage", "Combat Damage", "Controls floatingCombatTextCombatDamage_v2.")
    MakeToggle("NEXUS_FCT_SHOW_HEALING", "showCombatHealing", "Combat Healing", "Controls floatingCombatTextCombatHealing_v2.")
    MakeToggle("NEXUS_FCT_SHOW_FRIENDLY_HEALERS", "showFriendlyHealers", "Friendly Healers", "Controls floatingCombatTextFriendlyHealers_v2.")

    AddSectionHeader(category, "Floating Combat Text - Events")
    MakeToggle("NEXUS_FCT_SHOW_HEAL_ABSORB_SELF", "showHealingAbsorbSelf", "Self Healing Absorbs", "Controls floatingCombatTextCombatHealingAbsorbSelf_v2.")
    MakeToggle("NEXUS_FCT_SHOW_HEAL_ABSORB_TARGET", "showHealingAbsorbTarget", "Target Healing Absorbs", "Controls floatingCombatTextCombatHealingAbsorbTarget_v2.")
    MakeToggle("NEXUS_FCT_SHOW_COMBAT_STATE", "showCombatState", "Combat State", "Controls floatingCombatTextCombatState_v2.")
    MakeToggle("NEXUS_FCT_SHOW_COMBO_POINTS", "showComboPoints", "Combo Points", "Controls floatingCombatTextComboPoints_v2.")
    MakeToggle("NEXUS_FCT_SHOW_DAMAGE_REDUCTION", "showDamageReduction", "Damage Reduction", "Controls floatingCombatTextDamageReduction_v2.")
    MakeToggle("NEXUS_FCT_SHOW_DODGE_PARRY_MISS", "showDodgeParryMiss", "Dodge, Parry, and Miss", "Controls floatingCombatTextDodgeParryMiss_v2.")
    MakeToggle("NEXUS_FCT_SHOW_ENERGY_GAINS", "showEnergyGains", "Energy Gains", "Controls floatingCombatTextEnergyGains_v2.")
    MakeToggle("NEXUS_FCT_SHOW_FLOAT_MODE", "showFloatMode", "Floating Text Mode v2", "Controls floatingCombatTextFloatMode_v2.")
    MakeToggle("NEXUS_FCT_SHOW_HONOR_GAINS", "showHonorGains", "Honor Gains", "Controls floatingCombatTextHonorGains_v2.")
    MakeToggle("NEXUS_FCT_SHOW_LOW_MANA_HEALTH", "showLowManaHealth", "Low Mana/Health", "Controls floatingCombatTextLowManaHealth_v2.")
    MakeToggle("NEXUS_FCT_SHOW_PERIODIC_ENERGY", "showPeriodicEnergyGains", "Periodic Energy Gains", "Controls floatingCombatTextPeriodicEnergyGains_v2.")
    MakeToggle("NEXUS_FCT_SHOW_PET_MELEE", "showPetMeleeDamage", "Pet Melee Damage", "Controls floatingCombatTextPetMeleeDamage_v2.")
    MakeToggle("NEXUS_FCT_SHOW_PET_SPELL", "showPetSpellDamage", "Pet Spell Damage", "Controls floatingCombatTextPetSpellDamage_v2.")
end

local function BuildAssistedRotationOverlayControls(category)
    local function GetValue() return not not (NX.DB.assistedRotationOverlay and NX.DB.assistedRotationOverlay.enabled) end
    local function SetValue(v)
        NX.DB.assistedRotationOverlay = NX.DB.assistedRotationOverlay or {}
        NX.DB.assistedRotationOverlay.enabled = not not v
        if NX.AssistedRotationOverlay and NX.AssistedRotationOverlay.OnSettingsChanged then
            NX.AssistedRotationOverlay:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_ASSISTED_OVERLAY_HIDE", Settings.VarType.Boolean, "Hide Assisted Combat Rotation overlay", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides the Assisted Combat Rotation helper glow/overlay on action buttons.")
end

local function BuildExtraActionArtworkControls(category)
    local function GetValue() return not not (NX.DB.extraActionArtwork and NX.DB.extraActionArtwork.enabled) end
    local function SetValue(v)
        NX.DB.extraActionArtwork = NX.DB.extraActionArtwork or {}
        NX.DB.extraActionArtwork.enabled = not not v
        if NX.ExtraActionArtwork and NX.ExtraActionArtwork.OnSettingsChanged then
            NX.ExtraActionArtwork:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_EXTRA_ACTION_ART", Settings.VarType.Boolean, "Hide Extra Action / Zone Ability artwork", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides ExtraActionButton and ZoneAbilityFrame artwork (not the button).")
end

local function BuildHideTalkingHeadControls(category)
    local function GetValue() return not not (NX.DB.hideTalkingHead and NX.DB.hideTalkingHead.enabled) end
    local function SetValue(v)
        NX.DB.hideTalkingHead = NX.DB.hideTalkingHead or {}
        NX.DB.hideTalkingHead.enabled = not not v
        if NX.HideTalkingHead and NX.HideTalkingHead.OnSettingsChanged then
            NX.HideTalkingHead:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_TALKING_HEAD", Settings.VarType.Boolean, "Automatically hide Talking Head Frame", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides the Talking Head frame whenever it tries to show.")
end

local function BuildLuaErrorsControls(category)
    local function GetValue() return not not (NX.DB.luaErrors and NX.DB.luaErrors.enabled) end
    local function SetValue(v)
        NX.DB.luaErrors = NX.DB.luaErrors or {}
        NX.DB.luaErrors.enabled = not not v
        if NX.LuaErrors and NX.LuaErrors.OnSettingsChanged then NX.LuaErrors:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_LUA_ERRORS", Settings.VarType.Boolean, "Show LUA Errors", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Controls the CVar scriptErrors.")
end

local function BuildTutorialsControls(category)
    local function GetValue() return not (not not (NX.DB.tutorials and NX.DB.tutorials.disabled)) end
    local function SetValue(v)
        NX.DB.tutorials = NX.DB.tutorials or {}
        NX.DB.tutorials.disabled = not v
        if NX.Tutorials and NX.Tutorials.OnSettingsChanged then NX.Tutorials:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_DISABLE_TUTORIALS", Settings.VarType.Boolean, "Tutorials", true, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Disables most tutorial popups when set to Disabled (showTutorials = 0).")
end

local function BuildScreenshotStatusControls(category)
    local function GetValue() return not not (NX.DB.hideScreenshotStatus and NX.DB.hideScreenshotStatus.enabled) end
    local function SetValue(v)
        NX.DB.hideScreenshotStatus = NX.DB.hideScreenshotStatus or {}
        NX.DB.hideScreenshotStatus.enabled = not not v
        if NX.HideScreenshotStatus and NX.HideScreenshotStatus.OnSettingsChanged then NX.HideScreenshotStatus:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_SCREENSHOT_STATUS", Settings.VarType.Boolean, "Hide Screenshot Status", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Disables screenshot status notifications (started/succeeded/failed).")
end

local function BuildDeleteDialogControls(category)
    local function GetValue() return not not (NX.DB.deleteDialog and NX.DB.deleteDialog.enabled) end
    local function SetValue(v)
        NX.DB.deleteDialog = NX.DB.deleteDialog or {}
        NX.DB.deleteDialog.enabled = not not v
        if NX.DeleteDialog and NX.DeleteDialog.OnSettingsChanged then NX.DeleteDialog:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_DELETE_DIALOG", Settings.VarType.Boolean, "Add \"DELETE\" to delete dialog", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Auto-fills the required DELETE text when destroying protected items.")
end

local function BuildAutoConfirmDialogsControls(category)
    do
        local function GetValue() return not not (NX.DB.autoConfirmDialogs and NX.DB.autoConfirmDialogs.enabled) end
        local function SetValue(v)
            NX.DB.autoConfirmDialogs = NX.DB.autoConfirmDialogs or {}
            NX.DB.autoConfirmDialogs.enabled = not not v
            if NX.AutoConfirmDialogs and NX.AutoConfirmDialogs.OnSettingsChanged then NX.AutoConfirmDialogs:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTOCONFIRM_ENABLED", Settings.VarType.Boolean, "Auto-Confirm Dialogs", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Automatically clicks the confirm button for selected dialogs.")
    end

    local function MakeToggle(key, label, tooltip)
        local function GetValue() return not not (NX.DB.autoConfirmDialogs and NX.DB.autoConfirmDialogs[key]) end
        local function SetValue(v)
            NX.DB.autoConfirmDialogs = NX.DB.autoConfirmDialogs or {}
            NX.DB.autoConfirmDialogs[key] = not not v
            if NX.AutoConfirmDialogs and NX.AutoConfirmDialogs.OnSettingsChanged then NX.AutoConfirmDialogs:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTOCONFIRM_" .. key:upper(), Settings.VarType.Boolean, label, false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, tooltip)
    end

    MakeToggle("replaceEnchant", "Accept Enchants", "Automatically confirms the enchant replacement dialog.")
    MakeToggle("acceptSockets", "Replace Sockets", "Automatically confirms the socket replacement dialog.")

    BuildDeleteDialogControls(category)
end

local function BuildAutoDismountControls(category)
    do
        local function GetValue() return (NX.DB.autoDismount and NX.DB.autoDismount.enabled ~= false) end
        local function SetValue(v)
            NX.DB.autoDismount = NX.DB.autoDismount or {}
            NX.DB.autoDismount.enabled = not not v
            if NX.AutoDismount and NX.AutoDismount.OnSettingsChanged then NX.AutoDismount:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTODISMOUNT", Settings.VarType.Boolean, "Dismount when using Abilities", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Controls the CVar autoDismount.")
    end

    do
        local function GetValue() return (NX.DB.autoDismount and NX.DB.autoDismount.flying ~= false) end
        local function SetValue(v)
            NX.DB.autoDismount = NX.DB.autoDismount or {}
            NX.DB.autoDismount.flying = not not v
            if NX.AutoDismount and NX.AutoDismount.OnSettingsChanged then NX.AutoDismount:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTODISMOUNT_FLY", Settings.VarType.Boolean, "Dismount when using Abilities (Flying)", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Controls the CVar autoDismountFlying.")
    end
end

local function BuildCinematicsControls(category)
    do
        local function GetValue() return not not (NX.DB.cinematics and NX.DB.cinematics.autoSkip) end
        local function SetValue(v)
            NX.DB.cinematics = NX.DB.cinematics or {}
            NX.DB.cinematics.autoSkip = not not v
            if v then NX.DB.cinematics.quickSkip = false end
            if NX.Cinematics and NX.Cinematics.OnSettingsChanged then NX.Cinematics:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_CIN_AUTO", Settings.VarType.Boolean, "Auto-skip", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Skips cinematics automatically when possible.")
    end

    do
        local function GetValue() return not not (NX.DB.cinematics and NX.DB.cinematics.quickSkip) end
        local function SetValue(v)
            NX.DB.cinematics = NX.DB.cinematics or {}
            NX.DB.cinematics.quickSkip = not not v
            if v then NX.DB.cinematics.autoSkip = false end
            if NX.Cinematics and NX.Cinematics.OnSettingsChanged then NX.Cinematics:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_CIN_QUICK", Settings.VarType.Boolean, "Quick skip", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Confirms the skip prompt when you press Esc, Space, or Enter.")
    end
end

local function BuildQuestTrackerStateControls(category)
    local function GetValue() return not not (NX.DB.questTrackerState and NX.DB.questTrackerState.enabled) end
    local function SetValue(v)
        NX.DB.questTrackerState = NX.DB.questTrackerState or {}
        NX.DB.questTrackerState.enabled = not not v
        if NX.QuestTrackerState and NX.QuestTrackerState.OnSettingsChanged then NX.QuestTrackerState:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_QT_STATE", Settings.VarType.Boolean, "Remember quest tracker state", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Restores the Objective Tracker's collapsed/expanded state after login or /reload.")
end

local function BuildAuctionHouseFilterControls(category)
    local function GetValue() return not not (NX.DB.auctionHouse and NX.DB.auctionHouse.currentExpansionOnly) end
    local function SetValue(v)
        NX.DB.auctionHouse = NX.DB.auctionHouse or {}
        NX.DB.auctionHouse.currentExpansionOnly = not not v
        if NX.AuctionHouse and NX.AuctionHouse.OnSettingsChanged then NX.AuctionHouse:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_AH_CUR_EXP", Settings.VarType.Boolean, "Current Expansion Only Filter", true, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Automatically enables 'Current Expansion Only' when the Auction House opens.")
end

local function BuildWaypointTrackingControls(category)
    do
        local function GetValue()
            return not not (NX.DB.waypointTracking and NX.DB.waypointTracking.autoTrackMapPins)
        end

        local function SetValue(v)
            NX.DB.waypointTracking = NX.DB.waypointTracking or {}
            NX.DB.waypointTracking.autoTrackMapPins = not not v
            if NX.WaypointTracking and NX.WaypointTracking.OnSettingsChanged then
                NX.WaypointTracking:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_AUTO_TRACK_MAP_PINS",
            Settings.VarType.Boolean,
            "Automatically Track Map Pins",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Automatically super-tracks your latest user waypoint when a map pin is placed or updated."
        )
    end

    do
        local function GetValue()
            return not not (NX.DB.waypointTracking and NX.DB.waypointTracking.unlimitedMapPinDistance)
        end

        local function SetValue(v)
            NX.DB.waypointTracking = NX.DB.waypointTracking or {}
            NX.DB.waypointTracking.unlimitedMapPinDistance = not not v
            if NX.WaypointTracking and NX.WaypointTracking.OnSettingsChanged then
                NX.WaypointTracking:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_UNLIMITED_MAP_PIN_DISTANCE",
            Settings.VarType.Boolean,
            "Unlimited Map Pin Distance",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Keeps super-tracked map pins visible at any distance when in-game navigation is enabled."
        )
    end
end

S._registered = S._registered or false
S._previewCloseHooked = S._previewCloseHooked or false

function S:Register()
    if self._registered then return end
    if not Settings
        or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterVerticalLayoutSubcategory
        or not Settings.RegisterAddOnCategory
    then
        return
    end
    if not NX.DB then return end

    local landing = CreateLandingPanel()
    local parentCategory = Settings.RegisterCanvasLayoutCategory(landing, "Nexus")
    self.parentCategoryID = parentCategory:GetID()

    local automationCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Automation")
    self.automationCategoryID = automationCategory:GetID()

    AddSectionHeader(automationCategory, "Achievement Screenshots")
    BuildAchievementScreenshotControls(automationCategory)
    AddSectionHeader(automationCategory, "Cinematics")
    BuildCinematicsControls(automationCategory)
    AddSectionHeader(automationCategory, "Dialogs")
    BuildAutoConfirmDialogsControls(automationCategory)
    AddSectionHeader(automationCategory, "Tutorials")
    BuildTutorialsControls(automationCategory)

    local combatCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Combat")
    self.combatCategoryID = combatCategory:GetID()

    AddSectionHeader(combatCategory, "Action Behaviour")
    BuildAutoPlaceSpellsControls(combatCategory)
    BuildAutoDismountControls(combatCategory)
    AddSectionHeader(combatCategory, "Combat Logging")
    BuildAutoCombatLogControls(combatCategory)
    AddSectionHeader(combatCategory, "Crosshair")
    BuildCrosshairControls(combatCategory)

    local pveCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Dungeons & Raids")
    self.pveCategoryID = pveCategory:GetID()

    AddSectionHeader(pveCategory, "Great Vault Loot Spec")
    BuildGreatVaultControls(pveCategory)
    AddSectionHeader(pveCategory, "Mythic+")
    BuildMythicPlusControls(pveCategory)

    local interfaceCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Interface")
    self.interfaceCategoryID = interfaceCategory:GetID()

    AddSectionHeader(interfaceCategory, "Clean Objective Tracker")
    BuildCleanObjectiveTrackerControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Floating Combat Text")
    BuildFloatingCombatTextControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Low Durability")
    BuildLowDurabilityControls(interfaceCategory)
    BuildEnhancedErrorTextControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Visual Clarity")
    BuildMotionSicknessControls(interfaceCategory)
    BuildSkyridingEffectsControls(interfaceCategory)
    BuildAlwaysSharpenControls(interfaceCategory)
    BuildExtraActionArtworkControls(interfaceCategory)
    BuildAssistedRotationOverlayControls(interfaceCategory)
    BuildHideTalkingHeadControls(interfaceCategory)
    BuildScreenshotStatusControls(interfaceCategory)
    BuildQuestTrackerStateControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Waypoint Tracking")
    BuildWaypointTrackingControls(interfaceCategory)

    local systemCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "System")
    self.systemCategoryID = systemCategory:GetID()

    AddSectionHeader(systemCategory, "Auction House")
    BuildAuctionHouseFilterControls(systemCategory)
    AddSectionHeader(systemCategory, "General")
    BuildCommonControls(systemCategory)
    BuildLuaErrorsControls(systemCategory)
    AddSectionHeader(systemCategory, "Slash Commands")
    BuildSlashCommandControls(systemCategory)

    Settings.RegisterAddOnCategory(parentCategory)
    self._registered = true
end

function S:Open()
    self:Register()

    if not self._previewCloseHooked and SettingsPanel then
        self._previewCloseHooked = true
        SettingsPanel:HookScript("OnHide", function()
            if NX.Vault and NX.Vault.OnSettingsClosed then
                NX.Vault:OnSettingsClosed()
            end
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsClosed then
                NX.Common.LowDurability:OnSettingsClosed()
            end
        end)
    end

    if Settings and Settings.OpenToCategory and type(self.parentCategoryID) == "number" then
        Settings.OpenToCategory(self.parentCategoryID)
        Settings.OpenToCategory(self.parentCategoryID)
        C_Timer.After(0, function()
            if NX.Core and NX.Core.UpdateSettingsPanelMovable then
                NX.Core:UpdateSettingsPanelMovable()
            end
        end)
        return
    end

    if SettingsPanel then
        SettingsPanel:Show()
        C_Timer.After(0, function()
            if NX.Core and NX.Core.UpdateSettingsPanelMovable then
                NX.Core:UpdateSettingsPanelMovable()
            end
        end)
    end
end
