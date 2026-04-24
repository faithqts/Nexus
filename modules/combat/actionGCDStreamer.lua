local NX = Nexus
NX.ActionGCDStreamer = NX.ActionGCDStreamer or {}
local AG = NX.ActionGCDStreamer
local FN = NX.Functions

local DEFAULT_DURATION = 7.5
local DEFAULT_LIMIT = 7
local DEFAULT_ICON_SIZE = 30
local DEFAULT_ICON_ZOOM_PCT = 10
local DEFAULT_SPACING = 1
local DEFAULT_GROWTH_DIRECTION = "LEFT"
local DEFAULT_ANCHOR_X = 0
local DEFAULT_ANCHOR_Y = 0
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16
local DEFAULT_BLACKLIST = { 75 }
local DEFAULT_SHOW_LAST_CAST_MS = false
local DEFAULT_SHOW_LAST_CAST_MS_FONT_SIZE = 12

AG.Anchor = AG.Anchor or nil
AG.DragHandle = AG.DragHandle or nil
AG.AnchorDisplayName = AG.AnchorDisplayName or "Action GCD Streamer"
AG._icons = AG._icons or {}
AG._blacklist = AG._blacklist or {}

local function BuildBlacklistSet(list)
    local set = {}
    if type(list) == "table" then
        for _, v in ipairs(list) do
            local id = tonumber(v)
            if id and id > 0 then
                set[id] = true
            end
        end
    end
    return set
end

