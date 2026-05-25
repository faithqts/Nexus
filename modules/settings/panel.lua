local NX = Nexus
NX.Settings = NX.Settings or {}
local S = NX.Settings
local FN = NX.Functions

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
    if Settings and Settings.CreateCheckbox then
        local ok = pcall(Settings.CreateCheckbox, category, setting, tooltip)
        if ok then
            return
        end
    end

    local init = Settings.CreateDropdown(category, setting, GetEnabledDisabledOptionsData, tooltip)
    init.reinitializeOnValueChanged = true
    return init
end

local function CreateBooleanCheckboxControl(category, setting, tooltip)
    if Settings and Settings.CreateCheckbox then
        local ok = pcall(Settings.CreateCheckbox, category, setting, tooltip)
        if ok then
            return
        end
    end

    CreateEnabledDisabledDropdown(category, setting, tooltip)
end

local function NormalizeSharedHexColor(v, fallback)
    local defaultHex = tostring(fallback or "#FFFFFF")
    local hex = string.upper(tostring(v or defaultHex)):gsub("%s+", "")
    if not hex:match("^#") then
        hex = "#" .. hex
    end
    if #hex ~= 7 and #hex ~= 9 then
        hex = defaultHex
    end
    return hex
end

local function GetSharedFontColorSourceList()
    local list = (NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.GetColorList)
        and NX.Common.LowDurability:GetColorList()
        or nil

    if type(list) == "table" and #list > 0 then
        return list
    end

    return {
        { hex = "#FFFFFF", name = "White" },
        { hex = "#FFFF00", name = "Yellow" },
        { hex = "#FFD133", name = "Gold" },
    }
end

local function GetSharedColorPreviewLabel(hex, name)
    local raw = NormalizeSharedHexColor(hex):gsub("#", "")
    local argb = (#raw == 6) and ("FF" .. raw) or raw
    return string.format("|c%s%s|r", argb, tostring(name or hex or "Color"))
end

local function GetSharedFontColorOptionsData()
    local c = Settings.CreateControlTextContainer()
    for _, entry in ipairs(GetSharedFontColorSourceList()) do
        c:Add(entry.hex, GetSharedColorPreviewLabel(entry.hex, entry.name))
    end
    return c:GetData()
end

local function CreateSharedFontColorDropdown(category, setting, tooltip)
    local init = Settings.CreateDropdown(category, setting, GetSharedFontColorOptionsData, tooltip)
    init.reinitializeOnValueChanged = true
    return init
end

local function CreateToggleActionButton(category, label, onClick, tooltip)
    local function runClick()
        if onClick then
            onClick()
        end
    end

    if Settings and Settings.CreateElementInitializer and Settings.RegisterInitializer then
        local data = {
            name = label or "",
            buttonText = "Toggle",
            buttonClick = runClick,
            tooltip = tooltip,
        }

        local ok, init = pcall(Settings.CreateElementInitializer, "SettingButtonControlTemplate", data)
        if ok and init then
            pcall(function()
                if label and label ~= "" and init.AddSearchTags then
                    init:AddSearchTags(label)
                end
                if init.AddSearchTags then
                    init:AddSearchTags("Toggle")
                end
            end)

            local okRegister = pcall(Settings.RegisterInitializer, category, init)
            if okRegister then
                return init
            end
        end
    end

    if Settings and Settings.CreateButton then
        local ok, control = pcall(Settings.CreateButton, category, label or "", "Toggle", runClick, tooltip, true)
        if ok and control then
            return control
        end
    end

    if Settings and Settings.CreateControl then
        local ok, control = pcall(Settings.CreateControl, category, "UIPanelButtonTemplate", function(button)
            if button.SetText then
                button:SetText("Toggle")
            end
            if button.SetWidth then
                button:SetWidth(200)
            end
            if button.SetHeight then
                button:SetHeight(22)
            end
            if button.SetScript then
                button:SetScript("OnClick", runClick)
            end
        end)
        if ok and control then
            return control
        end
    end

    if Settings and Settings.CreateText then
        Settings.CreateText(category, "Toggle button unavailable on this client build.")
    end

    return nil
end

local function CreateStringSettingControl(category, setting, tooltip)
    if Settings and Settings.CreateEditBox then
        Settings.CreateEditBox(category, setting, tooltip)
        return
    end

    if Settings and Settings.CreateText then
        Settings.CreateText(category, "Text input is not available on this client build.")
    end
end

local function GetAddonFontOptionsData()
    if NX.Functions and NX.Functions.GetAddonFontOptionsData then
        local data = NX.Functions:GetAddonFontOptionsData()
        if data then
            return data
        end
    end

    local c = Settings.CreateControlTextContainer()
    c:Add("Fonts\\FRIZQT__.TTF", "FrizQT")
    return c:GetData()
end

local function GetVoicePackOptionsData()
    return FN:GetVoicePackOptionsData()
end

local function NormalizeVoicePackActor(value)
    return FN:NormalizeVoicePackActor(value)
end

local function GetSharedVoicePackActor()
    return FN:GetSharedVoicePackActor()
end

local function SetSharedVoicePackActor(actor)
    FN:SetSharedVoicePackActor(actor)
end

local function CreateLandingPanel()
    local panel = CreateFrame("Frame")

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT")
    content:SetSize(620, 1)
    scroll:SetScrollChild(content)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Nexus Settings")

    local body = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    body:SetWidth(620)
    body:SetJustifyH("LEFT")
    body:SetText(
        "This addon was created to preserve and replace functionality lost with Midnight. " ..
        "It restores key workflows previously handled by WeakAuras and other unsupported addons, " ..
        "while staying compatible with the current addon-restricted environment."
    )
    body:SetTextColor(1, 1, 1, 1)

    local function CreateHeaderLine(anchor, text)
        local line = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
        line:SetWidth(620)
        line:SetJustifyH("LEFT")
        local _, fontSize, fontFlags = line:GetFont()
        if fontSize then
            if NX.Functions and NX.Functions.ApplyAddonFont then
                NX.Functions:ApplyAddonFont(line, fontSize + 2, fontFlags)
            end
        end
        line:SetTextColor(1.0, 0.82, 0.0, 1)
        line:SetText(text)
        return line
    end

    local function CreateBodyLine(anchor, text)
        local line = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        line:SetWidth(620)
        line:SetJustifyH("LEFT")
        line:SetTextColor(1, 1, 1, 1)
        line:SetText(text)
        return line
    end

    local automationHeader = CreateHeaderLine(body, "Automation:")
    local automationBody = CreateBodyLine(automationHeader, "Achievement Screenshots, Cinematics, Dialog confirmations, Tutorials, and Auction House defaults.")

    local clickableBuffsHeader = CreateHeaderLine(automationBody, "Clickable Buffs:")
    local clickableBuffsBody = CreateBodyLine(clickableBuffsHeader, "Out-of-combat buff buttons, flashing, icon/text sizing, zoom, and anchor controls.")

    local combatHeader = CreateHeaderLine(clickableBuffsBody, "Combat:")
    local combatBody = CreateBodyLine(combatHeader, "Crosshair and mouse cursor controls.")

    local dungeonsHeader = CreateHeaderLine(combatBody, "Great Vault:")
    local dungeonsBody = CreateBodyLine(dungeonsHeader, "Great Vault loot spec warning settings and anchor controls.")

    local gameplayHeader = CreateHeaderLine(dungeonsBody, "Gameplay:")
    local gameplayBody = CreateBodyLine(gameplayHeader, "Auto place spells and auto dismount behavior, including flying dismount controls.")

    local interfaceHeader = CreateHeaderLine(gameplayBody, "Interface:")
    local interfaceBody = CreateBodyLine(interfaceHeader, "Objective tracker cleanup, durability/errors text, and visual effect toggles.")

    local minimapHeader = CreateHeaderLine(interfaceBody, "Minimap:")
    local minimapBody = CreateBodyLine(minimapHeader, "Automatic minimap zoom behavior and waypoint tracking options.")

    local portalsHeader = CreateHeaderLine(minimapBody, "Portals:")
    local portalsBody = CreateBodyLine(portalsHeader, "Portal bar visibility, legacy portal filtering, layout sizing, spacing, and anchor positioning.")

    local professionsHeader = CreateHeaderLine(portalsBody, "Professions:")
    local professionsBody = CreateBodyLine(professionsHeader, "Crafting Order Filter Defaults, Simple First Craft Bonus, Auto Withdraw Treatise, Artisan Moxie Bags, and Moxie on Profession Frame controls.")

    local settingsAnchorsHeader = CreateHeaderLine(professionsBody, "Settings & Anchors:")
    local settingsAnchorsBody = CreateBodyLine(settingsAnchorsHeader, "Shared addon settings, LUA errors, slash command toggles, and unified anchor toggles.")

    local statsPlusHeader = CreateHeaderLine(settingsAnchorsBody, "Stats+:")
    local statsPlusBody = CreateBodyLine(statsPlusHeader, "Combat stat display style, content toggles, font settings, and anchor controls.")

    local warbankHeader = CreateHeaderLine(statsPlusBody, "Warbank:")
    local warbankBody = CreateBodyLine(warbankHeader, "Bank Warbound Gear alerts with text style, color, flashing, and anchor controls.")

    local function UpdateScrollContentHeight()
        local top = title:GetTop()
        local bottom = warbankBody:GetBottom()
        if not top or not bottom then
            return
        end

        local height = math.max(1, math.floor((top - bottom) + 36 + 0.5))
        content:SetHeight(height)
    end

    panel:SetScript("OnShow", UpdateScrollContentHeight)
    C_Timer.After(0, UpdateScrollContentHeight)

    return panel
end

local function BuildLowDurabilityControls(category)
    do
        local function GetValue()
            return (NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.enabled) and true or false
        end

        local function SetValue(v)
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            NX.DB.interface.lowDurability.enabled = v and true or false

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
        local function GetValue()
            return tonumber(NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.fontSize) or 48
        end

        local function SetValue(v)
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            v = tonumber(v) or 48
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 128 then v = 128 end

            NX.DB.interface.lowDurability.fontSize = v
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
            return tonumber(NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.threshold) or 20
        end

        local function SetValue(v)
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            v = tonumber(v) or 20
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end

            NX.DB.interface.lowDurability.threshold = v
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
            return (NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.flashing) and true or false
        end

        local function SetValue(v)
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            NX.DB.interface.lowDurability.flashing = v and true or false
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
        local function GetValue()
            local v = NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.color
            if type(v) ~= "string" or v == "" then
                return "#FFFF00"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            if type(v) ~= "string" or v == "" then
                v = "#FFFF00"
            end
            NX.DB.interface.lowDurability.color = v
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

        CreateSharedFontColorDropdown(category, setting, "Selects the color used for the Low Durability warning text.")
    end

    do
        local function GetValue()
            return not not (NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.positionUnlocked)
        end

        local function SetValue(v)
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.SetPositionUnlocked then
                NX.Common.LowDurability:SetPositionUnlocked(v, true)
            else
                NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
                NX.DB.interface.lowDurability.positionUnlocked = not not v
                if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                    NX.Common.LowDurability:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end

end

local function BuildCommonControls(category)
    if Settings.CreateSectionHeader then
        Settings.CreateSectionHeader(category, "Common")
    end

    do
        local function GetValue()
            if NX.Functions and NX.Functions.GetAddonFontPath then
                return NX.Functions:GetAddonFontPath()
            end
            local p = NX.DB and NX.DB.media.fonts.addonFontPath
            if type(p) ~= "string" or p == "" then
                return "Fonts\\FRIZQT__.TTF"
            end
            return p
        end

        local function SetValue(v)
            if NX.Functions and NX.Functions.SetAddonFontPath then
                NX.Functions:SetAddonFontPath(v)
            else
                NX.DB.media.fonts.addonFontPath = (type(v) == "string" and v ~= "") and v or "Fonts\\FRIZQT__.TTF"
            end

            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
            if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.OnSettingsChanged then
                NX.Common.LowDurability:OnSettingsChanged()
            end
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                NX.ClickableBuffs:OnSettingsChanged()
            end
            if NX.Portals and NX.Portals.OnSettingsChanged then
                NX.Portals:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ADDON_FONT_FAMILY",
            Settings.VarType.String,
            "Addon Font Family",
            "Fonts\\FRIZQT__.TTF",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            GetAddonFontOptionsData,
            "Selects the shared font family used by Nexus labels and module text. Falls back to FrizQT when unavailable."
        )
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return (NX.DB and NX.DB.settings.panel.moveSettingsPanel) and true or false
        end

        local function SetValue(v)
            NX.DB.settings.panel.moveSettingsPanel = v and true or false
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
            return NX.DB.common.options.allowEscCloseCdmEditMode ~= false
        end

        local function SetValue(v)
            NX.DB.common.options.allowEscCloseCdmEditMode = v and true or false
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
                return (NX.DB and NX.DB.common.options.quickReloadSlash) and true or false
            end

            local function SetValue(v)
                NX.DB.common.options.quickReloadSlash = v and true or false
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
                NX.DB.common.options.quickReloadSlash = false
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
                c:Add("unavailable", string.format("|cffe73f3fUnavailable (Registered by %s)|r", owner))
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
            return NX.DB.common.options.quickCdmSlash ~= false
        end

        local function SetValue(v)
            NX.DB.common.options.quickCdmSlash = v and true or false
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
            "Enables /cd and /cdm. Command execution is blocked while in combat."
        )
    end

    do
        local function IsAvailable()
            if NX.Common and NX.Common.IsWeakAurasCdmSlashAvailable then
                return NX.Common:IsWeakAurasCdmSlashAvailable()
            end
            return true
        end

        if IsAvailable() then
            local function GetValue()
                if not NX.DB then return true end
                return NX.DB.common.options.quickWeakAurasCdmSlash ~= false
            end

            local function SetValue(v)
                NX.DB.common.options.quickWeakAurasCdmSlash = v and true or false
                if NX.Common and NX.Common.SyncWeakAurasCdmSlash then
                    NX.Common:SyncWeakAurasCdmSlash()
                end
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_QUICK_WA_CDM_SLASH",
                Settings.VarType.Boolean,
                "WeakAuras CDM (/wa)",
                true,
                GetValue,
                SetValue
            )

            local tooltip = "Registers /wa to open Cooldown Manager (CDM)."
            if NX.Common and NX.Common.GetWeakAurasCdmUnavailableTooltip then
                tooltip = NX.Common:GetWeakAurasCdmUnavailableTooltip()
            end

            CreateEnabledDisabledDropdown(category, setting, tooltip)
        else
            if NX.DB then
                NX.DB.common.options.quickWeakAurasCdmSlash = false
            end

            local function GetValue()
                return "unavailable"
            end

            local function SetValue(_)
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_QUICK_WA_CDM_SLASH_UNAVAILABLE",
                Settings.VarType.String,
                "WeakAuras CDM (/wa)",
                "unavailable",
                GetValue,
                SetValue
            )

            local function GetUnavailableOptionsData()
                local owner = (NX.Common and NX.Common.GetWeakAurasCdmSlashOwnerDisplay and NX.Common:GetWeakAurasCdmSlashOwnerDisplay())
                    or "another addon"
                local c = Settings.CreateControlTextContainer()
                c:Add("unavailable", string.format("|cffe73f3fUnavailable (Registered by %s)|r", owner))
                return c:GetData()
            end

            local tooltip = "WeakAuras CDM cannot be enabled because /wa is already registered by another addon."
            if NX.Common and NX.Common.GetWeakAurasCdmUnavailableTooltip then
                tooltip = NX.Common:GetWeakAurasCdmUnavailableTooltip()
            end

            Settings.CreateDropdown(category, setting, GetUnavailableOptionsData, tooltip)
        end
    end

    do
        local function GetValue()
            if not NX.DB then return true end
            return NX.DB.common.options.quickEditModeSlash ~= false
        end

        local function SetValue(v)
            NX.DB.common.options.quickEditModeSlash = v and true or false
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
    local function EnsureDB()
        NX.DB.dungeonsRaids.greatVault = NX.DB.dungeonsRaids.greatVault or {}
        return NX.DB.dungeonsRaids.greatVault
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled and true or false
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            if not db.enabled and NX.Vault and NX.Vault.StopPreview then
                NX.Vault:StopPreview()
            end
            if NX.Vault and NX.Vault.OnSettingsChanged then
                NX.Vault:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_VAULT_ENABLED",
            Settings.VarType.Boolean,
            "Enable",
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
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.fontSize) or 48
        end

        local function SetValue(v)
            v = tonumber(v) or 48
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 128 then v = 128 end

            local db = EnsureDB()
            db.fontSize = v
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
        local function GetValue()
            local db = EnsureDB()
            return db.flashing and true or false
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.flashing = v and true or false
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
        local function GetValue()
            local db = EnsureDB()
            return db.positionUnlocked == true
        end

        local function SetValue(v)
            if NX.Vault and NX.Vault.SetPositionUnlocked then
                NX.Vault:SetPositionUnlocked(v, true)
            else
                local db = EnsureDB()
                db.positionUnlocked = v and true or false
                if NX.Vault and NX.Vault.OnSettingsChanged then
                    NX.Vault:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end
