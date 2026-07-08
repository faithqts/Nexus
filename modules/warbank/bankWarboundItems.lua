local NX = Nexus
NX.BankWarboundItems = NX.BankWarboundItems or {}
NX.Warbank = NX.BankWarboundItems

local WB = NX.BankWarboundItems
local FN = NX.Functions

local ALLOWED_UI_MAP_IDS = {
    [2339] = true,
    [2443] = true,
    [2393] = true,
    [1269] = true,
    [85] = true,
    [86] = true,
    [84] = true,
    [1264] = true,
    [1012] = true,
}

local DEFAULTS = {
    enabled = true,
    textSize = 48,
    align = "CENTER",
    flashText = false,
    color = "#FFD133",
    anchorX = 0,
    anchorY = 300,
    positionUnlocked = false,
}

local MESSAGE_TEXT = "Bank Warbound Gear"

local frame
local displayFrame
local pendingScan = false
local lastSignature
local lastShouldShow = false
local lastCount = 0

local ANCHOR_WIDTH = 700
local ANCHOR_HEIGHT = 120
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16

WB.Anchor = WB.Anchor or nil
WB.DragHandle = WB.DragHandle or nil
WB.AnchorDisplayName = WB.AnchorDisplayName or "Bank Warbound Gear"

local COLORS = {
    { hex = "#FF0000", name = "Red",                r = 255, g = 0,   b = 0   },
    { hex = "#FF8000", name = "Orange",             r = 255, g = 128, b = 0   },
    { hex = "#FFFF00", name = "Yellow",             r = 255, g = 255, b = 0   },
    { hex = "#80FF00", name = "Lime Green",         r = 128, g = 255, b = 0   },
    { hex = "#00FF00", name = "Green",              r = 0,   g = 255, b = 0   },
    { hex = "#00FF80", name = "Spring Green",       r = 0,   g = 255, b = 128 },
    { hex = "#00FFFF", name = "Cyan",               r = 0,   g = 255, b = 255 },
    { hex = "#0080FF", name = "Dodge Blue",         r = 0,   g = 128, b = 255 },
    { hex = "#0000FF", name = "Blue",               r = 0,   g = 0,   b = 255 },
    { hex = "#8000FF", name = "Purple",             r = 128, g = 0,   b = 255 },
    { hex = "#FF00FF", name = "Violet",             r = 255, g = 0,   b = 255 },
    { hex = "#FF0080", name = "Magenta",            r = 255, g = 0,   b = 128 },
    { hex = "#FF8888", name = "Coral",              r = 255, g = 136, b = 136 },
    { hex = "#FFCC88", name = "Light Salmon",       r = 255, g = 204, b = 136 },
    { hex = "#FFFF88", name = "Pale Yellow",        r = 255, g = 255, b = 136 },
    { hex = "#CCFF88", name = "Pale Green",         r = 204, g = 255, b = 136 },
    { hex = "#88FF88", name = "Pale Turquoise",     r = 136, g = 255, b = 136 },
    { hex = "#88FFCC", name = "Aquamarine",         r = 136, g = 255, b = 204 },
    { hex = "#88FFFF", name = "Light Cyan",         r = 136, g = 255, b = 255 },
    { hex = "#88CCFF", name = "Sky Blue",           r = 136, g = 204, b = 255 },
    { hex = "#8888FF", name = "Slate Blue",         r = 136, g = 136, b = 255 },
    { hex = "#CC88FF", name = "Medium Purple",      r = 204, g = 136, b = 255 },
    { hex = "#FF88FF", name = "Orchid",             r = 255, g = 136, b = 255 },
    { hex = "#FF88CC", name = "Light Pink",         r = 255, g = 136, b = 204 },
}

local function NormalizeAlign(value)
    value = string.upper(tostring(value or "CENTER"))
    if value == "LEFT" or value == "CENTER" or value == "RIGHT" then
        return value
    end
    return "CENTER"
end

