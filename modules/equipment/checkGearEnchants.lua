local NX = Nexus
NX.Equipment = NX.Equipment or {}

local EQ = NX.Equipment
local FN = NX.Functions

local SLOT_NAMES = {
    [1] = "HELM",
    [2] = "AMULET",
    [3] = "SHOULDERS",
    [5] = "CHEST",
    [6] = "BELT",
    [8] = "BOOTS",
    [9] = "BRACERS",
    [11] = "RING 1",
    [12] = "RING 2",
    [16] = "MAINHAND",
    [17] = "OFFHAND",
}

local DEFAULTS = {
    enabled = true,
    flashText = false,
    fontSize = 28,
    align = "CENTER",
    grow = "DOWN",
    anchorX = 0,
    anchorY = 180,
    positionUnlocked = false,
    blacklistCsv = "",
    blacklist = {},
    checkMissingGems = true,
    checkSocketRequirements = true,
    checkMissingEnchants = true,
    maxLevelOnly = false,
    levelAppropriateGear = false,
    considerEnchantId0Missing = true,
    gemCheckSlotsByInvSlotId = {
        [1] = true,
        [2] = true,
        [11] = true,
        [12] = true,
        [6] = true,
        [9] = true,
    },
    requiredSocketsByInvSlotId = {
        [2] = 2,
        [11] = 2,
        [12] = 2,
    },
    enchantCheckSlotsByInvSlotId = {
        [8] = true,
        [5] = true,
        [1] = true,
        [11] = true,
        [12] = true,
        [3] = true,
        [16] = true,
        [17] = true,
    },
}

local frame
local displayFrame
local pendingScan = false
local lastSignature
local lastResults = {}

local ANCHOR_WIDTH = 900
local ANCHOR_HEIGHT = 360
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16

EQ.Anchor = EQ.Anchor or nil
EQ.DragHandle = EQ.DragHandle or nil
EQ.AnchorDisplayName = EQ.AnchorDisplayName or "Equipment"

local function BuildBoolSetCopy(src)
    local out = {}
    for key, value in pairs(src or {}) do
        out[key] = value and true or false
    end
    return out
end

local function BuildNumberMapCopy(src)
    local out = {}
    for key, value in pairs(src or {}) do
        local num = tonumber(value)
        if num then
            out[key] = num
        end
    end
    return out
end

local function NormalizeAlign(value)
    value = string.upper(tostring(value or "CENTER"))
    if value == "LEFT" or value == "CENTER" or value == "RIGHT" then
        return value
    end
    return "CENTER"
end

local function NormalizeGrow(value)
    value = string.upper(tostring(value or "DOWN"))
    if value == "UP" or value == "DOWN" then
        return value
    end
    return "DOWN"
end

