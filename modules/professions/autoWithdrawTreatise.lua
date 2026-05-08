local NX = Nexus

NX.AutoWithdrawTreatise = NX.AutoWithdrawTreatise or {}
do
    local M = NX.AutoWithdrawTreatise
    local frame
    local isProcessing = false

    local WITHDRAW_STEP_DELAY = 0.5
    local ACCOUNT_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Account

    local MIDNIGHT_TREATISE_BY_PROFESSION = {
        [171] = { itemID = 245755, questID = 95127 }, -- Alchemy
        [164] = { itemID = 245763, questID = 95128 }, -- Blacksmithing
        [333] = { itemID = 245759, questID = 95129 }, -- Enchanting
        [202] = { itemID = 245809, questID = 95138 }, -- Engineering
        [182] = { itemID = 245761, questID = 95130 }, -- Herbalism
        [773] = { itemID = 245757, questID = 95131 }, -- Inscription
        [755] = { itemID = 245760, questID = 95133 }, -- Jewelcrafting
        [165] = { itemID = 245758, questID = 95134 }, -- Leatherworking
        [186] = { itemID = 245762, questID = 95135 }, -- Mining
        [393] = { itemID = 245828, questID = 95136 }, -- Skinning
        [197] = { itemID = 245756, questID = 95137 }, -- Tailoring
    }

    function M:EnsureDB()
        NX.DB.professions.autoWithdrawTreatise = NX.DB.professions.autoWithdrawTreatise or {}
        local db = NX.DB.professions.autoWithdrawTreatise

        if db.enabled == nil then
            db.enabled = false
        end

        db.enabled = db.enabled and true or false
        return db
    end

    function M:IsEnabled()
        local db = self:EnsureDB()
        return db.enabled == true
    end

    local function IsQuestCompleted(questID)
        if not questID then
            return false
        end

        if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
            return C_QuestLog.IsQuestFlaggedCompleted(questID)
        end

        if IsQuestFlaggedCompleted then
            return IsQuestFlaggedCompleted(questID)
        end

        return false
    end

    local function GetActiveProfessionSkillLines()
        local active = {}

        if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
            return active
        end

        local prof1, prof2 = GetProfessions()
        for _, profIndex in ipairs({ prof1, prof2 }) do
            if profIndex then
                local _, _, _, _, _, _, skillLine = GetProfessionInfo(profIndex)
                if skillLine then
                    active[skillLine] = true
                end
            end
        end

        return active
    end

    local function FindEmptyBagSlot(reservedSlots)
        if not C_Container or not C_Container.GetContainerFreeSlots then
            return nil, nil
        end

        for bag = 0, 4 do
            local freeSlots = C_Container.GetContainerFreeSlots(bag)
            if type(freeSlots) == "table" and #freeSlots > 0 then
                for _, slot in ipairs(freeSlots) do
                    local key = bag .. "_" .. slot
                    if not reservedSlots or not reservedSlots[key] then
                        if reservedSlots then
                            reservedSlots[key] = true
                        end
                        return bag, slot
                    end
                end
            end
        end

        return nil, nil
    end

    local function ScanWarbankSlotsByItem(bankTabs, wantedItems)
        local slotsByItem = {}

        if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
            return slotsByItem
        end

        for _, bagID in ipairs(bankTabs) do
            local numSlots = C_Container.GetContainerNumSlots(bagID) or 0
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bagID, slot)
                if info and info.itemID and wantedItems[info.itemID] then
                    local slots = slotsByItem[info.itemID]
                    if not slots then
                        slots = {}
                        slotsByItem[info.itemID] = slots
                    end

                    table.insert(slots, {
                        bagID = bagID,
                        slot = slot,
                        stackCount = info.stackCount or 1,
                    })
                end
            end
        end

        return slotsByItem
    end

    local function BuildTreatiseQueue(bankTabs)
        local queue = {}

        local activeProfessionSkillLines = GetActiveProfessionSkillLines()
        if not next(activeProfessionSkillLines) then
            return queue
        end

        local wantedItems = {}
        for skillLine, data in pairs(MIDNIGHT_TREATISE_BY_PROFESSION) do
            if activeProfessionSkillLines[skillLine] and not IsQuestCompleted(data.questID) then
                local countInBags = 0
                if C_Item and C_Item.GetItemCount then
                    countInBags = C_Item.GetItemCount(data.itemID, false) or 0
                end

                if countInBags < 1 then
                    wantedItems[data.itemID] = true
                end
            end
        end

        if not next(wantedItems) then
            return queue
        end

        local slotsByItem = ScanWarbankSlotsByItem(bankTabs, wantedItems)
        for itemID in pairs(wantedItems) do
            local slots = slotsByItem[itemID]
            if slots and #slots > 0 then
                local slotData = slots[1]
                table.insert(queue, {
                    bagID = slotData.bagID,
                    slot = slotData.slot,
                    amount = 1,
                    itemID = itemID,
                })
            end
        end

        return queue
    end

    function M:ProcessWithdrawal(retry)
        if isProcessing then
            return
        end

        if not self:IsEnabled() then
            return
        end

        if not ACCOUNT_BANK_TYPE or not C_Bank or not C_Bank.CanViewBank or not C_Bank.FetchPurchasedBankTabIDs then
            return
        end

        retry = retry or 0

        if not C_Bank.CanViewBank(ACCOUNT_BANK_TYPE) then
            if retry < 6 then
                C_Timer.After(0.5, function()
                    M:ProcessWithdrawal(retry + 1)
                end)
            end
            return
        end

        local bankTabs = C_Bank.FetchPurchasedBankTabIDs(ACCOUNT_BANK_TYPE)
        if not bankTabs or #bankTabs == 0 then
            return
        end

        local queue = BuildTreatiseQueue(bankTabs)
        if #queue == 0 then
            return
        end

        isProcessing = true
        local reservedSlots = {}

        local function ProcessQueue()
            if not M:IsEnabled() then
                isProcessing = false
                return
            end

            if #queue == 0 then
                isProcessing = false
                return
            end

            local task = table.remove(queue, 1)
            local info = C_Container.GetContainerItemInfo(task.bagID, task.slot)

            if info and info.isLocked then
                table.insert(queue, 1, task)
                C_Timer.After(0.1, ProcessQueue)
                return
            end

            if info and info.itemID == task.itemID then
                if task.amount >= info.stackCount then
                    C_Container.UseContainerItem(task.bagID, task.slot)
                    C_Timer.After(WITHDRAW_STEP_DELAY, ProcessQueue)
                    return
                end

                ClearCursor()
                C_Container.SplitContainerItem(task.bagID, task.slot, task.amount)

                local attempts = 0
                local function CheckCursor()
                    local cursorType = GetCursorInfo()
                    if cursorType == "item" then
                        local emptyBag, emptySlot = FindEmptyBagSlot(reservedSlots)
                        if emptyBag and emptySlot then
                            C_Container.PickupContainerItem(emptyBag, emptySlot)
                        else
                            PutItemInBackpack()
                        end

                        C_Timer.After(WITHDRAW_STEP_DELAY, ProcessQueue)
                    elseif attempts < 20 then
                        attempts = attempts + 1
                        C_Timer.After(0.05, CheckCursor)
                    else
                        ClearCursor()
                        C_Timer.After(WITHDRAW_STEP_DELAY, ProcessQueue)
                    end
                end

                CheckCursor()
                return
            end

            C_Timer.After(WITHDRAW_STEP_DELAY, ProcessQueue)
        end

        ProcessQueue()
    end

    function M:OnSettingsChanged()
        self:EnsureDB()

        if self:IsEnabled() and BankFrame and BankFrame:IsShown() then
            C_Timer.After(0.1, function()
                M:ProcessWithdrawal(0)
            end)
        end
    end

    function M:Init()
        self:EnsureDB()

        if frame then
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("BANKFRAME_OPENED")
        frame:SetScript("OnEvent", function(_, event)
            if event == "BANKFRAME_OPENED" and M:IsEnabled() then
                C_Timer.After(0.5, function()
                    M:ProcessWithdrawal(0)
                end)
            end
        end)
    end
end