end

local function BuildCrosshairControls(category)
    do
        local function GetValue()
            return (NX.DB.combat.crosshair and NX.DB.combat.crosshair.show) and true or false
        end

        local function SetValue(v)
            NX.DB.combat.crosshair.show = v and true or false
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
            return tonumber(NX.DB.combat.crosshair and NX.DB.combat.crosshair.size) or 18
        end

        local function SetValue(v)
            v = tonumber(v) or 18
            v = math.floor(v + 0.5)
            if v < 4 then v = 4 end
            if v > 256 then v = 256 end
            NX.DB.combat.crosshair.size = v
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
            return tonumber(NX.DB.combat.crosshair and NX.DB.combat.crosshair.thickness) or 2
        end

        local function SetValue(v)
            v = tonumber(v) or 2
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 32 then v = 32 end
            NX.DB.combat.crosshair.thickness = v
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
            return (NX.DB.combat.crosshair and NX.DB.combat.crosshair.color) or "#FFFFFF"
        end

        local function SetValue(v)
            if type(v) ~= "string" or v == "" then
                v = "#FFFFFF"
            end
            NX.DB.combat.crosshair.color = v
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

        CreateSharedFontColorDropdown(category, setting, "Color of the crosshair. Can be set to any hex color code, such as #RRGGBB or #RRGGBBAA.")
    end

    do
        local function GetValue()
            local a = tonumber(NX.DB.combat.crosshair and NX.DB.combat.crosshair.alpha)
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
            NX.DB.combat.crosshair.alpha = v
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