function EQ:EnsureDB()
    NX.DB.equipment = NX.DB.equipment or {}
    local db = NX.DB.equipment

    if db.enabled == nil then db.enabled = DEFAULTS.enabled end
    if db.flashText == nil then db.flashText = DEFAULTS.flashText end
    if db.fontSize == nil then db.fontSize = DEFAULTS.fontSize end
    if db.align == nil then db.align = DEFAULTS.align end
    if db.grow == nil then db.grow = DEFAULTS.grow end
    if db.anchorX == nil then db.anchorX = DEFAULTS.anchorX end
    if db.anchorY == nil then db.anchorY = DEFAULTS.anchorY end
    if db.positionUnlocked == nil then db.positionUnlocked = DEFAULTS.positionUnlocked end
    if db.blacklistCsv == nil then db.blacklistCsv = DEFAULTS.blacklistCsv end
    if db.blacklist == nil then db.blacklist = {} end
    if db.checkMissingGems == nil then db.checkMissingGems = DEFAULTS.checkMissingGems end
    if db.checkSocketRequirements == nil then db.checkSocketRequirements = DEFAULTS.checkSocketRequirements end
    if db.checkMissingEnchants == nil then db.checkMissingEnchants = DEFAULTS.checkMissingEnchants end
    if db.maxLevelOnly == nil then db.maxLevelOnly = DEFAULTS.maxLevelOnly end
    if db.levelAppropriateGear == nil then db.levelAppropriateGear = DEFAULTS.levelAppropriateGear end

    db.gemCheckSlotsByInvSlotId = db.gemCheckSlotsByInvSlotId or BuildBoolSetCopy(DEFAULTS.gemCheckSlotsByInvSlotId)
    db.requiredSocketsByInvSlotId = db.requiredSocketsByInvSlotId or BuildNumberMapCopy(DEFAULTS.requiredSocketsByInvSlotId)
    db.enchantCheckSlotsByInvSlotId = db.enchantCheckSlotsByInvSlotId or BuildBoolSetCopy(DEFAULTS.enchantCheckSlotsByInvSlotId)

    db.gemCheckSlotsByInvSlotId = BuildBoolSetCopy(db.gemCheckSlotsByInvSlotId)
    db.requiredSocketsByInvSlotId = BuildNumberMapCopy(db.requiredSocketsByInvSlotId)
    db.enchantCheckSlotsByInvSlotId = BuildBoolSetCopy(db.enchantCheckSlotsByInvSlotId)

    if type(db.blacklistCsv) ~= "string" then
        db.blacklistCsv = tostring(db.blacklistCsv or "")
    end

    db.enabled = db.enabled and true or false
    db.flashText = db.flashText and true or false
    db.fontSize = math.floor((tonumber(db.fontSize) or DEFAULTS.fontSize) + 0.5)
    if db.fontSize < 12 then db.fontSize = 12 end
    if db.fontSize > 64 then db.fontSize = 64 end
    db.align = NormalizeAlign(db.align)
    db.grow = NormalizeGrow(db.grow)
    db.checkMissingGems = db.checkMissingGems and true or false
    db.checkSocketRequirements = db.checkSocketRequirements and true or false
    db.checkMissingEnchants = db.checkMissingEnchants and true or false
    db.maxLevelOnly = db.maxLevelOnly and true or false
    db.levelAppropriateGear = db.levelAppropriateGear and true or false
    db.considerEnchantId0Missing = true

    if FN and FN.RoundToNearestPixel then
        db.anchorX = FN:RoundToNearestPixel(db.anchorX)
        db.anchorY = FN:RoundToNearestPixel(db.anchorY)
    else
        db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULTS.anchorX)
        db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULTS.anchorY)
    end
    db.positionUnlocked = db.positionUnlocked and true or false

    db._blacklistSet = nil

    return db
end

function EQ:BuildBlacklistSet()
    local db = self:EnsureDB()
    if db._blacklistSet then
        return db._blacklistSet
    end

    local set = {}
    local csv = db.blacklistCsv or ""
    for token in string.gmatch(csv, "[^,%s]+") do
        local id = tonumber(token)
        if id then
            set[id] = true
        end
    end

    if type(db.blacklist) == "table" then
        for id, value in pairs(db.blacklist) do
            local numericID = tonumber(id)
            if numericID and value then
                set[numericID] = true
            end
        end
    end

    db._blacklistSet = set
    return set
end

