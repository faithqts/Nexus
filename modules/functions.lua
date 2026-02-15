local NX = Nexus
NX.Functions = NX.Functions or {}
local FN = NX.Functions

FN.restricted = FN.restricted or {
    inRaidEncounter = false,
    inChallengeRun = false,
}

function FN:InRestrictiveEnvironment()
    return self.restricted.inRaidEncounter or self.restricted.inChallengeRun
end

function FN:HandleRestrictionEvent(event, ...)
    if event == "ENCOUNTER_START" then
        self.restricted.inRaidEncounter = true
        if NX.MythicPlus and NX.MythicPlus.StopWatcher then
            NX.MythicPlus:StopWatcher()
        end
        return
    end

    if event == "ENCOUNTER_END" then
        self.restricted.inRaidEncounter = false
        return
    end

    if event == "CHALLENGE_MODE_START" then
        self.restricted.inChallengeRun = true
        if NX.MythicPlus and NX.MythicPlus.StopWatcher then
            NX.MythicPlus:StopWatcher()
        end
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        self.restricted.inChallengeRun = false
        return
    end
end

function FN:IsKeystoneFrameVisible()
    return ChallengesKeystoneFrame and ChallengesKeystoneFrame:IsShown()
end

function FN:IsInDungeonInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "party"
end

function FN:MarkerIcon(marker, size)
    if not marker then return "" end
    size = size or 14
    return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d:0:0|t", marker, size, size)
end

function FN:GetPlayerBestMapID()
    if not C_Map or not C_Map.GetBestMapForUnit then return nil end
    return C_Map.GetBestMapForUnit("player")
end

function FN:DeriveCurrentChallengeModeIDFromPlayerMap()
    if not C_ChallengeMode or not C_ChallengeMode.GetMapTable or not C_ChallengeMode.GetMapUIInfo then
        return nil
    end

    local playerMapID = self:GetPlayerBestMapID()
    if not playerMapID then return nil end

    local tbl = C_ChallengeMode.GetMapTable()
    if type(tbl) ~= "table" then return nil end

    for _, challengeModeID in ipairs(tbl) do
        local _, _, _, _, _, mapID = C_ChallengeMode.GetMapUIInfo(challengeModeID)
        if mapID and mapID == playerMapID then
            return challengeModeID
        end
    end

    return nil
end

function FN:GetOwnedKeystoneChallengeModeID()
    if not C_MythicPlus or not C_MythicPlus.GetOwnedKeystoneChallengeMapID then return nil end
    return C_MythicPlus.GetOwnedKeystoneChallengeMapID()
end

function FN:KeystoneMatchesCurrentDungeon()
    if not self:IsInDungeonInstance() then return false end

    local owned = self:GetOwnedKeystoneChallengeModeID()
    if not owned then return false end

    local current = self:DeriveCurrentChallengeModeIDFromPlayerMap()
    if not current then return false end

    return owned == current
end

function FN:FindKeystoneInBags(itemIDs)
    if type(itemIDs) ~= "table" then return nil end
    for _, itemID in ipairs(itemIDs) do
        local c = GetItemCount(itemID, false)
        if c and c > 0 then
            return itemID
        end
    end
    return nil
end