local function GetSpellIcon(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local iconID = C_Spell.GetSpellTexture(spellID)
        if iconID then
            return iconID
        end
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.iconID then
            return info.iconID
        end
    end

    return nil
end

local function ApplyTextureZoom(texture, zoomPct)
    if not texture or not texture.SetTexCoord then
        return
    end

    local pct = tonumber(zoomPct) or DEFAULT_ICON_ZOOM_PCT
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end

    local zoomFactor = 1 + (pct / 100)
    local margin = (1 - (1 / zoomFactor)) * 0.5
    texture:SetTexCoord(margin, 1 - margin, margin, 1 - margin)
end

local function ApplyMsTextStyle(iconFrame, db)
    if not iconFrame or not iconFrame._msText then
        return
    end

    local fontPath = (FN and FN.GetAddonFontPath and FN:GetAddonFontPath())
        or ((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF")

    local size = math.floor((tonumber(db and db.showLastCastMSFontSize) or DEFAULT_SHOW_LAST_CAST_MS_FONT_SIZE) + 0.5)
    if size < 8 then size = 8 end
    if size > 32 then size = 32 end

    iconFrame._msText:SetFont(fontPath, size, "OUTLINE")
    iconFrame._msText:SetTextColor(1, 0.82, 0.2, 1)
end

function AG:EnsureDB()
    NX.DB.combat.actionGCDStreamer = NX.DB.combat.actionGCDStreamer or {}
    local db = NX.DB.combat.actionGCDStreamer

    if db.enabled == nil then db.enabled = false end
    if db.duration == nil then db.duration = DEFAULT_DURATION end
    if db.limit == nil then db.limit = DEFAULT_LIMIT end
    if db.iconSize == nil then db.iconSize = DEFAULT_ICON_SIZE end
    if db.iconZoomPct == nil then db.iconZoomPct = DEFAULT_ICON_ZOOM_PCT end
    if db.spacing == nil then db.spacing = DEFAULT_SPACING end
    if db.growthDirection == nil then db.growthDirection = DEFAULT_GROWTH_DIRECTION end
    if db.tooltipOnMouseover == nil then db.tooltipOnMouseover = false end
    if db.showLastCastMS == nil then db.showLastCastMS = DEFAULT_SHOW_LAST_CAST_MS end
    if db.showLastCastMSFontSize == nil then db.showLastCastMSFontSize = DEFAULT_SHOW_LAST_CAST_MS_FONT_SIZE end
    if db.anchorX == nil then db.anchorX = DEFAULT_ANCHOR_X end
    if db.anchorY == nil then db.anchorY = DEFAULT_ANCHOR_Y end
    if db.positionUnlocked == nil then db.positionUnlocked = false end
    if type(db.blacklist) ~= "table" then
        db.blacklist = {}
        for i, v in ipairs(DEFAULT_BLACKLIST) do
            db.blacklist[i] = v
        end
    end

    db.duration = tonumber(db.duration) or DEFAULT_DURATION
    if db.duration < 0.1 then db.duration = 0.1 end
    if db.duration > 30 then db.duration = 30 end

    db.limit = math.floor((tonumber(db.limit) or DEFAULT_LIMIT) + 0.5)
    if db.limit < 1 then db.limit = 1 end
    if db.limit > 20 then db.limit = 20 end

    db.iconSize = math.floor((tonumber(db.iconSize) or DEFAULT_ICON_SIZE) + 0.5)
    if db.iconSize < 16 then db.iconSize = 16 end
    if db.iconSize > 96 then db.iconSize = 96 end

    db.iconZoomPct = math.floor((tonumber(db.iconZoomPct) or DEFAULT_ICON_ZOOM_PCT) + 0.5)
    if db.iconZoomPct < 0 then db.iconZoomPct = 0 end
    if db.iconZoomPct > 100 then db.iconZoomPct = 100 end

    db.spacing = math.floor((tonumber(db.spacing) or DEFAULT_SPACING) + 0.5)
    if db.spacing < 0 then db.spacing = 0 end
    if db.spacing > 20 then db.spacing = 20 end

    db.growthDirection = string.upper(tostring(db.growthDirection or DEFAULT_GROWTH_DIRECTION))
    if db.growthDirection ~= "UP" and db.growthDirection ~= "DOWN" and db.growthDirection ~= "LEFT" and db.growthDirection ~= "RIGHT" then
        db.growthDirection = DEFAULT_GROWTH_DIRECTION
    end

    db.tooltipOnMouseover = db.tooltipOnMouseover and true or false
    db.showLastCastMS = db.showLastCastMS and true or false
    db.showLastCastMSFontSize = math.floor((tonumber(db.showLastCastMSFontSize) or DEFAULT_SHOW_LAST_CAST_MS_FONT_SIZE) + 0.5)
    if db.showLastCastMSFontSize < 8 then db.showLastCastMSFontSize = 8 end
    if db.showLastCastMSFontSize > 32 then db.showLastCastMSFontSize = 32 end

    db.anchorX = FN and FN.RoundToNearestPixel and FN:RoundToNearestPixel(db.anchorX) or math.floor(tonumber(db.anchorX) or 0)
    db.anchorY = FN and FN.RoundToNearestPixel and FN:RoundToNearestPixel(db.anchorY) or math.floor(tonumber(db.anchorY) or 0)

    return db
end

function AG:IsEnabled()
    local db = self:EnsureDB()
    return db.enabled == true
end

function AG:IsPositionUnlocked()
    local db = self:EnsureDB()
    return db.positionUnlocked == true
end

function AG:RebuildBlacklist()
    local db = self:EnsureDB()
    self._blacklist = BuildBlacklistSet(db.blacklist)
end

function AG:GetContainerSize()
    local db = self:EnsureDB()
    local growth = string.upper(tostring(db.growthDirection or DEFAULT_GROWTH_DIRECTION))
    local horizontal = (growth == "LEFT" or growth == "RIGHT")
    local length = (db.iconSize * db.limit) + (db.spacing * math.max(0, db.limit - 1))
    local width = horizontal and length or db.iconSize
    local height = horizontal and db.iconSize or length
    return math.max(1, width), math.max(1, height)
end

function AG:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function AG:GetFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    if not self.Anchor then
        return db.anchorX, db.anchorY
    end

    local centerX, centerY = self.Anchor:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if centerX and centerY and parentCenterX and parentCenterY then
        if FN and FN.RoundToNearestPixel then
            return FN:RoundToNearestPixel(centerX - parentCenterX), FN:RoundToNearestPixel(centerY - parentCenterY)
        end
        return math.floor((centerX - parentCenterX) + 0.5), math.floor((centerY - parentCenterY) + 0.5)
    end

    local _, _, _, x, y = self.Anchor:GetPoint(1)
    if FN and FN.RoundToNearestPixel then
        return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
    end
    return math.floor((tonumber(x) or 0) + 0.5), math.floor((tonumber(y) or 0) + 0.5)
end

function AG:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function AG:SetAnchorOffsets(x, y)
    local db = self:EnsureDB()
    if FN and FN.RoundToNearestPixel then
        db.anchorX = FN:RoundToNearestPixel(x)
        db.anchorY = FN:RoundToNearestPixel(y)
    else
        db.anchorX = math.floor((tonumber(x) or 0) + 0.5)
        db.anchorY = math.floor((tonumber(y) or 0) + 0.5)
    end
    self:ApplyAnchorPoint()
end

function AG:UpdateDragHandleReadout()
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

function AG:UpdateDragHandle()
    if not self.Anchor then
        return
    end

    if not self.DragHandle and FN and FN.CreateAnchorController then
        self.DragHandle = FN:CreateAnchorController({
            parent = self.Anchor,
            moveFrame = self.Anchor,
            elementName = self.AnchorDisplayName,
            nudgeStep = ANCHOR_STEP_PX,
            extraVerticalPadding = ANCHOR_EXTRA_VERTICAL_PADDING,
            labelFontSize = ANCHOR_LABEL_FONT_SIZE,
            isMoveEnabled = function()
                return AG:IsPositionUnlocked()
            end,
            getOffsets = function()
                return AG:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                AG:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                AG:StoreFlooredAnchorOffsetsFromFrame()
                AG:ApplyAnchorPoint()
                AG:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(AG, false))
                or function()
                    AG:SetPositionUnlocked(false)
                end,
        })
    end

    if not self.DragHandle then
        return
    end

    if self.DragHandle.SetElementName then
        self.DragHandle:SetElementName(self.AnchorDisplayName or "Element")
    end

    self.DragHandle:SetShown(self:IsPositionUnlocked())
    self:UpdateDragHandleReadout()
end

function AG:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false
    self:UpdateVisibility()

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Action GCD Streamer position unlocked.")
    else
        print("|cffffd200Nexus:|r Action GCD Streamer position locked.")
    end
end

function AG:EnsureAnchor()
    if self.Anchor then
        return self.Anchor
    end

    local width, height = self:GetContainerSize()
    local anchor
    if FN and FN.CreateAnchorFrame then
        anchor = FN:CreateAnchorFrame(UIParent, width, height, 1, 1)
    else
        anchor = CreateFrame("Frame", nil, UIParent)
        anchor:SetSize(width, height)
    end

    self.Anchor = anchor
    self.Anchor:SetFrameStrata("MEDIUM")
    self.Anchor:SetFrameLevel(50)
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    return self.Anchor
end

function AG:_ReleaseIconFrame(iconFrame)
    if not iconFrame then
        return
    end

    if iconFrame._ag then
        iconFrame._ag:Stop()
    end

    iconFrame._ag = nil
    iconFrame:Hide()
    iconFrame:ClearAllPoints()
    if iconFrame._tex then
        iconFrame._tex:SetTexture(nil)
        iconFrame._tex:SetTexCoord(0, 1, 0, 1)
    end
    if iconFrame._msText then
        iconFrame._msText:SetText("")
        iconFrame._msText:Hide()
    end
    iconFrame._spellID = nil
    iconFrame:EnableMouse(false)
    iconFrame:SetScript("OnEnter", nil)
    iconFrame:SetScript("OnLeave", nil)
    iconFrame:SetParent(nil)
end

function AG:ApplyIconTooltipBehavior(iconFrame)
    if not iconFrame then
        return
    end

    local db = self:EnsureDB()
    local enabled = db.tooltipOnMouseover == true and tonumber(iconFrame._spellID)
    iconFrame:EnableMouse(enabled and true or false)

    if not enabled then
        iconFrame:SetScript("OnEnter", nil)
        iconFrame:SetScript("OnLeave", nil)
        return
    end

    iconFrame:SetScript("OnEnter", function(frame)
        if not GameTooltip then
            return
        end

        local spellID = tonumber(frame._spellID)
        if not spellID then
            return
        end

        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        if GameTooltip.SetSpellByID then
            local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, spellID)
            if not ok and GameTooltip.SetHyperlink then
                GameTooltip:SetHyperlink("spell:" .. tostring(spellID))
            end
        elseif GameTooltip.SetHyperlink then
            GameTooltip:SetHyperlink("spell:" .. tostring(spellID))
        end
        GameTooltip:Show()
    end)

    iconFrame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
end

function AG:RefreshIconTooltipBehavior()
    for _, iconFrame in ipairs(self._icons) do
        self:ApplyIconTooltipBehavior(iconFrame)
    end
end

function AG:_AcquireIconFrame()
    local anchor = self:EnsureAnchor()
    local db = self:EnsureDB()

    local iconFrame = CreateFrame("Frame", nil, anchor)
    iconFrame:SetSize(db.iconSize, db.iconSize)
    iconFrame:SetFrameLevel((anchor:GetFrameLevel() or 0) + 5)

    local tex = iconFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(true)
    iconFrame._tex = tex

    local msText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msText:SetPoint("TOP", iconFrame, "BOTTOM", 0, -1)
    msText:SetWidth(db.iconSize + 8)
    msText:SetJustifyH("CENTER")
    msText:SetText("")
    msText:Hide()
    iconFrame._msText = msText
    ApplyMsTextStyle(iconFrame, db)

    return iconFrame
end

function AG:_Layout()
    local anchor = self:EnsureAnchor()
    local db = self:EnsureDB()
    local growth = string.upper(tostring(db.growthDirection or DEFAULT_GROWTH_DIRECTION))

    local width, height = self:GetContainerSize()
    if FN and FN.SetAnchorSize then
        FN:SetAnchorSize(anchor, width, height, 1, 1)
    else
        anchor:SetSize(width, height)
    end

    for i, iconFrame in ipairs(self._icons) do
        iconFrame:SetSize(db.iconSize, db.iconSize)
        ApplyTextureZoom(iconFrame._tex, db.iconZoomPct)
        ApplyMsTextStyle(iconFrame, db)
        if iconFrame._msText and iconFrame._msText.SetWidth then
            iconFrame._msText:SetWidth(db.iconSize + 8)
        end
        iconFrame:ClearAllPoints()
        if growth == "RIGHT" then
            if i == 1 then
                iconFrame:SetPoint("LEFT", anchor, "LEFT", 0, 0)
            else
                iconFrame:SetPoint("LEFT", self._icons[i - 1], "RIGHT", db.spacing, 0)
            end
        elseif growth == "UP" then
            if i == 1 then
                iconFrame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 0)
            else
                iconFrame:SetPoint("BOTTOM", self._icons[i - 1], "TOP", 0, db.spacing)
            end
        elseif growth == "DOWN" then
            if i == 1 then
                iconFrame:SetPoint("TOP", anchor, "TOP", 0, 0)
            else
                iconFrame:SetPoint("TOP", self._icons[i - 1], "BOTTOM", 0, -db.spacing)
            end
        else
            if i == 1 then
                iconFrame:SetPoint("RIGHT", anchor, "RIGHT", 0, 0)
            else
                iconFrame:SetPoint("RIGHT", self._icons[i - 1], "LEFT", -db.spacing, 0)
            end
        end
    end