local function BuildMouseCursorControls(category)
    local function EnsureDB()
        NX.DB.combat = NX.DB.combat or {}
        NX.DB.combat.mouseCursor = NX.DB.combat.mouseCursor or {}
        local db = NX.DB.combat.mouseCursor
        if db.enabled == nil then db.enabled = false end
        if db.size == nil then db.size = 32 end
        if db.alpha == nil then db.alpha = 1.0 end
        if db.color == nil then db.color = "#FFFFFF" end
        if db.hz == nil then db.hz = 120 end
        if db.texture == nil then db.texture = "circle.tga" end
        if db.animationsEnabled == nil then db.animationsEnabled = false end
        if db.pulsing == nil then db.pulsing = false end
        if db.flashing == nil then db.flashing = false end
        if db.rotating == nil then db.rotating = false end
        if db.pulseSpeedHz == nil then db.pulseSpeedHz = 2.2 end
        if db.flashSpeedHz == nil then db.flashSpeedHz = 4.0 end
        if db.rotateRps == nil then db.rotateRps = 0.5 end
        return db
    end

    local function NotifyChanged()
        if NX.MouseCursor and NX.MouseCursor.OnSettingsChanged then
            NX.MouseCursor:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Enable or disable the custom mouse cursor.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.size) or 32
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = tonumber(v) or 32
            n = math.floor(n / 2 + 0.5) * 2
            if n < 0 then n = 0 end
            if n > 100 then n = 100 end
            db.size = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_SIZE",
            Settings.VarType.Number,
            "Size",
            32,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 100, 2)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Mouse cursor size in pixels.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            local a = tonumber(db.alpha)
            if not a then return 1.0 end
            return FN:ClampNumber(a, 0, 1)
        end

        local function SetValue(v)
            local db = EnsureDB()
            local a = tonumber(v) or 1.0
            db.alpha = FN:ClampNumber(a, 0, 1)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_ALPHA",
            Settings.VarType.Number,
            "Alpha",
            1.0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 1, 0.1)
        ApplyRightLabel(options, function(v) return string.format("%.1f", v) end)
        Settings.CreateSlider(category, setting, options, "Mouse cursor alpha from 0.0 to 1.0.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tostring(db.color or "#FFFFFF")
        end

        local function SetValue(v)
            local db = EnsureDB()
            if type(v) ~= "string" or v == "" then
                v = "#FFFFFF"
            end
            db.color = v
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_COLOR",
            Settings.VarType.String,
            "Color",
            "#FFFFFF",
            GetValue,
            SetValue
        )

        CreateSharedFontColorDropdown(category, setting, "Selects the mouse cursor color. Supports #RRGGBB or #RRGGBBAA.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.hz) or 120
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = tonumber(v) or 120
            n = math.floor(n / 5 + 0.5) * 5
            if n < 30 then n = 30 end
            if n > 600 then n = 600 end
            db.hz = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_HZ",
            Settings.VarType.Number,
            "Update Rate (Hz)",
            120,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(30, 600, 5)
        ApplyRightLabel(options, function(v) return string.format("%d Hz", v) end)
        Settings.CreateSlider(category, setting, options, "Caps cursor updates per second.")
    end

    do
        local function GetTextureOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("circle.tga", "circle.tga (Default)")
            c:Add("spiked.tga", "spiked.tga")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            return tostring(db.texture or "circle.tga")
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.lower(tostring(v or "circle.tga"))
            if value ~= "circle.tga" and value ~= "spiked.tga" then
                value = "circle.tga"
            end
            db.texture = value
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_TEXTURE",
            Settings.VarType.String,
            "Texture",
            "circle.tga",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetTextureOptionsData, "Choose the mouse cursor texture.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.animationsEnabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.animationsEnabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_ANIMATIONS_ENABLED",
            Settings.VarType.Boolean,
            "Animation Effects",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Enables cursor animation effects.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.pulsing == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.pulsing = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_PULSING",
            Settings.VarType.Boolean,
            "Pulsing",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Slightly scales the cursor up and down repeatedly.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.pulseSpeedHz) or 2.2
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.pulseSpeedHz = FN:ClampNumber(tonumber(v) or 2.2, 0.2, 8.0)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_PULSE_SPEED_HZ",
            Settings.VarType.Number,
            "Pulse Speed",
            2.2,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0.2, 8.0, 0.1)
        ApplyRightLabel(options, function(v) return string.format("%.1f Hz", v) end)
        Settings.CreateSlider(category, setting, options, "Pulse animation frequency.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.flashing == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.flashing = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_FLASHING",
            Settings.VarType.Boolean,
            "Flashing",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Animates cursor alpha repeatedly.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.flashSpeedHz) or 4.0
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.flashSpeedHz = FN:ClampNumber(tonumber(v) or 4.0, 0.2, 12.0)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_FLASH_SPEED_HZ",
            Settings.VarType.Number,
            "Flash Speed",
            4.0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0.2, 12.0, 0.1)
        ApplyRightLabel(options, function(v) return string.format("%.1f Hz", v) end)
        Settings.CreateSlider(category, setting, options, "Flash animation frequency.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.rotating == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.rotating = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_ROTATING",
            Settings.VarType.Boolean,
            "Rotating",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Rotates the cursor continuously through 360 degrees.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.rotateRps) or 0.5
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.rotateRps = FN:ClampNumber(tonumber(v) or 0.5, 0.1, 5.0)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MOUSE_CURSOR_ROTATE_RPS",
            Settings.VarType.Number,
            "Rotate Speed",
            0.5,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0.1, 5.0, 0.1)
        ApplyRightLabel(options, function(v) return string.format("%.1f rps", v) end)
        Settings.CreateSlider(category, setting, options, "Rotation speed in rotations per second.")
    end
end

local function BuildPortalsControls(category)
    local function Notify()
        if NX.Portals and NX.Portals.OnSettingsChanged then
            NX.Portals:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            if NX.DB.portals == nil then return true end
            return NX.DB.portals.enabled ~= false
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            NX.DB.portals.enabled = not not v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ENABLED", Settings.VarType.Boolean, "Portals", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Enable or disable the Portals bar.")
    end

    do
        local function GetValue()
            if NX.DB.portals == nil then return true end
            return NX.DB.portals.showLegacyPortals ~= false
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            NX.DB.portals.showLegacyPortals = not not v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PORTALS_SHOW_LEGACY",
            Settings.VarType.Boolean,
            "Show Old Portals",
            true,
            GetValue,
            SetValue
        )
        CreateEnabledDisabledDropdown(category, setting, "Show or hide old raid and dungeon portals. When disabled, only pinned top-row portals are shown.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.anchorX) or 0
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or 0) + 0.5)
            if v < -500 then v = -500 end
            if v > 500 then v = 500 end
            NX.DB.portals.anchorX = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ANCHOR_X", Settings.VarType.Number, "Anchor X", 0, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(-500, 500, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Horizontal anchor offset for the portals bar.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.anchorY) or -35
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or -35) + 0.5)
            if v < -500 then v = -500 end
            if v > 500 then v = 500 end
            NX.DB.portals.anchorY = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ANCHOR_Y", Settings.VarType.Number, "Anchor Y", -35, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(-500, 500, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Vertical anchor offset for the portals bar.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.topRowMax) or 8
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or 8) + 0.5)
            if v < 6 then v = 6 end
            if v > 8 then v = 8 end
            NX.DB.portals.topRowMax = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_TOP_ROW_MAX", Settings.VarType.Number, "Top Row Portals", 8, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(6, 8, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Maximum pinned portals in the top row.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.topRowHeightPct) or 80
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or 80) + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end
            NX.DB.portals.topRowHeightPct = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_TOP_ROW_HEIGHT", Settings.VarType.Number, "Top Row Height %", 80, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(1, 100, 1)
        ApplyRightLabel(options, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, setting, options, "Top row button height as a percentage of button width.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.perRow) or 12
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or 12) + 0.5)
            if v < 8 then v = 8 end
            if v > 12 then v = 12 end
            NX.DB.portals.perRow = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_PER_ROW", Settings.VarType.Number, "Portals Per Row", 12, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(8, 12, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Portals per row for non-pinned portal buttons.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.smallRowHeightPct) or 80
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = math.floor((tonumber(v) or 80) + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end
            NX.DB.portals.smallRowHeightPct = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_SMALL_ROW_HEIGHT", Settings.VarType.Number, "Small Row Height %", 80, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(1, 100, 1)
        ApplyRightLabel(options, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, setting, options, "Small row button height as a percentage of button width.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals and NX.DB.portals.spacing) or 2
        end

        local function SetValue(v)
            NX.DB.portals = NX.DB.portals or {}
            v = tonumber(v) or 2
            v = math.floor((v * 5) + 0.5) / 5
            if v < 0 then v = 0 end
            if v > 5 then v = 5 end
            NX.DB.portals.spacing = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_SPACING", Settings.VarType.Number, "Spacing", 2, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(0, 5, 0.2)
        ApplyRightLabel(options, function(v) return string.format("%.1f", v) end)
        Settings.CreateSlider(category, setting, options, "Spacing between portal buttons.")
    end
end

local function BuildMotionSicknessControls(category)
    do
        local function GetValue()
            return not not (NX.DB.interface.motionSickness and NX.DB.interface.motionSickness.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.motionSickness = NX.DB.interface.motionSickness or {}
            NX.DB.interface.motionSickness.enabled = not not v
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
            return not not (NX.DB.interface.skyridingEffects and NX.DB.interface.skyridingEffects.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.skyridingEffects = NX.DB.interface.skyridingEffects or {}
            NX.DB.interface.skyridingEffects.enabled = not not v
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
            return not not (NX.DB.automation.achievementScreenshot and NX.DB.automation.achievementScreenshot.enabled)
        end

        local function SetValue(v)
            NX.DB.automation.achievementScreenshot = NX.DB.automation.achievementScreenshot or {}
            NX.DB.automation.achievementScreenshot.enabled = not not v
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
            return tonumber(NX.DB.automation.achievementScreenshot and NX.DB.automation.achievementScreenshot.delaySeconds) or 1.6
        end

        local function SetValue(v)
            NX.DB.automation.achievementScreenshot = NX.DB.automation.achievementScreenshot or {}
            NX.DB.automation.achievementScreenshot.delaySeconds = tonumber(v) or 1.6
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

local function BuildAlwaysSharpenControls(category)
    do
        local function GetValue()
            return not not (NX.DB.interface.alwaysSharpen and NX.DB.interface.alwaysSharpen.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.alwaysSharpen = NX.DB.interface.alwaysSharpen or {}
            NX.DB.interface.alwaysSharpen.enabled = not not v
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

local function BuildMoneyFrameFixControls(category)
    do
        local function GetValue()
            return not not (NX.DB.interface.moneyFrameFix and NX.DB.interface.moneyFrameFix.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.moneyFrameFix = NX.DB.interface.moneyFrameFix or {}
            local enabled = not not v

            if NX.MoneyFrameFix and NX.MoneyFrameFix.SetEnabled then
                NX.MoneyFrameFix:SetEnabled(enabled, true)
            else
                NX.DB.interface.moneyFrameFix.enabled = enabled
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MONEY_FRAME_FIX_ENABLED",
            Settings.VarType.Boolean,
            "Money Frame Fix",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Overrides SetTooltipMoney to work around the MoneyFrame tooltip bug. Requires a UI reload when enabling."
        )
    end
end

local function BuildEnhancedErrorTextControls(category)
    AddSectionHeader(category, "Objective & Error Text")

    do
        local function GetValue()
            return not not (NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            NX.DB.interface.enhancedErrorText.enabled = not not v
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
            return tonumber(NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.fontSize) or 22
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            NX.DB.interface.enhancedErrorText.fontSize = tonumber(v) or 22
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
            return tonumber(NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.width) or 800
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            v = tonumber(v) or 800
            v = math.floor(v + 0.5)
            if v < 200 then v = 200 end
            if v > 2000 then v = 2000 end
            NX.DB.interface.enhancedErrorText.width = v
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
            return tonumber(NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.height) or 120
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            v = tonumber(v) or 120
            v = math.floor(v + 0.5)
            if v < 40 then v = 40 end
            if v > 400 then v = 400 end
            NX.DB.interface.enhancedErrorText.height = v
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
            return tonumber(NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.offsetY) or 0
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            v = tonumber(v) or 0
            v = math.floor(v + 0.5)
            if v < -600 then v = -600 end
            if v > 600 then v = 600 end
            NX.DB.interface.enhancedErrorText.offsetY = v
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
            return not not (NX.DB.interface.enhancedErrorText and NX.DB.interface.enhancedErrorText.outline)
        end

        local function SetValue(v)
            NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
            NX.DB.interface.enhancedErrorText.outline = not not v
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
            return not not (NX.DB.interface.cleanObjectiveTracker and NX.DB.interface.cleanObjectiveTracker.enabled)
        end

        local function SetValue(v)
            NX.DB.interface.cleanObjectiveTracker = NX.DB.interface.cleanObjectiveTracker or {}
            NX.DB.interface.cleanObjectiveTracker.enabled = not not v
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
            return not not (NX.DB.interface.cleanObjectiveTracker and NX.DB.interface.cleanObjectiveTracker.hideBackground)
        end

        local function SetValue(v)
            NX.DB.interface.cleanObjectiveTracker = NX.DB.interface.cleanObjectiveTracker or {}
            NX.DB.interface.cleanObjectiveTracker.hideBackground = not not v
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
            return not not (NX.DB.interface.cleanObjectiveTracker and NX.DB.interface.cleanObjectiveTracker.hideTitle)
        end

        local function SetValue(v)
            NX.DB.interface.cleanObjectiveTracker = NX.DB.interface.cleanObjectiveTracker or {}
            NX.DB.interface.cleanObjectiveTracker.hideTitle = not not v
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
        return not not (NX.DB.system.autoPlaceSpells and NX.DB.system.autoPlaceSpells.enabled)
    end

    local function SetValue(v)
        NX.DB.system.autoPlaceSpells = NX.DB.system.autoPlaceSpells or {}
        NX.DB.system.autoPlaceSpells.enabled = not not v
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

local function BuildCatalystControls(category)
    local function GetValue()
        return not not (NX.DB.system.catalyst and NX.DB.system.catalyst.enabled)
    end

    local function SetValue(v)
        NX.DB.system.catalyst = NX.DB.system.catalyst or {}
        NX.DB.system.catalyst.enabled = not not v
        if NX.Catalyst and NX.Catalyst.OnSettingsChanged then
            NX.Catalyst:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_CATALYST_ENABLED",
        Settings.VarType.Boolean,
        "Instantly Catalyze Button",
        false,
        GetValue,
        SetValue
    )

    CreateBooleanCheckboxControl(
        category,
        setting,
        "Enable the button to instantly catalyze gear without a delay or confirmation"
    )
end

local function BuildExtraActionArtworkControls(category)
    local function GetValue() return not not (NX.DB.combat.extraActionArtwork and NX.DB.combat.extraActionArtwork.enabled) end
    local function SetValue(v)
        NX.DB.combat.extraActionArtwork = NX.DB.combat.extraActionArtwork or {}
        NX.DB.combat.extraActionArtwork.enabled = not not v
        if NX.ExtraActionArtwork and NX.ExtraActionArtwork.OnSettingsChanged then
            NX.ExtraActionArtwork:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_EXTRA_ACTION_ART", Settings.VarType.Boolean, "Hide Extra Action / Zone Ability artwork", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides ExtraActionButton and ZoneAbilityFrame artwork (not the button).")
end

local function BuildHideTalkingHeadControls(category)
    local function GetValue() return not not (NX.DB.system.hideTalkingHead and NX.DB.system.hideTalkingHead.enabled) end
    local function SetValue(v)
        NX.DB.system.hideTalkingHead = NX.DB.system.hideTalkingHead or {}
        NX.DB.system.hideTalkingHead.enabled = not not v
        if NX.HideTalkingHead and NX.HideTalkingHead.OnSettingsChanged then
            NX.HideTalkingHead:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_TALKING_HEAD", Settings.VarType.Boolean, "Automatically hide Talking Head Frame", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides the Talking Head frame whenever it tries to show.")
end

local function BuildHideMicroMenuPopupsControls(category)
    local function GetValue()
        return not not (NX.DB.system.tutorials and NX.DB.system.tutorials.hideMicroMenuPopups)
    end

    local function SetValue(v)
        NX.DB.system.tutorials = NX.DB.system.tutorials or {}
        NX.DB.system.tutorials.hideMicroMenuPopups = not not v
        if NX.Tutorials and NX.Tutorials.OnSettingsChanged then
            NX.Tutorials:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_HIDE_MICROMENU_POPUPS",
        Settings.VarType.Boolean,
        "Hide Micro-Menu Popups",
        false,
        GetValue,
        SetValue
    )

    CreateEnabledDisabledDropdown(
        category,
        setting,
        "When Enabled, sets hideHelptips to 0. When Disabled, restores hideHelptips to 1."
    )
end

local function BuildLuaErrorsControls(category)
    local function GetValue() return not not (NX.DB.system.luaErrors and NX.DB.system.luaErrors.enabled) end
    local function SetValue(v)
        NX.DB.system.luaErrors = NX.DB.system.luaErrors or {}
        NX.DB.system.luaErrors.enabled = not not v
        if NX.LuaErrors and NX.LuaErrors.OnSettingsChanged then NX.LuaErrors:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_LUA_ERRORS", Settings.VarType.Boolean, "Show LUA Errors", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Controls the CVar scriptErrors.")
end

local function BuildTutorialsControls(category)
    local function GetValue() return not not (NX.DB.system.tutorials and NX.DB.system.tutorials.disabled) end
    local function SetValue(v)
        NX.DB.system.tutorials = NX.DB.system.tutorials or {}
        NX.DB.system.tutorials.disabled = not not v
        if NX.Tutorials and NX.Tutorials.OnSettingsChanged then NX.Tutorials:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_DISABLE_TUTORIALS", Settings.VarType.Boolean, "Disable Tutorials", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "When Enabled, Nexus disables most tutorial popups (showTutorials = 0).")
end

local function BuildScreenshotStatusControls(category)
    local function GetValue() return not not (NX.DB.system.hideScreenshotStatus and NX.DB.system.hideScreenshotStatus.enabled) end
    local function SetValue(v)
        NX.DB.system.hideScreenshotStatus = NX.DB.system.hideScreenshotStatus or {}
        NX.DB.system.hideScreenshotStatus.enabled = not not v
        if NX.HideScreenshotStatus and NX.HideScreenshotStatus.OnSettingsChanged then NX.HideScreenshotStatus:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_HIDE_SCREENSHOT_STATUS", Settings.VarType.Boolean, "Hide Screenshot Status", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Disables screenshot status notifications (started/succeeded/failed).")