local function NormalizeHex(hex)
    if type(hex) ~= "string" then return DEFAULTS.color end
    hex = hex:gsub("%s+", ""):upper()
    if not hex:match("^#") then hex = "#" .. hex end
    if #hex == 7 or #hex == 9 then return hex end
    return DEFAULTS.color
end

local function HexToRGB01(hex)
    hex = NormalizeHex(hex):gsub("#", "")

    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        return r / 255, g / 255, b / 255
    end
    if #hex == 8 then
        local r = tonumber(hex:sub(3, 4), 16) or 255
        local g = tonumber(hex:sub(5, 6), 16) or 255
        local b = tonumber(hex:sub(7, 8), 16) or 255
        return r / 255, g / 255, b / 255
    end
    return 1, 0.82, 0.2
end

function WB:GetColorList()
    local list = (NX.Common and NX.Common.LowDurability and NX.Common.LowDurability.GetColorList)
        and NX.Common.LowDurability:GetColorList()
        or COLORS
    return list
end

local function SetLineFlashing(line, enabled)
    if not line then
        return
    end

    if enabled then
        if not line._nxFlashAnim then
            local ag = line:CreateAnimationGroup()
            ag:SetLooping("BOUNCE")
            local alpha = ag:CreateAnimation("Alpha")
            alpha:SetFromAlpha(1)
            alpha:SetToAlpha(0.35)
            alpha:SetDuration(0.45)
            alpha:SetSmoothing("IN_OUT")
            line._nxFlashAnim = ag
        end
        if line._nxFlashAnim and not line._nxFlashAnim:IsPlaying() then
            line._nxFlashAnim:Play()
        end
        return
    end

    if line._nxFlashAnim and line._nxFlashAnim:IsPlaying() then
        line._nxFlashAnim:Stop()
    end
    line:SetAlpha(1)
end

function WB:GetFontPath()
    if NX.Functions and NX.Functions.GetAddonFontPath then
        local path = NX.Functions:GetAddonFontPath()
        if type(path) == "string" and path ~= "" then
            return path
        end
    end

    if GameFontNormal and GameFontNormal.GetFont then
        local path = select(1, GameFontNormal:GetFont())
        if type(path) == "string" and path ~= "" then
            return path
        end
    end

    return "Fonts\\FRIZQT__.TTF"
end

function WB:EnsureDB()
    NX.DB.alerts.bankWarboundItems = NX.DB.alerts.bankWarboundItems or {}
    local db = NX.DB.alerts.bankWarboundItems

    if db.enabled == nil then db.enabled = DEFAULTS.enabled end
    if db.textSize == nil then db.textSize = DEFAULTS.textSize end
    if db.align == nil then db.align = DEFAULTS.align end
    if db.flashText == nil then db.flashText = DEFAULTS.flashText end
    if db.color == nil then db.color = DEFAULTS.color end
    if db.anchorX == nil then db.anchorX = DEFAULTS.anchorX end
    if db.anchorY == nil then db.anchorY = DEFAULTS.anchorY end
    if db.positionUnlocked == nil then db.positionUnlocked = DEFAULTS.positionUnlocked end

    db.enabled = db.enabled and true or false
    db.textSize = math.floor(FN:ClampNumber(db.textSize, 12, 96) + 0.5)
    db.align = NormalizeAlign(db.align)
    db.flashText = db.flashText and true or false
    db.color = NormalizeHex(db.color)

    if FN and FN.RoundToNearestPixel then
        db.anchorX = FN:RoundToNearestPixel(db.anchorX)
        db.anchorY = FN:RoundToNearestPixel(db.anchorY)
    else
        db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULTS.anchorX)
        db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULTS.anchorY)
    end
    db.positionUnlocked = db.positionUnlocked and true or false

    return db
end

function WB:IsPositionUnlocked()
    local db = self:EnsureDB()
    return db.positionUnlocked == true
end

function WB:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function WB:GetFlooredAnchorOffsetsFromFrame()
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

function WB:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function WB:SetAnchorOffsets(x, y)
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

