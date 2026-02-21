local NX = Nexus
NX.MythicPlus = NX.MythicPlus or {}
local MP = NX.MythicPlus
local FN = NX.Functions

MP.KEYSTONE_ITEM_IDS = {
    151086, 168195, 168197, 168196, 158923, 187786, 180653, 138019
}

MP.KEY_LINK_ITEM_ID_SET = {
    [186159] = true,
    [180653] = true,
    [158923] = true,
    [138019] = true,
    [187786] = true,
    [151086] = true,
}

MP.countdownEndsAt = MP.countdownEndsAt or 0
MP.pendingAfterCombat = MP.pendingAfterCombat or false
MP.lastKeysTriggerTime = MP.lastKeysTriggerTime or 0
MP.objectiveTrackerInitialShown = MP.objectiveTrackerInitialShown
MP.objectiveTrackerRestoreTimer = MP.objectiveTrackerRestoreTimer

MP.watcher = MP.watcher or CreateFrame("Frame")
MP.watcher:Hide()
MP.watcher.elapsed = 0

function MP:EnsureDB()
    NX.DB.dungeonsRaids.mythicPlus = NX.DB.dungeonsRaids.mythicPlus or {}
    local db = NX.DB.dungeonsRaids.mythicPlus
    if db.respondToKeys == nil then db.respondToKeys = true end
    if db.autoHideObjectives == nil then db.autoHideObjectives = false end
    if db.keysResponderCooldownSeconds == nil then db.keysResponderCooldownSeconds = 5 end
    if db.objectiveTrackerRestoreDelaySeconds == nil then db.objectiveTrackerRestoreDelaySeconds = 30 end
end

function MP:GetObjectiveTrackerRestoreDelaySeconds()
    self:EnsureDB()
    local delay = tonumber(NX.DB.dungeonsRaids.mythicPlus.objectiveTrackerRestoreDelaySeconds) or 30
    delay = math.floor(delay + 0.5)
    if delay < 0 then delay = 0 end
    if delay > 120 then delay = 120 end
    return delay
end

function MP:CancelObjectiveTrackerRestoreTimer()
    if self.objectiveTrackerRestoreTimer then
        self.objectiveTrackerRestoreTimer:Cancel()
        self.objectiveTrackerRestoreTimer = nil
    end
end

function MP:CaptureObjectiveTrackerInitialState()
    if self.objectiveTrackerInitialShown ~= nil then return end
    local obj = ObjectiveTrackerFrame
    if not obj then return end
    self.objectiveTrackerInitialShown = obj:IsShown() and true or false
end

function MP:RestoreObjectiveTrackerInitialState()
    local obj = ObjectiveTrackerFrame
    if not obj then return end
    local initialShown = self.objectiveTrackerInitialShown
    if initialShown == nil then return end

    if initialShown then
        obj:Show()
    else
        obj:Hide()
    end

    self.objectiveTrackerInitialShown = nil
end

function MP:ScheduleObjectiveTrackerRestore()
    self:CancelObjectiveTrackerRestoreTimer()

    local delay = self:GetObjectiveTrackerRestoreDelaySeconds()
    self.objectiveTrackerRestoreTimer = C_Timer.NewTimer(delay, function()
        self.objectiveTrackerRestoreTimer = nil
        self:RestoreObjectiveTrackerInitialState()
    end)
end

function MP:InChallengeCountdown()
    return self.countdownEndsAt > 0 and GetTime() <= self.countdownEndsAt
end

function MP:StartWatcher()
    self.watcher.elapsed = 0
    self.watcher:Show()
end

function MP:StopWatcher()
    self.watcher.elapsed = 0
    self.watcher:Hide()
end

