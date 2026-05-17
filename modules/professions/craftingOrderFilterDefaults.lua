local NX = Nexus

NX.CraftingOrderFilterDefaults = NX.CraftingOrderFilterDefaults or {}
do
    local M = NX.CraftingOrderFilterDefaults

    local state = {
        savedOrdersFilterSet = nil,
        customFiltersApplied = false,
        awaitingInitialOpenTab = false,
        openSearchTriggered = false,
        openCycle = 0,
        frameShownAt = 0,
        openedOnOrders = nil,
        openDetectionExpiry = 0,
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

    local function IsOnOrdersTab(frame)
        if not frame then
            return false
        end

        local ordersTabID = frame.craftingOrdersTabID
        if not ordersTabID then
            return false
        end

        if frame.GetTab then
            return frame:GetTab() == ordersTabID
        end

        return false
    end

    local function GetActiveTabID(frame)
        if not frame or not frame.GetTab then
            return nil
        end

        local ok, tabID = pcall(frame.GetTab, frame)
        if ok then
            return tabID
        end

        return nil
    end

    local function TriggerOrdersSearch(frame)
        if not frame or not frame.IsShown or not frame:IsShown() then
            return false
        end

        if not IsOnOrdersTab(frame) then
            return false
        end

        local ordersPage = frame.OrdersPage
        local searchButton = ordersPage and ordersPage.BrowseFrame and ordersPage.BrowseFrame.SearchButton

        if searchButton then
            if searchButton.Click and SafeCall(searchButton.Click, searchButton) then
                return true
            end

            local onClick = searchButton.GetScript and searchButton:GetScript("OnClick")
            if onClick and SafeCall(onClick, searchButton, "LeftButton", false) then
                return true
            end
        end

        if ordersPage and ordersPage.RequestOrders then
            local selectedSkillLineAbility = nil
            local searchFavorites = false
            local initialNonPublicSearch = false
            return SafeCall(ordersPage.RequestOrders, ordersPage, selectedSkillLineAbility, searchFavorites, initialNonPublicSearch)
        end

        return false
    end

    local function ScheduleOpenOrdersSearch(frame)
        if not frame or state.openSearchTriggered then
            return
        end

        local function TrySearch(markTriggered)
            if markTriggered and state.openSearchTriggered then
                return
            end

            if TriggerOrdersSearch(frame) and markTriggered then
                state.openSearchTriggered = true
            end
        end

        local function ForceLateRefresh()
            if not frame.IsShown or not frame:IsShown() then
                return
            end

            if not IsOnOrdersTab(frame) then
                return
            end

            if TriggerOrdersSearch(frame) then
                state.openSearchTriggered = true
            end
        end

        C_Timer.After(0, function()
            TrySearch(true)
        end)

        C_Timer.After(0.18, function()
            TrySearch(true)
        end)

        -- Blizzard calls StartDefaultSearch during Orders page startup, which can restore the
        -- "no favorites" state for public orders. Do one final refresh after startup settles.
        C_Timer.After(0.85, ForceLateRefresh)
    end

    local function IsOpenOnOrdersAllowed(frame)
        if state.openedOnOrders == true then
            return true
        end

        if state.openedOnOrders == false then
            return false
        end

        local now = GetTime and GetTime() or 0
        if now > (state.openDetectionExpiry or 0) then
            state.openedOnOrders = false
            return false
        end

        local activeTabID = GetActiveTabID(frame)
        if activeTabID == nil then
            return false
        end

        local ordersTabID = frame and frame.craftingOrdersTabID
        local openedOnOrders = ordersTabID ~= nil and activeTabID == ordersTabID
        state.openedOnOrders = openedOnOrders
        return openedOnOrders
    end

    local function MarkOpenStartingTab(frame)
        local activeTabID = GetActiveTabID(frame)
        local ordersTabID = frame and frame.craftingOrdersTabID

        if activeTabID == nil or ordersTabID == nil then
            state.openedOnOrders = nil
            return
        end

        state.openedOnOrders = (activeTabID == ordersTabID)
    end

    local function BuildCustomOrdersFilterSet(frame, db)
        local filterSet = nil

        if frame and frame.craftingOrdersFilters then
            filterSet = CloneFilterSet(frame.craftingOrdersFilters)
        elseif Professions and Professions.GetCurrentFilterSet then
            filterSet = CloneFilterSet(Professions.GetCurrentFilterSet())
        else
            filterSet = {}
        end

        if type(filterSet.textFilter) ~= "string" then
            filterSet.textFilter = ""
        end

        if filterSet.sourceTypeFilter == nil and C_TradeSkillUI and C_TradeSkillUI.GetSourceTypeFilter then
            local ok, sourceTypeFilter = pcall(C_TradeSkillUI.GetSourceTypeFilter)
            if ok then
                filterSet.sourceTypeFilter = sourceTypeFilter
            end
        end
        if filterSet.sourceTypeFilter == nil then
            filterSet.sourceTypeFilter = 0
        end

        if type(filterSet.invTypeFilters) ~= "table" then
            filterSet.invTypeFilters = {}
        end

        filterSet.showLearned = db.showLearned
        filterSet.showUnlearned = db.showUnlearned
        filterSet.showOnlyMakeable = db.haveMaterials
        filterSet.showOnlySkillUps = db.hasSkillUp
        filterSet.showOnlyFirstCraft = db.firstCraftBonus

        return filterSet
    end

    local function ApplyFilterSet(filterSet, frame)
        local applyFilterSet = Professions and (Professions.ApplyFilterSet or Professions.ApplyfilterSet)

        if frame and filterSet then
            frame.craftingOrdersFilters = CloneFilterSet(filterSet)
        end

        if filterSet and applyFilterSet then
            local ok = SafeCall(applyFilterSet, filterSet)
            if ok then
                return true
            end
        end

        if C_TradeSkillUI and filterSet then
            if C_TradeSkillUI.SetRecipeItemNameFilter and type(filterSet.textFilter) == "string" then
                SafeCall(C_TradeSkillUI.SetRecipeItemNameFilter, filterSet.textFilter)
            end
            SafeCall(C_TradeSkillUI.SetShowLearned, filterSet.showLearned and true or false)
            SafeCall(C_TradeSkillUI.SetShowUnlearned, filterSet.showUnlearned and true or false)
            SafeCall(C_TradeSkillUI.SetOnlyShowMakeableRecipes, filterSet.showOnlyMakeable and true or false)
            SafeCall(C_TradeSkillUI.SetOnlyShowSkillUpRecipes, filterSet.showOnlySkillUps and true or false)
            SafeCall(C_TradeSkillUI.SetOnlyShowFirstCraftRecipes, filterSet.showOnlyFirstCraft and true or false)

            if C_TradeSkillUI.SetSourceTypeFilter and type(filterSet.sourceTypeFilter) == "number" then
                SafeCall(C_TradeSkillUI.SetSourceTypeFilter, filterSet.sourceTypeFilter)
            end

            if type(filterSet.invTypeFilters) == "table" and C_TradeSkillUI.SetInventorySlotFilter then
                for idx, filtered in ipairs(filterSet.invTypeFilters) do
                    SafeCall(C_TradeSkillUI.SetInventorySlotFilter, idx, not (filtered and true or false))
                end
            end

            return true
        end

        return false
    end

    local function ApplyOrdersTabFilters(frame, forceApply, requestOrders)
        if (state.customFiltersApplied and not forceApply) or not C_TradeSkillUI then
            return
        end

        if requestOrders == nil then
            requestOrders = true
        end

        local db = M:EnsureDB()
        if not db.enabled then
            return
        end

        if not state.customFiltersApplied then
            SaveCurrentOrdersFilters(frame)
        end

        local customFilterSet = BuildCustomOrdersFilterSet(frame, db)
        ApplyFilterSet(customFilterSet, frame)

        if C_TradeSkillUI.SetOnlyShowAvailableForOrders then
            SafeCall(C_TradeSkillUI.SetOnlyShowAvailableForOrders, db.haveMaterials)
        end

        ValidateFilterDropdowns(frame)

        if requestOrders and frame and frame.OrdersPage and frame.OrdersPage.RequestOrders then
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
            if savedFilterSet then
                ApplyFilterSet(savedFilterSet, frame)
            elseif Professions and Professions.SetDefaultFilters then
                local ignoreSkillLine = true
                SafeCall(Professions.SetDefaultFilters, ignoreSkillLine)
            end
        end

        if C_TradeSkillUI and C_TradeSkillUI.SetOnlyShowAvailableForOrders then
            SafeCall(C_TradeSkillUI.SetOnlyShowAvailableForOrders, false)
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

    local function ScheduleOrdersTabFilterApply(frame, requestOrders)
        if not frame then
            return
        end

        local function ApplyIfReady(forceApply, shouldRequestOrders)
            if not frame.IsShown or not frame:IsShown() then
                return
            end

            if not IsOnOrdersTab(frame) then
                return
            end

            ApplyOrdersTabFilters(frame, forceApply, shouldRequestOrders)
        end

        C_Timer.After(0, function()
            ApplyIfReady(false, requestOrders)
        end)

        -- Blizzard orders page toggles some flags during OnShow/next-frame startup.
        -- A second forced pass keeps Nexus settings authoritative after that initialization.
        C_Timer.After(0.15, function()
            ApplyIfReady(true, false)
        end)
    end

    local function OnProfessionsTabSet(_, frame, tabID)
        if not frame then
            return
        end

        local ordersTabID = frame.craftingOrdersTabID
        local onOrdersTab = ordersTabID ~= nil and tabID == ordersTabID

        if onOrdersTab then
            ScheduleOrdersTabFilterApply(frame, false)

            if state.awaitingInitialOpenTab and not state.openSearchTriggered and IsOpenOnOrdersAllowed(frame) then
                ScheduleOpenOrdersSearch(frame)
            end

            state.awaitingInitialOpenTab = false
        else
            RestoreNormalFilters(frame, true)

            if state.awaitingInitialOpenTab and state.openedOnOrders == nil then
                state.openedOnOrders = false
            end

            state.awaitingInitialOpenTab = false
        end
    end

    local function OnProfessionsFrameShow(_, frame)
        local professionsFrame = frame or _G.ProfessionsFrame

        state.openCycle = state.openCycle + 1
        local thisOpenCycle = state.openCycle
        state.frameShownAt = GetTime and GetTime() or 0
        state.awaitingInitialOpenTab = true
        state.openSearchTriggered = false
        state.openedOnOrders = nil
        state.openDetectionExpiry = (GetTime and GetTime() or 0) + 0.4

        MarkOpenStartingTab(professionsFrame)

        ResetToDefaultFilters(professionsFrame)

        local function TryInitialOpenSearch(forceFinalize)
            if state.openCycle ~= thisOpenCycle then
                return
            end

            if state.openSearchTriggered then
                return
            end

            if not professionsFrame.IsShown or not professionsFrame:IsShown() then
                return
            end

            if IsOpenOnOrdersAllowed(professionsFrame) then
                ScheduleOpenOrdersSearch(professionsFrame)
                state.awaitingInitialOpenTab = false
                return
            end

            if forceFinalize then
                state.awaitingInitialOpenTab = false
                if state.openedOnOrders == nil then
                    state.openedOnOrders = false
                end
            end
        end

        TryInitialOpenSearch(false)
        C_Timer.After(0.2, function()
            TryInitialOpenSearch(false)
        end)
        C_Timer.After(0.5, function()
            TryInitialOpenSearch(true)
        end)

        -- End the "initial open" window after startup has settled.
        C_Timer.After(1.0, function()
            if state.openCycle ~= thisOpenCycle then
                return
            end

            state.awaitingInitialOpenTab = false
            if state.openedOnOrders == nil then
                state.openedOnOrders = false
            end
        end)

        if IsOnOrdersTab(professionsFrame) then
            ScheduleOrdersTabFilterApply(professionsFrame, false)
        end
    end

    local function OnProfessionsFrameHide(_, frame)
        RestoreNormalFilters(frame or _G.ProfessionsFrame, true)
        state.awaitingInitialOpenTab = false
        state.openSearchTriggered = false
        state.frameShownAt = 0
        state.openedOnOrders = nil
        state.openDetectionExpiry = 0
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

        ScheduleOrdersTabFilterApply(frame, false)
    end

    function M:Init()
        self:EnsureDB()
        RegisterCallbacks()
    end
end