end

local function BuildDeleteDialogControls(category)
    local function GetValue() return not not (NX.DB.system.deleteDialog and NX.DB.system.deleteDialog.enabled) end
    local function SetValue(v)
        NX.DB.system.deleteDialog = NX.DB.system.deleteDialog or {}
        NX.DB.system.deleteDialog.enabled = not not v
        if NX.DeleteDialog and NX.DeleteDialog.OnSettingsChanged then NX.DeleteDialog:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_DELETE_DIALOG", Settings.VarType.Boolean, "Add \"DELETE\" to delete dialog", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Auto-fills the required DELETE text when destroying protected items.")
end

local function BuildAutoConfirmDialogsControls(category)
    do
        local function GetValue() return not not (NX.DB.system.autoConfirmDialogs and NX.DB.system.autoConfirmDialogs.enabled) end
        local function SetValue(v)
            NX.DB.system.autoConfirmDialogs = NX.DB.system.autoConfirmDialogs or {}
            NX.DB.system.autoConfirmDialogs.enabled = not not v
            if NX.AutoConfirmDialogs and NX.AutoConfirmDialogs.OnSettingsChanged then NX.AutoConfirmDialogs:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTOCONFIRM_ENABLED", Settings.VarType.Boolean, "Auto-Confirm Dialogs", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Automatically clicks the confirm button for selected dialogs.")
    end

    local function MakeToggle(key, label, tooltip)
        local function GetValue() return not not (NX.DB.system.autoConfirmDialogs and NX.DB.system.autoConfirmDialogs[key]) end
        local function SetValue(v)
            NX.DB.system.autoConfirmDialogs = NX.DB.system.autoConfirmDialogs or {}
            NX.DB.system.autoConfirmDialogs[key] = not not v
            if NX.AutoConfirmDialogs and NX.AutoConfirmDialogs.OnSettingsChanged then NX.AutoConfirmDialogs:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTOCONFIRM_" .. key:upper(), Settings.VarType.Boolean, label, false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, tooltip)
    end

    MakeToggle("replaceEnchant", "Replace Enchants", "Automatically confirms the enchant replacement dialog.")
    MakeToggle("acceptSockets", "Replace Sockets", "Automatically confirms the socket replacement dialog.")

    BuildDeleteDialogControls(category)
end

local function BuildAutoDismountControls(category)
    do
        local function GetValue() return (NX.DB.system.autoDismount and NX.DB.system.autoDismount.enabled ~= false) end
        local function SetValue(v)
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.enabled = not not v
            if NX.AutoDismount and NX.AutoDismount.OnSettingsChanged then NX.AutoDismount:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTODISMOUNT", Settings.VarType.Boolean, "Dismount when using Abilities", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Controls the CVar autoDismount.")
    end

    do
        local function GetValue() return (NX.DB.system.autoDismount and NX.DB.system.autoDismount.flying ~= false) end
        local function SetValue(v)
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.flying = not not v
            if NX.AutoDismount and NX.AutoDismount.OnSettingsChanged then NX.AutoDismount:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_AUTODISMOUNT_FLY", Settings.VarType.Boolean, "Dismount when using Abilities (Flying)", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Controls the CVar autoDismountFlying.")
    end
end

local function BuildCinematicsControls(category)
    do
        local function GetValue() return not not (NX.DB.automation.cinematics and NX.DB.automation.cinematics.autoSkip) end
        local function SetValue(v)
            NX.DB.automation.cinematics = NX.DB.automation.cinematics or {}
            NX.DB.automation.cinematics.autoSkip = not not v
            if v then NX.DB.automation.cinematics.quickSkip = false end
            if NX.Cinematics and NX.Cinematics.OnSettingsChanged then NX.Cinematics:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_CIN_AUTO", Settings.VarType.Boolean, "Auto-skip", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Skips cinematics automatically when possible.")
    end

    do
        local function GetValue() return not not (NX.DB.automation.cinematics and NX.DB.automation.cinematics.quickSkip) end
        local function SetValue(v)
            NX.DB.automation.cinematics = NX.DB.automation.cinematics or {}
            NX.DB.automation.cinematics.quickSkip = not not v
            if v then NX.DB.automation.cinematics.autoSkip = false end
            if NX.Cinematics and NX.Cinematics.OnSettingsChanged then NX.Cinematics:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_CIN_QUICK", Settings.VarType.Boolean, "Quick skip", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Confirms the skip prompt when you press Esc, Space, or Enter.")
    end
end

local function BuildQuestTrackerStateControls(category)
    local function GetValue() return not not (NX.DB.system.questTrackerState and NX.DB.system.questTrackerState.enabled) end
    local function SetValue(v)
        NX.DB.system.questTrackerState = NX.DB.system.questTrackerState or {}
        NX.DB.system.questTrackerState.enabled = not not v
        if NX.QuestTrackerState and NX.QuestTrackerState.OnSettingsChanged then NX.QuestTrackerState:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_QT_STATE", Settings.VarType.Boolean, "Remember quest tracker state", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Restores the Objective Tracker's collapsed/expanded state after login or /reload.")
end

