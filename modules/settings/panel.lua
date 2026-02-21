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
    local t = NX.DB.dungeonsRaids.keyHelpers.tankMarker
    local h = NX.DB.dungeonsRaids.keyHelpers.healerMarker
    if t ~= nil and h ~= nil and t == h then
        NX.DB.dungeonsRaids.keyHelpers.healerMarker = nil
    end
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

    local alertsHeader = CreateHeaderLine(body, "Alerts:")
    local alertsBody = CreateBodyLine(alertsHeader, "Utility Alerts event configuration, text behavior, flashing, sounds, and anchor controls.")

    local automationHeader = CreateHeaderLine(alertsBody, "Automation:")
    local automationBody = CreateBodyLine(automationHeader, "Achievement Screenshots, Cinematics, Dialog confirmations, Tutorials, and Auction House defaults.")

    local clickableBuffsHeader = CreateHeaderLine(automationBody, "Clickable Buffs:")
    local clickableBuffsBody = CreateBodyLine(clickableBuffsHeader, "Out-of-combat buff buttons, flashing, icon/text sizing, zoom, and anchor controls.")

    local combatHeader = CreateHeaderLine(clickableBuffsBody, "Combat:")
    local combatBody = CreateBodyLine(combatHeader, "Auto Combat Log, Action GCD Streamer, Crosshair, and Floating Combat Text controls.")

    local currencyHeader = CreateHeaderLine(combatBody, "Currency:")
    local currencyBody = CreateBodyLine(currencyHeader, "Tracked currency display toggles, scale, background visibility, and font sizing.")

    local dungeonsHeader = CreateHeaderLine(currencyBody, "Dungeons & Raids:")
    local dungeonsBody = CreateBodyLine(dungeonsHeader, "Great Vault and Mythic+ tools, including key handling and objective tracker behavior.")

    local equipmentHeader = CreateHeaderLine(dungeonsBody, "Equipment:")
    local equipmentBody = CreateBodyLine(equipmentHeader, "Missing gem/enchant checks, level filters, display style, blacklist, and anchor controls.")

    local gameplayHeader = CreateHeaderLine(equipmentBody, "Gameplay:")
    local gameplayBody = CreateBodyLine(gameplayHeader, "Auto place spells and auto dismount behavior, including flying dismount controls.")

    local interfaceHeader = CreateHeaderLine(gameplayBody, "Interface:")
    local interfaceBody = CreateBodyLine(interfaceHeader, "Objective tracker cleanup, durability/errors text, visual effect toggles, and clean names in instances.")

    local minimapHeader = CreateHeaderLine(interfaceBody, "Minimap:")
    local minimapBody = CreateBodyLine(minimapHeader, "Automatic minimap zoom behavior and waypoint tracking options.")

    local portalsHeader = CreateHeaderLine(minimapBody, "Portals:")
    local portalsBody = CreateBodyLine(portalsHeader, "Portal bar visibility, legacy portal filtering, layout sizing, spacing, and anchor positioning.")

    local professionsHeader = CreateHeaderLine(portalsBody, "Professions:")
    local professionsBody = CreateBodyLine(professionsHeader, "Simple First Craft Bonus, Easy Disenchant, and Personal Crafting Orders controls.")

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
            return GetSharedVoicePackActor()
        end

        local function SetValue(v)
            local actor = NormalizeVoicePackActor(v)
            SetSharedVoicePackActor(actor)

            NX.DB.alerts = NX.DB.alerts or {}
            NX.DB.alerts.alertEvents = NX.DB.alerts.alertEvents or {}
            NX.DB.alerts.alertEvents.voicePack = actor

            NX.DB.professions = NX.DB.professions or {}
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.voicePack = actor

            if NX.AlertEvents and NX.AlertEvents.OnSettingsChanged then
                NX.AlertEvents:OnSettingsChanged()
            end
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_SHARED_VOICE_PACK",
            Settings.VarType.String,
            "Voice Pack",
            "xalatath",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(
            category,
            setting,
            GetVoicePackOptionsData,
            "Selects the shared actor voice pack used by Utility Alerts and New Personal Crafting Order sounds."
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
            "Enables /cd, /cdm, and /wa. Command execution is blocked while in combat."
        )
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