local function GetFilledGemsFromLink(link)
    if type(link) ~= "string" or link == "" then
        return 0
    end

    local parts = {}
    for value in string.gmatch(link .. ":", "([^:]*):") do
        parts[#parts + 1] = value
    end

    local gems = 0
    for i = 5, 8 do
        local gemID = tonumber(parts[i]) or 0
        if gemID > 0 then
            gems = gems + 1
        end
    end

    return gems
end

local function GetEmptySocketCountFromStats(link)
    if not (C_Item and C_Item.GetItemStats) then
        return 0
    end

    local stats = C_Item.GetItemStats(link)
    if type(stats) ~= "table" then
        return 0
    end

    local empty = 0
    for stat, count in pairs(stats) do
        if type(stat) == "string" and string.find(stat, "^EMPTY_SOCKET") then
            empty = empty + (tonumber(count) or 0)
        end
    end

    return empty
end

local function GetTotalSocketCount(link)
    local filled = GetFilledGemsFromLink(link)
    local empty = GetEmptySocketCountFromStats(link)
    local total = filled + empty
    return total, filled, empty
end

local function GetPlayerMaxLevel()
    if GetMaxLevelForLatestExpansion then
        local maxLevel = tonumber(GetMaxLevelForLatestExpansion())
        if maxLevel and maxLevel > 0 then
            return maxLevel
        end
    end

    if GetMaxLevelForPlayerExpansion then
        local maxLevel = tonumber(GetMaxLevelForPlayerExpansion())
        if maxLevel and maxLevel > 0 then
            return maxLevel
        end
    end

    return 90
end

local function GetItemRequiredLevel(itemRef)
    if not GetItemInfo then
        return nil
    end

    local _, _, _, _, minLevel = GetItemInfo(itemRef)
    return tonumber(minLevel)
end

function EQ:CanEvaluateByPlayerLevel()
    local db = self:EnsureDB()
    if not db.maxLevelOnly then
        return true
    end

    local playerLevel = tonumber(UnitLevel and UnitLevel("player")) or 0
    return playerLevel >= GetPlayerMaxLevel()
end

function EQ:IsSlotLevelAppropriate(itemID, link)
    local db = self:EnsureDB()
    if not db.levelAppropriateGear then
        return true
    end

    local playerLevel = tonumber(UnitLevel and UnitLevel("player")) or 0
    local requiredLevel = GetItemRequiredLevel(itemID)
    if not requiredLevel and link then
        requiredLevel = GetItemRequiredLevel(link)
    end
    if not requiredLevel or requiredLevel <= 0 then
        return false
    end

    return requiredLevel == playerLevel
end

function EQ:IsMissingGemsInSlot(slotID, blacklistSet)
    local db = self:EnsureDB()
    if not db.gemCheckSlotsByInvSlotId[slotID] then
        return false
    end

    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then
        return false
    end

    if blacklistSet[itemID] then
        return false
    end

    local link = GetInventoryItemLink("player", slotID)
    if not link then
        return false
    end

    if not self:IsSlotLevelAppropriate(itemID, link) then
        return false
    end

    local total, filled = GetTotalSocketCount(link)
    if total <= 0 then
        return false
    end

    return filled < total
end

function EQ:IsMissingRequiredSockets(slotID, blacklistSet)
    local db = self:EnsureDB()
    local required = tonumber(db.requiredSocketsByInvSlotId[slotID]) or 0
    if required <= 0 then
        return false
    end

    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then
        return false
    end

    if blacklistSet[itemID] then
        return false
    end

    local link = GetInventoryItemLink("player", slotID)
    if not link then
        return false
    end

    if not self:IsSlotLevelAppropriate(itemID, link) then
        return false
    end

    local total = GetTotalSocketCount(link)
    return total < required
end

local function IsWeaponOffhand(link)
    if not (C_Item and C_Item.GetItemInfoInstant) then
        return false
    end

    local _, _, _, _, _, itemClassID = C_Item.GetItemInfoInstant(link)
    local weaponClassID = LE_ITEM_CLASS_WEAPON or 2
    return itemClassID == weaponClassID
end

local TOOLTIP_LINE_ITEM_ENCHANTMENT_PERMANENT = 15

local function HasPermanentEnchantFromTooltip(slotID)
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then
        return false
    end

    local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID, true)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
        return false
    end

    for _, line in ipairs(data.lines) do
        if type(line) == "table" then
            local lineType = tonumber(line.type)
            if lineType == TOOLTIP_LINE_ITEM_ENCHANTMENT_PERMANENT then
                return true
            end
        end
    end

    return false
end

function EQ:IsMissingEnchantInSlot(slotID, blacklistSet)
    local db = self:EnsureDB()
    if not db.enchantCheckSlotsByInvSlotId[slotID] then
        return false
    end

    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then
        return false
    end

    if blacklistSet[itemID] then
        return false
    end

    local link = GetInventoryItemLink("player", slotID)
    if not link then
        return false
    end

    if not self:IsSlotLevelAppropriate(itemID, link) then
        return false
    end

    if slotID == 17 and not IsWeaponOffhand(link) then
        return false
    end

    local _, enchantIDString = string.match(link, "item:(%-?%d+):(%-?%d+)")
    local enchanted = enchantIDString ~= nil

    if enchanted and db.considerEnchantId0Missing then
        local enchantID = tonumber(enchantIDString) or 0
        if enchantID == 0 then
            enchanted = false
        end
    end

    if not enchanted and HasPermanentEnchantFromTooltip(slotID) then
        enchanted = true
    end

    return not enchanted
end

