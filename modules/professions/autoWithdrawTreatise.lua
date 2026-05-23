local NX = Nexus

NX.AutoWithdrawTreatise = NX.AutoWithdrawTreatise or {}
do
    local M = NX.AutoWithdrawTreatise
    local frame
    local isProcessing = false

    local WITHDRAW_STEP_DELAY = 0.5
    local ACCOUNT_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Account

    local MIDNIGHT_TREATISE_BY_PROFESSION = {
        [171] = { itemID = 245755, questID = 95127, midnightSkillLineID = 2906, midnightSpellID = 471003 }, -- Alchemy
        [164] = { itemID = 245763, questID = 95128, midnightSkillLineID = 2907, midnightSpellID = 471004 }, -- Blacksmithing
        [333] = { itemID = 245759, questID = 95129, midnightSkillLineID = 2909, midnightSpellID = 471006 }, -- Enchanting
        [202] = { itemID = 245809, questID = 95138, midnightSkillLineID = 2910, midnightSpellID = 471007 }, -- Engineering
        [182] = { itemID = 245761, questID = 95130, midnightSkillLineID = 2912, midnightSpellID = 471009 }, -- Herbalism
        [773] = { itemID = 245757, questID = 95131, midnightSkillLineID = 2913, midnightSpellID = 471010 }, -- Inscription
        [755] = { itemID = 245760, questID = 95133, midnightSkillLineID = 2914, midnightSpellID = 471011 }, -- Jewelcrafting
        [165] = { itemID = 245758, questID = 95134, midnightSkillLineID = 2915, midnightSpellID = 471012 }, -- Leatherworking
        [186] = { itemID = 245762, questID = 95135, midnightSkillLineID = 2916, midnightSpellID = 471013 }, -- Mining
        [393] = { itemID = 245828, questID = 95136, midnightSkillLineID = 2917, midnightSpellID = 471014 }, -- Skinning
        [197] = { itemID = 245756, questID = 95137, midnightSkillLineID = 2918, midnightSpellID = 471015 }, -- Tailoring
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

    local function GetKnownProfessionTradeSkillLines()
        local known = {}

        if not C_TradeSkillUI or type(C_TradeSkillUI.GetAllProfessionTradeSkillLines) ~= "function" then
            return known
        end

        local skillLines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if type(skillLines) ~= "table" then
            return known
        end

        for _, skillLineID in pairs(skillLines) do
            if skillLineID then
                known[skillLineID] = true
            end
        end

        return known
    end

    local function GetKnownPrimaryProfessionInfoBySkillLine()
        local infoBySkillLine = {}

        if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
            return infoBySkillLine
        end

        local prof1, prof2 = GetProfessions()
        for _, profIndex in ipairs({ prof1, prof2 }) do
            if profIndex then
                local _, _, skillLevel, maxSkillLevel, _, _, skillLineID, bonusSkill, _, _, professionName = GetProfessionInfo(profIndex)
                if skillLineID then
                    infoBySkillLine[skillLineID] = {
                        skillLevel = skillLevel or 0,
                        maxSkillLevel = maxSkillLevel or 0,
                        bonusSkill = bonusSkill or 0,
                        professionName = professionName,
                    }
                end
            end
        end

        return infoBySkillLine
    end

    local function IsSpellKnownForPlayer(spellID)
        if not spellID then
            return false
        end

        if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
            local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
            if ok and known then
                return true
            end
        end

        if C_Spell and type(C_Spell.IsSpellKnown) == "function" then
            local ok, known = pcall(C_Spell.IsSpellKnown, spellID)
            if ok and known then
                return true
            end
        end

        if type(IsPlayerSpell) == "function" and IsPlayerSpell(spellID) then
            return true
        end

        return false
    end

    local function HasRequiredMidnightSkill(baseSkillLineID, treatiseData, knownSkillLines, infoBySkillLine, primaryInfoBySkillLine)
        local midnightSkillLineID = treatiseData and treatiseData.midnightSkillLineID
        local midnightSpellID = treatiseData and treatiseData.midnightSpellID
        if not midnightSkillLineID then
            return false
        end

        local hasMidnightSkillLine = knownSkillLines[midnightSkillLineID] == true
        local isMidnightLearnedBySpell = IsSpellKnownForPlayer(midnightSpellID)
        local hasMidnightLearned = isMidnightLearnedBySpell or hasMidnightSkillLine
        local primaryProfessionInfo = primaryInfoBySkillLine[baseSkillLineID]

        if not hasMidnightLearned then
            return false
        end

        if not primaryProfessionInfo and not hasMidnightSkillLine then
            return false
        end

        local skillLevel
        local maxSkillLevel

        if hasMidnightSkillLine and C_TradeSkillUI and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) == "function" then
            local professionInfo = infoBySkillLine[midnightSkillLineID]
            if professionInfo == nil then
                professionInfo = C_TradeSkillUI.GetProfessionInfoBySkillLineID(midnightSkillLineID) or false
                infoBySkillLine[midnightSkillLineID] = professionInfo
            end

            if professionInfo ~= false then
                skillLevel = professionInfo.skillLevel
                maxSkillLevel = professionInfo.maxSkillLevel
            end
        end

        -- Match MKPT behavior: use GetProfessionInfo for live character skill values, then fallback to C_TradeSkillUI.
        if primaryProfessionInfo then
            if (primaryProfessionInfo.skillLevel or 0) > 0 then
                skillLevel = primaryProfessionInfo.skillLevel
                maxSkillLevel = primaryProfessionInfo.maxSkillLevel
            end
        end

        skillLevel = skillLevel or 0
        if skillLevel < 25 then
            return false
        end

        return true
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

        local knownSkillLines = GetKnownProfessionTradeSkillLines()
        local primaryInfoBySkillLine = GetKnownPrimaryProfessionInfoBySkillLine()
        if not next(knownSkillLines) and not next(primaryInfoBySkillLine) then
            return queue
        end

        local infoBySkillLine = {}
        local wantedItems = {}

        for baseSkillLineID, data in pairs(MIDNIGHT_TREATISE_BY_PROFESSION) do
            local hasPrimaryProfession = primaryInfoBySkillLine[baseSkillLineID] ~= nil
            local hasMidnightSkillLine = knownSkillLines[data.midnightSkillLineID] == true
            local hasMidnightLearned = hasMidnightSkillLine or IsSpellKnownForPlayer(data.midnightSpellID)

            if hasPrimaryProfession or hasMidnightLearned then
                local hasRequiredSkill = HasRequiredMidnightSkill(baseSkillLineID, data, knownSkillLines, infoBySkillLine, primaryInfoBySkillLine)

                if hasRequiredSkill and not IsQuestCompleted(data.questID) then
                    local countInBags = 0
                    if C_Item and C_Item.GetItemCount then
                        countInBags = C_Item.GetItemCount(data.itemID, false) or 0
                    end

                    if countInBags < 1 then
                        wantedItems[data.itemID] = true
                    end
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