local function BuildMythicPlusControls(category)
    do
        local function GetValue()
            return not not (NX.DB.dungeonsRaids.mythicPlus and NX.DB.dungeonsRaids.mythicPlus.respondToKeys)
        end

        local function SetValue(v)
            NX.DB.dungeonsRaids.mythicPlus = NX.DB.dungeonsRaids.mythicPlus or {}
            NX.DB.dungeonsRaids.mythicPlus.respondToKeys = not not v
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
            return tonumber(NX.DB.dungeonsRaids.mythicPlus and NX.DB.dungeonsRaids.mythicPlus.keysResponderCooldownSeconds) or 5
        end

        local function SetValue(v)
            NX.DB.dungeonsRaids.mythicPlus = NX.DB.dungeonsRaids.mythicPlus or {}
            v = tonumber(v) or 5
            v = math.floor(v + 0.5)
            if v < 1 then v = 1 end
            if v > 10 then v = 10 end
            NX.DB.dungeonsRaids.mythicPlus.keysResponderCooldownSeconds = v
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
            return not not (NX.DB.dungeonsRaids.mythicPlus and NX.DB.dungeonsRaids.mythicPlus.autoHideObjectives)
        end

        local function SetValue(v)
            NX.DB.dungeonsRaids.mythicPlus = NX.DB.dungeonsRaids.mythicPlus or {}
            NX.DB.dungeonsRaids.mythicPlus.autoHideObjectives = not not v
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
            return tonumber(NX.DB.dungeonsRaids.mythicPlus and NX.DB.dungeonsRaids.mythicPlus.objectiveTrackerRestoreDelaySeconds) or 30
        end

        local function SetValue(v)
            NX.DB.dungeonsRaids.mythicPlus = NX.DB.dungeonsRaids.mythicPlus or {}
            v = tonumber(v) or 30
            v = math.floor(v + 0.5)
            if v < 0 then v = 0 end
            if v > 120 then v = 120 end
            NX.DB.dungeonsRaids.mythicPlus.objectiveTrackerRestoreDelaySeconds = v
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
        local function GetValue() return NX.DB.dungeonsRaids.keyHelpers.markingStyle or "leader" end
        local function SetValue(v) NX.DB.dungeonsRaids.keyHelpers.markingStyle = v end
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
        local function GetValue() return NX.DB.dungeonsRaids.keyHelpers.tankMarker or 0 end
        local function SetValue(v)
            v = tonumber(v) or 0
            local newMarker = (v == 0) and nil or v

            NX.DB.dungeonsRaids.keyHelpers.tankMarker = newMarker
            if newMarker ~= nil and NX.DB.dungeonsRaids.keyHelpers.healerMarker == newMarker then
                NX.DB.dungeonsRaids.keyHelpers.healerMarker = nil
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
            function() return GetMarkerOptionsData(NX.DB.dungeonsRaids.keyHelpers.healerMarker) end,
            "Automatically marks the tank during the Mythic+ Start Countdown."
        )
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue() return NX.DB.dungeonsRaids.keyHelpers.healerMarker or 0 end
        local function SetValue(v)
            v = tonumber(v) or 0
            local newMarker = (v == 0) and nil or v

            NX.DB.dungeonsRaids.keyHelpers.healerMarker = newMarker
            if newMarker ~= nil and NX.DB.dungeonsRaids.keyHelpers.tankMarker == newMarker then
                NX.DB.dungeonsRaids.keyHelpers.tankMarker = nil
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
            function() return GetMarkerOptionsData(NX.DB.dungeonsRaids.keyHelpers.tankMarker) end,
            "Automatically marks the healer during the Mythic+ Start Countdown."
        )
        init.reinitializeOnValueChanged = true
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
            if NX.DB.portals.portals == nil then return true end
            return NX.DB.portals.portals.enabled ~= false
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            NX.DB.portals.portals.enabled = not not v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ENABLED", Settings.VarType.Boolean, "Portals", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Enable or disable the Portals bar.")
    end

    do
        local function GetValue()
            if NX.DB.portals.portals == nil then return true end
            return NX.DB.portals.portals.showLegacyPortals ~= false
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            NX.DB.portals.portals.showLegacyPortals = not not v
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
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.anchorX) or 0
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or 0) + 0.5)
            if v < -500 then v = -500 end
            if v > 500 then v = 500 end
            NX.DB.portals.portals.anchorX = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ANCHOR_X", Settings.VarType.Number, "Anchor X", 0, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(-500, 500, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Horizontal anchor offset for the portals bar.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.anchorY) or -35
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or -35) + 0.5)
            if v < -500 then v = -500 end
            if v > 500 then v = 500 end
            NX.DB.portals.portals.anchorY = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_ANCHOR_Y", Settings.VarType.Number, "Anchor Y", -35, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(-500, 500, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Vertical anchor offset for the portals bar.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.topRowMax) or 8
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or 8) + 0.5)
            if v < 6 then v = 6 end
            if v > 8 then v = 8 end
            NX.DB.portals.portals.topRowMax = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_TOP_ROW_MAX", Settings.VarType.Number, "Top Row Portals", 8, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(6, 8, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Maximum pinned portals in the top row.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.topRowHeightPct) or 80
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or 80) + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end
            NX.DB.portals.portals.topRowHeightPct = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_TOP_ROW_HEIGHT", Settings.VarType.Number, "Top Row Height %", 80, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(1, 100, 1)
        ApplyRightLabel(options, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, setting, options, "Top row button height as a percentage of button width.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.perRow) or 12
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or 12) + 0.5)
            if v < 8 then v = 8 end
            if v > 12 then v = 12 end
            NX.DB.portals.portals.perRow = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_PER_ROW", Settings.VarType.Number, "Portals Per Row", 12, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(8, 12, 1)
        ApplyRightLabel(options)
        Settings.CreateSlider(category, setting, options, "Portals per row for non-pinned portal buttons.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.smallRowHeightPct) or 80
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = math.floor((tonumber(v) or 80) + 0.5)
            if v < 1 then v = 1 end
            if v > 100 then v = 100 end
            NX.DB.portals.portals.smallRowHeightPct = v
            Notify()
        end

        local setting = Settings.RegisterProxySetting(category, "NEXUS_PORTALS_SMALL_ROW_HEIGHT", Settings.VarType.Number, "Small Row Height %", 80, GetValue, SetValue)
        local options = Settings.CreateSliderOptions(1, 100, 1)
        ApplyRightLabel(options, function(v) return string.format("%d%%", v) end)
        Settings.CreateSlider(category, setting, options, "Small row button height as a percentage of button width.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.portals.portals and NX.DB.portals.portals.spacing) or 2
        end

        local function SetValue(v)
            NX.DB.portals.portals = NX.DB.portals.portals or {}
            v = tonumber(v) or 2
            v = math.floor((v * 5) + 0.5) / 5
            if v < 0 then v = 0 end
            if v > 5 then v = 5 end
            NX.DB.portals.portals.spacing = v
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

local function BuildAutoCombatLogControls(category)
    do
        local function GetValue()
            return not not (NX.DB.automation.autoCombatLog and NX.DB.automation.autoCombatLog.enabled)
        end

        local function SetValue(v)
            NX.DB.automation.autoCombatLog = NX.DB.automation.autoCombatLog or {}
            NX.DB.automation.autoCombatLog.enabled = not not v
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
            return tonumber(NX.DB.automation.autoCombatLog and NX.DB.automation.autoCombatLog.stopDelaySeconds) or 30
        end

        local function SetValue(v)
            NX.DB.automation.autoCombatLog = NX.DB.automation.autoCombatLog or {}
            NX.DB.automation.autoCombatLog.stopDelaySeconds = tonumber(v) or 30
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

local function BuildActionGCDStreamerControls(category)
    do
        local function GetValue()
            return not not (NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.enabled)
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            NX.DB.combat.actionGCDStreamer.enabled = not not v
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Shows recent successful player casts as fading icons.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.duration) or 7.5
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = tonumber(v) or 7.5
            if n < 0.1 then n = 0.1 end
            if n > 30 then n = 30 end
            NX.DB.combat.actionGCDStreamer.duration = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_DURATION",
            Settings.VarType.Number,
            "Duration",
            7.5,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0.1, 30, 0.1)
        ApplyRightLabel(options, function(value) return string.format("%.1fs", value) end)
        Settings.CreateSlider(category, setting, options, "How long each cast icon remains visible before fading out.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.limit) or 7
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = math.floor((tonumber(v) or 7) + 0.5)
            if n < 1 then n = 1 end
            if n > 20 then n = 20 end
            NX.DB.combat.actionGCDStreamer.limit = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_LIMIT",
            Settings.VarType.Number,
            "Icon Limit",
            7,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 20, 1)
        ApplyRightLabel(options, function(value) return string.format("%d", value) end)
        Settings.CreateSlider(category, setting, options, "Maximum number of recent cast icons shown at once.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.iconSize) or 30
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = math.floor((tonumber(v) or 30) + 0.5)
            if n < 16 then n = 16 end
            if n > 96 then n = 96 end
            NX.DB.combat.actionGCDStreamer.iconSize = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_ICON_SIZE",
            Settings.VarType.Number,
            "Icon Size",
            30,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(16, 96, 1)
        ApplyRightLabel(options, function(value) return string.format("%dpx", value) end)
        Settings.CreateSlider(category, setting, options, "Size of each cast icon in pixels.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.iconZoomPct) or 10
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = math.floor((tonumber(v) or 10) + 0.5)
            if n < 0 then n = 0 end
            if n > 100 then n = 100 end
            NX.DB.combat.actionGCDStreamer.iconZoomPct = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_ICON_ZOOM_PCT",
            Settings.VarType.Number,
            "Icon Zoom",
            10,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 100, 1)
        ApplyRightLabel(options, function(value) return string.format("%d%%", value) end)
        Settings.CreateSlider(category, setting, options, "Zooms into each cast icon by cropping edges.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.spacing) or 1
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = math.floor((tonumber(v) or 1) + 0.5)
            if n < 0 then n = 0 end
            if n > 20 then n = 20 end
            NX.DB.combat.actionGCDStreamer.spacing = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_SPACING",
            Settings.VarType.Number,
            "Icon Spacing",
            1,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 20, 1)
        ApplyRightLabel(options, function(value) return string.format("%dpx", value) end)
        Settings.CreateSlider(category, setting, options, "Spacing between cast icons in pixels.")
    end

    do
        local function GetDirectionOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("UP", "Up")
            c:Add("DOWN", "Down")
            c:Add("LEFT", "Left")
            c:Add("RIGHT", "Right")
            return c:GetData()
        end

        local function GetValue()
            local value = NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.growthDirection
            value = string.upper(tostring(value or "LEFT"))
            if value ~= "UP" and value ~= "DOWN" and value ~= "LEFT" and value ~= "RIGHT" then
                value = "LEFT"
            end
            return value
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local value = string.upper(tostring(v or "LEFT"))
            if value ~= "UP" and value ~= "DOWN" and value ~= "LEFT" and value ~= "RIGHT" then
                value = "LEFT"
            end
            NX.DB.combat.actionGCDStreamer.growthDirection = value
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_GROWTH_DIRECTION",
            Settings.VarType.String,
            "Growth Direction",
            "LEFT",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetDirectionOptionsData, "Changes the direction in which cast icons grow.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return not not (NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.tooltipOnMouseover)
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            NX.DB.combat.actionGCDStreamer.tooltipOnMouseover = not not v
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_TOOLTIP_MOUSEOVER",
            Settings.VarType.Boolean,
            "Tooltip on Mouseover",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Shows a spell tooltip when mousing over a GCD stream icon.")
    end

    do
        local function GetValue()
            return not not (NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.showLastCastMS)
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            NX.DB.combat.actionGCDStreamer.showLastCastMS = not not v
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_SHOW_LAST_CAST_MS",
            Settings.VarType.Boolean,
            "Show Last Cast MS",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Shows elapsed time from the previous cast as text like 100ms. The first icon in the stream does not show this.")
    end

    do
        local function GetValue()
            return tonumber(NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.showLastCastMSFontSize) or 12
        end

        local function SetValue(v)
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            local n = math.floor((tonumber(v) or 12) + 0.5)
            if n < 8 then n = 8 end
            if n > 32 then n = 32 end
            NX.DB.combat.actionGCDStreamer.showLastCastMSFontSize = n
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                NX.ActionGCDStreamer:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ACTION_GCD_STREAMER_SHOW_LAST_CAST_MS_FONT_SIZE",
            Settings.VarType.Number,
            "Last Cast MS Font Size",
            12,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(8, 32, 1)
        ApplyRightLabel(options, function(value) return string.format("%dpx", value) end)
        Settings.CreateSlider(category, setting, options, "Font size for the last-cast ms text shown on each icon.")
    end

    do
        local function GetValue()
            return not not (NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.positionUnlocked)
        end

        local function SetValue(v)
            if NX.ActionGCDStreamer and NX.ActionGCDStreamer.SetPositionUnlocked then
                NX.ActionGCDStreamer:SetPositionUnlocked(v, true)
            else
                NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
                NX.DB.combat.actionGCDStreamer.positionUnlocked = not not v
                if NX.ActionGCDStreamer and NX.ActionGCDStreamer.OnSettingsChanged then
                    NX.ActionGCDStreamer:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
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

local function BuildFloatingCombatTextControls(category)
    do
        local function GetValue() return not (not not (NX.DB.combat.floatingCombatText and NX.DB.combat.floatingCombatText.hideOverPlayer)) end
        local function SetValue(v)
            NX.DB.combat.floatingCombatText = NX.DB.combat.floatingCombatText or {}
            NX.DB.combat.floatingCombatText.hideOverPlayer = not v
            if NX.FloatingCombatText and NX.FloatingCombatText.OnSettingsChanged then NX.FloatingCombatText:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_FCT_HIDE_OVER_PLAYER", Settings.VarType.Boolean, "Enable Player", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Shows damage/healing hit indicator text above your character.")
    end

    do
        local function GetValue() return not (not not (NX.DB.combat.floatingCombatText and NX.DB.combat.floatingCombatText.hideOverPet)) end
        local function SetValue(v)
            NX.DB.combat.floatingCombatText = NX.DB.combat.floatingCombatText or {}
            NX.DB.combat.floatingCombatText.hideOverPet = not v
            if NX.FloatingCombatText and NX.FloatingCombatText.OnSettingsChanged then NX.FloatingCombatText:OnSettingsChanged() end
        end
        local setting = Settings.RegisterProxySetting(category, "NEXUS_FCT_HIDE_OVER_PET", Settings.VarType.Boolean, "Enable Pet", true, GetValue, SetValue)
        CreateEnabledDisabledDropdown(category, setting, "Shows damage/healing hit indicator text above your pet.")
    end

    local function MakeToggle(proxyKey, dbKey, label, tooltip)
        local function GetValue() return not not (NX.DB.combat.floatingCombatText and NX.DB.combat.floatingCombatText[dbKey]) end
        local function SetValue(v)
            NX.DB.combat.floatingCombatText = NX.DB.combat.floatingCombatText or {}
            NX.DB.combat.floatingCombatText[dbKey] = not not v
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
    local function GetValue() return not not (NX.DB.combat.assistedRotationOverlay and NX.DB.combat.assistedRotationOverlay.enabled) end
    local function SetValue(v)
        NX.DB.combat.assistedRotationOverlay = NX.DB.combat.assistedRotationOverlay or {}
        NX.DB.combat.assistedRotationOverlay.enabled = not not v
        if NX.AssistedRotationOverlay and NX.AssistedRotationOverlay.OnSettingsChanged then
            NX.AssistedRotationOverlay:OnSettingsChanged()
        end
    end

    local setting = Settings.RegisterProxySetting(category, "NEXUS_ASSISTED_OVERLAY_HIDE", Settings.VarType.Boolean, "Hide Assisted Combat Rotation overlay", false, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Hides the Assisted Combat Rotation helper glow/overlay on action buttons.")
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
    local function GetValue() return not (not not (NX.DB.system.tutorials and NX.DB.system.tutorials.disabled)) end
    local function SetValue(v)
        NX.DB.system.tutorials = NX.DB.system.tutorials or {}
        NX.DB.system.tutorials.disabled = not v
        if NX.Tutorials and NX.Tutorials.OnSettingsChanged then NX.Tutorials:OnSettingsChanged() end
    end
    local setting = Settings.RegisterProxySetting(category, "NEXUS_DISABLE_TUTORIALS", Settings.VarType.Boolean, "Tutorials", true, GetValue, SetValue)
    CreateEnabledDisabledDropdown(category, setting, "Disables most tutorial popups when set to Disabled (showTutorials = 0).")
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

    MakeToggle("replaceEnchant", "Accept Enchants", "Automatically confirms the enchant replacement dialog.")
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

local function BuildPersonalCraftingOrdersControls(category)
    AddSectionHeader(category, "Current Personal Crafting Orders")

    do
        local function GetValue()
            return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.textAlertEnabled)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.textAlertEnabled = not not v
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_TEXT_ENABLED",
            Settings.VarType.Boolean,
            "Enable",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Shows personal crafting order count beneath the Professions tab system.")
    end

    do
        local function GetValue()
            return math.floor((tonumber(NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.currentOrdersFontSize) or 20) + 0.5)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            local n = math.floor((tonumber(v) or 20) + 0.5)
            if n < 8 then n = 8 end
            if n > 96 then n = 96 end
            NX.DB.professions.personalCraftingOrders.currentOrdersFontSize = n
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_CURRENT_FONT_SIZE",
            Settings.VarType.Number,
            "Font Size",
            20,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(8, 96, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Font size for Current Personal Orders text (uses addon font family).")
    end

    do
        local function GetValue()
            local db = NX.DB.professions.personalCraftingOrders or {}
            return NormalizeSharedHexColor(db.currentOrdersColor or "#FFFFFF", "#FFFFFF")
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.currentOrdersColor = NormalizeSharedHexColor(v, "#FFFFFF")
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_CURRENT_COLOR",
            Settings.VarType.String,
            "Font Colour",
            "#FFFFFF",
            GetValue,
            SetValue
        )

        CreateSharedFontColorDropdown(category, setting, "Selects the font colour for Current Personal Orders text. Each option previews its colour.")
    end

    AddSectionHeader(category, "New Personal Crafting Order Received")

    do
        local function GetValue()
            return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderAlertEnabled)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.newOrderAlertEnabled = not not v
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_ENABLED",
            Settings.VarType.Boolean,
            "Enable",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Enables or disables the New Personal Order Received alert text and sound trigger.")
    end

    do
        local function GetValue()
            return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.soundAlertEnabled)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.soundAlertEnabled = not not v
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_SOUND_ENABLED",
            Settings.VarType.Boolean,
            "Enable Sound",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Enables or disables the voice pack audio for New Personal Crafting Order Received alerts.")
    end

    do
        local function PlayTestSound()
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.PlayAlertSound then
                local played = NX.PersonalCraftingOrders:PlayAlertSound()
                if not played then
                    print("|cffffd200Nexus:|r Personal Crafting Orders sound is disabled.")
                end
            end
        end

        if Settings and Settings.CreateButton then
            local ok = pcall(Settings.CreateButton, category, "Test Sound", "Play", PlayTestSound, "Plays the currently selected sound alert for Personal Crafting Orders.", true)
            if not ok then
                CreateToggleActionButton(category, "Test Sound", PlayTestSound, "Plays the currently selected sound alert for Personal Crafting Orders.")
            end
        else
            CreateToggleActionButton(category, "Test Sound", PlayTestSound, "Plays the currently selected sound alert for Personal Crafting Orders.")
        end
    end

    do
        local function GetValue()
            return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderPositionUnlocked)
        end

        local function SetValue(v)
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.SetNewOrderPositionUnlocked then
                NX.PersonalCraftingOrders:SetNewOrderPositionUnlocked(v, true)
            else
                NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
                NX.DB.professions.personalCraftingOrders.newOrderPositionUnlocked = not not v
                if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                    NX.PersonalCraftingOrders:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end, "Shows or hides the drag anchor for New Personal Order Received text.")
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
            local db = NX.DB.professions.personalCraftingOrders or {}
            local value = string.upper(tostring(db.newOrderAlignment or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            return value
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            local value = string.upper(tostring(v or "CENTER"))
            if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                value = "CENTER"
            end
            NX.DB.professions.personalCraftingOrders.newOrderAlignment = value
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_ALIGNMENT",
            Settings.VarType.String,
            "New Order Text Alignment",
            "CENTER",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetAlignmentOptionsData, "Sets the alignment for New Personal Order Received text.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return math.floor((tonumber(NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderFontSize) or 28) + 0.5)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            local n = math.floor((tonumber(v) or 28) + 0.5)
            if n < 8 then n = 8 end
            if n > 96 then n = 96 end
            NX.DB.professions.personalCraftingOrders.newOrderFontSize = n
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_FONT_SIZE",
            Settings.VarType.Number,
            "New Order Font Size",
            28,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(8, 96, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Controls font size for New Personal Order Received text.")
    end

    do
        local function GetValue()
            local db = NX.DB.professions.personalCraftingOrders or {}
            return NormalizeSharedHexColor(db.newOrderColor or "#FFD133", "#FFD133")
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.newOrderColor = NormalizeSharedHexColor(v, "#FFD133")
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_COLOR",
            Settings.VarType.String,
            "New Order Font Colour",
            "#FFD133",
            GetValue,
            SetValue
        )

        CreateSharedFontColorDropdown(category, setting, "Selects the font colour for New Personal Order Received text.")
    end

    do
        local function GetValue()
            return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderFlashing)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.newOrderFlashing = not not v
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_FLASHING",
            Settings.VarType.Boolean,
            "New Order Flashing",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Enable or disable flashing for New Personal Order Received text.")
    end

    do
        local function GetValue()
            return math.floor((tonumber(NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderDuration) or 4) + 0.5)
        end

        local function SetValue(v)
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            local n = math.floor((tonumber(v) or 4) + 0.5)
            if n < 1 then n = 1 end
            if n > 30 then n = 30 end
            NX.DB.professions.personalCraftingOrders.newOrderDuration = n
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_PERSONAL_CRAFTING_ORDERS_NEW_ORDER_DURATION",
            Settings.VarType.Number,
            "New Order Duration",
            4,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 30, 1)
        ApplyRightLabel(options, function(v) return string.format("%ds", v) end)
        Settings.CreateSlider(category, setting, options, "How long New Personal Order Received text stays visible.")
    end
