local NX = Nexus

NX.MoxieOnProfessionFrame = NX.MoxieOnProfessionFrame or {}
do
    local M = NX.MoxieOnProfessionFrame
    local FN = NX.Functions

    local frame
    local displayFrame
    local segmentPool = {}
    local hooksInstalled = false

    local DEFAULTS = {
        enabled = true,
    }

    local FONT_SIZE = 13
    local FONT_PATH_FALLBACK = "Fonts\\FRIZQT__.TTF"
    local FALLBACK_ICON = 134400
    local ICON_SIZE = 12
    local ICON_TO_TEXT_GAP = 3
    local SEGMENT_GAP = 8
    local CREATE_ALL_GAP_X = 6
    local CREATE_ALL_GAP_Y = 0

    local SKILL_LINE_TO_MOXIE_CURRENCY = {
        [171] = 3256, -- Alchemy
        [164] = 3257, -- Blacksmithing
        [333] = 3258, -- Enchanting
        [202] = 3259, -- Engineering
        [182] = 3260, -- Herbalism
        [773] = 3261, -- Inscription
        [755] = 3262, -- Jewelcrafting
        [165] = 3263, -- Leatherworking
        [186] = 3264, -- Mining
        [393] = 3265, -- Skinning
        [197] = 3266, -- Tailoring
    }

    local TRACKED_CURRENCY_IDS = {}
    for _, currencyID in pairs(SKILL_LINE_TO_MOXIE_CURRENCY) do
        TRACKED_CURRENCY_IDS[currencyID] = true
    end

    local function GetSchematicForm()
        local pf = _G.ProfessionsFrame
        return pf and pf.CraftingPage and pf.CraftingPage.SchematicForm or nil
    end

    local function GetCreateAllButton()
        local pf = _G.ProfessionsFrame
        return pf and pf.CraftingPage and pf.CraftingPage.CreateAllButton or nil
    end

    local function IsProfessionsFrameShown()
        local pf = _G.ProfessionsFrame
        return pf and pf.IsShown and pf:IsShown() or false
    end

    local function GetCurrencyQuantityAndIcon(currencyID)
        if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
            return 0, FALLBACK_ICON
        end

        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
        if not ok or type(info) ~= "table" then
            return 0, FALLBACK_ICON
        end

        return tonumber(info.quantity) or 0, tonumber(info.iconFileID) or FALLBACK_ICON
    end

    local function GetPrimaryProfessionEntries()
        local entries = {}

        if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
            return entries
        end

        local prof1, prof2 = GetProfessions()
        for _, professionIndex in ipairs({ prof1, prof2 }) do
            if professionIndex then
                local name, _, _, _, _, _, skillLine = GetProfessionInfo(professionIndex)
                local currencyID = skillLine and SKILL_LINE_TO_MOXIE_CURRENCY[skillLine] or nil
                if name and currencyID then
                    entries[#entries + 1] = {
                        name = name,
                        currencyID = currencyID,
                    }
                end
            end
        end

        return entries
    end

    local function ApplyStyledFont(fontString)
        local fontApplied = false
        if FN and FN.ApplyAddonFont then
            fontApplied = FN:ApplyAddonFont(fontString, FONT_SIZE, "OUTLINE") and true or false
        end

        if not fontApplied then
            local fontPath = FONT_PATH_FALLBACK
            if FN and FN.GetAddonFontPath then
                local customPath = FN:GetAddonFontPath()
                if type(customPath) == "string" and customPath ~= "" then
                    fontPath = customPath
                end
            end
            fontString:SetFont(fontPath, FONT_SIZE, "OUTLINE")
        end

        fontString:SetTextColor(1, 0.93, 0.75, 1)
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.9)
    end

    function M:EnsureDB()
        NX.DB.professions.moxieOnProfessionFrame = NX.DB.professions.moxieOnProfessionFrame or {}
        local db = NX.DB.professions.moxieOnProfessionFrame

        if db.enabled == nil then
            db.enabled = DEFAULTS.enabled
        end

        db.enabled = db.enabled and true or false
        return db
    end

    function M:IsEnabled()
        local db = self:EnsureDB()
        return db.enabled == true
    end

    function M:LoadProfessionUI()
        if UIParentLoadAddOn then
            pcall(UIParentLoadAddOn, "Blizzard_Professions")
        end
    end

    function M:HideDisplay()
        if displayFrame then
            displayFrame:Hide()
        end

        for _, segment in ipairs(segmentPool) do
            segment:Hide()
        end
    end

    function M:EnsureDisplayFrame()
        local schematicForm = GetSchematicForm()
        if not schematicForm then
            return nil
        end

        if displayFrame and displayFrame.GetParent and displayFrame:GetParent() ~= schematicForm then
            self:HideDisplay()
            displayFrame = nil
            segmentPool = {}
        end

        if not displayFrame then
            displayFrame = CreateFrame("Frame", nil, schematicForm)
            displayFrame:SetSize(1, 1)
        end

        return displayFrame
    end

    function M:ApplyDisplayAnchor()
        if not displayFrame then
            return
        end

        displayFrame:ClearAllPoints()

        local createAllButton = GetCreateAllButton()
        if createAllButton then
            displayFrame:SetPoint("RIGHT", createAllButton, "LEFT", -CREATE_ALL_GAP_X, CREATE_ALL_GAP_Y)
            return
        end

        local schematicForm = GetSchematicForm()
        if schematicForm then
            displayFrame:SetPoint("BOTTOMLEFT", schematicForm, "BOTTOMLEFT", 5, 2)
        end
    end

    function M:EnsureSegment(index)
        local segment = segmentPool[index]
        if segment then
            return segment
        end

        segment = CreateFrame("Frame", nil, displayFrame)

        segment.icon = segment:CreateTexture(nil, "ARTWORK")
        segment.icon:SetSize(ICON_SIZE, ICON_SIZE)
        segment.icon:SetPoint("LEFT", segment, "LEFT", 0, 0)

        segment.text = segment:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        segment.text:SetPoint("LEFT", segment.icon, "RIGHT", ICON_TO_TEXT_GAP, 0)
        segment.text:SetJustifyH("LEFT")
        segment.text:SetJustifyV("MIDDLE")
        ApplyStyledFont(segment.text)

        segmentPool[index] = segment
        return segment
    end

    function M:BuildDisplayEntries()
        local professionEntries = GetPrimaryProfessionEntries()
        local entries = {}

        for _, professionEntry in ipairs(professionEntries) do
            local amount, iconFileID = GetCurrencyQuantityAndIcon(professionEntry.currencyID)
            entries[#entries + 1] = {
                iconFileID = iconFileID,
                text = string.format("%d %s", amount, professionEntry.name),
            }
        end

        return entries
    end

    function M:UpdateDisplay()
        local host = self:EnsureDisplayFrame()
        if not host then
            return
        end

        if not self:IsEnabled() or not IsProfessionsFrameShown() then
            self:HideDisplay()
            return
        end

        local entries = self:BuildDisplayEntries()
        if #entries == 0 then
            self:HideDisplay()
            return
        end

        self:ApplyDisplayAnchor()

        local x = 0
        local maxHeight = ICON_SIZE

        for index, entry in ipairs(entries) do
            local segment = self:EnsureSegment(index)
            local label = segment.text
            local icon = segment.icon

            ApplyStyledFont(label)
            label:SetText(entry.text)
            icon:SetTexture(entry.iconFileID or FALLBACK_ICON)

            local textWidth = math.ceil(label:GetStringWidth() or 0)
            local textHeight = math.ceil(label:GetStringHeight() or FONT_SIZE)
            local segmentHeight = math.max(ICON_SIZE, textHeight)
            local segmentWidth = ICON_SIZE + ICON_TO_TEXT_GAP + textWidth

            segment:SetSize(segmentWidth, segmentHeight)
            segment:ClearAllPoints()
            segment:SetPoint("LEFT", host, "LEFT", x, 0)

            icon:ClearAllPoints()
            icon:SetPoint("LEFT", segment, "LEFT", 0, 0)

            label:ClearAllPoints()
            label:SetPoint("LEFT", icon, "RIGHT", ICON_TO_TEXT_GAP, 0)

            segment:Show()

            x = x + segmentWidth
            if index < #entries then
                x = x + SEGMENT_GAP
            end

            if segmentHeight > maxHeight then
                maxHeight = segmentHeight
            end
        end

        for index = #entries + 1, #segmentPool do
            local segment = segmentPool[index]
            if segment then
                segment:Hide()
            end
        end

        host:SetSize(math.max(1, x), math.max(1, maxHeight))
        host:Show()
    end

    function M:EnsureHooks()
        if hooksInstalled then
            return
        end

        local pf = _G.ProfessionsFrame
        if not pf then
            return
        end

        hooksInstalled = true
        if pf.HookScript then
            pf:HookScript("OnShow", function()
                M:UpdateDisplay()
            end)

            pf:HookScript("OnHide", function()
                M:HideDisplay()
            end)
        end

        local createAllButton = GetCreateAllButton()
        if createAllButton and createAllButton.HookScript then
            createAllButton:HookScript("OnShow", function()
                M:UpdateDisplay()
            end)

            createAllButton:HookScript("OnHide", function()
                M:UpdateDisplay()
            end)
        end
    end

    function M:OnSettingsChanged()
        self:UpdateDisplay()
    end

    function M:Init()
        self:EnsureDB()
        self:LoadProfessionUI()

        if frame then
            self:EnsureHooks()
            self:UpdateDisplay()
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("SKILL_LINES_CHANGED")
        frame:RegisterEvent("TRADE_SKILL_SHOW")
        frame:RegisterEvent("TRADE_SKILL_CLOSE")
        frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        frame:RegisterEvent("ADDON_LOADED")

        frame:SetScript("OnEvent", function(_, event, arg1)
            if event == "ADDON_LOADED" then
                if arg1 == "Blizzard_Professions" then
                    M:EnsureHooks()
                    C_Timer.After(0, function()
                        M:UpdateDisplay()
                    end)
                end
                return
            end

            if event == "CURRENCY_DISPLAY_UPDATE" then
                local currencyID = tonumber(arg1)
                if currencyID and not TRACKED_CURRENCY_IDS[currencyID] then
                    return
                end
            end

            M:EnsureHooks()

            if event == "TRADE_SKILL_SHOW" then
                C_Timer.After(0, function()
                    M:UpdateDisplay()
                end)
                C_Timer.After(0.15, function()
                    M:UpdateDisplay()
                end)
                return
            end

            M:UpdateDisplay()
        end)

        C_Timer.After(0, function()
            M:EnsureHooks()
            M:UpdateDisplay()
        end)
    end
end