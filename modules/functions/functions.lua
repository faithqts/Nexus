local NX = Nexus
NX.Functions = NX.Functions or {}
local FN = NX.Functions

FN.restricted = FN.restricted or {
    inRaidEncounter = false,
    inChallengeRun = false,
    challengeInactiveSince = nil,
}

FN.CHALLENGE_SELF_HEAL_SECONDS = FN.CHALLENGE_SELF_HEAL_SECONDS or 300
FN.CHALLENGE_SELF_HEAL_TICK_SECONDS = FN.CHALLENGE_SELF_HEAL_TICK_SECONDS or 15
FN._challengeSelfHealTicker = FN._challengeSelfHealTicker or nil

FN.DEFAULT_FONT_PATH = FN.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
FN.DEFAULT_FONT_NAME = FN.DEFAULT_FONT_NAME or "FrizQT"
FN.ANCHOR_MIN_WIDTH = FN.ANCHOR_MIN_WIDTH or 350
FN.ANCHOR_MIN_HEIGHT = FN.ANCHOR_MIN_HEIGHT or 1
FN.VOICE_PACK_DEFAULT = FN.VOICE_PACK_DEFAULT or "xalatath"
FN.VOICE_PACK_ACTORS = FN.VOICE_PACK_ACTORS or {
    xalatath = "Xalatath",
    liadrin = "Liadrin",
    cortana = "Cortana",
    hazel = "Hazel",
    ion = "Ion",
    jimmy = "Jimmy",
    khadgar = "Khadgar",
    magni = "Magni",
}

function FN:InRestrictiveEnvironment()
    self:ReconcileChallengeRestrictionState()
    return self.restricted.inRaidEncounter or self.restricted.inChallengeRun
end

function FN:IsProgrammaticChatAllowed()
    if self:InRestrictiveEnvironment() then
        return false
    end

    if not IsInInstance then
        return true
    end

    local ok, inInstance = pcall(IsInInstance)
    if ok and inInstance then
        return false
    end

    return true
end

function FN:GetChallengeModeActiveNow()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        local ok, active = pcall(C_ChallengeMode.IsChallengeModeActive)
        if ok then
            return active and true or false
        end
    end

    if IsChallengeModeActive then
        local ok, active = pcall(IsChallengeModeActive)
        if ok then
            return active and true or false
        end
    end

    return false
end

function FN:ReconcileChallengeRestrictionState()
    if self.restricted.inRaidEncounter then
        if IsInInstance then
            local ok, inInstance, instanceType = pcall(IsInInstance)
            if (not ok) or (not inInstance) or instanceType ~= "raid" then
                self.restricted.inRaidEncounter = false
            end
        else
            self.restricted.inRaidEncounter = false
        end
    end

    if not self.restricted.inChallengeRun then
        self.restricted.challengeInactiveSince = nil
        return
    end

    if self:GetChallengeModeActiveNow() then
        self.restricted.challengeInactiveSince = nil
        return
    end

    if IsInInstance then
        local ok, inInstance, instanceType = pcall(IsInInstance)
        if ok and ((not inInstance) or instanceType ~= "party") then
            self.restricted.inChallengeRun = false
            self.restricted.challengeInactiveSince = nil
            return
        end
    end

    local now = GetTime and GetTime() or 0
    if not self.restricted.challengeInactiveSince then
        self.restricted.challengeInactiveSince = now
        return
    end

    if (now - self.restricted.challengeInactiveSince) >= self.CHALLENGE_SELF_HEAL_SECONDS then
        self.restricted.inChallengeRun = false
        self.restricted.challengeInactiveSince = nil
    end
end

function FN:EnsureChallengeSelfHealTicker()
    if self._challengeSelfHealTicker then
        return
    end

    if not C_Timer or not C_Timer.NewTicker then
        return
    end

    self._challengeSelfHealTicker = C_Timer.NewTicker(self.CHALLENGE_SELF_HEAL_TICK_SECONDS, function()
        FN:ReconcileChallengeRestrictionState()
    end)