local function BuildAuctionHouseFilterControls(category)
    local function GetValue() return not not (NX.DB.system.auctionHouse and NX.DB.system.auctionHouse.currentExpansionOnly) end
    local function SetValue(v)
        NX.DB.system.auctionHouse = NX.DB.system.auctionHouse or {}
        NX.DB.system.auctionHouse.currentExpansionOnly = not not v
        if NX.AuctionHouse and NX.AuctionHouse.OnSettingsChanged then NX.AuctionHouse:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_AH_CUR_EXP", Settings.VarType.Boolean, "Current Expansion Only Filter", true, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Automatically enables 'Current Expansion Only' when the Auction House opens.")
end

local function BuildSimpleFirstCraftBonusControls(category)
    local function GetValue()
        return not not (NX.DB.professions.simpleFirstCraftBonus and NX.DB.professions.simpleFirstCraftBonus.enabled)
    end

    local function SetValue(v)
        NX.DB.professions.simpleFirstCraftBonus = NX.DB.professions.simpleFirstCraftBonus or {}
        NX.DB.professions.simpleFirstCraftBonus.enabled = not not v
        if NX.SimpleFirstCraftBonus and NX.SimpleFirstCraftBonus.OnSettingsChanged then
            NX.SimpleFirstCraftBonus:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_SIMPLE_FIRST_CRAFT_BONUS",
        Settings.VarType.Boolean,
        "Simple First Craft Bonus",
        true,
        GetValue,
        SetValue
    )

    CreateEnabledDisabledDropdown(category, setting, "Shows a first-craft icon beside eligible profession recipes.")
end

local function BuildAutoWithdrawTreatiseControls(category)
    local function GetValue()
        return not not (NX.DB.professions.autoWithdrawTreatise and NX.DB.professions.autoWithdrawTreatise.enabled)
    end

    local function SetValue(v)
        NX.DB.professions.autoWithdrawTreatise = NX.DB.professions.autoWithdrawTreatise or {}
        NX.DB.professions.autoWithdrawTreatise.enabled = not not v
        if NX.AutoWithdrawTreatise and NX.AutoWithdrawTreatise.OnSettingsChanged then
            NX.AutoWithdrawTreatise:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_AUTO_WITHDRAW_TREATISE_ENABLED",
        Settings.VarType.Boolean,
        "Enabled",
        false,
        GetValue,
        SetValue
    )

    CreateEnabledDisabledDropdown(
        category,
        setting,
        "Automatically withdraws one Midnight treatise per active profession when the bank opens if the weekly quest is incomplete, the treatise is present in Warband bank, and you do not already have one in bags."
    )
end

local function BuildArtisanMoxieBagsControls(category)
    local function EnsureDB()
        NX.DB.professions.artisanMoxieBags = NX.DB.professions.artisanMoxieBags or {}
        local db = NX.DB.professions.artisanMoxieBags

        if db.enabled == nil then db.enabled = true end
        if db.textSize == nil then db.textSize = 22 end
        if db.anchorX == nil then db.anchorX = 0 end
        if db.anchorY == nil then db.anchorY = 220 end
        if db.positionUnlocked == nil then db.positionUnlocked = false end

        return db
    end

    local function NotifyChanged()
        if NX.ArtisanMoxieBags and NX.ArtisanMoxieBags.OnSettingsChanged then
            NX.ArtisanMoxieBags:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ARTISAN_MOXIE_BAGS_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Shows Collect Moxie Bag reminders in The Bazaar when any tracked Artisan Moxie currency is 600 or higher."
        )
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.textSize) or 22
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = math.floor((tonumber(v) or 22) + 0.5)
            if n < 10 then n = 10 end
            if n > 64 then n = 64 end
            db.textSize = n
            NotifyChanged()
            if NX.ArtisanMoxieBags and NX.ArtisanMoxieBags.RefreshDisplayStyle then
                NX.ArtisanMoxieBags:RefreshDisplayStyle()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ARTISAN_MOXIE_BAGS_TEXT_SIZE",
            Settings.VarType.Number,
            "Text Size",
            22,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(10, 64, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Adjusts the reminder text size for Artisan Moxie Bags.")
    end

    do
        local function GetValue()
            return not not (NX.DB.professions and NX.DB.professions.artisanMoxieBags and NX.DB.professions.artisanMoxieBags.positionUnlocked)
        end

        local function SetValue(v)
            if NX.ArtisanMoxieBags and NX.ArtisanMoxieBags.SetPositionUnlocked then
                NX.ArtisanMoxieBags:SetPositionUnlocked(v, true)
            else
                NX.DB.professions.artisanMoxieBags = NX.DB.professions.artisanMoxieBags or {}
                NX.DB.professions.artisanMoxieBags.positionUnlocked = not not v
                NotifyChanged()
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end
end

local function BuildMoxieOnProfessionFrameControls(category)
    local function GetValue()
        return not not (NX.DB.professions.moxieOnProfessionFrame and NX.DB.professions.moxieOnProfessionFrame.enabled)
    end

    local function SetValue(v)
        NX.DB.professions.moxieOnProfessionFrame = NX.DB.professions.moxieOnProfessionFrame or {}
        NX.DB.professions.moxieOnProfessionFrame.enabled = not not v

        if NX.MoxieOnProfessionFrame and NX.MoxieOnProfessionFrame.OnSettingsChanged then
            NX.MoxieOnProfessionFrame:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_MOXIE_ON_PROFESSION_FRAME_ENABLED",
        Settings.VarType.Boolean,
        "Enabled",
        true,
        GetValue,
        SetValue
    )

    CreateEnabledDisabledDropdown(
        category,
        setting,
        "Shows current Artisan Moxie values for your two primary professions at the bottom-left of the Professions crafting frame."
    )
end

local function BuildCraftingOrderFilterDefaultsControls(category)
    local function EnsureDB()
        NX.DB.professions.craftingOrderFilterDefaults = NX.DB.professions.craftingOrderFilterDefaults or {}
        local db = NX.DB.professions.craftingOrderFilterDefaults

        if db.enabled == nil then db.enabled = true end
        if db.showLearned == nil then db.showLearned = true end
        if db.haveMaterials == nil then db.haveMaterials = false end
        if db.showUnlearned == nil then db.showUnlearned = true end
        if db.hasSkillUp == nil then db.hasSkillUp = false end
        if db.firstCraftBonus == nil then db.firstCraftBonus = false end

        db.enabled = db.enabled and true or false
        db.showLearned = db.showLearned and true or false
        db.haveMaterials = db.haveMaterials and true or false
        db.showUnlearned = db.showUnlearned and true or false
        db.hasSkillUp = db.hasSkillUp and true or false
        db.firstCraftBonus = db.firstCraftBonus and true or false

        return db
    end

    local function NotifyChanged()
        if NX.CraftingOrderFilterDefaults and NX.CraftingOrderFilterDefaults.OnSettingsChanged then
            NX.CraftingOrderFilterDefaults:OnSettingsChanged()
        end
    end

    local function CreateToggle(dbKey, cvarSuffix, label, defaultValue, tooltip)
        local function GetValue()
            local db = EnsureDB()
            return not not db[dbKey]
        end

        local function SetValue(v)
            local db = EnsureDB()
            db[dbKey] = not not v
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CRAFTING_ORDER_FILTER_DEFAULTS_" .. cvarSuffix,
            Settings.VarType.Boolean,
            label,
            defaultValue and true or false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, tooltip)
    end

    CreateToggle(
        "enabled",
        "ENABLED",
        "Enabled",
        true,
        "Enable to apply your Crafting Orders filter defaults when opening the Orders tab."
    )

    CreateToggle(
        "showLearned",
        "SHOW_LEARNED",
        "Show Learned",
        true,
        "Sets whether learned recipes are shown by default on the Crafting Orders browse list."
    )

    CreateToggle(
        "haveMaterials",
        "HAVE_MATERIALS",
        "Have Materials",
        false,
        "Sets whether the Orders list defaults to recipes you can currently make with available materials."
    )

    CreateToggle(
        "showUnlearned",
        "SHOW_UNLEARNED",
        "Show Unlearned",
        true,
        "Sets whether unlearned recipes are shown by default on the Orders list."
    )

    CreateToggle(
        "hasSkillUp",
        "HAS_SKILL_UP",
        "Has Skill Up",
        false,
        "Sets whether only recipes that grant skill-ups are shown by default."
    )

    CreateToggle(
        "firstCraftBonus",
        "FIRST_CRAFT_BONUS",
        "First Craft Bonus",
        false,
        "Sets whether only recipes with first craft bonus are shown by default."
    )
end

local function BuildClickableBuffsControls(category)
    local function GetValue()
        return not not (NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.enabled)
    end

    local function SetValue(v)
        NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
        NX.DB.interface.clickableBuffs.enabled = not not v
        if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
            NX.ClickableBuffs:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(
        category,
        "NEXUS_CLICKABLE_BUFFS_ENABLED",
        Settings.VarType.Boolean,
        "Clickable Buffs",
        false,
        GetValue,
        SetValue
    )

    CreateEnabledDisabledDropdown(
        category,
        setting,
        "Shows clickable out-of-combat buff and consumable buttons when buffs are missing and items are available in bags."
    )

    do
        local function GetValue()
            return not not (NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.flashMissing)
        end

        local function SetValue(v)
            NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
            NX.DB.interface.clickableBuffs.flashMissing = not not v
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                NX.ClickableBuffs:OnSettingsChanged()
            end
        end

        local settingFlash = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLICKABLE_BUFFS_FLASH_MISSING",
            Settings.VarType.Boolean,
            "Flash When Missing",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, settingFlash, "Makes missing clickable buff buttons pulse.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.iconSize) or 48
        end

        local function SetValue(v)
            NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
            v = math.floor((tonumber(v) or 48) + 0.5)
            if v < 24 then v = 24 end
            if v > 96 then v = 96 end
            NX.DB.interface.clickableBuffs.iconSize = v
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                NX.ClickableBuffs:OnSettingsChanged()
            end
        end

        local settingSize = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLICKABLE_BUFFS_ICON_SIZE",
            Settings.VarType.Number,
            "Icon Size",
            48,
            GetValue,
            SetValue
        )

        local optionsSize = Settings.CreateSliderOptions(24, 96, 1)
        ApplyRightLabel(optionsSize, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, settingSize, optionsSize, "Clickable Buff button size in pixels.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.textSize) or 18
        end

        local function SetValue(v)
            NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
            v = math.floor((tonumber(v) or 18) + 0.5)
            if v < 10 then v = 10 end
            if v > 32 then v = 32 end
            NX.DB.interface.clickableBuffs.textSize = v
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                NX.ClickableBuffs:OnSettingsChanged()
            end
        end

        local settingTextSize = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLICKABLE_BUFFS_TEXT_SIZE",
            Settings.VarType.Number,
            "Text Size",
            18,
            GetValue,
            SetValue
        )

        local optionsTextSize = Settings.CreateSliderOptions(10, 32, 1)
        ApplyRightLabel(optionsTextSize, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, settingTextSize, optionsTextSize, "Clickable Buff label text size in pixels.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.iconZoomPct) or 15
        end

        local function SetValue(v)
            NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
            v = tonumber(v) or 15
            v = math.floor((v / 5) + 0.5) * 5
            if v < 0 then v = 0 end
            if v > 100 then v = 100 end
            NX.DB.interface.clickableBuffs.iconZoomPct = v
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                NX.ClickableBuffs:OnSettingsChanged()
            end
        end

        local settingIconZoom = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLICKABLE_BUFFS_ICON_ZOOM",
            Settings.VarType.Number,
            "Icon Zoom",
            15,
            GetValue,
            SetValue
        )

        local optionsIconZoom = Settings.CreateSliderOptions(0, 100, 5)
        ApplyRightLabel(optionsIconZoom, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, settingIconZoom, optionsIconZoom, "Zooms icon art inward while keeping button size unchanged.")
    end

    do
        local function GetValue()
            return not not (NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.positionUnlocked)
        end

        local function SetValue(v)
            if NX.ClickableBuffs and NX.ClickableBuffs.SetPositionUnlocked then
                NX.ClickableBuffs:SetPositionUnlocked(v, true)
            else
                NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
                NX.DB.interface.clickableBuffs.positionUnlocked = not not v
                if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsChanged then
                    NX.ClickableBuffs:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end