function WB:UpdateDragHandleReadout()
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

function WB:UpdateDragHandle()
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
                return WB:IsPositionUnlocked()
            end,
            getOffsets = function()
                return WB:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                WB:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                WB:StoreFlooredAnchorOffsetsFromFrame()
                WB:ApplyAnchorPoint()
                WB:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(WB, false))
                or function()
                    WB:SetPositionUnlocked(false)
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

function WB:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false
    self:RunEvaluation(true)

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Warbank position unlocked.")
    else
        print("|cffffd200Nexus:|r Warbank position locked.")
    end
end

function WB:InAllowedZone()
    if not (C_Map and C_Map.GetBestMapForUnit) then
        return false
    end
    local uiMapID = C_Map.GetBestMapForUnit("player")
    if not uiMapID then
        return false
    end
    return ALLOWED_UI_MAP_IDS[uiMapID] == true
end

function WB:CountWarboundUnboundGearInBags()
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
        return 0
    end
    if not (C_Item and C_Item.IsBoundToAccountUntilEquip and C_Item.IsBound) then
        return 0
    end

    local count = 0

    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local itemLoc = ItemLocation and ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc and itemLoc:IsValid() then
                    local isWarboundUntilEquip = C_Item.IsBoundToAccountUntilEquip(itemLoc)
                    local isAlreadyBound = C_Item.IsBound(itemLoc)

                    if isWarboundUntilEquip and not isAlreadyBound then
                        local isGear = true
                        if C_Item.IsEquippableItem then
                            local itemInfo = info.itemID or info.hyperlink
                            if itemInfo then
                                isGear = C_Item.IsEquippableItem(itemInfo) == true
                            end
                        end

                        if isGear then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    return count
end

function WB:EnsureDisplay()
    if displayFrame then
        return displayFrame
    end

    if FN and FN.CreateAnchorFrame then
        displayFrame = FN:CreateAnchorFrame(UIParent, ANCHOR_WIDTH, ANCHOR_HEIGHT, 1, 1)
        displayFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    else
        displayFrame = CreateFrame("Frame", nil, UIParent)
        displayFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    end

    self.Anchor = displayFrame
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()

    displayFrame:Hide()
    displayFrame.text = displayFrame:CreateFontString(nil, "OVERLAY")
    do
        local db = self:EnsureDB()
        displayFrame.text:SetFont(self:GetFontPath(), db.textSize or 48, "OUTLINE")
        displayFrame.text:SetJustifyH(NormalizeAlign(db.align))
        displayFrame.text:SetJustifyV("MIDDLE")
    end
    return displayFrame
end

function WB:UpdateDisplay(shouldShow, count)
    local db = self:EnsureDB()
    local host = self:EnsureDisplay()
    local line = host.text

    if not db.enabled or not shouldShow then
        host:SetShown(self:IsPositionUnlocked())
        if line then
            SetLineFlashing(line, false)
            line:Hide()
            line:SetText("")
        end
        self:UpdateDragHandle()
        return
    end

    local fontPath = self:GetFontPath()
    local align = NormalizeAlign(db.align)
    local fontSize = db.textSize
    local justifyPoint = "CENTER"
    if align == "LEFT" then
        justifyPoint = "LEFT"
    elseif align == "RIGHT" then
        justifyPoint = "RIGHT"
    end

    host:SetShown(self:IsPositionUnlocked() or (db.enabled and shouldShow))

    line:ClearAllPoints()
    line:SetPoint(justifyPoint, host, justifyPoint, 0, 0)
    line:SetWidth(host:GetWidth())
    line:SetFont(fontPath, fontSize, "OUTLINE")
    line:SetJustifyH(align)
    line:SetJustifyV("MIDDLE")
    line:SetText(MESSAGE_TEXT)
    local r, g, b = HexToRGB01(db.color)
    line:SetTextColor(r, g, b, 1)
    SetLineFlashing(line, db.flashText)
    line:Show()

    self:UpdateDragHandle()