end

function FN:IsMythicPlusChallengeActive()
    if self:GetChallengeModeActiveNow() then
        return true
    end

    return self.restricted.inChallengeRun == true
end

function FN:PassesCommonNonCombatRules()
    self:ReconcileChallengeRestrictionState()

    if InCombatLockdown and InCombatLockdown() then
        return false
    end

    local playerInCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    if playerInCombat then
        return false
    end

    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "raid" and playerInCombat then
            return false
        end
    end

    if self:InRestrictiveEnvironment() then
        return false
    end

    if self:IsMythicPlusChallengeActive() then
        return false
    end

    return true
end

function FN:ClampNumber(value, minValue, maxValue)
    local minNum = tonumber(minValue) or 0
    local maxNum = tonumber(maxValue) or minNum
    local n = tonumber(value) or minNum

    if minNum > maxNum then
        minNum, maxNum = maxNum, minNum
    end

    if n < minNum then
        return minNum
    end
    if n > maxNum then
        return maxNum
    end
    return n
end

function FN:HandleRestrictionEvent(event, ...)
    if event == "ENCOUNTER_START" then
        self.restricted.inRaidEncounter = true
        return
    end

    if event == "ENCOUNTER_END" then
        self.restricted.inRaidEncounter = false
        return
    end

    if event == "CHALLENGE_MODE_START" then
        self.restricted.inChallengeRun = true
        self.restricted.challengeInactiveSince = nil
        self:EnsureChallengeSelfHealTicker()
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        self.restricted.inChallengeRun = false
        self.restricted.challengeInactiveSince = nil
        return
    end
end

function FN:NormalizeVoicePackActor(value)
    local actor = string.lower(tostring(value or self.VOICE_PACK_DEFAULT or "xalatath"))
    if self.VOICE_PACK_ACTORS and self.VOICE_PACK_ACTORS[actor] then
        return actor
    end
    return self.VOICE_PACK_DEFAULT or "xalatath"
end

function FN:GetVoicePackOptionsData()
    if not Settings or not Settings.CreateControlTextContainer then
        return nil
    end

    local c = Settings.CreateControlTextContainer()
    local orderedActors = { "cortana", "hazel", "ion", "jimmy", "khadgar", "liadrin", "magni", "xalatath" }
    for _, actor in ipairs(orderedActors) do
        local label = (self.VOICE_PACK_ACTORS and self.VOICE_PACK_ACTORS[actor]) or actor
        c:Add(actor, label)
    end
    return c:GetData()
end

function FN:GetSharedVoicePackActor()
    local actor = NX and NX.DB and NX.DB.settings and NX.DB.settings.voicePack and NX.DB.settings.voicePack.actor
    return self:NormalizeVoicePackActor(actor)
end

function FN:SetSharedVoicePackActor(actor)
    local normalized = self:NormalizeVoicePackActor(actor)
    if not NX or not NX.DB then
        return normalized
    end

    NX.DB.settings = NX.DB.settings or {}
    NX.DB.settings.voicePack = NX.DB.settings.voicePack or {}
    NX.DB.settings.voicePack.actor = normalized
    return normalized
end

function FN:GetVoicePackSoundPaths(actor, filename, addonName)
    local soundFile = tostring(filename or "")
    if soundFile == "" then
        return nil
    end

    local safeActor = self:NormalizeVoicePackActor(actor)
    local safeAddon = tostring(addonName or (NX and NX.name) or "Nexus")

    return {
        string.format("Interface\\AddOns\\%s\\media\\voices\\%s\\%s", safeAddon, safeActor, soundFile),
        string.format("Interface\\AddOns\\%s\\Media\\voices\\%s\\%s", safeAddon, safeActor, soundFile),
        string.format("Interface\\AddOns\\%s\\media\\voice\\%s\\%s", safeAddon, safeActor, soundFile),
        string.format("Interface\\AddOns\\%s\\Media\\voice\\%s\\%s", safeAddon, safeActor, soundFile),
        string.format("Interface/AddOns/%s/media/voices/%s/%s", safeAddon, safeActor, soundFile),
        string.format("Interface/AddOns/%s/Media/voices/%s/%s", safeAddon, safeActor, soundFile),
        string.format("Interface/AddOns/%s/media/voice/%s/%s", safeAddon, safeActor, soundFile),
        string.format("Interface/AddOns/%s/Media/voice/%s/%s", safeAddon, safeActor, soundFile),
    }
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