end

local function BuildEasyDisenchantControls(category)
    local function EnsureDB()
        NX.DB.professions.easyDisenchant = NX.DB.professions.easyDisenchant or {}
        local db = NX.DB.professions.easyDisenchant
        if db.enabled == nil then db.enabled = true end
        if db.anchorSide == nil then db.anchorSide = "LEFT" end
        if db.xOffset == nil then db.xOffset = 0 end
        if db.yOffset == nil then db.yOffset = -50 end
        if db.outsidePadding == nil then db.outsidePadding = 6 end
        if db.size == nil then db.size = 38 end
        if db.iconZoom == nil then db.iconZoom = 0.10 end
        return db
    end

    local function NotifyChanged()
        if NX.EasyDisenchant and NX.EasyDisenchant.OnSettingsChanged then
            NX.EasyDisenchant:OnSettingsChanged()
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
            "NEXUS_EASY_DISENCHANT_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Show a Disenchant button on your bag frame when Disenchant is known and Enchanting is learned.")
    end

    do
        local function GetAnchorSideOptionsData()
            local c = Settings.CreateControlTextContainer()
            c:Add("LEFT", "Left")
            c:Add("RIGHT", "Right")
            return c:GetData()
        end

        local function GetValue()
            local db = EnsureDB()
            local value = string.upper(tostring(db.anchorSide or "LEFT"))
            if value ~= "LEFT" and value ~= "RIGHT" then
                value = "LEFT"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.upper(tostring(v or "LEFT"))
            if value ~= "LEFT" and value ~= "RIGHT" then
                value = "LEFT"
            end
            db.anchorSide = value
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_ANCHOR_SIDE",
            Settings.VarType.String,
            "Anchor Side",
            "LEFT",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetAnchorSideOptionsData, "Choose which side of the bag frame the button anchors to.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.xOffset) or 0
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.xOffset = math.floor((tonumber(v) or 0) + 0.5)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_X_OFFSET",
            Settings.VarType.Number,
            "X Offset",
            0,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(-200, 200, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Horizontal offset for the Disenchant button anchor.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.yOffset) or -50
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.yOffset = math.floor((tonumber(v) or -50) + 0.5)
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_Y_OFFSET",
            Settings.VarType.Number,
            "Y Offset",
            -50,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(-200, 200, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Vertical offset for the Disenchant button anchor.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.outsidePadding) or 6
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.outsidePadding = math.floor((tonumber(v) or 6) + 0.5)
            if db.outsidePadding < 0 then db.outsidePadding = 0 end
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_OUTSIDE_PADDING",
            Settings.VarType.Number,
            "Outside Padding",
            6,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 40, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Extra gap between the button and the bag frame edge.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.size) or 38
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.size = math.floor((tonumber(v) or 38) + 0.5)
            if db.size < 20 then db.size = 20 end
            if db.size > 96 then db.size = 96 end
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_SIZE",
            Settings.VarType.Number,
            "Button Size",
            38,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(20, 96, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Size of the Easy Disenchant button.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return math.floor(((tonumber(db.iconZoom) or 0.10) * 100) + 0.5)
        end

        local function SetValue(v)
            local db = EnsureDB()
            local pct = math.floor((tonumber(v) or 10) + 0.5)
            if pct < 0 then pct = 0 end
            if pct > 49 then pct = 49 end
            db.iconZoom = pct / 100
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_EASY_DISENCHANT_ICON_ZOOM",
            Settings.VarType.Number,
            "Icon Zoom",
            10,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(0, 49, 1)
        ApplyRightLabel(options, function(v)
            return string.format("%d%%", v)
        end)
        Settings.CreateSlider(category, setting, options, "Crops the icon inward to mimic zoom.")
    end
end

local function BuildUtilityAlertsControls(category)
    local EVENT_ROWS = {
        { key = "FEAST", label = "Feast" },
        { key = "POTION_CAULDRON", label = "Potion Cauldron" },
        { key = "FLASK_CAULDRON", label = "Flask Cauldron" },
        { key = "JEEVES", label = "Jeeves" },
        { key = "MAILBOX", label = "Mailbox" },
        { key = "AUTO_HAMMER", label = "Auto-Hammer" },
        { key = "SOULWELL", label = "Soulwell" },
        { key = "MAGE_TABLE", label = "Mage Table" },
    }

    local function EnsureDB()
        NX.DB.alerts.alertEvents = NX.DB.alerts.alertEvents or {}
        local db = NX.DB.alerts.alertEvents
        db.events = db.events or {}
        db.voicePack = NormalizeVoicePackActor(db.voicePack or GetSharedVoicePackActor())

        for _, row in ipairs(EVENT_ROWS) do
            db.events[row.key] = db.events[row.key] or {}
            local eventCfg = db.events[row.key]
            if eventCfg.enabled == nil then
                eventCfg.enabled = true
            end
            if eventCfg.flashing == nil then
                eventCfg.flashing = false
            end
            eventCfg.enabled = eventCfg.enabled and true or false
            eventCfg.flashing = eventCfg.flashing and true or false
        end

        return db
    end

    local function NotifyChanged()
        if NX.AlertEvents and NX.AlertEvents.OnSettingsChanged then
            NX.AlertEvents:OnSettingsChanged()
        end
    end

    AddSectionHeader(category, "Settings")

    do
        local function GetValue()
            local db = EnsureDB()
            return db.enabled ~= false
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.enabled = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALERT_EVENTS_ENABLED",
            Settings.VarType.Boolean,
            "Enabled",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Enable or disable Utility Alerts for feasts, cauldrons, mailbox, repairs, soulwell, and mage table.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.textSize) or 28
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = math.floor((tonumber(v) or 28) + 0.5)
            if n < 8 then n = 8 end
            if n > 96 then n = 96 end
            db.textSize = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALERT_EVENTS_TEXT_SIZE",
            Settings.VarType.Number,
            "Text Size",
            28,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(8, 96, 1)
        ApplyRightLabel(options, function(v) return string.format("%dpx", v) end)
        Settings.CreateSlider(category, setting, options, "Sets the Utility Alerts text size.")
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

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALERT_EVENTS_ALIGN",
            Settings.VarType.String,
            "Text Alignment",
            "CENTER",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetAlignmentOptionsData, "Sets alert text alignment.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return tonumber(db.duration) or 3
        end

        local function SetValue(v)
            local db = EnsureDB()
            local n = math.floor((tonumber(v) or 3) + 0.5)
            if n < 1 then n = 1 end
            if n > 10 then n = 10 end
            db.duration = n
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALERT_EVENTS_DURATION",
            Settings.VarType.Number,
            "Alert Duration",
            3,
            GetValue,
            SetValue
        )

        local options = Settings.CreateSliderOptions(1, 10, 1)
        ApplyRightLabel(options, function(v) return string.format("%ds", v) end)
        Settings.CreateSlider(category, setting, options, "Sets how long each alert stays visible.")
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
            local value = string.upper(tostring(db.grow or "UP"))
            if value ~= "UP" and value ~= "DOWN" then
                value = "UP"
            end
            return value
        end

        local function SetValue(v)
            local db = EnsureDB()
            local value = string.upper(tostring(v or "UP"))
            if value ~= "UP" and value ~= "DOWN" then
                value = "UP"
            end
            db.grow = value
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_ALERT_EVENTS_GROW",
            Settings.VarType.String,
            "Text Growth Direction",
            "UP",
            GetValue,
            SetValue
        )

        local init = Settings.CreateDropdown(category, setting, GetGrowOptionsData, "Changes whether new alerts stack upward or downward.")
        init.reinitializeOnValueChanged = true
    end

    do
        local function GetValue()
            return not not (NX.DB.alerts.alertEvents and NX.DB.alerts.alertEvents.positionUnlocked)
        end

        local function SetValue(v)
            if NX.AlertEvents and NX.AlertEvents.SetPositionUnlocked then
                NX.AlertEvents:SetPositionUnlocked(v, true)
            else
                NX.DB.alerts.alertEvents = NX.DB.alerts.alertEvents or {}
                NX.DB.alerts.alertEvents.positionUnlocked = not not v
                if NX.AlertEvents and NX.AlertEvents.OnSettingsChanged then
                    NX.AlertEvents:OnSettingsChanged()
                end
            end
        end

        CreateToggleActionButton(category, "Show Anchor", function()
            SetValue(not GetValue())
        end)
    end

    do
        local function RunTest()
            if NX.AlertEvents and NX.AlertEvents.TestAlerts then
                NX.AlertEvents:TestAlerts()
            end
        end

        if Settings and Settings.CreateButton then
            local ok = pcall(Settings.CreateButton, category, "Test Alerts", "Run", RunTest, "Shows sample Utility Alerts so you can preview size, alignment, growth, and sounds.", true)
            if not ok then
                CreateToggleActionButton(category, "Test Alerts", RunTest, "Shows sample Utility Alerts so you can preview size, alignment, growth, and sounds.")
            end
        else
            CreateToggleActionButton(category, "Test Alerts", RunTest, "Shows sample Utility Alerts so you can preview size, alignment, growth, and sounds.")
        end
    end

    AddSectionHeader(category, "Events")

    for _, row in ipairs(EVENT_ROWS) do
        do
            local function GetValue()
                local db = EnsureDB()
                local eventCfg = db.events and db.events[row.key]
                return eventCfg and eventCfg.enabled == true or false
            end

            local function SetValue(v)
                local db = EnsureDB()
                db.events[row.key].enabled = v and true or false
                NotifyChanged()
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_ALERT_EVENTS_EVENT_ENABLED_" .. row.key,
                Settings.VarType.Boolean,
                row.label,
                true,
                GetValue,
                SetValue
            )

            CreateEnabledDisabledDropdown(category, setting, "Enable or disable the " .. row.label .. " alert event.")
        end

        do
            local function GetValue()
                local db = EnsureDB()
                local eventCfg = db.events and db.events[row.key]
                return eventCfg and eventCfg.flashing == true or false
            end

            local function SetValue(v)
                local db = EnsureDB()
                db.events[row.key].flashing = v and true or false
                NotifyChanged()
            end

            local setting = Settings.RegisterProxySetting(
                category,
                "NEXUS_ALERT_EVENTS_EVENT_FLASHING_" .. row.key,
                Settings.VarType.Boolean,
                row.label .. " Flashing",
                false,
                GetValue,
                SetValue
            )

            CreateEnabledDisabledDropdown(category, setting, "Enable or disable flashing text for the " .. row.label .. " alert.")
        end
    end