end

function WB:RunEvaluation(printAlways)
    local db = self:EnsureDB()

    local shouldShow = false
    local count = 0

    if db.enabled and self:InAllowedZone() then
        count = self:CountWarboundUnboundGearInBags()
        shouldShow = count > 0
    end

    lastShouldShow = shouldShow
    lastCount = count

    local signature = table.concat({
        tostring(db.enabled),
        tostring(shouldShow),
        tostring(count),
        db.align,
        tostring(db.textSize),
        tostring(db.flashText),
        tostring(db.anchorX),
        tostring(db.anchorY),
        tostring(db.positionUnlocked),
    }, "|")

    if printAlways or signature ~= lastSignature then
        self:UpdateDisplay(shouldShow, count)
        lastSignature = signature
    end

    return shouldShow, count
end

function WB:RefreshDisplayStyle()
    self:UpdateDisplay(lastShouldShow, lastCount)
end

function WB:ScheduleEvaluation()
    if pendingScan then
        return
    end

    pendingScan = true
    C_Timer.After(0.10, function()
        pendingScan = false
        WB:RunEvaluation(false)
    end)
end

function WB:OnSettingsChanged()
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    self:RunEvaluation(true)
end

function WB:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "check" or text == "run" or text == "test" then
        self:RunEvaluation(true)
        return true
    end

    if text == "toggle" then
        local db = self:EnsureDB()
        db.enabled = not db.enabled
        print("|cffffd200Nexus:|r Warbank " .. (db.enabled and "enabled." or "disabled."))
        self:RunEvaluation(true)
        return true
    end

    if text == "on" or text == "enable" or text == "enabled" then
        local db = self:EnsureDB()
        db.enabled = true
        print("|cffffd200Nexus:|r Warbank enabled.")
        self:RunEvaluation(true)
        return true
    end

    if text == "off" or text == "disable" or text == "disabled" then
        local db = self:EnsureDB()
        db.enabled = false
        print("|cffffd200Nexus:|r Warbank disabled.")
        self:RunEvaluation(true)
        return true
    end

    if text == "flash" or text == "flash toggle" then
        local db = self:EnsureDB()
        db.flashText = not db.flashText
        print("|cffffd200Nexus:|r Warbank flashing text " .. (db.flashText and "enabled." or "disabled."))
        self:RunEvaluation(true)
        return true
    end

    if text == "anchor" or text == "anchor toggle" then
        self:SetPositionUnlocked(not self:IsPositionUnlocked())
        return true
    end

    if text == "anchor on" or text == "anchor show" then
        self:SetPositionUnlocked(true)
        return true
    end

    if text == "anchor off" or text == "anchor hide" then
        self:SetPositionUnlocked(false)
        return true
    end

    if text == "left" then
        local db = self:EnsureDB()
        db.align = "LEFT"
        self:RunEvaluation(true)
        return true
    end

    if text == "center" or text == "middle" then
        local db = self:EnsureDB()
        db.align = "CENTER"
        self:RunEvaluation(true)
        return true
    end

    if text == "right" then
        local db = self:EnsureDB()
        db.align = "RIGHT"
        self:RunEvaluation(true)
        return true
    end

    if text == "help" or text == "?" then
        print("|cffffd200Nexus:|r /nx warbank, /nx warbank on, /nx warbank off, /nx warbank toggle")
        print("|cffffd200Nexus:|r /nx warbank left, /nx warbank center, /nx warbank right, /nx warbank flash")
        print("|cffffd200Nexus:|r /nx warbank anchor, /nx warbank anchor on, /nx warbank anchor off")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx warbank command. Use: /nx warbank help")
    return true
end

function WB:Init()
    self:EnsureDB()

    if frame then
        self:ScheduleEvaluation()
        return
    end

    frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")

    frame:SetScript("OnEvent", function()
        WB:ScheduleEvaluation()
    end)

    C_Timer.After(0.5, function()
        WB:RunEvaluation(false)
    end)
end