end

function AG:ClearIcons()
    for i = #self._icons, 1, -1 do
        local f = self._icons[i]
        self._icons[i] = nil
        self:_ReleaseIconFrame(f)
    end
    self:_Layout()
end

function AG:_PushIcon(spellID, lastCastDeltaMs)
    local iconID = GetSpellIcon(spellID)
    if not iconID then
        return
    end

    local db = self:EnsureDB()
    local isFirstIcon = (#self._icons == 0)
    local iconFrame = self:_AcquireIconFrame()
    iconFrame._spellID = spellID
    iconFrame._tex:SetTexture(iconID)
    ApplyTextureZoom(iconFrame._tex, db.iconZoomPct)
    ApplyMsTextStyle(iconFrame, db)
    iconFrame:SetAlpha(1)

    if iconFrame._msText then
        if db.showLastCastMS and not isFirstIcon and lastCastDeltaMs and lastCastDeltaMs > 0 then
            iconFrame._msText:SetText(string.format("%.2fs", (tonumber(lastCastDeltaMs) or 0) / 1000))
            iconFrame._msText:Show()
        else
            iconFrame._msText:SetText("")
            iconFrame._msText:Hide()
        end
    end

    self:ApplyIconTooltipBehavior(iconFrame)
    iconFrame:Show()

    local ag = iconFrame:CreateAnimationGroup()
    iconFrame._ag = ag
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0)
    a:SetDuration(db.duration)
    a:SetSmoothing("OUT")

    ag:SetScript("OnFinished", function()
        for i = #AG._icons, 1, -1 do
            if AG._icons[i] == iconFrame then
                table.remove(AG._icons, i)
                break
            end
        end
        AG:_Layout()
        AG:_ReleaseIconFrame(iconFrame)
        AG:UpdateVisibility()
    end)

    table.insert(self._icons, 1, iconFrame)

    while #self._icons > db.limit do
        local old = table.remove(self._icons)
        self:_ReleaseIconFrame(old)
    end

    self:_Layout()
    self:UpdateVisibility()
    ag:Play()