function MP:FindKeyLinksInBags()
    local links = {}

    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and self.KEY_LINK_ITEM_ID_SET[itemID] then
                local link = C_Container.GetContainerItemLink(bag, slot)
                if link then
                    links[#links + 1] = link
                end
            end
        end
    end

    return links
end

function MP:IsKeysCommand(msg)
    if type(msg) ~= "string" then return false end
    msg = msg:lower():match("^%s*(.-)%s*$")
    return msg == "!keys"
end

function MP:CanTriggerKeysResponse()
    self:EnsureDB()

    local cooldown = tonumber(NX.DB.dungeonsRaids.mythicPlus.keysResponderCooldownSeconds) or 5
    cooldown = math.floor(cooldown + 0.5)
    if cooldown < 1 then cooldown = 1 end
    if cooldown > 10 then cooldown = 10 end

    local now = GetTime()
    if (now - (self.lastKeysTriggerTime or 0)) < cooldown then
        return false
    end
    self.lastKeysTriggerTime = now
    return true
end

function MP:ReportKeysToParty()
    local links = self:FindKeyLinksInBags()
    if not links or #links == 0 then return end

    for i = 1, #links do
        SendChatMessage(links[i], "PARTY")
    end
end

function MP:ApplyObjectiveTrackerVisibility(event)
    self:EnsureDB()

    local obj = ObjectiveTrackerFrame
    if not obj then return end

    if not NX.DB.dungeonsRaids.mythicPlus.autoHideObjectives then
        self:CancelObjectiveTrackerRestoreTimer()
        self:RestoreObjectiveTrackerInitialState()
        return
    end

    local inDungeon = FN and FN.IsInDungeonInstance and FN:IsInDungeonInstance()
    if inDungeon then
        self:CancelObjectiveTrackerRestoreTimer()
        self:CaptureObjectiveTrackerInitialState()
        obj:Hide()
    else
        self:ScheduleObjectiveTrackerRestore()
    end
end

function MP:TryAutoSlotKeystone()
    if not FN or FN:InRestrictiveEnvironment() then return end
    if not NX.DB.dungeonsRaids.keyHelpers.autoInsertKeystone then return end
    if not FN:IsKeystoneFrameVisible() then return end
    if InCombatLockdown() then return end
    if CursorHasItem() then return end

    if not FN:KeystoneMatchesCurrentDungeon() then return end

    if not C_ChallengeMode or not C_ChallengeMode.GetSlottedKeystoneInfo or not C_ChallengeMode.SlotKeystone then
        return
    end

    local slottedMapID = C_ChallengeMode.GetSlottedKeystoneInfo()
    if slottedMapID ~= nil then
        return
    end

    local itemID = FN:FindKeystoneInBags(self.KEYSTONE_ITEM_IDS)
    if not itemID then return end

    PickupItem(itemID)
    if CursorHasItem() then
        C_ChallengeMode.SlotKeystone()
        ClearCursor()
    end
end

function MP:PlayerCanMarkTargets()
    if not IsInGroup() then return false end
    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end
    return true
end

function MP:CanAutoMark()
    local style = NX.DB.dungeonsRaids.keyHelpers.markingStyle
    if style == "never" then return false end
    if style == "always" then return true end
    return UnitIsGroupLeader("player") == true
end

function MP:GetGroupUnits()
    local units = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup() then
        units[#units + 1] = "player"
        for i = 1, 4 do
            local u = "party" .. i
            if UnitExists(u) then
                units[#units + 1] = u
            end
        end
    end

    return units
end

function MP:ApplyRoleMarkers()
    if not FN or FN:InRestrictiveEnvironment() then return end
    if not FN:IsKeystoneFrameVisible() then return end
    if not FN:IsInDungeonInstance() then return end
    if not self:InChallengeCountdown() then return end
    if not self:CanAutoMark() then return end
    if not self:PlayerCanMarkTargets() then return end

    if InCombatLockdown() then
        self.pendingAfterCombat = true
        return
    end

    local tankMarker = NX.DB.dungeonsRaids.keyHelpers.tankMarker
    local healerMarker = NX.DB.dungeonsRaids.keyHelpers.healerMarker

    for _, unit in ipairs(self:GetGroupUnits()) do
        local role = UnitGroupRolesAssigned(unit)
        local current = GetRaidTargetIndex(unit)

        if role == "TANK" and tankMarker then
            if current ~= tankMarker then
                SetRaidTarget(unit, tankMarker)
            end
        elseif role == "HEALER" and healerMarker then
            if current ~= healerMarker then
                SetRaidTarget(unit, healerMarker)
            end
        end
    end
end

MP.watcher:SetScript("OnUpdate", function(_, elapsed)
    MP.watcher.elapsed = MP.watcher.elapsed + elapsed
    if MP.watcher.elapsed < 0.25 then return end
    MP.watcher.elapsed = 0

    if not FN or FN:InRestrictiveEnvironment() or not FN:IsKeystoneFrameVisible() or not MP:InChallengeCountdown() then
        MP:StopWatcher()
        return
    end

    MP:ApplyRoleMarkers()
end)

function MP:OnKeystoneFrameShown()
    C_Timer.After(0, function()
        if not FN or FN:InRestrictiveEnvironment() then return end

        self:TryAutoSlotKeystone()

        if self:InChallengeCountdown() then
            self:StartWatcher()
            self:ApplyRoleMarkers()
        end
    end)
end

function MP:HookKeystoneFrame()
    if not ChallengesKeystoneFrame or ChallengesKeystoneFrame.__NEXUSHooked then return end

    ChallengesKeystoneFrame:HookScript("OnShow", function() self:OnKeystoneFrameShown() end)
    ChallengesKeystoneFrame:HookScript("OnHide", function() self:StopWatcher() end)

    ChallengesKeystoneFrame.__NEXUSHooked = true
end

function MP:Init()
    self:EnsureDB()

    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_ChallengesUI") then
        self:HookKeystoneFrame()
    end

    self:ApplyObjectiveTrackerVisibility("PLAYER_LOGIN")
end

function MP:OnSettingsChanged()
    self:EnsureDB()
    self:ApplyObjectiveTrackerVisibility("SETTINGS_CHANGED")
end

function MP:OnEvent(event, ...)
    if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
        self:EnsureDB()
        if not NX.DB.dungeonsRaids.mythicPlus.respondToKeys then return end

        local msg = ...
        if self:IsKeysCommand(msg) and self:CanTriggerKeysResponse() then
            self:ReportKeysToParty()
        end
        return
    end

    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Blizzard_ChallengesUI" then
            self:HookKeystoneFrame()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        self:ApplyObjectiveTrackerVisibility(event)
        return
    end

    if event == "ENCOUNTER_START" or event == "CHALLENGE_MODE_START" then
        self:StopWatcher()
        self:ApplyObjectiveTrackerVisibility(event)
        return
    end

    if event == "ENCOUNTER_END" or event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        self:ApplyObjectiveTrackerVisibility(event)
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        self:ApplyObjectiveTrackerVisibility(event)
        if FN and not FN:IsInDungeonInstance() then
            self:StopWatcher()
        end
        return
    end

    if event == "START_TIMER" then
        local timerType, duration = ...
        if timerType == 3 and type(duration) == "number" and duration > 0 then
            self.countdownEndsAt = GetTime() + duration

            if FN and (not FN:InRestrictiveEnvironment()) and FN:IsKeystoneFrameVisible() and self:CanAutoMark() then
                self:StartWatcher()
                self:ApplyRoleMarkers()
            else
                self:StopWatcher()
            end
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if self.pendingAfterCombat then
            self.pendingAfterCombat = false
            if FN and (not FN:InRestrictiveEnvironment()) and FN:IsKeystoneFrameVisible() then
                self:ApplyRoleMarkers()
            end
        end
        return
    end

    if FN and FN:IsKeystoneFrameVisible() and (not FN:InRestrictiveEnvironment()) then
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" or event == "ROLE_CHANGED_INFORM" then
            if self:InChallengeCountdown() then
                self:ApplyRoleMarkers()
            end
            return
        end

        self:TryAutoSlotKeystone()
        self:ApplyRoleMarkers()
    end
end


