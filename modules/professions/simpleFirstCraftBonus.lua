local NX = Nexus

NX.SimpleFirstCraftBonus = NX.SimpleFirstCraftBonus or {}
do
    local M = NX.SimpleFirstCraftBonus
    local frame

    local hooked = {
        craftingRecipes = false,
        browseRecipes = false,
        browseOrders = false,
    }

    local ATLAS_FIRST_CRAFT = "professions_icon_firsttimecraft"

    function M:EnsureDB()
        NX.DB.professions.simpleFirstCraftBonus = NX.DB.professions.simpleFirstCraftBonus or {}
        local db = NX.DB.professions.simpleFirstCraftBonus
        if db.enabled == nil then
            db.enabled = true
        end
        return db
    end

    local function IsEnabled()
        local db = M:EnsureDB()
        return db.enabled == true
    end

    local function IsFirstCraftRecipe(recipeID)
        if not recipeID then
            return false
        end

        if C_TradeSkillUI and C_TradeSkillUI.IsRecipeFirstCraft then
            local ok, result = pcall(C_TradeSkillUI.IsRecipeFirstCraft, recipeID)
            if ok and result ~= nil then
                return result and true or false
            end
        end

        if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
            local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
            if ok and type(info) == "table" then
                return info.firstCraft == true
            end
        end

        return false
    end

    local function GetRowTextAnchor(row)
        if not row then
            return nil
        end

        if row.Count then
            return row.Count
        end

        if row.Label then
            return row.Label
        end

        if row.Name then
            return row.Name
        end

        return row
    end

    local function EnsureIcon(row)
        if not row or not row.CreateTexture then
            return nil
        end

        row._nxSimpleFirstCraftIcon = row._nxSimpleFirstCraftIcon or row:CreateTexture(nil, "OVERLAY", nil, 7)
        local icon = row._nxSimpleFirstCraftIcon
        local textAnchor = GetRowTextAnchor(row)
        if icon.SetAtlas then
            icon:SetAtlas(ATLAS_FIRST_CRAFT, true)
        end
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", textAnchor, "RIGHT", 5, -1)
        icon:SetScale(0.65)
        return icon
    end

    local function HideIcon(row)
        if row and row._nxSimpleFirstCraftIcon and row._nxSimpleFirstCraftIcon.Hide then
            row._nxSimpleFirstCraftIcon:Hide()
        end
    end

    local function GetRecipeIDFromElementData(elementData)
        if type(elementData) ~= "table" then
            return nil
        end

        if elementData.data and elementData.data.recipeInfo and elementData.data.recipeInfo.recipeID then
            return elementData.data.recipeInfo.recipeID
        end

        if elementData.recipeInfo and elementData.recipeInfo.recipeID then
            return elementData.recipeInfo.recipeID
        end

        if elementData.recipeID then
            return elementData.recipeID
        end

        if elementData.option and elementData.option.recipeID then
            return elementData.option.recipeID
        end

        if elementData.option and elementData.option.skillLineAbilityID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfoForSkillLineAbility then
            local info = C_TradeSkillUI.GetRecipeInfoForSkillLineAbility(elementData.option.skillLineAbilityID)
            if info and info.recipeID then
                return info.recipeID
            end
        end

        return nil
    end

    local function UpdateRecipeRow(row, enabled)
        if not row then
            return
        end

        if not enabled then
            HideIcon(row)
            return
        end

        local elementData = row.GetElementData and row:GetElementData()
        local recipeID = GetRecipeIDFromElementData(elementData)
        if not recipeID then
            HideIcon(row)
            return
        end

        local icon = EnsureIcon(row)
        if not icon then
            return
        end

        if IsFirstCraftRecipe(recipeID) then
            icon:Show()
        else
            icon:Hide()
        end
    end

    local function GetOrderRowRecipeID(row)
        if not row then
            return nil
        end

        local rowData = row.rowData
        if type(rowData) ~= "table" then
            return nil
        end

        if rowData.option and rowData.option.recipeID then
            return rowData.option.recipeID
        end

        local skillLineAbilityID = rowData.option and rowData.option.skillLineAbilityID
        if skillLineAbilityID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfoForSkillLineAbility then
            local info = C_TradeSkillUI.GetRecipeInfoForSkillLineAbility(skillLineAbilityID)
            if info and info.recipeID then
                return info.recipeID
            end
        end

        return nil
    end

    local function UpdateOrderRow(row, enabled)
        if not row then
            return
        end

        if not enabled then
            HideIcon(row)
            return
        end

        local recipeID = GetOrderRowRecipeID(row)
        if not recipeID then
            HideIcon(row)
            return
        end

        local icon = EnsureIcon(row)
        if not icon then
            return
        end

        if IsFirstCraftRecipe(recipeID) then
            icon:Show()
        else
            icon:Hide()
        end
    end

    local function IterateRows(listFrame, callback)
        if not listFrame or not listFrame.ScrollBox then
            return
        end

        local scrollBox = listFrame.ScrollBox

        if scrollBox.ScrollTarget then
            for _, row in ipairs({ scrollBox.ScrollTarget:GetChildren() }) do
                if type(row) == "table" and row.GetObjectType and row:GetObjectType() == "Frame" then
                    callback(row)
                end
            end
        end

        if scrollBox.GetView then
            local view = scrollBox:GetView()
            if view and type(view.frames) == "table" then
                for _, row in ipairs(view.frames) do
                    callback(row)
                end
            end
        end
    end

    function M:RefreshCraftingRecipeList()
        local pf = _G.ProfessionsFrame
        local listFrame = pf and pf.CraftingPage and pf.CraftingPage.RecipeList
        local enabled = IsEnabled()

        IterateRows(listFrame, function(row)
            UpdateRecipeRow(row, enabled)
        end)
    end

    function M:RefreshBrowseRecipeList()
        local pf = _G.ProfessionsFrame
        local listFrame = pf and pf.OrdersPage and pf.OrdersPage.BrowseFrame and pf.OrdersPage.BrowseFrame.RecipeList
        local enabled = IsEnabled()

        IterateRows(listFrame, function(row)
            UpdateRecipeRow(row, enabled)
        end)
    end

    function M:RefreshBrowseOrderList()
        local pf = _G.ProfessionsFrame
        local listFrame = pf and pf.OrdersPage and pf.OrdersPage.BrowseFrame and pf.OrdersPage.BrowseFrame.OrderList
        local enabled = IsEnabled()

        IterateRows(listFrame, function(row)
            UpdateOrderRow(row, enabled)
        end)
    end

    function M:RefreshAll()
        self:RefreshCraftingRecipeList()
        self:RefreshBrowseRecipeList()
        self:RefreshBrowseOrderList()
    end

    local function HookScrollBoxUpdate(scrollBox, key, callback)
        if hooked[key] then
            return
        end
        if not scrollBox or not hooksecurefunc then
            return
        end

        hooksecurefunc(scrollBox, "Update", callback)
        hooked[key] = true
    end

    function M:EnsureHooks()
        local pf = _G.ProfessionsFrame
        if not pf then
            return
        end

        local craftingBox = pf.CraftingPage and pf.CraftingPage.RecipeList and pf.CraftingPage.RecipeList.ScrollBox
        HookScrollBoxUpdate(craftingBox, "craftingRecipes", function()
            M:RefreshCraftingRecipeList()
        end)

        local browseRecipesBox = pf.OrdersPage and pf.OrdersPage.BrowseFrame and pf.OrdersPage.BrowseFrame.RecipeList and pf.OrdersPage.BrowseFrame.RecipeList.ScrollBox
        HookScrollBoxUpdate(browseRecipesBox, "browseRecipes", function()
            M:RefreshBrowseRecipeList()
        end)

        local browseOrdersBox = pf.OrdersPage and pf.OrdersPage.BrowseFrame and pf.OrdersPage.BrowseFrame.OrderList and pf.OrdersPage.BrowseFrame.OrderList.ScrollBox
        HookScrollBoxUpdate(browseOrdersBox, "browseOrders", function()
            M:RefreshBrowseOrderList()
        end)
    end

    function M:LoadProfessionUIs()
        if C_AddOns and C_AddOns.LoadAddOn then
            if not (C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_Professions")) then
                pcall(C_AddOns.LoadAddOn, "Blizzard_Professions")
            end
            if not (C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_ProfessionsCustomerOrders")) then
                pcall(C_AddOns.LoadAddOn, "Blizzard_ProfessionsCustomerOrders")
            end
        end
    end

    function M:Apply()
        self:EnsureDB()
        self:EnsureHooks()
        self:RefreshAll()
    end

    function M:OnSettingsChanged()
        self:Apply()
    end

    function M:Init()
        self:EnsureDB()

        if frame then
            self:Apply()
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("TRADE_SKILL_SHOW")
        frame:SetScript("OnEvent", function(_, event, addonName)
            if event == "ADDON_LOADED" then
                if addonName == "Blizzard_Professions" or addonName == "Blizzard_ProfessionsCustomerOrders" then
                    self:EnsureHooks()
                    self:RefreshAll()
                end
                return
            end

            self:LoadProfessionUIs()
            C_Timer.After(0, function()
                self:Apply()
            end)
        end)

        C_Timer.After(0, function()
            self:Apply()
        end)
    end
end

