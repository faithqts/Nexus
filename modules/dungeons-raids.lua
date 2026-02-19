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
    NX.DB.mythicPlus = NX.DB.mythicPlus or {}
    local db = NX.DB.mythicPlus
    if db.respondToKeys == nil then db.respondToKeys = true end
    if db.autoHideObjectives == nil then db.autoHideObjectives = false end
    if db.keysResponderCooldownSeconds == nil then db.keysResponderCooldownSeconds = 5 end
    if db.objectiveTrackerRestoreDelaySeconds == nil then db.objectiveTrackerRestoreDelaySeconds = 30 end
end

function MP:GetObjectiveTrackerRestoreDelaySeconds()
    self:EnsureDB()
    local delay = tonumber(NX.DB.mythicPlus.objectiveTrackerRestoreDelaySeconds) or 30
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

    local cooldown = tonumber(NX.DB.mythicPlus.keysResponderCooldownSeconds) or 5
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

    if not NX.DB.mythicPlus.autoHideObjectives then
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
    if not NX.DB.autoInsertKeystone then return end
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
    local style = NX.DB.markingStyle
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

    local tankMarker = NX.DB.tankMarker
    local healerMarker = NX.DB.healerMarker

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
        if not NX.DB.mythicPlus.respondToKeys then return end

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

local NX = Nexus
NX.Vault = NX.Vault or {}
local V = NX.Vault

local FALLBACK_SECONDS = 5
local OUTLINE = "OUTLINE"
local DEFAULT_ANCHOR_X = 0
local DEFAULT_ANCHOR_Y = 0
local DEFAULT_ENABLED = true
local DEFAULT_POSITION_UNLOCKED = false
local DEFAULT_FONT_SIZE = 48
local DEFAULT_FLASHING = true
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 28
local ANCHOR_LABEL_FONT_SIZE = 16
local BANNER_ANCHOR_WIDTH = 960
local BANNER_ANCHOR_HEIGHT = 96

V.previewActive = false
V.hideTimer = nil
V.Anchor = V.Anchor or nil
V.DragHandle = V.DragHandle or nil
V.AnchorDisplayName = "Great Vault"

local function GetVaultSpellID()
    return (NX.Constants and NX.Constants.VAULT_SPELL_ID) or 449976
end

local function ApplyAndMaybeRefresh()
    if V.ApplyConfig then
        V:ApplyConfig()
    end
    if V.IsPreviewActive and V:IsPreviewActive() then
        if V.RefreshPreview then
            V:RefreshPreview()
        end
    end
end

function V:EnsureDB()
    NX.DB.greatVault = NX.DB.greatVault or {}
    local db = NX.DB.greatVault
    local legacy = NX.DB and NX.DB.vault

    if db.enabled == nil then
        if legacy and legacy.enabled ~= nil then
            db.enabled = legacy.enabled and true or false
        else
            db.enabled = DEFAULT_ENABLED
        end
    end

    if db.anchorX == nil then
        if legacy and legacy.anchorX ~= nil then
            db.anchorX = legacy.anchorX
        else
            db.anchorX = DEFAULT_ANCHOR_X
        end
    end

    if db.anchorY == nil then
        if legacy and legacy.anchorY ~= nil then
            db.anchorY = legacy.anchorY
        elseif legacy and legacy.offsetY ~= nil then
            db.anchorY = legacy.offsetY
        else
            db.anchorY = DEFAULT_ANCHOR_Y
        end
    end

    if db.positionUnlocked == nil then
        db.positionUnlocked = DEFAULT_POSITION_UNLOCKED
    end

    if db.fontSize == nil then
        if legacy and legacy.fontSize ~= nil then
            db.fontSize = legacy.fontSize
        else
            db.fontSize = DEFAULT_FONT_SIZE
        end
    end

    if db.flashing == nil then
        if legacy and legacy.flashing ~= nil then
            db.flashing = legacy.flashing and true or false
        else
            db.flashing = DEFAULT_FLASHING
        end
    end

    db.enabled = db.enabled and true or false
    db.positionUnlocked = db.positionUnlocked and true or false
    db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULT_ANCHOR_X)
    db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULT_ANCHOR_Y)
    db.fontSize = math.floor((tonumber(db.fontSize) or DEFAULT_FONT_SIZE) + 0.5)
    if db.fontSize < 1 then db.fontSize = 1 end
    if db.fontSize > 128 then db.fontSize = 128 end
    db.flashing = db.flashing and true or false

    return db
