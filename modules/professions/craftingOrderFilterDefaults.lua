local NX = Nexus

NX.CraftingOrderFilterDefaults = NX.CraftingOrderFilterDefaults or {}
do
    local M = NX.CraftingOrderFilterDefaults

    local state = {
        savedOrdersFilterSet = nil,
        customFiltersApplied = false,
    }

    local callbacksRegistered = false

    function M:EnsureDB()
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

    local function CloneFilterSet(filterSet)
        if not filterSet then
            return nil
        end

        if CopyTable then
            return CopyTable(filterSet)
        end

        local copy = {}
        for key, value in pairs(filterSet) do
            if type(value) == "table" then
                local innerCopy = {}
                for innerKey, innerValue in pairs(value) do
                    innerCopy[innerKey] = innerValue
                end
                copy[key] = innerCopy
            else
                copy[key] = value
            end
        end

        return copy
    end

    local function SafeCall(func, ...)
        if type(func) ~= "function" then
            return false
        end

        local ok = pcall(func, ...)
        return ok
    end

    local function SafeValidate(dropdown)
        if dropdown and dropdown.ValidateResetState then
            dropdown:ValidateResetState()
        end
    end

    local function ValidateFilterDropdowns(frame)
        if not frame then
            return
        end

        if frame.CraftingPage and frame.CraftingPage.RecipeList then
            SafeValidate(frame.CraftingPage.RecipeList.FilterDropdown)
        end

        if frame.OrdersPage and frame.OrdersPage.BrowseFrame and frame.OrdersPage.BrowseFrame.RecipeList then
            SafeValidate(frame.OrdersPage.BrowseFrame.RecipeList.FilterDropdown)
        end
    end

    local function SaveCurrentOrdersFilters(frame)
        if Professions and Professions.GetCurrentFilterSet then
            state.savedOrdersFilterSet = CloneFilterSet(Professions.GetCurrentFilterSet())
        elseif frame and frame.craftingOrdersFilters then
            state.savedOrdersFilterSet = CloneFilterSet(frame.craftingOrdersFilters)
        else
            state.savedOrdersFilterSet = nil
        end
    end

    local function ApplyOrdersTabFilters(frame)
        if state.customFiltersApplied or not C_TradeSkillUI then
            return
        end

        local db = M:EnsureDB()
        if not db.enabled then
            return
        end

        SaveCurrentOrdersFilters(frame)

        SafeCall(C_TradeSkillUI.SetShowLearned, db.showLearned)
        SafeCall(C_TradeSkillUI.SetOnlyShowMakeableRecipes, db.haveMaterials)
        SafeCall(C_TradeSkillUI.SetShowUnlearned, db.showUnlearned)
        SafeCall(C_TradeSkillUI.SetOnlyShowSkillUpRecipes, db.hasSkillUp)
        SafeCall(C_TradeSkillUI.SetOnlyShowFirstCraftRecipes, db.firstCraftBonus)

        if Professions and Professions.SetAllSourcesFiltered then
            SafeCall(Professions.SetAllSourcesFiltered, false)
        end

        if Professions and Professions.SetAllInventorySlotsFiltered then
            SafeCall(Professions.SetAllInventorySlotsFiltered, true)
        end

        ValidateFilterDropdowns(frame)

        if frame and frame.OrdersPage and frame.OrdersPage.RequestOrders then
            local selectedSkillLineAbility = nil
            local searchFavorites = false
            local initialNonPublicSearch = false
            SafeCall(frame.OrdersPage.RequestOrders, frame.OrdersPage, selectedSkillLineAbility, searchFavorites, initialNonPublicSearch)
        end

        state.customFiltersApplied = true
    end

    local function RestoreNormalFilters(frame, applyImmediately)
        if not state.customFiltersApplied then
            return
        end

        local savedFilterSet = state.savedOrdersFilterSet and CloneFilterSet(state.savedOrdersFilterSet) or nil

        if frame and savedFilterSet then
            frame.craftingOrdersFilters = CloneFilterSet(savedFilterSet)
        end

        if applyImmediately then
            local applyFilterSet = Professions and (Professions.ApplyFilterSet or Professions.ApplyfilterSet)
            if savedFilterSet and applyFilterSet then
                SafeCall(applyFilterSet, savedFilterSet)
            elseif Professions and Professions.SetDefaultFilters then
                local ignoreSkillLine = true
                SafeCall(Professions.SetDefaultFilters, ignoreSkillLine)
            end
        end

        state.savedOrdersFilterSet = nil
        state.customFiltersApplied = false

        ValidateFilterDropdowns(frame)
    end

    local function ResetToDefaultFilters(frame)
        RestoreNormalFilters(frame, true)

        if Professions and Professions.SetDefaultFilters then
            local ignoreSkillLine = true
            SafeCall(Professions.SetDefaultFilters, ignoreSkillLine)
        end

        ValidateFilterDropdowns(frame)
    end

    local function OnProfessionsTabSet(_, frame, tabID)
        if not frame then
            return
        end

        local ordersTabID = frame.craftingOrdersTabID
        local onOrdersTab = ordersTabID ~= nil and tabID == ordersTabID

        if onOrdersTab then
            C_Timer.After(0, function()
                if not frame:IsShown() then
                    return
                end

                if frame.GetTab and frame:GetTab() ~= ordersTabID then
                    return
                end

                ApplyOrdersTabFilters(frame)
            end)
        else
            RestoreNormalFilters(frame, true)
        end
    end

    local function OnProfessionsFrameShow(_, frame)
        ResetToDefaultFilters(frame or _G.ProfessionsFrame)
    end

    local function OnProfessionsFrameHide(_, frame)
        RestoreNormalFilters(frame or _G.ProfessionsFrame, true)
    end

    local function RegisterCallbacks()
        if callbacksRegistered then
            return
        end

        if not EventRegistry or not EventRegistry.RegisterCallback then
            return
        end

        EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", OnProfessionsTabSet)
        EventRegistry:RegisterCallback("ProfessionsFrame.Show", OnProfessionsFrameShow)
        EventRegistry:RegisterCallback("ProfessionsFrame.Hide", OnProfessionsFrameHide)

        callbacksRegistered = true
    end

    function M:OnSettingsChanged()
        self:EnsureDB()

        local frame = _G.ProfessionsFrame
        if not frame or not frame.IsShown or not frame:IsShown() then
            return
        end

        ResetToDefaultFilters(frame)

        local ordersTabID = frame.craftingOrdersTabID
        if not ordersTabID or not frame.GetTab or frame:GetTab() ~= ordersTabID then
            return
        end

        C_Timer.After(0, function()
            if not frame:IsShown() then
                return
            end

            if frame.GetTab and frame:GetTab() ~= ordersTabID then
                return
            end

            ApplyOrdersTabFilters(frame)
        end)
    end

    function M:Init()
        self:EnsureDB()
        RegisterCallbacks()
    end
end