end

function AG:UpdateVisibility()
    local anchor = self:EnsureAnchor()
    local showAnchor = self:IsPositionUnlocked() or (#self._icons > 0 and self:IsEnabled())
    anchor:SetShown(showAnchor)
    self:UpdateDragHandle()
end

function AG:ProcessCastSent(unit, target, castGUID, spellID)
    if unit ~= "player" then
        return
    end

    local id = tonumber(spellID)

    self._pendingSentCastsByGUID = self._pendingSentCastsByGUID or {}
    self._pendingSentSpellCounts = self._pendingSentSpellCounts or {}

    if castGUID then
        self._pendingSentCastsByGUID[castGUID] = id
    end

    if id then
        self._pendingSentSpellCounts[id] = (self._pendingSentSpellCounts[id] or 0) + 1
    end
end

function AG:ProcessCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then
        return
    end

    local id = tonumber(spellID)
    if not id then
        return
    end
    if self._blacklist[id] then
        return
    end

    local pendingByGUID = self._pendingSentCastsByGUID
    local pendingCounts = self._pendingSentSpellCounts

    if castGUID and pendingByGUID and pendingByGUID[castGUID] ~= nil then
        local sentID = pendingByGUID[castGUID]
        pendingByGUID[castGUID] = nil

        if sentID and pendingCounts and pendingCounts[sentID] then
            pendingCounts[sentID] = pendingCounts[sentID] - 1
            if pendingCounts[sentID] <= 0 then
                pendingCounts[sentID] = nil
            end
        end
    elseif pendingCounts and pendingCounts[id] then
        pendingCounts[id] = pendingCounts[id] - 1
        if pendingCounts[id] <= 0 then
            pendingCounts[id] = nil
        end
    end

    local nowMs
    if GetTimePreciseSec then
        nowMs = GetTimePreciseSec() * 1000
    elseif GetTime then
        nowMs = GetTime() * 1000
    end

    local deltaMs
    if nowMs and self._lastCastSucceededAtMs and self._lastCastSucceededAtMs > 0 then
        deltaMs = math.floor((nowMs - self._lastCastSucceededAtMs) + 0.5)
        if deltaMs < 0 then
            deltaMs = nil
        end
    end

    if nowMs then
        self._lastCastSucceededAtMs = nowMs
    end

    self:_PushIcon(id, deltaMs)
end

function AG:UpdateEventRegistration()
    self.frame = self.frame or CreateFrame("Frame")

    self.frame:UnregisterEvent("UNIT_SPELLCAST_SENT")
    self.frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    if self:IsEnabled() then
        self.frame:RegisterEvent("UNIT_SPELLCAST_SENT")
        self.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
end

function AG:Apply()
    self:EnsureDB()
    self:RebuildBlacklist()
    self:EnsureAnchor()
    self:UpdateEventRegistration()

    if not self:IsEnabled() then
        self._pendingSentCastsByGUID = nil
        self._pendingSentSpellCounts = nil
        self._lastCastSucceededAtMs = nil
        self:ClearIcons()
    else
        self:_Layout()
        self:RefreshIconTooltipBehavior()
    end

    self:UpdateVisibility()
end

function AG:OnSettingsChanged()
    self:Apply()
end

function AG:Toggle()
    local db = self:EnsureDB()
    db.enabled = not db.enabled
    self:Apply()
    print("|cffffd200Nexus:|r Action GCD Streamer " .. (db.enabled and "enabled" or "disabled") .. ".")
end

function AG:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "toggle" then
        self:Toggle()
        return true
    end

    if text == "on" or text == "enable" or text == "enabled" then
        local db = self:EnsureDB()
        db.enabled = true
        self:Apply()
        print("|cffffd200Nexus:|r Action GCD Streamer enabled.")
        return true
    end

    if text == "off" or text == "disable" or text == "disabled" then
        local db = self:EnsureDB()
        db.enabled = false
        self:Apply()
        print("|cffffd200Nexus:|r Action GCD Streamer disabled.")
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
        print("|cffffd200Nexus:|r /nx gcd, /nx gcd on, /nx gcd off, /nx gcd lock, /nx gcd unlock")
        print("|cffffd200Nexus:|r /nx gcd tooltip, /nx gcd tooltip on, /nx gcd tooltip off")
        print("|cffffd200Nexus:|r /nx gcd ms, /nx gcd ms on, /nx gcd ms off")
        return true
    end

    local subcmd, rest = string.match(text, "^(%S+)%s*(.-)%s*$")
    if subcmd == "tooltip" then
        local db = self:EnsureDB()
        local value = string.lower(tostring(rest or ""))
        value = string.match(value, "^%s*(.-)%s*$") or ""

        if value == "" or value == "toggle" then
            db.tooltipOnMouseover = not db.tooltipOnMouseover
        elseif value == "on" or value == "enable" or value == "enabled" then
            db.tooltipOnMouseover = true
        elseif value == "off" or value == "disable" or value == "disabled" then
            db.tooltipOnMouseover = false
        else
            print("|cffffd200Nexus:|r Unknown /nx gcd tooltip command. Use: /nx gcd tooltip on|off")
            return true
        end

        self:Apply()
        print("|cffffd200Nexus:|r Action GCD Streamer tooltip on mouseover " .. (db.tooltipOnMouseover and "enabled" or "disabled") .. ".")
        return true
    end

    if subcmd == "ms" then
        local db = self:EnsureDB()
        local value = string.lower(tostring(rest or ""))
        value = string.match(value, "^%s*(.-)%s*$") or ""

        if value == "" or value == "toggle" then
            db.showLastCastMS = not db.showLastCastMS
        elseif value == "on" or value == "enable" or value == "enabled" then
            db.showLastCastMS = true
        elseif value == "off" or value == "disable" or value == "disabled" then
            db.showLastCastMS = false
        else
            print("|cffffd200Nexus:|r Unknown /nx gcd ms command. Use: /nx gcd ms on|off")
            return true
        end

        self:Apply()
        print("|cffffd200Nexus:|r Action GCD Streamer last cast ms display " .. (db.showLastCastMS and "enabled" or "disabled") .. ".")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx gcd command. Use: /nx gcd help")
    return true
end

function AG:Init()
    self:EnsureDB()
    self:RebuildBlacklist()

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, unit, ...)
        if not AG:IsEnabled() then
            return
        end

        if event == "UNIT_SPELLCAST_SENT" then
            local target, castGUID, spellID = ...
            AG:ProcessCastSent(unit, target, castGUID, spellID)
            return
        end

        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local castGUID, spellID = ...
            AG:ProcessCastSucceeded(unit, castGUID, spellID)
        end
    end)

    self:Apply()
end