end

local function BuildStatsPlusControls(category)
    do
        local function GetValue()
            return not not (NX.DB.statsPlus and NX.DB.statsPlus.enabled)
        end

        local function SetValue(v)
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            NX.DB.statsPlus.enabled = not not v
            if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                NX.StatsPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_STATSPLUS_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            false,
            GetValue,
            SetValue
        )

        CreateBooleanCheckboxControl(category, setting, "Enable or disable Stats+.")
    end

    do
        local function GetStyleOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("VERTICAL", "Vertical")
            c:Add("HORIZONTAL", "Horizontal")
            return c:GetData()
        end

        local function GetValue()
            local v = NX.DB.statsPlus and NX.DB.statsPlus.style
            v = string.upper(tostring(v or "VERTICAL"))
            if v ~= "VERTICAL" and v ~= "HORIZONTAL" then
                v = "VERTICAL"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            v = string.upper(tostring(v or "VERTICAL"))
            if v ~= "VERTICAL" and v ~= "HORIZONTAL" then
                v = "VERTICAL"
            end
            NX.DB.statsPlus.style = v
            if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                NX.StatsPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_STATSPLUS_STYLE",
            Settings.VarType.String,
            "Style",
            "VERTICAL",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetStyleOptionsData, "Choose whether Stats+ is shown in stacked lines or a single pipe-separated row.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetAlignmentOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("LEFT", "Left")
            c:Add("CENTER", "Center")
            c:Add("RIGHT", "Right")
            return c:GetData()
        end

        local function GetValue()
            local v = NX.DB.statsPlus and NX.DB.statsPlus.textAlignment
            v = string.upper(tostring(v or "LEFT"))
            if v ~= "LEFT" and v ~= "CENTER" and v ~= "RIGHT" then
                v = "LEFT"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            v = string.upper(tostring(v or "LEFT"))
            if v ~= "LEFT" and v ~= "CENTER" and v ~= "RIGHT" then
                v = "LEFT"
            end
            NX.DB.statsPlus.textAlignment = v
            if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                NX.StatsPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_STATSPLUS_ALIGNMENT",
            Settings.VarType.String,
            "Text Alignment",
            "LEFT",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetAlignmentOptionsData, "Choose line alignment.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetGrowthDirectionOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("DOWN", "Down")
            c:Add("UP", "Up")
            return c:GetData()
        end

        local function GetValue()
            local v = NX.DB.statsPlus and NX.DB.statsPlus.textGrowthDirection
            v = string.upper(tostring(v or "DOWN"))
            if v ~= "UP" and v ~= "DOWN" then
                v = "DOWN"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            v = string.upper(tostring(v or "DOWN"))
            if v ~= "UP" and v ~= "DOWN" then
                v = "DOWN"
            end
            NX.DB.statsPlus.textGrowthDirection = v
            if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                NX.StatsPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_STATSPLUS_GROWTH_DIRECTION",
            Settings.VarType.String,
            "Growth Direction",
            "DOWN",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetGrowthDirectionOptionsData, "Choose whether text expands upward or downward from the anchor.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return tonumber(NX.DB.statsPlus and NX.DB.statsPlus.fontSize) or 14
        end

        local function SetValue(v)
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            v = math.floor((tonumber(v) or 14) + 0.5)
            if v < 0 then v = 0 end
            if v > 100 then v = 100 end
            NX.DB.statsPlus.fontSize = v
            if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                NX.StatsPlus:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_STATSPLUS_FONTSIZE",
            Settings.VarType.Number,
            "Font Size",
            14,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 100, 2)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Controls Stats+ font size.")
    end

    do
        local function GetValue()
            return not not (NX.DB.statsPlus and NX.DB.statsPlus.positionUnlocked)
        end

        local function SetValue(v)
            if NX.StatsPlus and NX.StatsPlus.SetPositionUnlocked then
                NX.StatsPlus:SetPositionUnlocked(v, true)
            else
                NX.DB.statsPlus = NX.DB.statsPlus or {}
                NX.DB.statsPlus.positionUnlocked = not not v
                if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                    NX.StatsPlus:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end

    AddSectionHeader(category, "Stats")

    do
        local function CreateStatToggle(key, label)
            local function GetValue()
                return not not (NX.DB.statsPlus and NX.DB.statsPlus[key])
            end

            local function SetValue(v)
                NX.DB.statsPlus = NX.DB.statsPlus or {}
                NX.DB.statsPlus[key] = not not v
                if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                    NX.StatsPlus:OnSettingsChanged()
                end
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_STATSPLUS_" .. string.upper(key),
                Settings.VarType.Boolean,
                label,
                true,
                GetValue,
                SetValue
            )

            CreateBooleanCheckboxControl(category, setting, "Show or hide this stat line.")
        end

        CreateStatToggle("showPrimaryStat", "Primary Stat")
        CreateStatToggle("showHaste", "Haste")
        CreateStatToggle("showMastery", "Mastery")
        CreateStatToggle("showCriticalStrike", "Critical Strike")
        CreateStatToggle("showVersatility", "Versatility")
    end

    AddSectionHeader(category, "Tank Stats")

    do
        local function CreateTankStatToggle(key, label)
            local function GetValue()
                return not not (NX.DB.statsPlus and NX.DB.statsPlus[key])
            end

            local function SetValue(v)
                NX.DB.statsPlus = NX.DB.statsPlus or {}
                NX.DB.statsPlus[key] = not not v
                if NX.StatsPlus and NX.StatsPlus.OnSettingsChanged then
                    NX.StatsPlus:OnSettingsChanged()
                end
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_STATSPLUS_" .. string.upper(key),
                Settings.VarType.Boolean,
                label,
                true,
                GetValue,
                SetValue
            )

            CreateBooleanCheckboxControl(category, setting, "Show or hide this tank stat line.")
        end

        CreateTankStatToggle("showArmor", "Armor")
        CreateTankStatToggle("showMeleeAvoidance", "Melee Avoidance")
    end
end

local function BuildWaypointTrackingControls(category)
    do
        local function GetValue()
            return not not (NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.autoTrackMapPins)
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            NX.DB.interface.waypointTracking.autoTrackMapPins = not not v
            if NX.WaypointAutoPinTracking and NX.WaypointAutoPinTracking.OnSettingsChanged then
                NX.WaypointAutoPinTracking:OnSettingsChanged()
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
            return not not (NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.unlimitedMapPinDistance)
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            NX.DB.interface.waypointTracking.unlimitedMapPinDistance = not not v
            if NX.WaypointUnlimitedPinDistance and NX.WaypointUnlimitedPinDistance.OnSettingsChanged then
                NX.WaypointUnlimitedPinDistance:OnSettingsChanged()
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

    do
        local function GetValue()
            return not not (NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker)
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            NX.DB.interface.waypointTracking.highlightedQuestMarker = not not v
            if NX.WaypointHighlightQuestMarker and NX.WaypointHighlightQuestMarker.OnSettingsChanged then
                NX.WaypointHighlightQuestMarker:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_HIGHLIGHTED_QUEST_MARKER",
            Settings.VarType.Boolean,
            "Highlighted Quest Marker",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(
            category,
            setting,
            "Shows a highlight ring around the super-tracked quest marker while it is visible."
        )
    end

    do
        local function GetMarkerStyleOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("default", "Default Circle")
            c:Add("huntersMark", "Hunter's Mark")
            return c:GetData()
        end

        local function GetValue()
            local db = NX.DB.interface.waypointTracking
            local style = tostring((db and db.highlightedQuestMarkerStyle) or "default")
            style = string.match(style, "^%s*(.-)%s*$") or "default"
            style = string.lower(style)
            if style ~= "default" and style ~= "huntersmark" then
                return "default"
            end
            if style == "huntersmark" then
                return "huntersMark"
            end
            return "default"
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            local style = string.lower(tostring(v or "default"))
            if style ~= "default" and style ~= "huntersmark" then
                style = "default"
            end
            NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle = (style == "huntersmark") and "huntersMark" or "default"
            if NX.WaypointHighlightQuestMarker and NX.WaypointHighlightQuestMarker.OnSettingsChanged then
                NX.WaypointHighlightQuestMarker:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_HIGHLIGHTED_QUEST_MARKER_STYLE",
            Settings.VarType.String,
            "Highlighted Marker Style",
            "default",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            GetMarkerStyleOptionsData,
            "Choose the icon style for highlighted waypoint marker. Hunter's Mark anchors above the waypoint pin."
        )
        init.reinitializeOnValueChanged = true
    end
end

