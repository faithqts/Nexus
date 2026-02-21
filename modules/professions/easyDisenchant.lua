local NX = Nexus

NX.EasyDisenchant = NX.EasyDisenchant or {}
do
    local ED = NX.EasyDisenchant
    local frame
    local button
    local hookedFrame
    local pendingReanchor = false

    local DEFAULTS = {
        enabled = true,
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
    }

    local function IsInCombat()
        return InCombatLockdown and InCombatLockdown()
    end

    local function GetSpellNameFromID(spellID)
        if C_Spell and C_Spell.GetSpellName then
            local name = C_Spell.GetSpellName(spellID)
            if type(name) == "string" and name ~= "" then
                return name
            end
        end

        if GetSpellInfo then
            local name = GetSpellInfo(spellID)
            if type(name) == "string" and name ~= "" then
                return name
            end
        end

        return "Disenchant"
    end

    local function GetSpellIconFromID(spellID)
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info and info.iconID then
                return info.iconID
            end
        end

        if GetSpellTexture then
            local ok, icon = pcall(GetSpellTexture, spellID)
            if ok and icon then
                return icon
            end
        end

        return 132853
    end

    local function PlayerKnowsSpell(spellID)
        if not spellID then
            return false
        end
        if C_SpellBook and C_SpellBook.IsSpellKnown then
            return C_SpellBook.IsSpellKnown(spellID)
        end
        if IsSpellKnown then
            return IsSpellKnown(spellID)
        end
        return false
    end

    local function HasEnchantingProfession(enchantingSkillLineID, enchantingNameSpellID)
        if not (GetProfessions and GetProfessionInfo) then
            return false
        end

        local enchantingName = (_G.PROFESSIONS_ENCHANTING)
            or GetSpellNameFromID(enchantingNameSpellID)
            or "Enchanting"

        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        for _, profIndex in ipairs({ prof1, prof2, archaeology, fishing, cooking }) do
            if profIndex then
                local name, _, _, _, _, _, skillLine = GetProfessionInfo(profIndex)
                if name then
                    if name == enchantingName then
                        return true
                    end
                    if skillLine and enchantingSkillLineID and skillLine == enchantingSkillLineID then
                        return true
                    end
                end
            end
        end

        return false
    end

    local function GetBagAnchorFrame()
        if _G.ElvUI_ContainerFrame then
            return _G.ElvUI_ContainerFrame
        end
        if _G.ContainerFrameCombinedBags then
            return _G.ContainerFrameCombinedBags
        end
        if _G.ContainerFrame1 then
            return _G.ContainerFrame1
        end
        return nil
    end

    function ED:EnsureDB()
        NX.DB.professions.easyDisenchant = NX.DB.professions.easyDisenchant or {}
        local db = NX.DB.professions.easyDisenchant

        if db.enabled == nil then db.enabled = DEFAULTS.enabled end
        if db.anchorSide == nil then db.anchorSide = DEFAULTS.anchorSide end
        if db.xOffset == nil then db.xOffset = DEFAULTS.xOffset end
        if db.yOffset == nil then db.yOffset = DEFAULTS.yOffset end
        if db.outsidePadding == nil then db.outsidePadding = DEFAULTS.outsidePadding end
        if db.size == nil then db.size = DEFAULTS.size end
        if db.iconZoom == nil then db.iconZoom = DEFAULTS.iconZoom end
        if db.alpha == nil then db.alpha = DEFAULTS.alpha end
        if db.frameStrata == nil then db.frameStrata = DEFAULTS.frameStrata end
        if db.spellID == nil then db.spellID = DEFAULTS.spellID end
        if db.enchantingSkillLineID == nil then db.enchantingSkillLineID = DEFAULTS.enchantingSkillLineID end
        if db.enchantingNameSpellID == nil then db.enchantingNameSpellID = DEFAULTS.enchantingNameSpellID end

        db.border = db.border or {}
        if db.border.enabled == nil then db.border.enabled = DEFAULTS.border.enabled end
        if db.border.size == nil then db.border.size = DEFAULTS.border.size end
        if db.border.offset == nil then db.border.offset = DEFAULTS.border.offset end
        db.border.color = db.border.color or {}
        for i = 1, 4 do
            if db.border.color[i] == nil then
                db.border.color[i] = DEFAULTS.border.color[i]
            end
        end

        db.enabled = db.enabled and true or false
        db.anchorSide = string.upper(tostring(db.anchorSide or DEFAULTS.anchorSide))
        if db.anchorSide ~= "LEFT" and db.anchorSide ~= "RIGHT" then
            db.anchorSide = "LEFT"
        end
        db.xOffset = math.floor((tonumber(db.xOffset) or DEFAULTS.xOffset) + 0.5)
        db.yOffset = math.floor((tonumber(db.yOffset) or DEFAULTS.yOffset) + 0.5)
        db.outsidePadding = math.floor((tonumber(db.outsidePadding) or DEFAULTS.outsidePadding) + 0.5)
        if db.outsidePadding < 0 then db.outsidePadding = 0 end
        db.size = math.floor((tonumber(db.size) or DEFAULTS.size) + 0.5)
        if db.size < 20 then db.size = 20 end
        if db.size > 96 then db.size = 96 end
        db.iconZoom = tonumber(db.iconZoom) or DEFAULTS.iconZoom
        if db.iconZoom < 0 then db.iconZoom = 0 end
        if db.iconZoom > 0.49 then db.iconZoom = 0.49 end
        db.alpha = tonumber(db.alpha) or DEFAULTS.alpha
        if db.alpha < 0 then db.alpha = 0 end
        if db.alpha > 1 then db.alpha = 1 end
        db.frameStrata = tostring(db.frameStrata or DEFAULTS.frameStrata)
        db.spellID = math.floor((tonumber(db.spellID) or DEFAULTS.spellID) + 0.5)
        db.enchantingSkillLineID = math.floor((tonumber(db.enchantingSkillLineID) or DEFAULTS.enchantingSkillLineID) + 0.5)
        db.enchantingNameSpellID = math.floor((tonumber(db.enchantingNameSpellID) or DEFAULTS.enchantingNameSpellID) + 0.5)

        db.border.enabled = db.border.enabled and true or false
        db.border.size = math.floor((tonumber(db.border.size) or DEFAULTS.border.size) + 0.5)
        if db.border.size < 1 then db.border.size = 1 end
        if db.border.size > 8 then db.border.size = 8 end
        db.border.offset = math.floor((tonumber(db.border.offset) or DEFAULTS.border.offset) + 0.5)
        if db.border.offset < 0 then db.border.offset = 0 end

        return db
    end

    function ED:ShouldShowButton()
        local db = self:EnsureDB()
        if not db.enabled then
            return false
        end

        if not PlayerKnowsSpell(db.spellID) then
            return false
        end

        if not HasEnchantingProfession(db.enchantingSkillLineID, db.enchantingNameSpellID) then
            return false
        end

        return true
    end

    function ED:ApplyButtonVisuals()
        if not button then
            return
        end

        local db = self:EnsureDB()
        button:SetSize(db.size, db.size)
        button:SetAlpha(db.alpha)
        button:SetFrameStrata(db.frameStrata)

        if not button.icon then
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetAllPoints(button)
        end

        button.icon:SetTexture(GetSpellIconFromID(db.spellID))
        local z = db.iconZoom
        button.icon:SetTexCoord(z, 1 - z, z, 1 - z)

        if db.border and db.border.enabled then
            if not button.border then
                button.border = CreateFrame("Frame", nil, button, "BackdropTemplate")
                button.border:SetFrameLevel(button:GetFrameLevel() + 1)
            end

            local borderOffset = tonumber(db.border.offset) or 0
            button.border:ClearAllPoints()
            button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -borderOffset, borderOffset)
            button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", borderOffset, -borderOffset)

            button.border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = db.border.size or 1,
            })

            local c = db.border.color or { 0, 0, 0, 1 }
            button.border:SetBackdropBorderColor(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
            button.border:Show()
        elseif button.border then
            button.border:Hide()
        end
    end

    function ED:AnchorButtonTo(frameToAnchor)
        if not button or not frameToAnchor then
            return
        end

        if IsInCombat() then
            pendingReanchor = true
            return
        end

        local db = self:EnsureDB()
        local pad = tonumber(db.outsidePadding) or 0
        local x = tonumber(db.xOffset) or 0
        local y = tonumber(db.yOffset) or 0

        button:ClearAllPoints()
        if db.anchorSide == "RIGHT" then
            button:SetPoint("TOPLEFT", frameToAnchor, "TOPRIGHT", pad + x, y)
        else
            button:SetPoint("TOPRIGHT", frameToAnchor, "TOPLEFT", -(pad + x), y)
        end

        button:SetParent(frameToAnchor)
        button:SetFrameStrata(db.frameStrata)
    end

    function ED:EnsureButton()
        if button then
            return true
        end

        if IsInCombat() then
            return false
        end

        local db = self:EnsureDB()
        button = CreateFrame("Button", "NexusEasyDisenchantButton", UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyDown", "AnyUp")
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", GetSpellNameFromID(db.spellID))

        self:ApplyButtonVisuals()
        button:Hide()
        return true
    end

    function ED:ShowButton()
        local db = self:EnsureDB()
        if not db.enabled then
            if button then button:Hide() end
            return
        end

        if not self:ShouldShowButton() then
            if button then button:Hide() end
            return
        end

        local bagFrame = GetBagAnchorFrame()
        if not bagFrame then
            return
        end

        if not self:EnsureButton() then
            return
        end

        self:ApplyButtonVisuals()
        self:AnchorButtonTo(bagFrame)
        button:Show()
    end

    function ED:HideButton()
        if button then
            button:Hide()
        end
    end

    function ED:HookBagFrame(frameToHook)
        if not frameToHook or frameToHook == hookedFrame then
            return
        end

        hookedFrame = frameToHook

        frameToHook:HookScript("OnShow", function()
            ED:ShowButton()
        end)
        frameToHook:HookScript("OnHide", function()
            ED:HideButton()
        end)

        if frameToHook:IsShown() then
            self:ShowButton()
        end
    end

    function ED:TryInit()
        self:EnsureDB()
        local bagFrame = GetBagAnchorFrame()
        if bagFrame then
            self:HookBagFrame(bagFrame)
            if bagFrame:IsShown() then
                self:ShowButton()
            else
                self:HideButton()
            end
            return
        end

        C_Timer.After(0.5, function()
            ED:TryInit()
        end)
    end

    function ED:Apply()
        self:EnsureDB()
        self:TryInit()

        if hookedFrame and hookedFrame:IsShown() then
            self:ShowButton()
        else
            self:HideButton()
        end
    end

    function ED:OnSettingsChanged()
        self:Apply()
    end

    function ED:SetEnabled(enabled)
        local db = self:EnsureDB()
        db.enabled = enabled and true or false
        self:Apply()
        print("|cffffd200Nexus:|r Easy Disenchant " .. (db.enabled and "enabled." or "disabled."))
    end

    function ED:Toggle()
        local db = self:EnsureDB()
        self:SetEnabled(not db.enabled)
    end

    function ED:HandleNxSlash(msg)
        local text = string.lower(tostring(msg or ""))
        text = string.match(text, "^%s*(.-)%s*$") or ""

        if text == "" or text == "toggle" then
            self:Toggle()
            return true
        end

        if text == "on" or text == "enable" or text == "enabled" then
            self:SetEnabled(true)
            return true
        end

        if text == "off" or text == "disable" or text == "disabled" then
            self:SetEnabled(false)
            return true
        end

        if text == "help" or text == "?" then
            print("|cffffd200Nexus:|r /nx disenchant, /nx disenchant on, /nx disenchant off")
            return true
        end

        print("|cffffd200Nexus:|r Unknown /nx disenchant command. Use: /nx disenchant help")
        return true
    end

    function ED:Init()
        self:EnsureDB()

        if frame then
            self:Apply()
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("SPELLS_CHANGED")
        frame:RegisterEvent("SKILL_LINES_CHANGED")

        frame:SetScript("OnEvent", function(_, event, arg1)
            if event == "PLAYER_LOGIN" then
                ED:TryInit()
                return
            end

            if event == "ADDON_LOADED" then
                ED:EnsureDB()
                if arg1 == "ElvUI" then
                    ED:TryInit()
                end
                return
            end

            if event == "PLAYER_REGEN_ENABLED" then
                if pendingReanchor then
                    pendingReanchor = false
                    if hookedFrame and hookedFrame:IsShown() then
                        ED:ShowButton()
                    end
                end
                return
            end

            if event == "SPELLS_CHANGED" or event == "SKILL_LINES_CHANGED" then
                if hookedFrame and hookedFrame:IsShown() then
                    ED:ShowButton()
                else
                    ED:HideButton()
                end
            end
        end)

        C_Timer.After(0, function()
            ED:Apply()
        end)
    end
end