end

local function BuildCurrenciesControls(category)
    do
        local function GetValue()
            return not not (NX.DB.system.currencies and NX.DB.system.currencies.enabled)
        end

        local function SetValue(v)
            NX.DB.system.currencies = NX.DB.system.currencies or {}
            NX.DB.system.currencies.enabled = not not v
            if NX.Currencies and NX.Currencies.OnSettingsChanged then
                NX.Currencies:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CURRENCIES_ENABLED",
            Settings.VarType.Boolean,
            "Currencies",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Show or hide tracked currencies next to the character frame.")
    end

    do
        local options = Settings.CreateSliderOptions(50, 200, 5)
        ApplyRightLabel(options, function(v)
            return string.format("%d%%", v)
        end)

        local percentSetting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CURRENCIES_SCALE_PCT",
            Settings.VarType.Number,
            "Scale",
            100,
            function()
                local s = tonumber(NX.DB.system.currencies and NX.DB.system.currencies.scale) or 1.0
                return math.floor((s * 100) + 0.5)
            end,
            function(v)
                v = tonumber(v) or 100
                if v < 50 then v = 50 end
                if v > 200 then v = 200 end
                NX.DB.system.currencies = NX.DB.system.currencies or {}
                NX.DB.system.currencies.scale = v / 100
                if NX.Currencies and NX.Currencies.OnSettingsChanged then
                    NX.Currencies:OnSettingsChanged()
                end
            end
        )

        Settings.CreateSlider(category, percentSetting, options, "Adjusts the currency tracker scale.")
    end

    do
        local function GetValue()
            return not not (NX.DB.system.currencies and NX.DB.system.currencies.showBackground)
        end

        local function SetValue(v)
            NX.DB.system.currencies = NX.DB.system.currencies or {}
            NX.DB.system.currencies.showBackground = not not v
            if NX.Currencies and NX.Currencies.OnSettingsChanged then
                NX.Currencies:OnSettingsChanged()
            end
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CURRENCIES_BACKGROUND",
            Settings.VarType.Boolean,
            "Background",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Show or hide the tracker background.")
    end

    do
        local options = Settings.CreateSliderOptions(8, 32, 1)
        ApplyRightLabel(options, function(v)
            return string.format("%dpx", v)
        end)

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CURRENCIES_FONT_SIZE",
            Settings.VarType.Number,
            "Font Size",
            12,
            function()
                return math.floor((tonumber(NX.DB.system.currencies and NX.DB.system.currencies.fontSize) or 12) + 0.5)
            end,
            function(v)
                v = tonumber(v) or 12
                v = math.floor(v + 0.5)
                if v < 8 then v = 8 end
                if v > 32 then v = 32 end
                NX.DB.system.currencies = NX.DB.system.currencies or {}
                NX.DB.system.currencies.fontSize = v
                if NX.Currencies and NX.Currencies.OnSettingsChanged then
                    NX.Currencies:OnSettingsChanged()
                end
            end
        )

        Settings.CreateSlider(category, setting, options, "Adjusts the currency tracker font size.")
    end
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
            return not not (NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.enabled)
        end

        local function SetValue(v)
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            NX.DB.statsPlus.statsPlus.enabled = not not v
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
            local v = NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.style
            v = string.upper(tostring(v or "VERTICAL"))
            if v ~= "VERTICAL" and v ~= "HORIZONTAL" then
                v = "VERTICAL"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            v = string.upper(tostring(v or "VERTICAL"))
            if v ~= "VERTICAL" and v ~= "HORIZONTAL" then
                v = "VERTICAL"
            end
            NX.DB.statsPlus.statsPlus.style = v
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
            local v = NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.textAlignment
            v = string.upper(tostring(v or "LEFT"))
            if v ~= "LEFT" and v ~= "CENTER" and v ~= "RIGHT" then
                v = "LEFT"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            v = string.upper(tostring(v or "LEFT"))
            if v ~= "LEFT" and v ~= "CENTER" and v ~= "RIGHT" then
                v = "LEFT"
            end
            NX.DB.statsPlus.statsPlus.textAlignment = v
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
            local v = NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.textGrowthDirection
            v = string.upper(tostring(v or "DOWN"))
            if v ~= "UP" and v ~= "DOWN" then
                v = "DOWN"
            end
            return v
        end

        local function SetValue(v)
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            v = string.upper(tostring(v or "DOWN"))
            if v ~= "UP" and v ~= "DOWN" then
                v = "DOWN"
            end
            NX.DB.statsPlus.statsPlus.textGrowthDirection = v
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
            return tonumber(NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.fontSize) or 14
        end

        local function SetValue(v)
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            v = math.floor((tonumber(v) or 14) + 0.5)
            if v < 0 then v = 0 end
            if v > 100 then v = 100 end
            NX.DB.statsPlus.statsPlus.fontSize = v
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
            return not not (NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.positionUnlocked)
        end

        local function SetValue(v)
            if NX.StatsPlus and NX.StatsPlus.SetPositionUnlocked then
                NX.StatsPlus:SetPositionUnlocked(v, true)
            else
                NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
                NX.DB.statsPlus.statsPlus.positionUnlocked = not not v
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
                return not not (NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus[key])
            end

            local function SetValue(v)
                NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
                NX.DB.statsPlus.statsPlus[key] = not not v
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
                return not not (NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus[key])
            end

            local function SetValue(v)
                NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
                NX.DB.statsPlus.statsPlus[key] = not not v
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
            return not not (NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.unlimitedMapPinDistance)
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            NX.DB.interface.waypointTracking.unlimitedMapPinDistance = not not v
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

    do
        local function GetValue()
            return not not (NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker)
        end

        local function SetValue(v)
            NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
            NX.DB.interface.waypointTracking.highlightedQuestMarker = not not v
            if NX.WaypointTracking and NX.WaypointTracking.OnSettingsChanged then
                NX.WaypointTracking:OnSettingsChanged()
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
end