end

function V:IsEnabled()
    return self:EnsureDB().enabled == true
end

function V:IsPositionUnlocked()
    return self:EnsureDB().positionUnlocked == true
end

function V:WarnMovementBlocked()
    local now = GetTime and GetTime() or 0
    local last = self._lastMovementBlockedWarningAt or 0
    if (now - last) < 0.25 then
        return
    end
    self._lastMovementBlockedWarningAt = now
    print("|cffffd200Nexus:|r Great Vault movement is blocked in combat state.")
end

local text

function V:EnsureAnchor()
    if self.Anchor then
        return self.Anchor
    end

    local anchor = FN:CreateAnchorFrame(UIParent, BANNER_ANCHOR_WIDTH, BANNER_ANCHOR_HEIGHT)
    self.Anchor = anchor
    self:ApplyAnchorPoint()
    return anchor
end

function V:EnsureText()
    if text then
        return text
    end

    local anchor = self:EnsureAnchor()
    text = anchor:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)
    text:Hide()
    return text
end

function V:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function V:GetFlooredAnchorOffsetsFromFrame()
    if not self.Anchor then
        local db = self:EnsureDB()
        return FN:RoundToNearestPixel(db.anchorX), FN:RoundToNearestPixel(db.anchorY)
    end

    local centerX, centerY = self.Anchor:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if centerX and centerY and parentCenterX and parentCenterY then
        return FN:RoundToNearestPixel(centerX - parentCenterX), FN:RoundToNearestPixel(centerY - parentCenterY)
    end

    local _, _, _, x, y = self.Anchor:GetPoint(1)
    return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
end

function V:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function V:SetAnchorOffsets(x, y)
    local db = self:EnsureDB()
    db.anchorX = FN:RoundToNearestPixel(x)
    db.anchorY = FN:RoundToNearestPixel(y)
    self:ApplyAnchorPoint()
end

function V:UpdateDragHandleReadout()
    if not self.DragHandle then
        return
    end

    local x, y = self:GetFlooredAnchorOffsetsFromFrame()
    if self.DragHandle.CoordLabel then
        self.DragHandle.CoordLabel:SetText(string.format("%d, %d", x, y))
    end
    if self.DragHandle.NameLabel then
        self.DragHandle.NameLabel:SetText(self.AnchorDisplayName or "Element")
    end
end

function V:UpdateDragHandle()
    local anchor = self:EnsureAnchor()
    if not anchor then
        return
    end

    local functionsModule = NX.Functions or FN

    if not self.DragHandle and functionsModule and functionsModule.CreateAnchorController then
        self.DragHandle = functionsModule:CreateAnchorController({
            parent = anchor,
            moveFrame = anchor,
            elementName = self.AnchorDisplayName,
            nudgeStep = ANCHOR_STEP_PX,
            extraVerticalPadding = ANCHOR_EXTRA_VERTICAL_PADDING,
            labelFontSize = ANCHOR_LABEL_FONT_SIZE,
            isBlocked = function()
                if InCombatLockdown and InCombatLockdown() then
                    V:WarnMovementBlocked()
                    return true
                end
                return false
            end,
            isMoveEnabled = function()
                return V:IsPositionUnlocked()
            end,
            getOffsets = function()
                return V:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                V:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                V:StoreFlooredAnchorOffsetsFromFrame()
                V:ApplyAnchorPoint()
                V:UpdateDragHandleReadout()
            end,
            onLock = (functionsModule and functionsModule.CreateLockOnClickHandler and functionsModule:CreateLockOnClickHandler(V, false))
                or function()
                    V:SetPositionUnlocked(false)
                end,
        })
    end

    if not self.DragHandle then
        return
    end

    if self.DragHandle.SetElementName then
        self.DragHandle:SetElementName(self.AnchorDisplayName)
    end

    if self.DragHandle.RefreshFonts then
        self.DragHandle:RefreshFonts()
    end

    self:UpdateDragHandleReadout()

    local showHandle = self:IsPositionUnlocked()
    self.DragHandle:SetShown(showHandle)
    self.DragHandle:EnableMouse(showHandle)