function EQ:Evaluate()
    local db = self:EnsureDB()
    local results = {}

    if not db.enabled then
        return results
    end

    if not self:CanEvaluateByPlayerLevel() then
        return results
    end

    local blacklistSet = self:BuildBlacklistSet()

    if db.checkMissingGems then
        for slotID in pairs(db.gemCheckSlotsByInvSlotId) do
            if self:IsMissingGemsInSlot(slotID, blacklistSet) then
                local slotName = SLOT_NAMES[slotID] or ("SLOT " .. tostring(slotID))
                results[#results + 1] = {
                    kind = "GEM",
                    slotID = slotID,
                    slotName = slotName,
                    message = "MISSING GEM: " .. slotName,
                }
            end
        end
    end

    if db.checkSocketRequirements then
        for slotID, required in pairs(db.requiredSocketsByInvSlotId) do
            if self:IsMissingRequiredSockets(slotID, blacklistSet) then
                local slotName = SLOT_NAMES[slotID] or ("SLOT " .. tostring(slotID))
                local link = GetInventoryItemLink("player", slotID)
                local total = 0
                if link then
                    total = GetTotalSocketCount(link)
                end
                results[#results + 1] = {
                    kind = "SOCKET_REQ",
                    slotID = slotID,
                    slotName = slotName,
                    message = string.format("MISSING SOCKETS: %s (%d/%d)", slotName, total, required),
                }
            end
        end
    end

    if db.checkMissingEnchants then
        for slotID in pairs(db.enchantCheckSlotsByInvSlotId) do
            if self:IsMissingEnchantInSlot(slotID, blacklistSet) then
                local slotName = SLOT_NAMES[slotID] or ("SLOT " .. tostring(slotID))
                results[#results + 1] = {
                    kind = "ENCHANT",
                    slotID = slotID,
                    slotName = slotName,
                    message = "MISSING ENCHANT: " .. slotName,
                }
            end
        end
    end

    local KIND_SORT_ORDER = {
        ENCHANT = 1,
        GEM = 2,
        SOCKET_REQ = 3,
    }

    table.sort(results, function(a, b)
        local aOrder = KIND_SORT_ORDER[a.kind] or 99
        local bOrder = KIND_SORT_ORDER[b.kind] or 99
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        if a.slotID ~= b.slotID then
            return a.slotID < b.slotID
        end
        return tostring(a.message or "") < tostring(b.message or "")
    end)

    return results
end

local function BuildSignature(results)
    local out = {}
    for i, result in ipairs(results) do
        out[i] = result.message
    end
    return table.concat(out, "|")
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

function EQ:GetFontPath()
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

function EQ:IsPositionUnlocked()
    local db = self:EnsureDB()
    return db.positionUnlocked == true
end

function EQ:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function EQ:GetFlooredAnchorOffsetsFromFrame()
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

function EQ:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function EQ:SetAnchorOffsets(x, y)
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

function EQ:UpdateDragHandleReadout()
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

function EQ:UpdateDragHandle()
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
                return EQ:IsPositionUnlocked()
            end,
            getOffsets = function()
                return EQ:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                EQ:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                EQ:StoreFlooredAnchorOffsetsFromFrame()
                EQ:ApplyAnchorPoint()
                EQ:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(EQ, false))
                or function()
                    EQ:SetPositionUnlocked(false)
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

function EQ:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false
    self:RunEvaluation(true)

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Equipment position unlocked.")
    else
        print("|cffffd200Nexus:|r Equipment position locked.")
    end
end

function EQ:EnsureDisplay()
    if displayFrame then
        return displayFrame
    end

    if FN and FN.CreateAnchorFrame then
        displayFrame = FN:CreateAnchorFrame(UIParent, ANCHOR_WIDTH, ANCHOR_HEIGHT, 1, 1)
        displayFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    else
        displayFrame = CreateFrame("Frame", "NexusEquipmentAlertsFrame", UIParent)
        displayFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    end
    self.Anchor = displayFrame
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    displayFrame:Hide()
    displayFrame.lines = {}
    return displayFrame
end