local function BuildCleanNamesInInstancesControls(category)
    local function EnsureDB()
        NX.DB.system.cleanNamesInInstances = NX.DB.system.cleanNamesInInstances or {}
        local db = NX.DB.system.cleanNamesInInstances
        if db.enabled == nil then
            db.enabled = false
        end
        if db.unitNameNPC == nil then
            if C_CVar and C_CVar.GetCVar then
                local ok, value = pcall(C_CVar.GetCVar, "UnitNameNPC")
                if ok then
                    db.unitNameNPC = (value == "1" or value == true)
                end
            end
            if db.unitNameNPC == nil then
                db.unitNameNPC = true
            end
        end
        return db
    end

    local function NotifyChanged()
        if NX.CleanNamesInInstances and NX.CleanNamesInInstances.OnSettingsChanged then
            NX.CleanNamesInInstances:OnSettingsChanged()
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
            "NEXUS_CLEAN_NAMES_ENABLED",
            Settings.VarType.Boolean,
            "Clean Names in Instances",
            false,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Applies default name cleanup CVars in instances and restores them outside instances.")
    end

    do
        local function GetValue()
            local db = EnsureDB()
            return db.unitNameNPC == true
        end

        local function SetValue(v)
            local db = EnsureDB()
            db.unitNameNPC = v and true or false
            NotifyChanged()
        end

        local setting = Settings.RegisterProxySetting(
            category,
            "NEXUS_CLEAN_NAMES_UNITNAMENPC",
            Settings.VarType.Boolean,
            "Show NPC Names",
            true,
            GetValue,
            SetValue
        )

        CreateEnabledDisabledDropdown(category, setting, "Keeps UnitNameNPC synchronized with client/server updates and addon changes.")
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
        if NX.Minimap and NX.Minimap.OnSettingsChanged then
            NX.Minimap:OnSettingsChanged()
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