end

function V:UpdateAnchorVisibility()
    local anchor = self:EnsureAnchor()
    if not anchor then
        return
    end

    local showAnchor = self:IsPositionUnlocked() or (text and text:IsShown())
    anchor:SetShown(showAnchor)
    self:UpdateDragHandle()
end

function V:Toggle()
    local db = self:EnsureDB()
    db.enabled = not db.enabled

    if not db.enabled then
        self:HidePreview()
    else
        self:ApplyConfig()
    end

    self:OnSettingsChanged()
    local state = db.enabled and "enabled" or "disabled"
    print("|cffffd200Nexus:|r Great Vault " .. state .. ".")
end

function V:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false

    if db.positionUnlocked then
        self:TestPreview()
    else
        self:StopPreview()
    end

    self:UpdateAnchorVisibility()

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Great Vault position unlocked.")
    else
        print("|cffffd200Nexus:|r Great Vault position locked.")
    end
end

function V:HandleNxSlash(msg)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd200Nexus:|r Slash command blocked in combat state.")
        return true
    end

    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "toggle" then
        self:Toggle()
        return true
    end

    if text == "lock" then
        self:SetPositionUnlocked(false)
        return true
    end

    if text == "unlock" then
        self:SetPositionUnlocked(true)
        return true
    end

    if text == "help" or text == "?" then
        print("|cffffd200Nexus:|r /nx vault, /nx vault lock, /nx vault unlock, /nx vault help")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx vault command. Use: /nx vault help")
    return true
end

function V:OnSettingsChanged()
    ApplyAndMaybeRefresh()
end

function V:OnSettingsClosed()
    self:SetPositionUnlocked(false, true)
    self:StopPreview()
end

local function GetTextObject()
    return V:EnsureText()
end

local function IsTextShown()
    return text and text:IsShown()
end

local flash

local function EnsureFlashAnimation()
    if flash then
        return flash
    end

    local t = GetTextObject()
    flash = t:CreateAnimationGroup()
    flash:SetLooping("REPEAT")

    local fadeOut = flash:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.2)
    fadeOut:SetDuration(0.35)
    fadeOut:SetOrder(1)

    local fadeIn = flash:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.2)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.35)
    fadeIn:SetOrder(2)

    return flash
end

local function GetClassColorCode()
    local _, classTag = UnitClass("player")
    local c = classTag and RAID_CLASS_COLORS[classTag]
    if not c or not c.colorStr then
        return "|cFFFFFFFF"
    end
    return "|c" .. c.colorStr
end

local function BuildBannerText()
    local specID = GetLootSpecialization()
    local lootSpecIcon, lootSpecName

    if specID == 0 then
        local specIndex = GetSpecialization()
        if not specIndex then
            return GetClassColorCode() .. "OPENING GREAT VAULT AS UNKNOWN|r"
        end
        local _, name, _, icon = GetSpecializationInfo(specIndex)
        lootSpecName = name
        lootSpecIcon = icon
    else
        local _, name, _, icon = GetSpecializationInfoByID(specID)
        lootSpecName = name
        lootSpecIcon = icon
    end

    lootSpecName = lootSpecName or "UNKNOWN"
    lootSpecIcon = lootSpecIcon or 134400

    return GetClassColorCode() ..
        format("|T%d:0|t OPENING GREAT VAULT AS %s |T%d:0|t",
            lootSpecIcon,
            string.upper(lootSpecName),
            lootSpecIcon
        ) .. "|r"
end

local function GetCurrentCastRemainingSeconds(spellID)
    local _, _, _, startMS, endMS, _, _, _, castSpellID = UnitCastingInfo("player")
    if not startMS then
        local _, _, _, sMS, eMS, _, _, chanSpellID = UnitChannelInfo("player")
        startMS, endMS, castSpellID = sMS, eMS, chanSpellID
    end

    if not startMS or not endMS then return nil end
    if castSpellID ~= spellID then return nil end

    local nowMS = GetTime() * 1000
    local remaining = (endMS - nowMS) / 1000
    if remaining <= 0 then return 0 end
    return remaining
end