function FN:GetCVarValue(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    if C_CVar and C_CVar.GetCVar then
        local ok, value = pcall(C_CVar.GetCVar, name)
        if ok then
            return value
        end
    elseif GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok then
            return value
        end
    end

    return nil
end

function FN:SetCVarValue(name, value)
    if type(name) ~= "string" or name == "" or value == nil then
        return
    end

    if type(value) == "boolean" then
        value = value and "1" or "0"
    end

    value = tostring(value)

    local current = self:GetCVarValue(name)
    if current == value then
        return
    end

    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, name, value)
        return
    end

    if SetCVar then
        pcall(SetCVar, name, value)
    end
end

function FN:GetCVarBool(name, fallback)
    local value = self:GetCVarValue(name)
    if value == nil then
        return fallback and true or false
    end

    if type(value) == "boolean" then
        return value
    end

    local s = tostring(value)
    if s == "1" or s == "true" then
        return true
    end
    if s == "0" or s == "false" then
        return false
    end

    return fallback and true or false
end

function FN:SetCVarBool(name, enabled)
    self:SetCVarValue(name, enabled and "1" or "0")
end

function FN:GetAvailableFontEntries()
    local entries = {}
    local seenPath = {}

    local defaultPath = self.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
    local defaultName = self.DEFAULT_FONT_NAME or "FrizQT"

    seenPath[defaultPath] = true
    entries[#entries + 1] = { path = defaultPath, name = defaultName }

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.List and LSM.Fetch then
        local names = LSM:List("font")
        if type(names) == "table" then
            table.sort(names)
            for _, name in ipairs(names) do
                local path = LSM:Fetch("font", name)
                if type(path) == "string" and path ~= "" and not seenPath[path] then
                    seenPath[path] = true
                    entries[#entries + 1] = { path = path, name = name }
                end
            end
        end
    end

    return entries
end

function FN:GetAddonFontOptionsData()
    if not Settings or not Settings.CreateControlTextContainer then
        return nil
    end

    local c = Settings.CreateControlTextContainer()
    for _, e in ipairs(self:GetAvailableFontEntries()) do
        c:Add(e.path, e.name)
    end
    return c:GetData()
end

function FN:IsFontPathAvailable(path)
    if type(path) ~= "string" or path == "" then
        return false
    end

    for _, e in ipairs(self:GetAvailableFontEntries()) do
        if e.path == path then
            return true
        end
    end

    return false
end

function FN:GetAddonFontPath()
    local defaultPath = self.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
    local selected

    if NX and NX.DB and NX.DB.media and NX.DB.media.fonts then
        selected = NX.DB.media.fonts.addonFontPath
    end

    if type(selected) ~= "string" or selected == "" then
        return defaultPath
    end

    if self:IsFontPathAvailable(selected) then
        return selected
    end

    return defaultPath
end

function FN:SetAddonFontPath(path)
    if not NX or not NX.DB then
        return self.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
    end

    NX.DB.media = NX.DB.media or {}
    NX.DB.media.fonts = NX.DB.media.fonts or {}

    local selected = path
    if not self:IsFontPathAvailable(selected) then
        selected = self.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
    end

    NX.DB.media.fonts.addonFontPath = selected
    return selected
end

function FN:ApplyAddonFont(fontObject, fontSize, fontFlags, preferredPath)
    if not fontObject or not fontObject.SetFont then
        return false
    end

    local size = math.max(1, math.floor(tonumber(fontSize) or 12))
    local flags = fontFlags
    local defaultPath = self.DEFAULT_FONT_PATH or "Fonts\\FRIZQT__.TTF"
    local selectedPath = preferredPath or self:GetAddonFontPath()

    if type(selectedPath) ~= "string" or selectedPath == "" then
        selectedPath = defaultPath
    end

    if fontObject:SetFont(selectedPath, size, flags) then
        return true
    end

    return fontObject:SetFont(defaultPath, size, flags)
end

function FN:ClampAnchorSize(width, height, minWidth, minHeight)
    local defaultMinWidth = math.max(1, math.floor(tonumber(self.ANCHOR_MIN_WIDTH) or 500))
    local defaultMinHeight = math.max(1, math.floor(tonumber(self.ANCHOR_MIN_HEIGHT) or 50))

    local minW = math.max(1, math.floor(tonumber(minWidth) or defaultMinWidth))
    local minH = math.max(1, math.floor(tonumber(minHeight) or defaultMinHeight))

    local w = math.floor(tonumber(width) or minW)
    local h = math.floor(tonumber(height) or minH)

    if w < minW then
        w = minW
    end
    if h < minH then
        h = minH
    end

    return w, h
end

function FN:RoundToNearestPixel(value)
    local n = tonumber(value) or 0
    if n >= 0 then
        return math.floor(n + 0.5)
    end
    return math.ceil(n - 0.5)
end

function FN:SetAnchorSize(frame, width, height, minWidth, minHeight)
    local w, h = self:ClampAnchorSize(width, height, minWidth, minHeight)
    if frame and frame.SetSize then
        frame:SetSize(w, h)
    end
    return w, h
end

function FN:CreateAnchorFrame(parent, width, height, minWidth, minHeight)
    local anchorParent = parent or UIParent
    local frame = CreateFrame("Frame", nil, anchorParent)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(false)
    end
    self:SetAnchorSize(frame, width, height, minWidth, minHeight)
    return frame
end

function FN:CreateLockOnClickHandler(target, suppressPrint)
    if type(target) ~= "table" then
        return nil
    end

    return function()
        if target.SetPositionUnlocked then
            target:SetPositionUnlocked(false, suppressPrint)
        end
    end
end

function FN:CreateAnchorController(opts)
    if type(opts) ~= "table" then
        return nil
    end

    local parent = opts.parent
    local moveFrame = opts.moveFrame or parent
    if not parent or not moveFrame then
        return nil
    end

    local nudgeStep = math.max(1, math.floor(tonumber(opts.nudgeStep) or 1))
    local extraPadding = math.floor(tonumber(opts.extraVerticalPadding) or 0)
    local labelFontSize = math.max(8, math.floor(tonumber(opts.labelFontSize) or 14))

    local function isBlocked()
        if opts.isBlocked and opts.isBlocked() then
            return true
        end
        if InCombatLockdown and InCombatLockdown() then
            return true
        end
        return false
    end

    local function isMoveEnabled()
        if opts.isMoveEnabled then
            return opts.isMoveEnabled() and true or false
        end
        return true
    end

    local function getOffsets()
        if opts.getOffsets then
            local x, y = opts.getOffsets()
            return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
        end
        return 0, 0
    end

    local function setOffsets(x, y)
        if opts.setOffsets then
            opts.setOffsets(FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y))
        end
    end

    local controller = CreateFrame("Frame", nil, parent)
    controller:SetFrameStrata("HIGH")
    controller:SetPoint("TOPLEFT", parent, "TOPLEFT", -10, 10 + extraPadding)
    controller:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 10, -10 - extraPadding)
    controller:EnableMouse(true)
    controller:SetMovable(false)

    controller.BG = controller:CreateTexture(nil, "BACKGROUND")
    controller.BG:SetAllPoints()
    controller.BG:SetColorTexture(0.1, 0.6, 1.0, 0.16)

    controller.Top = controller:CreateTexture(nil, "BORDER")
    controller.Top:SetColorTexture(0.2, 0.8, 1.0, 0.95)
    controller.Top:SetPoint("TOPLEFT", controller, "TOPLEFT", 0, 0)
    controller.Top:SetPoint("TOPRIGHT", controller, "TOPRIGHT", 0, 0)
    controller.Top:SetHeight(1)

    controller.Bottom = controller:CreateTexture(nil, "BORDER")
    controller.Bottom:SetColorTexture(0.2, 0.8, 1.0, 0.95)
    controller.Bottom:SetPoint("BOTTOMLEFT", controller, "BOTTOMLEFT", 0, 0)
    controller.Bottom:SetPoint("BOTTOMRIGHT", controller, "BOTTOMRIGHT", 0, 0)
    controller.Bottom:SetHeight(1)

    controller.Left = controller:CreateTexture(nil, "BORDER")
    controller.Left:SetColorTexture(0.2, 0.8, 1.0, 0.95)
    controller.Left:SetPoint("TOPLEFT", controller, "TOPLEFT", 0, 0)
    controller.Left:SetPoint("BOTTOMLEFT", controller, "BOTTOMLEFT", 0, 0)
    controller.Left:SetWidth(1)

    controller.Right = controller:CreateTexture(nil, "BORDER")
    controller.Right:SetColorTexture(0.2, 0.8, 1.0, 0.95)
    controller.Right:SetPoint("TOPRIGHT", controller, "TOPRIGHT", 0, 0)
    controller.Right:SetPoint("BOTTOMRIGHT", controller, "BOTTOMRIGHT", 0, 0)
    controller.Right:SetWidth(1)

    controller.CoordLabel = controller:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    controller.CoordLabel:SetPoint("TOP", controller, "TOP", 0, -4)
    controller.CoordLabel:SetTextColor(0.85, 0.98, 1.0, 1)
    self:ApplyAddonFont(controller.CoordLabel, labelFontSize, "OUTLINE")

    controller.NameLabel = controller:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    controller.NameLabel:SetPoint("BOTTOM", controller, "BOTTOM", 0, 4)
    controller.NameLabel:SetTextColor(0.75, 0.95, 1.0, 1)
    self:ApplyAddonFont(controller.NameLabel, labelFontSize, "OUTLINE")

    local function createArrowButton(arrowText, onClicked)
        local button = CreateFrame("Button", nil, controller, "UIPanelButtonTemplate")
        button:SetSize(22, 22)
        button:SetFrameLevel(controller:GetFrameLevel() + 5)
        button:SetText(arrowText or "")

        if button.SetPropagateMouseClicks then
            button:SetPropagateMouseClicks(false)
        end
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function(_, mouseButton)
            if mouseButton ~= "LeftButton" then
                return
            end
            if onClicked then
                onClicked()
            end
        end)
        return button
    end

    local function nudge(dx, dy)
        if isBlocked() or not isMoveEnabled() then
            return
        end
        local x, y = getOffsets()
        setOffsets(x + (dx or 0), y + (dy or 0))
        controller:UpdateReadout()
    end

    controller.UpButton = createArrowButton("^", function() nudge(0, nudgeStep) end)
    controller.UpButton:SetPoint("LEFT", controller, "RIGHT", 6, 14)
    controller.DownButton = createArrowButton("v", function() nudge(0, -nudgeStep) end)
    controller.DownButton:SetPoint("LEFT", controller, "RIGHT", 6, -14)
    controller.LeftButton = createArrowButton("<", function() nudge(-nudgeStep, 0) end)
    controller.LeftButton:SetPoint("TOP", controller, "BOTTOM", -16, -6)
    controller.RightButton = createArrowButton(">", function() nudge(nudgeStep, 0) end)
    controller.RightButton:SetPoint("TOP", controller, "BOTTOM", 16, -6)

    controller.AlignVerticalButton = CreateFrame("Button", nil, controller, "UIPanelButtonTemplate")
    controller.AlignVerticalButton:SetSize(110, 20)
    controller.AlignVerticalButton:SetPoint("TOPLEFT", controller, "TOPLEFT", 4, -4)
    controller.AlignVerticalButton:SetText("Center Vertically")
    if controller.AlignVerticalButton.SetPropagateMouseClicks then
        controller.AlignVerticalButton:SetPropagateMouseClicks(false)
    end
    controller.AlignVerticalButton:SetScript("OnClick", function()
        if isBlocked() or not isMoveEnabled() then
            return
        end
        local x = getOffsets()
        setOffsets(x, 0)
        controller:UpdateReadout()
    end)

    controller.AlignHorizontalButton = CreateFrame("Button", nil, controller, "UIPanelButtonTemplate")
    controller.AlignHorizontalButton:SetSize(120, 20)
    controller.AlignHorizontalButton:SetPoint("TOPRIGHT", controller, "TOPRIGHT", -4, -4)
    controller.AlignHorizontalButton:SetText("Center Horizontally")
    if controller.AlignHorizontalButton.SetPropagateMouseClicks then
        controller.AlignHorizontalButton:SetPropagateMouseClicks(false)
    end
    controller.AlignHorizontalButton:SetScript("OnClick", function()
        if isBlocked() or not isMoveEnabled() then
            return
        end
        local _, y = getOffsets()
        setOffsets(0, y)
        controller:UpdateReadout()
    end)

    controller.LockButton = CreateFrame("Button", nil, controller, "UIPanelButtonTemplate")
    controller.LockButton:SetSize(56, 20)
    controller.LockButton:SetPoint("BOTTOMLEFT", controller, "BOTTOMLEFT", 4, 4)
    controller.LockButton:SetText("Lock")
    if controller.LockButton.SetPropagateMouseClicks then
        controller.LockButton:SetPropagateMouseClicks(false)
    end
    controller.LockButton:SetScript("OnClick", function()
        if isBlocked() then
            return
        end
        if opts.onLock then
            opts.onLock(controller)
        end
    end)

    function controller:RefreshFonts()
        if self.CoordLabel then
            FN:ApplyAddonFont(self.CoordLabel, labelFontSize, "OUTLINE")
        end
        if self.NameLabel then
            FN:ApplyAddonFont(self.NameLabel, labelFontSize, "OUTLINE")
        end
    end

    function controller:SetElementName(name)
        self._elementName = tostring(name or "Element")
        self:UpdateReadout()
    end

    function controller:UpdateReadout()
        local x, y = getOffsets()
        if self.CoordLabel then
            self.CoordLabel:SetText(string.format("%d, %d", x, y))
        end
        if self.NameLabel then
            self.NameLabel:SetText(self._elementName or "Element")
        end
    end

    controller.DragSurface = CreateFrame("Frame", nil, controller)
    controller.DragSurface:SetPoint("TOPLEFT", controller, "TOPLEFT", 2, -24)
    controller.DragSurface:SetPoint("BOTTOMRIGHT", controller, "BOTTOMRIGHT", -2, 24)
    controller.DragSurface:EnableMouse(true)
    controller.DragSurface:RegisterForDrag("LeftButton")

    controller.DragSurface:SetScript("OnDragStart", function()
        if isBlocked() or not isMoveEnabled() then
            return
        end
        moveFrame:SetMovable(true)
        moveFrame:StartMoving()
        controller._isDragging = true
        controller:SetScript("OnUpdate", function()
            controller:UpdateReadout()
        end)
    end)

    controller.DragSurface:SetScript("OnDragStop", function()
        if not controller._isDragging then
            return
        end
        controller._isDragging = false
        moveFrame:StopMovingOrSizing()
        moveFrame:SetMovable(false)
        controller:SetScript("OnUpdate", nil)
        if opts.onDragStop then
            opts.onDragStop(controller)
        end
        controller:UpdateReadout()
    end)

    controller:SetScript("OnHide", function()
        controller._isDragging = false
        moveFrame:StopMovingOrSizing()
        moveFrame:SetMovable(false)
        controller:SetScript("OnUpdate", nil)
    end)

    controller:SetElementName(opts.elementName or "Element")
    controller:RefreshFonts()
    controller:UpdateReadout()
    return controller
end

