local NX = Nexus

NX.EnchantingVellum = NX.EnchantingVellum or {}
do
    local M = NX.EnchantingVellum
    local frame
    local button
    local initialized = false
    local pendingRefresh = false
    local createAllHooksInstalled = false

    local PROFESSIONS_ADDON_NAME = "Blizzard_Professions"
    local ENCHANTING_PROFESSION_ID = 333
    local ENCHANTING_VELLUM_ITEM_ID = 38682
    local DEFAULT_ICON_SIZE = 36
    local DEFAULT_ANCHOR_OFFSET_X = 0
    local DEFAULT_ANCHOR_OFFSET_Y = 0

    local function IsInCombat()
        return InCombatLockdown and InCombatLockdown()
    end

    local function IsAddonLoaded(name)
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            return C_AddOns.IsAddOnLoaded(name)
        end
        if IsAddOnLoaded then
            return IsAddOnLoaded(name)
        end
        return false
    end

    local function GetProfessionsFrame()
        return _G.ProfessionsFrame
    end

    local function GetCraftingPage()
        local professionsFrame = GetProfessionsFrame()
        return professionsFrame and professionsFrame.CraftingPage or nil
    end

    local function GetSchematicForm()
        local craftingPage = GetCraftingPage()
        return craftingPage and craftingPage.SchematicForm or nil
    end

    local function GetCreateButton()
        local craftingPage = GetCraftingPage()
        return craftingPage and craftingPage.CreateButton or nil
    end

    local function GetCreateAllButton()
        local craftingPage = GetCraftingPage()
        return craftingPage and craftingPage.CreateAllButton or nil
    end

    local function IsProfessionsFrameShown()
        local professionsFrame = GetProfessionsFrame()
        return professionsFrame and professionsFrame.IsShown and professionsFrame:IsShown() or false
    end

    local function IsEnchantingProfessionOpen()
        if not IsProfessionsFrameShown() then
            return false
        end

        local professionsFrame = GetProfessionsFrame()
        local getter = professionsFrame and professionsFrame.GetProfessionInfo
        if type(getter) ~= "function" then
            return false
        end

        local ok, info = pcall(getter, professionsFrame)
        if (not ok) or type(info) ~= "table" then
            ok, info = pcall(getter)
        end

        if (not ok) or type(info) ~= "table" then
            return false
        end

        return info.parentProfessionID == ENCHANTING_PROFESSION_ID
    end

    local function GetCurrentRecipeInfo()
        local schematicForm = GetSchematicForm()
        local info = schematicForm and schematicForm.currentRecipeInfo
        if type(info) == "table" then
            return info
        end
        return nil
    end

    local function IsSoulboundRecipe(recipeID)
        if not recipeID or not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeDescription then
            return false
        end

        local ok, description = pcall(C_TradeSkillUI.GetRecipeDescription, recipeID, {})
        if (not ok) or type(description) ~= "string" then
            return false
        end

        if type(ITEM_SOULBOUND) ~= "string" or ITEM_SOULBOUND == "" then
            return false
        end

        return string.find(string.lower(description), string.lower(ITEM_SOULBOUND), 1, true) ~= nil
    end

    local function HasVellumInOptionalTarget()
        local schematicForm = GetSchematicForm()
        local extraSlotFrames = schematicForm and schematicForm.extraSlotFrames
        if type(extraSlotFrames) ~= "table" then
            return false
        end

        for _, slotFrame in ipairs(extraSlotFrames) do
            local allocationItem = slotFrame and slotFrame.allocationItem
            if allocationItem and allocationItem.GetItemID then
                local ok, itemID = pcall(allocationItem.GetItemID, allocationItem)
                if ok and itemID == ENCHANTING_VELLUM_ITEM_ID then
                    return true
                end
            end
        end

        return false
    end

    local function GetCraftableCount(recipeID)
        if not recipeID or not C_TradeSkillUI or not C_TradeSkillUI.GetCraftableCount then
            return 0
        end

        local ok, count = pcall(C_TradeSkillUI.GetCraftableCount, recipeID)
        if ok and type(count) == "number" and count > 0 then
            return count
        end

        return 0
    end

    local function GetVellumCount()
        if C_Item and C_Item.GetItemCount then
            local count = C_Item.GetItemCount(ENCHANTING_VELLUM_ITEM_ID, false)
            if type(count) == "number" then
                return count
            end
        end

        if GetItemCount then
            local ok, count = pcall(GetItemCount, ENCHANTING_VELLUM_ITEM_ID, false)
            if ok and type(count) == "number" then
                return count
            end
        end

        return 0
    end

    local function GetVellumIcon()
        if C_Item and C_Item.GetItemIconByID then
            local icon = C_Item.GetItemIconByID(ENCHANTING_VELLUM_ITEM_ID)
            if icon then
                return icon
            end
        end

        return 132880
    end

    local function UpdateButtonEnabledState(enabled)
        if not button then
            return
        end

        if enabled then
            button:Enable()
            if button.icon then
                button.icon:SetDesaturated(false)
                button.icon:SetVertexColor(1, 1, 1)
            end
            if button.countText then
                button.countText:SetTextColor(1, 1, 1)
            end
        else
            button:Disable()
            if button.icon then
                button.icon:SetDesaturated(true)
                button.icon:SetVertexColor(0.8, 0.8, 0.8)
            end
            if button.countText then
                button.countText:SetTextColor(0.65, 0.65, 0.65)
            end
        end
    end

    function M:EnsureDB()
        NX.DB.professions.enchantingVellum = NX.DB.professions.enchantingVellum or {}
        local db = NX.DB.professions.enchantingVellum

        if db.enabled == nil then
            db.enabled = true
        end
        if db.iconSize == nil then
            db.iconSize = DEFAULT_ICON_SIZE
        end
        if db.anchorOffsetX == nil then
            db.anchorOffsetX = DEFAULT_ANCHOR_OFFSET_X
        end
        if db.anchorOffsetY == nil then
            db.anchorOffsetY = DEFAULT_ANCHOR_OFFSET_Y
        end

        db.enabled = db.enabled and true or false
        db.iconSize = math.floor((tonumber(db.iconSize) or DEFAULT_ICON_SIZE) + 0.5)
        if db.iconSize < 24 then db.iconSize = 24 end
        if db.iconSize > 48 then db.iconSize = 48 end
        db.iconSize = math.floor((db.iconSize / 2) + 0.5) * 2

        db.anchorOffsetX = math.floor((tonumber(db.anchorOffsetX) or DEFAULT_ANCHOR_OFFSET_X) + 0.5)
        if db.anchorOffsetX < 0 then db.anchorOffsetX = 0 end
        if db.anchorOffsetX > 20 then db.anchorOffsetX = 20 end

        db.anchorOffsetY = math.floor((tonumber(db.anchorOffsetY) or DEFAULT_ANCHOR_OFFSET_Y) + 0.5)
        if db.anchorOffsetY < 0 then db.anchorOffsetY = 0 end
        if db.anchorOffsetY > 20 then db.anchorOffsetY = 20 end

        return db
    end

    function M:IsEnabled()
        local db = self:EnsureDB()
        return db.enabled == true
    end

    function M:EnsureButton()
        if button then
            return true
        end

        if IsInCombat() then
            return false
        end

        button = CreateFrame("Button", "NexusEnchantingVellumButton", UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyUp", "AnyDown")
        button:SetAttribute("type1", "macro")
        button:SetAttribute(
            "macrotext1",
            "/run if ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.CreateButton then ProfessionsFrame.CraftingPage.CreateButton:Click() end\n/use item:" .. ENCHANTING_VELLUM_ITEM_ID
        )

        local db = self:EnsureDB()
        button:SetSize(db.iconSize, db.iconSize)
        button:SetFrameStrata("DIALOG")

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(button)
        icon:SetTexture(GetVellumIcon())
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local countText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        countText:SetText("0")
        button.countText = countText

        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(button)
        border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        button.border = border

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(button)
        button.highlight = highlight

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(ENCHANTING_VELLUM_ITEM_ID)
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
            if ShoppingTooltip1 then
                ShoppingTooltip1:Hide()
            end
        end)

        button:Hide()
        return true
    end

    function M:ApplyButtonLayout()
        if not button then
            return
        end

        local db = self:EnsureDB()
        button:SetSize(db.iconSize, db.iconSize)
    end

    function M:AnchorButton()
        if not button then
            return false
        end

        local createButton = GetCreateButton()
        if not createButton then
            return false
        end

        local db = self:EnsureDB()

        button:ClearAllPoints()
        button:SetParent(createButton)
        button:SetPoint("BOTTOMRIGHT", createButton, "TOPRIGHT", db.anchorOffsetX, db.anchorOffsetY)
        return true
    end

    function M:EvaluateButtonState()
        if not self:IsEnabled() then
            return false, false, 0
        end

        if not IsEnchantingProfessionOpen() then
            return false, false, 0
        end

        local recipeInfo = GetCurrentRecipeInfo()
        if not recipeInfo or not recipeInfo.recipeID then
            return false, false, 0
        end

        if not recipeInfo.isEnchantingRecipe then
            return false, false, 0
        end

        if HasVellumInOptionalTarget() then
            return false, false, 0
        end

        if IsSoulboundRecipe(recipeInfo.recipeID) then
            return false, false, 0
        end

        local vellumCount = GetVellumCount()
        local craftableCount = GetCraftableCount(recipeInfo.recipeID)
        local available = math.min(vellumCount, craftableCount)

        return true, (craftableCount > 0 and vellumCount > 0), available
    end

    function M:InstallCreateAllHooks()
        if createAllHooksInstalled then
            return
        end

        local createAllButton = GetCreateAllButton()
        if not createAllButton or not hooksecurefunc then
            return
        end

        hooksecurefunc(createAllButton, "Show", function()
            M:Refresh()
        end)

        hooksecurefunc(createAllButton, "Hide", function()
            M:Refresh()
        end)

        createAllHooksInstalled = true
    end

    function M:TryInitialize()
        if initialized then
            self:InstallCreateAllHooks()
            return true
        end

        if not IsAddonLoaded(PROFESSIONS_ADDON_NAME) then
            if UIParentLoadAddOn then
                pcall(UIParentLoadAddOn, PROFESSIONS_ADDON_NAME)
            end
        end

        if not IsAddonLoaded(PROFESSIONS_ADDON_NAME) then
            return false
        end

        if not GetProfessionsFrame() then
            return false
        end

        if not self:EnsureButton() then
            pendingRefresh = true
            return false
        end

        self:InstallCreateAllHooks()
        initialized = true
        return true
    end

    function M:Refresh()
        if IsInCombat() then
            pendingRefresh = true
            if button then
                UpdateButtonEnabledState(false)
            end
            return
        end

        pendingRefresh = false

        if not self:IsEnabled() then
            if button then
                button:Hide()
            end
            return
        end

        if not self:TryInitialize() then
            return
        end

        self:ApplyButtonLayout()

        local shouldShow, enabled, count = self:EvaluateButtonState()
        if not shouldShow then
            if button then
                button:Hide()
            end
            return
        end

        if not self:AnchorButton() then
            if button then
                button:Hide()
            end
            return
        end

        if button and button.icon then
            button.icon:SetTexture(GetVellumIcon())
        end
        if button and button.countText then
            button.countText:SetText(tostring(count or 0))
        end

        UpdateButtonEnabledState(enabled)
        if button then
            button:Show()
        end
    end

    function M:OnSettingsChanged()
        self:EnsureDB()
        self:Refresh()
    end

    function M:Init()
        self:EnsureDB()

        if frame then
            self:Refresh()
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("TRADE_SKILL_SHOW")
        frame:RegisterEvent("TRADE_SKILL_CLOSE")
        frame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
        frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
        frame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
        frame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")

        frame:SetScript("OnEvent", function(_, event, arg1)
            if event == "ADDON_LOADED" then
                if arg1 == PROFESSIONS_ADDON_NAME then
                    M:TryInitialize()
                    M:Refresh()
                end
                return
            end

            if event == "TRADE_SKILL_CLOSE" then
                if button and not IsInCombat() then
                    button:Hide()
                else
                    pendingRefresh = true
                end
                return
            end

            if event == "PLAYER_REGEN_DISABLED" then
                if button then
                    UpdateButtonEnabledState(false)
                end
                pendingRefresh = true
                return
            end

            if event == "PLAYER_REGEN_ENABLED" then
                if pendingRefresh then
                    M:Refresh()
                end
                return
            end

            if event == "TRADE_SKILL_SHOW"
                or event == "TRADE_SKILL_DATA_SOURCE_CHANGED"
                or event == "TRADE_SKILL_LIST_UPDATE"
                or event == "TRADE_SKILL_ITEM_CRAFTED_RESULT"
                or event == "SPELL_DATA_LOAD_RESULT"
                or event == "BAG_UPDATE_DELAYED" then
                M:Refresh()
            end
        end)

        C_Timer.After(0, function()
            M:TryInitialize()
            M:Refresh()
        end)
    end
end