local function ApplyFontDeferred(path, size)
    local tries = 0
    local function try()
        tries = tries + 1
        local t = GetTextObject()
        if t:SetFont(path, size, OUTLINE) then
            return
        end
        if tries < 5 then
            C_Timer.After(0, try)
        else
            local fallback = (FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF"
            t:SetFont(fallback, size, OUTLINE)
        end
    end
    try()
end

function V:ApplyConfig()
    local db = self:EnsureDB()
    if not db then return end

    local fontPath = (FN and FN.GetAddonFontPath and FN:GetAddonFontPath())
        or ((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF")
    local fontSize = tonumber(db.fontSize) or 48

    self:EnsureAnchor()
    self:EnsureText()
    self:ApplyAnchorPoint()
    ApplyFontDeferred(fontPath, fontSize)
    self:UpdateAnchorVisibility()
end

function V:HideBanner()
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end

    local f = EnsureFlashAnimation()
    if f:IsPlaying() then
        f:Stop()
    end

    if text then
        text:Hide()
    end

    self:UpdateAnchorVisibility()
end

function V:HidePreview()
    self.previewActive = false
    self:HideBanner()
end

function V:TestPreview()
    local db = self:EnsureDB()
    if not db.enabled then
        self:HidePreview()
        return
    end

    self.previewActive = true
    self:ApplyConfig()

    local t = GetTextObject()
    t:SetText(BuildBannerText())
    t:SetAlpha(1)
    t:Show()

    local f = EnsureFlashAnimation()
    if db.flashing then
        if not f:IsPlaying() then f:Play() end
    else
        if f:IsPlaying() then f:Stop() end
    end

    self:UpdateAnchorVisibility()
end

function V:RefreshPreview()
    if not self.previewActive then return end
    self:TestPreview()
end

function V:IsPreviewActive()
    return self.previewActive == true
end

function V:StopPreview()
    self:HidePreview()
end

function V:TogglePreview()
    if self:IsPreviewActive() then
        self:StopPreview()
    else
        self:TestPreview()
    end
end

function V:ShowBannerFor(seconds)
    local db = self:EnsureDB()
    if not db.enabled then return end
    if self.previewActive then return end

    local dur = tonumber(seconds) or FALLBACK_SECONDS
    if dur <= 0 then dur = 0.01 end

    self:ApplyConfig()

    local t = GetTextObject()
    t:SetText(BuildBannerText())
    t:SetAlpha(1)
    t:Show()

    local f = EnsureFlashAnimation()
    if db.flashing then
        if not f:IsPlaying() then f:Play() end
    else
        if f:IsPlaying() then f:Stop() end
    end

    self:UpdateAnchorVisibility()

    if self.hideTimer then
        self.hideTimer:Cancel()
    end

    self.hideTimer = C_Timer.NewTimer(dur, function()
        if not self.previewActive then
            self:HideBanner()
        end
    end)
end

function V:ShowBannerMatchCastOrFallback()
    local db = self:EnsureDB()
    if not db.enabled then return end
    if self.previewActive then return end

    local SPELL_ID = GetVaultSpellID()

    C_Timer.After(0, function()
        if self.previewActive then return end
        if not self:IsEnabled() then return end

        local remaining = GetCurrentCastRemainingSeconds(SPELL_ID)
        if remaining and remaining > 0 then
            self:ShowBannerFor(remaining)
        else
            self:ShowBannerFor(FALLBACK_SECONDS)
        end
    end)
end

function V:Init()
    self:EnsureDB()
    self:ApplyConfig()

    local f = CreateFrame("Frame")

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_SPELLCAST_SENT")
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    f:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    f:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")

    f:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    f:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            self:HideBanner()
            return
        end

        if event == "PLAYER_LOOT_SPEC_UPDATED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            if IsTextShown() then
                GetTextObject():SetText(BuildBannerText())
            end
            return
        end

        local db = self:EnsureDB()
        if not db then return end

        local SPELL_ID = GetVaultSpellID()

        if event == "UNIT_SPELLCAST_SENT" then
            local unit, _, _, spellID = ...
            if unit ~= "player" then return end
            if not db.enabled then return end
            if spellID == SPELL_ID then
                self:ShowBannerMatchCastOrFallback()
            end
            return
        end

        local unit, _, spellID = ...
        if unit ~= "player" then return end
        if spellID ~= SPELL_ID then return end

        if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            self:HideBanner()
        end
    end)
end