local function BuildMinimapControls(category)
    local function EnsureDB()
        NX.DB.interface.minimap = NX.DB.interface.minimap or {}
        local db = NX.DB.interface.minimap
        if db.zoomoutEnabled == nil then db.zoomoutEnabled = false end
        if db.zoomoutDelaySeconds == nil then db.zoomoutDelaySeconds = 3 end
        if db.zoomoutTargetZoom == nil then db.zoomoutTargetZoom = 0 end
        return db
    end

    local function NotifyChanged()
        if NX.MinimapResourceIcons and NX.MinimapResourceIcons.OnSettingsChanged then
            NX.MinimapResourceIcons:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.zoomoutEnabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.zoomoutEnabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MINIMAP_ZOOMOUT_ENABLED",
            Settings.VarType.Boolean,
            "Auto Zoomout",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Automatically zooms your minimap out after zoom changes.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.zoomoutDelaySeconds) or 3
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.zoomoutDelaySeconds = FN:ClampNumber(tonumber(v) or 3, 0.1, 30)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MINIMAP_ZOOMOUT_DELAY_SECONDS",
            Settings.VarType.Number,
            "Zoomout Delay",
            3,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 10, 1)
        ApplyRightLabel(options, function(v) return string.format("%ds", v) end)
        Settings.CreateSlider(category, setting, options, "Delay before forcing automatic minimap zoomout.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return math.floor((tonumber(db.zoomoutTargetZoom) or 0) + 0.5)
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.zoomoutTargetZoom = math.floor(FN:ClampNumber(tonumber(v) or 0, 0, 5) + 0.5)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MINIMAP_ZOOMOUT_TARGET_ZOOM",
            Settings.VarType.Number,
            "Zoomout Target",
            0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 5, 1)
        ApplyRightLabel(options, function(v)
            if v == 0 then
                return string.format("%d (Furthest)", v)
            end
            if v == 5 then
                return string.format("%d (Closest)", v)
            end
            return tostring(v)
        end)
        Settings.CreateSlider(category, setting, options, "Target minimap zoom level for automatic zoomout.")
    end

end

local function BuildMinimapEnhancedResourceIconsControls(category)
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
        local text = string.lower(tostring(value or "default"))
        text = string.match(text, "^%s*(.-)%s*$") or "default"
        local compact = string.gsub(text, "[%s%+&%-_]", "")

        if text == "enhanced"
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
            return "enhanced"
        end

        return "default"
    end

    local function EnsureDB()
        NX.DB.interface.minimap = NX.DB.interface.minimap or {}
        local db = NX.DB.interface.minimap

        if db.enhancedResourceIconsMode == nil then
            local legacyEnabled = IsLegacyEnabled(db.enhancedResourceIconsEnabled)
            db.enhancedResourceIconsMode = legacyEnabled and "enhanced" or "default"
        end

        local mode = NormalizeMode(db.enhancedResourceIconsMode)
        db.enhancedResourceIconsMode = mode
        db.enhancedResourceIconsEnabled = mode ~= "default"

        return db
    end

    local function NotifyChanged()
        if NX.MinimapResourceIcons and NX.MinimapResourceIcons.OnSettingsChanged then
            NX.MinimapResourceIcons:OnSettingsChanged()
        end
    end

    do
        local function GetModeOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("default", "Default")
            c:Add("enhanced", "Enhanced")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            return db.enhancedResourceIconsMode
        end

        local function SetValue(v)
            if NX.MinimapResourceIcons and NX.MinimapResourceIcons.SetMode then
                NX.MinimapResourceIcons:SetMode(v, true)
            else
                local db = EnsureDB()
                local mode = NormalizeMode(v)
                db.enhancedResourceIconsMode = mode
                db.enhancedResourceIconsEnabled = mode ~= "default"
                NotifyChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_MINIMAP_ENHANCED_RESOURCE_ICONS_MODE",
            Settings.VarType.String,
            "Enhanced Resource Icons",
            "default",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            GetModeOptionsData,
            "Select which minimap icon atlas to use: Default or Enhanced."
        )
        init.reinitializeOnValueChanged = true
    end
end