local function BuildEquipmentControls(category)
    local function EnsureDB()
        NX.DB.equipment.equipment = NX.DB.equipment.equipment or {}
        local db = NX.DB.equipment.equipment
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
            return not not (NX.DB.equipment.equipment and NX.DB.equipment.equipment.positionUnlocked)
        end

        local function SetValue(v)
            if NX.Equipment and NX.Equipment.SetPositionUnlocked then
                NX.Equipment:SetPositionUnlocked(v, true)
            else
                NX.DB.equipment.equipment = NX.DB.equipment.equipment or {}
                NX.DB.equipment.equipment.positionUnlocked = not not v
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

    AddShowAnchorToggle("Action GCD Streamer", function()
        return not not (NX.DB.combat.actionGCDStreamer and NX.DB.combat.actionGCDStreamer.positionUnlocked)
    end, function(v)
        if NX.ActionGCDStreamer and NX.ActionGCDStreamer.SetPositionUnlocked then
            NX.ActionGCDStreamer:SetPositionUnlocked(v, true)
        else
            NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
            NX.DB.combat.actionGCDStreamer.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Great Vault Loot Spec", function()
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

    AddShowAnchorToggle("Utility Alerts", function()
        return not not (NX.DB.alerts.alertEvents and NX.DB.alerts.alertEvents.positionUnlocked)
    end, function(v)
        if NX.AlertEvents and NX.AlertEvents.SetPositionUnlocked then
            NX.AlertEvents:SetPositionUnlocked(v, true)
        else
            NX.DB.alerts.alertEvents = NX.DB.alerts.alertEvents or {}
            NX.DB.alerts.alertEvents.positionUnlocked = not not v
        end
    end)

    AddShowAnchorToggle("Equipment", function()
        return not not (NX.DB.equipment.equipment and NX.DB.equipment.equipment.positionUnlocked)
    end, function(v)
        if NX.Equipment and NX.Equipment.SetPositionUnlocked then
            NX.Equipment:SetPositionUnlocked(v, true)
        else
            NX.DB.equipment.equipment = NX.DB.equipment.equipment or {}
            NX.DB.equipment.equipment.positionUnlocked = not not v
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

    AddShowAnchorToggle("New Personal Order Received", function()
        return not not (NX.DB.professions.personalCraftingOrders and NX.DB.professions.personalCraftingOrders.newOrderPositionUnlocked)
    end, function(v)
        if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.SetNewOrderPositionUnlocked then
            NX.PersonalCraftingOrders:SetNewOrderPositionUnlocked(v, true)
        else
            NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
            NX.DB.professions.personalCraftingOrders.newOrderPositionUnlocked = not not v
            if NX.PersonalCraftingOrders and NX.PersonalCraftingOrders.OnSettingsChanged then
                NX.PersonalCraftingOrders:OnSettingsChanged()
            end
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
        return not not (NX.DB.statsPlus.statsPlus and NX.DB.statsPlus.statsPlus.positionUnlocked)
    end, function(v)
        if NX.StatsPlus and NX.StatsPlus.SetPositionUnlocked then
            NX.StatsPlus:SetPositionUnlocked(v, true)
        else
            NX.DB.statsPlus.statsPlus = NX.DB.statsPlus.statsPlus or {}
            NX.DB.statsPlus.statsPlus.positionUnlocked = not not v
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

    local alertsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Alerts")
    self.alertsCategoryID = alertsCategory:GetID()

    BuildUtilityAlertsControls(alertsCategory)

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
    AddSectionHeader(automationCategory, "Auction House")
    BuildAuctionHouseFilterControls(automationCategory)

    local clickableBuffsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Clickable Buffs")
    self.clickableBuffsCategoryID = clickableBuffsCategory:GetID()

    AddSectionHeader(clickableBuffsCategory, "Clickable Buffs")
    BuildClickableBuffsControls(clickableBuffsCategory)

    local combatCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Combat")
    self.combatCategoryID = combatCategory:GetID()

    AddSectionHeader(combatCategory, "Combat Logging")
    BuildAutoCombatLogControls(combatCategory)
    AddSectionHeader(combatCategory, "Action GCD Streamer")
    BuildActionGCDStreamerControls(combatCategory)
    AddSectionHeader(combatCategory, "Crosshair")
    BuildCrosshairControls(combatCategory)
    AddSectionHeader(combatCategory, "Floating Combat Text")
    BuildFloatingCombatTextControls(combatCategory)

    local currenciesCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Currency")
    self.currenciesCategoryID = currenciesCategory:GetID()

    AddSectionHeader(currenciesCategory, "Currency")
    BuildCurrenciesControls(currenciesCategory)

    local pveCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Dungeons & Raids")
    self.pveCategoryID = pveCategory:GetID()

    AddSectionHeader(pveCategory, "Great Vault Loot Spec")
    BuildGreatVaultControls(pveCategory)
    AddSectionHeader(pveCategory, "Mythic+")
    BuildMythicPlusControls(pveCategory)

    local equipmentCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Equipment")
    self.equipmentCategoryID = equipmentCategory:GetID()

    AddSectionHeader(equipmentCategory, "Equipment")
    BuildEquipmentControls(equipmentCategory)

    local gameplayCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Gameplay")
    self.gameplayCategoryID = gameplayCategory:GetID()

    AddSectionHeader(gameplayCategory, "Action Behaviour")
    BuildAutoPlaceSpellsControls(gameplayCategory)
    BuildAutoDismountControls(gameplayCategory)

    local interfaceCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Interface")
    self.interfaceCategoryID = interfaceCategory:GetID()

    AddSectionHeader(interfaceCategory, "Clean Objective Tracker")
    BuildCleanObjectiveTrackerControls(interfaceCategory)
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
    AddSectionHeader(interfaceCategory, "Clean Names in Instances")
    BuildCleanNamesInInstancesControls(interfaceCategory)

    local minimapCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Minimap")
    self.minimapCategoryID = minimapCategory:GetID()

    AddSectionHeader(minimapCategory, "Automatic Zoom")
    BuildMinimapControls(minimapCategory)
    AddSectionHeader(minimapCategory, "Waypoint Tracking")
    BuildWaypointTrackingControls(minimapCategory)

    local portalsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Portals")
    self.portalsCategoryID = portalsCategory:GetID()

    AddSectionHeader(portalsCategory, "Portals")
    BuildPortalsControls(portalsCategory)

    local professionsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Professions")
    self.professionsCategoryID = professionsCategory:GetID()

    AddSectionHeader(professionsCategory, "Simple First Craft Bonus")
    BuildSimpleFirstCraftBonusControls(professionsCategory)
    AddSectionHeader(professionsCategory, "Easy Disenchant")
    BuildEasyDisenchantControls(professionsCategory)
    BuildPersonalCraftingOrdersControls(professionsCategory)

    local settingsAnchorsCategory = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Settings & Anchors")
    self.settingsAnchorsCategoryID = settingsAnchorsCategory:GetID()

    AddSectionHeader(settingsAnchorsCategory, "General")
    BuildCommonControls(settingsAnchorsCategory)
    BuildLuaErrorsControls(settingsAnchorsCategory)
    AddSectionHeader(settingsAnchorsCategory, "Slash Commands")
    BuildSlashCommandControls(settingsAnchorsCategory)
    AddSectionHeader(settingsAnchorsCategory, "Anchors")
    BuildAnchorsControls(settingsAnchorsCategory)

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