function EQ:UpdateDisplay(results)
    local db = self:EnsureDB()
    local host = self:EnsureDisplay()

    if not db.enabled or #results == 0 then
        host:SetShown(self:IsPositionUnlocked())
        for _, line in ipairs(host.lines) do
            SetLineFlashing(line, false)
            line:Hide()
            line:SetText("")
        end
        self:UpdateDragHandle()
        return
    end

    host:Show()
    local fontPath = self:GetFontPath()
    local lineHeight = db.fontSize + 8
    local align = NormalizeAlign(db.align)
    local grow = NormalizeGrow(db.grow)
    local justifyPoint = (grow == "UP") and "BOTTOM" or "TOP"
    local pointInsetX = 0
    if align == "LEFT" then
        justifyPoint = (grow == "UP") and "BOTTOMLEFT" or "TOPLEFT"
        pointInsetX = 8
    elseif align == "RIGHT" then
        justifyPoint = (grow == "UP") and "BOTTOMRIGHT" or "TOPRIGHT"
        pointInsetX = -8
    end

    for i, result in ipairs(results) do
        local line = host.lines[i]
        if not line then
            line = host:CreateFontString(nil, "OVERLAY")
            host.lines[i] = line
        end

        line:SetFont(fontPath, db.fontSize, "OUTLINE")
        line:SetWidth(0)
        line:SetJustifyH(align)
        line:SetJustifyV("MIDDLE")
        line:SetText(result.message)
        line:ClearAllPoints()
        local direction = (grow == "UP") and 1 or -1
        local yOffset = ((i - 1) * lineHeight) * direction
        line:SetPoint(justifyPoint, host, justifyPoint, pointInsetX, yOffset)

        if result.kind == "GEM" then
            line:SetTextColor(1, 0.35, 0.35, 1)
        elseif result.kind == "ENCHANT" then
            line:SetTextColor(1, 0.65, 0.25, 1)
        else
            line:SetTextColor(1, 0.82, 0.2, 1)
        end

        SetLineFlashing(line, db.flashText)
        line:Show()
    end

    for i = #results + 1, #host.lines do
        SetLineFlashing(host.lines[i], false)
        host.lines[i]:Hide()
        host.lines[i]:SetText("")
    end

    self:UpdateDragHandle()
end

function EQ:RefreshDisplayStyle()
    self:RunEvaluation(true)
end

function EQ:RunEvaluation(printAlways)
    local results = self:Evaluate()
    lastResults = results
    local signature = BuildSignature(results)

    if printAlways or signature ~= lastSignature then
        self:UpdateDisplay(results)
        lastSignature = signature
    end

    return results
end

function EQ:ScheduleEvaluation()
    if pendingScan then
        return
    end

    pendingScan = true
    C_Timer.After(0.15, function()
        pendingScan = false
        EQ:RunEvaluation(false)
    end)
end

function EQ:OnSettingsChanged()
    local db = self:EnsureDB()
    db._blacklistSet = nil
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    self:RunEvaluation(true)
end

function EQ:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "check" or text == "run" then
        self:RunEvaluation(true)
        return true
    end

    if text == "toggle" then
        local db = self:EnsureDB()
        db.enabled = not db.enabled
        print("|cffffd200Nexus:|r Equipment checks " .. (db.enabled and "enabled." or "disabled."))
        self:RunEvaluation(true)
        return true
    end

    if text == "on" or text == "enable" or text == "enabled" then
        local db = self:EnsureDB()
        db.enabled = true
        print("|cffffd200Nexus:|r Equipment checks enabled.")
        self:RunEvaluation(true)
        return true
    end

    if text == "off" or text == "disable" or text == "disabled" then
        local db = self:EnsureDB()
        db.enabled = false
        print("|cffffd200Nexus:|r Equipment checks disabled.")
        self:RunEvaluation(true)
        return true
    end

    if text == "flash" or text == "flash toggle" then
        local db = self:EnsureDB()
        db.flashText = not db.flashText
        print("|cffffd200Nexus:|r Equipment flashing text " .. (db.flashText and "enabled." or "disabled."))
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

    if text == "test" then
        self:RunEvaluation(true)
        return true
    end

    if text == "help" or text == "?" then
        print("|cffffd200Nexus:|r /nx equipment, /nx equipment check, /nx equipment on, /nx equipment off")
        print("|cffffd200Nexus:|r /nx equipment toggle, /nx equipment flash, /nx equipment anchor, /nx equipment test")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx equipment command. Use: /nx equipment help")
    return true
end

function EQ:Init()
    self:EnsureDB()

    if frame then
        self:ScheduleEvaluation()
        return
    end

    frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")

    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "UNIT_INVENTORY_CHANGED" and arg1 and arg1 ~= "player" then
            return
        end
        EQ:ScheduleEvaluation()
    end)

    C_Timer.After(0.5, function()
        EQ:RunEvaluation(false)
    end)
end