local function BuildEquipmentControls(category)
    local function EnsureDB()
        NX.DB.equipment = NX.DB.equipment or {}
        local db = NX.DB.equipment
        if db.enabled == nil then db.enabled = true end
        if db.flashText == nil then db.flashText = false end
        if db.fontSize == nil then db.fontSize = 28 end
        if db.align == nil then db.align = "CENTER" end
        if db.grow == nil then db.grow = "DOWN" end
        if db.anchorX == nil then db.anchorX = 0 end
        if db.anchorY == nil then db.anchorY = 180 end
        if db.positionUnlocked == nil then db.positionUnlocked = false end
        if db.blacklistCsv == nil then db.blacklistCsv = "" end
        if db.checkMissingGems == nil then db.checkMissingGems = true end
        if db.checkSocketRequirements == nil then db.checkSocketRequirements = true end
        if db.checkMissingEnchants == nil then db.checkMissingEnchants = true end
        if db.maxLevelOnly == nil then db.maxLevelOnly = false end
        if db.levelAppropriateGear == nil then db.levelAppropriateGear = false end
        db.considerEnchantId0Missing = true
        return db
    end

    local function NotifyChanged()
        if NX.Equipment and NX.Equipment.OnSettingsChanged then
            NX.Equipment:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_ENABLED", Settings.VarType.Boolean, "Enabled", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Enable or disable Equipment checks for missing gems, sockets, and enchants.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.flashText == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.flashText = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_FLASH_TEXT", Settings.VarType.Boolean, "Flash Text", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Flashes center-screen notifications for missing gem and missing enchant messages.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.fontSize) or 28
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = math.floor((tonumber(v) or 28) + 0.5)
            if n < 12 then n = 12 end
            if n > 64 then n = 64 end
            db.fontSize = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_FONT_SIZE", Settings.VarType.Number, "Text Size", 28, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(12, 64, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Adjusts on-screen equipment alert text size.")
    end

    do
        local function GetAlignmentOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("LEFT", "Left")
            c:Add("CENTER", "Center")
            c:Add("RIGHT", "Right")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            local value = string.upper(tostring(db.align or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.upper(tostring(v or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            db.align = value
            NotifyChanged()
            if NX.Equipment and NX.Equipment.RefreshDisplayStyle then
                NX.Equipment:RefreshDisplayStyle()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_ALIGN", Settings.VarType.String, "Text Alignment", "CENTER", GetValue, SetValue)
        local init = Settings.CreateDropdown(category, setting, GetAlignmentOptionsData, "Sets equipment alert text alignment.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetGrowOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("UP", "Up")
            c:Add("DOWN", "Down")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            local value = string.upper(tostring(db.grow or "DOWN"))
            if value ~= "UP" and value ~= "DOWN" then
                value = "DOWN"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.upper(tostring(v or "DOWN"))
            if value ~= "UP" and value ~= "DOWN" then
                value = "DOWN"
            end
            db.grow = value
            NotifyChanged()
            if NX.Equipment and NX.Equipment.RefreshDisplayStyle then
                NX.Equipment:RefreshDisplayStyle()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_GROW", Settings.VarType.String, "Text Growth Direction", "DOWN", GetValue, SetValue)
        local init = Settings.CreateDropdown(category, setting, GetGrowOptionsData, "Changes whether equipment alerts stack upward or downward.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return not not (NX.DB.equipment and NX.DB.equipment.positionUnlocked)
        end

        local function SetValue(v)
            if NX.Equipment and NX.Equipment.SetPositionUnlocked then
                NX.Equipment:SetPositionUnlocked(v, true)
            else
                NX.DB.equipment = NX.DB.equipment or {}
                NX.DB.equipment.positionUnlocked = not not v
                if NX.Equipment and NX.Equipment.OnSettingsChanged then
                    NX.Equipment:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.maxLevelOnly == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.maxLevelOnly = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_MAX_LEVEL_ONLY", Settings.VarType.Boolean, "Max Level Only", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Only checks missing gems/sockets/enchants when your character is at max level.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.levelAppropriateGear == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.levelAppropriateGear = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_LEVEL_APPROPRIATE_GEAR", Settings.VarType.Boolean, "Level Appropriate Gear", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Only checks slots where the item required level matches your character level.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.checkMissingGems == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.checkMissingGems = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_CHECK_MISSING_GEMS", Settings.VarType.Boolean, "Missing Gems", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Alerts when an item has sockets and one or more sockets are empty.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.checkSocketRequirements == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.checkSocketRequirements = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_CHECK_SOCKET_REQUIREMENTS", Settings.VarType.Boolean, "Socket Requirements", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Alerts when ring/amulet socket count is below required targets.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.checkMissingEnchants == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.checkMissingEnchants = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_CHECK_MISSING_ENCHANTS", Settings.VarType.Boolean, "Missing Enchants", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Alerts when configured equipment slots are missing enchants.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tostring(db.blacklistCsv or "")
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.blacklistCsv = tostring(v or "")
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_EQUIPMENT_BLACKLIST_CSV", Settings.VarType.String, "Blacklist Item IDs (CSV)", "", GetValue, SetValue)
        CreateStringSettingControl(category, setting, "Comma-separated item IDs to ignore (example: 228411,235499)")
    end

    do
        local function RunCheck()
            if NX.Equipment and NX.Equipment.RunEvaluation then
                NX.Equipment:RunEvaluation(true)
            end
        end

        if Settings and Settings.CreateButton then
            local ok = pcall(Settings.CreateButton, category, "Test", "Test", RunCheck, "Runs an immediate missing gems/sockets/enchants check.", true)
            if not ok then
                CreateToggleActionButton(category, "Test", RunCheck, "Runs an immediate missing gems/sockets/enchants check.")
            end
        else
            CreateToggleActionButton(category, "Test", RunCheck, "Runs an immediate missing gems/sockets/enchants check.")
        end
    end
end

local function BuildWarbankControls(category)
    local function EnsureDB()
        NX.DB.alerts.bankWarboundItems = NX.DB.alerts.bankWarboundItems or {}
        local db = NX.DB.alerts.bankWarboundItems
        if db.enabled == nil then db.enabled = true end
        if db.textSize == nil then db.textSize = 48 end
        if db.align == nil then db.align = "CENTER" end
        if db.flashText == nil then db.flashText = false end
        if db.color == nil or db.color == "" then db.color = "#FFD133" end
        if db.anchorX == nil then db.anchorX = 0 end
        if db.anchorY == nil then db.anchorY = 300 end
        if db.positionUnlocked == nil then db.positionUnlocked = false end
        return db
    end

    local function NotifyChanged()
        if NX.BankWarboundItems and NX.BankWarboundItems.OnSettingsChanged then
            NX.BankWarboundItems:OnSettingsChanged()
        end
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_BANK_WARBOUND_ITEMS_ENABLED", Settings.VarType.Boolean, "Enabled", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Enable or disable Bank Warbound Gear reminder alerts.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.textSize) or 48
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = math.floor((tonumber(v) or 48) + 0.5)
            if n < 12 then n = 12 end
            if n > 96 then n = 96 end
            db.textSize = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_BANK_WARBOUND_ITEMS_TEXT_SIZE", Settings.VarType.Number, "Text Size", 48, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(12, 96, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Adjusts the Bank Warbound Gear text size.")
    end

    do
        local function GetAlignmentOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("LEFT", "Left")
            c:Add("CENTER", "Center")
            c:Add("RIGHT", "Right")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            local value = string.upper(tostring(db.align or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.upper(tostring(v or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            db.align = value
            NotifyChanged()
            if NX.BankWarboundItems and NX.BankWarboundItems.RefreshDisplayStyle then
                NX.BankWarboundItems:RefreshDisplayStyle()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_BANK_WARBOUND_ITEMS_ALIGN", Settings.VarType.String, "Text Alignment", "CENTER", GetValue, SetValue)
        local init = Settings.CreateDropdown(category, setting, GetAlignmentOptionsData, "Sets Bank Warbound Gear text alignment.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.flashText == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.flashText = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_BANK_WARBOUND_ITEMS_FLASH_TEXT", Settings.VarType.Boolean, "Flashing", false, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Flashes the Bank Warbound Gear text reminder.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            local value = tostring(db.color or "#FFD133")
            if value == "" then
                value = "#FFD133"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            if type(v) ~= "string" or v == "" then
                v = "#FFD133"
            end
            db.color = v
            NotifyChanged()
            if NX.BankWarboundItems and NX.BankWarboundItems.RefreshDisplayStyle then
                NX.BankWarboundItems:RefreshDisplayStyle()
            end
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_BANK_WARBOUND_ITEMS_COLOR", Settings.VarType.String, "Font Color", "#FFD133", GetValue, SetValue)
        CreateSharedFontColorDropdown(category, setting, "Selects the font color used for Bank Warbound Gear text.")
    end

    do
        local function GetValue()
            return not not (NX.DB.alerts.bankWarboundItems and NX.DB.alerts.bankWarboundItems.positionUnlocked)
        end

        local function SetValue(v)
            if NX.BankWarboundItems and NX.BankWarboundItems.SetPositionUnlocked then
                NX.BankWarboundItems:SetPositionUnlocked(v, true)
            else
                NX.DB.alerts.bankWarboundItems = NX.DB.alerts.bankWarboundItems or {}
                NX.DB.alerts.bankWarboundItems.positionUnlocked = not not v
                if NX.BankWarboundItems and NX.BankWarboundItems.OnSettingsChanged then
                    NX.BankWarboundItems:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end
end

local function BuildAnchorsControls(category)
    local function AddShowAnchorToggle(label, getUnlocked, setUnlocked)
        CreateToggleActionButton(category, label, function()
            local current = getUnlocked() == true
            setUnlocked(not current)
        end)
    end

    AddShowAnchorToggle("Loot Spec Warning", function()
        return not not (NX.DB.dungeonsRaids.greatVault and NX.DB.dungeonsRaids.greatVault.positionUnlocked)
    end, function(v)
        if NX.Vault and NX.Vault.SetPositionUnlocked then
            NX.Vault:SetPositionUnlocked(v, true)
        else
            NX.DB.dungeonsRaids.greatVault = NX.DB.dungeonsRaids.greatVault or {}
            NX.DB.dungeonsRaids.greatVault.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Low Durability", function()
        return not not (NX.DB.interface.lowDurability and NX.DB.interface.lowDurability.positionUnlocked)
    end, function(v)
        if NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.SetPositionUnlocked then
            NX.Common.LowDurability:SetPositionUnlocked(v, true)
        else
            NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
            NX.DB.interface.lowDurability.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Bank Warbound Gear", function()
        return not not (NX.DB.alerts.bankWarboundItems and NX.DB.alerts.bankWarboundItems.positionUnlocked)
    end, function(v)
        if NX.BankWarboundItems and NX.BankWarboundItems.SetPositionUnlocked then
            NX.BankWarboundItems:SetPositionUnlocked(v, true)
        else
            NX.DB.alerts.bankWarboundItems = NX.DB.alerts.bankWarboundItems or {}
            NX.DB.alerts.bankWarboundItems.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Clickable Buffs", function()
        return not not (NX.DB.interface.clickableBuffs and NX.DB.interface.clickableBuffs.positionUnlocked)
    end, function(v)
        if NX.ClickableBuffs and NX.ClickableBuffs.SetPositionUnlocked then
            NX.ClickableBuffs:SetPositionUnlocked(v, true)
        else
            NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
            NX.DB.interface.clickableBuffs.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Stats+", function()
        return not not (NX.DB.statsPlus and NX.DB.statsPlus.positionUnlocked)
    end, function(v)
        if NX.StatsPlus and NX.StatsPlus.SetPositionUnlocked then
            NX.StatsPlus:SetPositionUnlocked(v, true)
        else
            NX.DB.statsPlus = NX.DB.statsPlus or {}
            NX.DB.statsPlus.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Artisan Moxie Bags", function()
        return not not (NX.DB.professions and NX.DB.professions.artisanMoxieBags and NX.DB.professions.artisanMoxieBags.positionUnlocked)
    end, function(v)
        if NX.ArtisanMoxieBags and NX.ArtisanMoxieBags.SetPositionUnlocked then
            NX.ArtisanMoxieBags:SetPositionUnlocked(v, true)
        else
            NX.DB.professions.artisanMoxieBags = NX.DB.professions.artisanMoxieBags or {}
            NX.DB.professions.artisanMoxieBags.positionUnlocked = not not v
        end
    end)
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
    AddSectionHeader(automationCategory, "Auction House")
    BuildAuctionHouseFilterControls(automationCategory)
    AddSectionHeader(automationCategory, "Cinematics")
    BuildCinematicsControls(automationCategory)
    AddSectionHeader(automationCategory, "Dialogs")
    BuildAutoConfirmDialogsControls(automationCategory)
    AddSectionHeader(automationCategory, "Tutorials")
    BuildTutorialsControls(automationCategory)

    local clickableBuffsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Clickable Buffs")
    self.clickableBuffsCategoryID = clickableBuffsCategory:GetID()

    AddSectionHeader(clickableBuffsCategory, "Clickable Buffs")
    BuildClickableBuffsControls(clickableBuffsCategory)

    local combatCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Combat")
    self.combatCategoryID = combatCategory:GetID()

    AddSectionHeader(combatCategory, "Crosshair")
    BuildCrosshairControls(combatCategory)
    AddSectionHeader(combatCategory, "Mouse Cursor")
    BuildMouseCursorControls(combatCategory)

    local pveCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Great Vault")
    self.pveCategoryID = pveCategory:GetID()

    AddSectionHeader(pveCategory, "Loot Spec Warning")
    BuildGreatVaultControls(pveCategory)

    local gameplayCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Gameplay")
    self.gameplayCategoryID = gameplayCategory:GetID()

    AddSectionHeader(gameplayCategory, "Action Behaviour")
    BuildAutoPlaceSpellsControls(gameplayCategory)
    BuildAutoDismountControls(gameplayCategory)
    BuildCatalystControls(gameplayCategory)

    local interfaceCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Interface")
    self.interfaceCategoryID = interfaceCategory:GetID()

    AddSectionHeader(interfaceCategory, "Clean Objective Tracker")
    BuildCleanObjectiveTrackerControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Low Durability")
    BuildLowDurabilityControls(interfaceCategory)
    BuildEnhancedErrorTextControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Blizzard Interface Fixes")
    BuildMoneyFrameFixControls(interfaceCategory)
    AddSectionHeader(interfaceCategory, "Visual Clarity")
    BuildMotionSicknessControls(interfaceCategory)
    BuildSkyridingEffectsControls(interfaceCategory)
    BuildAlwaysSharpenControls(interfaceCategory)
    BuildExtraActionArtworkControls(interfaceCategory)
    BuildHideTalkingHeadControls(interfaceCategory)
    BuildHideMicroMenuPopupsControls(interfaceCategory)
    BuildScreenshotStatusControls(interfaceCategory)
    BuildQuestTrackerStateControls(interfaceCategory)

    local minimapCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Minimap")
    self.minimapCategoryID = minimapCategory:GetID()

    AddSectionHeader(minimapCategory, "Automatic Zoom")
    BuildMinimapControls(minimapCategory)
    AddSectionHeader(minimapCategory, "Enhanced Resource Icons")
    BuildMinimapEnhancedResourceIconsControls(minimapCategory)
    AddSectionHeader(minimapCategory, "Waypoint Tracking")
    BuildWaypointTrackingControls(minimapCategory)

    local portalsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Portals")
    self.portalsCategoryID = portalsCategory:GetID()

    AddSectionHeader(portalsCategory, "Portals")
    BuildPortalsControls(portalsCategory)

    local professionsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Professions")
    self.professionsCategoryID = professionsCategory:GetID()

    AddSectionHeader(professionsCategory, "Crafting Order Filter Defaults")
    BuildCraftingOrderFilterDefaultsControls(professionsCategory)
    AddSectionHeader(professionsCategory, "Auto Withdraw Treatise")
    BuildAutoWithdrawTreatiseControls(professionsCategory)
    AddSectionHeader(professionsCategory, "Artisan Moxie Bags")
    BuildArtisanMoxieBagsControls(professionsCategory)
    AddSectionHeader(professionsCategory, "Moxie on Profession Frame")
    BuildMoxieOnProfessionFrameControls(professionsCategory)
    AddSectionHeader(professionsCategory, "Simple First Craft Bonus")
    BuildSimpleFirstCraftBonusControls(professionsCategory)

    local settingsAnchorsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Settings & Anchors")
    self.settingsAnchorsCategoryID = settingsAnchorsCategory:GetID()

    AddSectionHeader(settingsAnchorsCategory, "Anchors")
    BuildAnchorsControls(settingsAnchorsCategory)
    AddSectionHeader(settingsAnchorsCategory, "General")
    BuildCommonControls(settingsAnchorsCategory)
    BuildLuaErrorsControls(settingsAnchorsCategory)
    AddSectionHeader(settingsAnchorsCategory, "Slash Commands")
    BuildSlashCommandControls(settingsAnchorsCategory)

    local statsPlusCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Stats+")
    self.statsPlusCategoryID = statsPlusCategory:GetID()

    AddSectionHeader(statsPlusCategory, "Category")
    BuildStatsPlusControls(statsPlusCategory)

    local warbankCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Warbank")
    self.warbankCategoryID = warbankCategory:GetID()

    AddSectionHeader(warbankCategory, "Bank Warbound Gear")
    BuildWarbankControls(warbankCategory)

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
            if NX.ClickableBuffs and NX.ClickableBuffs.OnSettingsClosed then
                NX.ClickableBuffs:OnSettingsClosed()
            end
            if NX.StatsPlus and NX.StatsPlus.OnSettingsClosed then
                NX.StatsPlus:OnSettingsClosed()
            end
            if NX.ArtisanMoxieBags and NX.ArtisanMoxieBags.OnSettingsClosed then
                NX.ArtisanMoxieBags:OnSettingsClosed()
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




