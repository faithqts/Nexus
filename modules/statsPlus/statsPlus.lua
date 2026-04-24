local NX = Nexus
NX.StatsPlus = NX.StatsPlus or {}
local SP = NX.StatsPlus
local FN = NX.Functions

local DEFAULT_ANCHOR_X = 0
local DEFAULT_ANCHOR_Y = 0
local DEFAULT_FONT_SIZE = 14
local DEFAULT_ALIGNMENT = "LEFT"
local DEFAULT_STYLE = "VERTICAL"
local DEFAULT_GROWTH_DIRECTION = "DOWN"
local ANCHOR_WIDTH = 560
local ANCHOR_HEIGHT = 180
local LINE_PADDING_X = 12
local LINE_PADDING_Y = 10
local LINE_SPACING = 2
local UPDATE_THROTTLE_SECONDS = 0.25
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16

SP.Anchor = SP.Anchor or nil
SP.DragHandle = SP.DragHandle or nil
SP.EventFrame = SP.EventFrame or nil
SP.LinePool = SP.LinePool or {}
SP.LastText = SP.LastText or {}
SP._lastLayoutKey = SP._lastLayoutKey or nil
SP._lastLayoutAnchor = SP._lastLayoutAnchor or nil
SP.pendingRefresh = SP.pendingRefresh or false
SP.pendingAuraRecheck = SP.pendingAuraRecheck or false
SP.AnchorDisplayName = SP.AnchorDisplayName or "Stats+"

local COLOR = {
    PRIMARY = "4FE7F4",
    CRIT = "E35A5A",
    HASTE = "2ECC71",
    MASTERY = "F1C40F",
    VERS = "4F79FF",
    ARMOR = "B07CFF",
    AVOID = "6FA8DC",
}

local function Hex(h)
    return "|cff" .. h
end

local function SafeToNumber(value, fallback)
    local defaultValue = fallback
    if type(defaultValue) ~= "number" then
        defaultValue = tonumber(defaultValue) or 0
    end

    local ok, numberValue = pcall(tonumber, value)
    if not ok or type(numberValue) ~= "number" then
        return defaultValue
    end

    local safeOk, normalized = pcall(function()
        return numberValue + 0
    end)
    if safeOk and type(normalized) == "number" then
        return normalized
    end

    return defaultValue
end

local function Pct(x)
    local ok, formatted = pcall(string.format, "%.2f%%", x)
    if ok then
        return formatted
    end

    local okText, text = pcall(tostring, x)
    if okText then
        return text
    end

    return "0.00%"
end

local function SafeAdd(left, right, fallback)
    local ok, sum = pcall(function()
        return (left or 0) + (right or 0)
    end)
    if ok then
        return sum
    end

    if type(fallback) ~= "nil" then
        return fallback
    end

    return 0
end

local function SafeMin(limit, value, fallback)
    local ok, minValue = pcall(function()
        return math.min(limit, value)
    end)
    if ok then
        return minValue
    end

    if type(fallback) ~= "nil" then
        return fallback
    end

    return value
end

local function SafeCall(defaultValue, fn, ...)
    if not fn then
        return defaultValue
    end

    local ok, value = pcall(fn, ...)
    if ok and type(value) ~= "nil" then
        return value
    end

    return defaultValue
end

local function GetPrimaryStatFallbackName()
    local _, classTag = UnitClass("player")

    if classTag == "WARRIOR" or classTag == "DEATHKNIGHT" then
        return "Strength"
    end

    if classTag == "HUNTER" or classTag == "ROGUE" or classTag == "DEMONHUNTER" then
        return "Agility"
    end

    if classTag == "MAGE" or classTag == "PRIEST" or classTag == "WARLOCK" or classTag == "EVOKER" then
        return "Intellect"
    end

    local spec = GetSpecialization and GetSpecialization() or nil
    local specID = spec and GetSpecializationInfo and select(1, GetSpecializationInfo(spec)) or nil

    if classTag == "PALADIN" then
        if specID == 65 then
            return "Intellect"
        end
        return "Strength"
    end

    if classTag == "SHAMAN" then
        return "Intellect"
    end

    if classTag == "DRUID" then
        if specID == 102 or specID == 105 then
            return "Intellect"
        end
        return "Agility"
    end

    if classTag == "MONK" then
        if specID == 270 then
            return "Intellect"
        end
        return "Agility"
    end

    return "Strength"
end

local function GetPrimaryStatIndexByName(statName)
    if statName == "Agility" then
        return 2
    end
    if statName == "Intellect" then
        return 4
    end
    return 1
end

local function SafeToString(value, fallback)
    local ok, text = pcall(tostring, value)
    if ok then
        return text
    end

    return fallback or "0"
end

local function IsTankRole()
    local spec = GetSpecialization and GetSpecialization() or nil
    if spec and GetSpecializationRole and GetSpecializationRole(spec) == "TANK" then
        return true
    end
    return UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK"
end

local function GetPrimaryStat()
    local fallbackName = GetPrimaryStatFallbackName()
    local statIndex = GetPrimaryStatIndexByName(fallbackName)

    local statValue = 0
    if UnitStat then
        local ok, _, effective = pcall(UnitStat, "player", statIndex)
        if ok then
            statValue = effective or 0
        end
    end

    return fallbackName, SafeToString(statValue, "0")
end

local function GetArmorValue()
    if not UnitArmor then
        return 0
    end

    local ok, base, effective = pcall(UnitArmor, "player")
    if not ok then
        return 0
    end

    return effective or base or 0
end

local function GetArmorReductionPct(armorValue)
    local armor = SafeToNumber(armorValue, 0)
    if armor < 0 then
        armor = 0
    end

    local attackerLevel = SafeToNumber(SafeCall(1, UnitLevel, "player"), 1)
    attackerLevel = math.max(1, attackerLevel)

    if PaperDollFrame_GetArmorReduction then
        local ok, reduction = pcall(PaperDollFrame_GetArmorReduction, armor, attackerLevel)
        if ok then
            return math.max(0, SafeToNumber(reduction, 0))
        end
    end

    return 0
end

function SP:EnsureDB()
    NX.DB = NX.DB or {}
    NX.DB.statsPlus = NX.DB.statsPlus or {}
    local db = NX.DB.statsPlus

    if db.enabled == nil then db.enabled = false end
    if db.anchorX == nil then db.anchorX = DEFAULT_ANCHOR_X end
    if db.anchorY == nil then db.anchorY = DEFAULT_ANCHOR_Y end
    if db.positionUnlocked == nil then db.positionUnlocked = false end

    if db.style == nil then db.style = DEFAULT_STYLE end
    if db.textAlignment == nil then db.textAlignment = DEFAULT_ALIGNMENT end
    if db.textGrowthDirection == nil then db.textGrowthDirection = DEFAULT_GROWTH_DIRECTION end
    if db.fontSize == nil then db.fontSize = DEFAULT_FONT_SIZE end

    if db.showPrimaryStat == nil then db.showPrimaryStat = true end
    if db.showHaste == nil then db.showHaste = true end
    if db.showMastery == nil then db.showMastery = true end
    if db.showCriticalStrike == nil then db.showCriticalStrike = true end
    if db.showVersatility == nil then db.showVersatility = true end

    if db.showArmor == nil then db.showArmor = true end
    if db.showMeleeAvoidance == nil then db.showMeleeAvoidance = true end

    db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULT_ANCHOR_X)
    db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULT_ANCHOR_Y)

    local style = string.upper(tostring(db.style or DEFAULT_STYLE))
    if style ~= "VERTICAL" and style ~= "HORIZONTAL" then
        style = DEFAULT_STYLE
    end
    db.style = style

    local align = string.upper(tostring(db.textAlignment or DEFAULT_ALIGNMENT))
    if align ~= "LEFT" and align ~= "CENTER" and align ~= "RIGHT" then
        align = DEFAULT_ALIGNMENT
    end
    db.textAlignment = align

    local growth = string.upper(tostring(db.textGrowthDirection or DEFAULT_GROWTH_DIRECTION))
    if growth ~= "UP" and growth ~= "DOWN" then
        growth = DEFAULT_GROWTH_DIRECTION
    end
    db.textGrowthDirection = growth

    local size = math.floor((tonumber(db.fontSize) or DEFAULT_FONT_SIZE) + 0.5)
    if size < 0 then size = 0 end
    if size > 100 then size = 100 end
    db.fontSize = size

    return db
end

function SP:IsEnabled()
    return self:EnsureDB().enabled == true
end

function SP:IsPositionUnlocked()
    return self:EnsureDB().positionUnlocked == true
end

function SP:GetFontSize()
    return self:EnsureDB().fontSize or DEFAULT_FONT_SIZE
end

function SP:GetEffectiveFontSize()
    local size = self:GetFontSize()
    if size < 1 then
        return 1
    end
    return size
end

function SP:GetTextAlignment()
    return self:EnsureDB().textAlignment or DEFAULT_ALIGNMENT
end

function SP:GetStyle()
    return self:EnsureDB().style or DEFAULT_STYLE
end

function SP:GetTextGrowthDirection()
    return self:EnsureDB().textGrowthDirection or DEFAULT_GROWTH_DIRECTION
end

function SP:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function SP:GetFlooredAnchorOffsetsFromFrame()
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

function SP:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function SP:SetAnchorOffsets(x, y)
    local db = self:EnsureDB()
    db.anchorX = FN:RoundToNearestPixel(x)
    db.anchorY = FN:RoundToNearestPixel(y)
    self:ApplyAnchorPoint()
end

function SP:EnsureAnchor()
    if self.Anchor then
        return self.Anchor
    end

    local anchor = FN:CreateAnchorFrame(UIParent, ANCHOR_WIDTH, ANCHOR_HEIGHT)
    self.Anchor = anchor
    self:ApplyAnchorPoint()
    return anchor
end

function SP:EnsureLine(index)
    local line = self.LinePool[index]
    if line then
        return line
    end

    local anchor = self:EnsureAnchor()
    line = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    line:SetText("")
    self.LinePool[index] = line
    return line
end

function SP:ApplyLineLayout(visibleCount)
    local align = self:GetTextAlignment()
    local growthDirection = self:GetTextGrowthDirection()
    local fontSize = self:GetEffectiveFontSize()
    local lineCount = math.max(1, math.floor(tonumber(visibleCount) or 1))
    local layoutKey = string.format("%s|%s|%d|%d", align, growthDirection, fontSize, lineCount)

    if self._lastLayoutKey == layoutKey and self._lastLayoutAnchor == self.Anchor then
        return
    end

    for index = 1, 7 do
        local line = self:EnsureLine(index)
        line:ClearAllPoints()

        local isGrowingUp = growthDirection == "UP"
        local step = fontSize + LINE_SPACING
        local slotIndex = index
        if isGrowingUp then
            slotIndex = lineCount - index + 1
            if slotIndex < 1 then
                slotIndex = 1
            end
        end

        local y = LINE_PADDING_Y + ((slotIndex - 1) * step)

        if align == "CENTER" then
            if isGrowingUp then
                line:SetPoint("BOTTOM", self.Anchor, "BOTTOM", 0, y)
            else
                line:SetPoint("TOP", self.Anchor, "TOP", 0, -y)
            end
            line:SetJustifyH("CENTER")
        elseif align == "RIGHT" then
            if isGrowingUp then
                line:SetPoint("BOTTOMRIGHT", self.Anchor, "BOTTOMRIGHT", -LINE_PADDING_X, y)
            else
                line:SetPoint("TOPRIGHT", self.Anchor, "TOPRIGHT", -LINE_PADDING_X, -y)
            end
            line:SetJustifyH("RIGHT")
        else
            if isGrowingUp then
                line:SetPoint("BOTTOMLEFT", self.Anchor, "BOTTOMLEFT", LINE_PADDING_X, y)
            else
                line:SetPoint("TOPLEFT", self.Anchor, "TOPLEFT", LINE_PADDING_X, -y)
            end
            line:SetJustifyH("LEFT")
        end

        if FN and FN.ApplyAddonFont then
            FN:ApplyAddonFont(line, fontSize, "OUTLINE")
        end
        line:SetJustifyV(isGrowingUp and "BOTTOM" or "TOP")
    end

    self._lastLayoutKey = layoutKey
    self._lastLayoutAnchor = self.Anchor
end

function SP:SetLine(index, text)
    local line = self:EnsureLine(index)

    if type(text) == "nil" then
        self.LastText[index] = ""
        line:SetText("")
        line:Hide()
        return
    end

    self.LastText[index] = text
    line:SetText(text)
    line:Show()
end

function SP:BuildLines()
    local db = self:EnsureDB()
    local lines = {}

    if db.showPrimaryStat then
        local statName, statValue = GetPrimaryStat()
        lines[#lines + 1] = Hex(COLOR.PRIMARY) .. statName .. ": " .. SafeToString(statValue, "0") .. "|r"
    end

    if db.showHaste then
        local hasteRating = SafeCall(0, GetCombatRating, CR_HASTE_SPELL)
        local hastePct = SafeCall(0, UnitSpellHaste, "player")
        lines[#lines + 1] = Hex(COLOR.HASTE) .. "Haste: " .. SafeToString(hasteRating, "0") .. " - " .. Pct(hastePct) .. "|r"
    end

    if db.showMastery then
        local masteryRating = SafeCall(0, GetCombatRating, CR_MASTERY)
        local masteryPct = SafeCall(0, GetMasteryEffect)
        lines[#lines + 1] = Hex(COLOR.MASTERY) .. "Mastery: " .. SafeToString(masteryRating, "0") .. " - " .. Pct(masteryPct) .. "|r"
    end

    if db.showCriticalStrike then
        local critRating = SafeCall(0, GetCombatRating, CR_CRIT_SPELL)
        local critPct = SafeCall(0, GetCritChance)
        lines[#lines + 1] = Hex(COLOR.CRIT) .. "Crit: " .. SafeToString(critRating, "0") .. " - " .. Pct(critPct) .. "|r"
    end

    if db.showVersatility then
        local versRating = SafeCall(0, GetCombatRating, CR_VERSATILITY_DAMAGE_DONE)
        local versDoneExtra = SafeCall(0, GetVersatilityBonus, CR_VERSATILITY_DAMAGE_DONE)
        local versTakenExtra = SafeCall(nil, GetVersatilityBonus, CR_VERSATILITY_DAMAGE_TAKEN)
        if type(versTakenExtra) == "nil" then
            versTakenExtra = versDoneExtra
        end
        local versDoneBase = SafeCall(0, GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE)
        local versTakenBase = SafeCall(0, GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_TAKEN)
        local versDonePct = SafeAdd(versDoneBase, versDoneExtra, versDoneBase)
        local versTakenPct = SafeAdd(versTakenBase, versTakenExtra, versTakenBase)
        lines[#lines + 1] = Hex(COLOR.VERS)
            .. "Vers: " .. SafeToString(versRating, "0")
            .. " - " .. Pct(versDonePct)
            .. " / " .. Pct(versTakenPct)
            .. "|r"
    end

    if IsTankRole() then
        if db.showArmor then
            local armor = GetArmorValue()
            local reductionPct = GetArmorReductionPct(armor)
            lines[#lines + 1] = Hex(COLOR.ARMOR)
                .. "Armor: " .. SafeToString(armor, "0")
                .. " - " .. Pct(reductionPct)
                .. "|r"
        end

        if db.showMeleeAvoidance then
            local dodge = SafeCall(0, GetDodgeChance)
            local parry = SafeCall(0, GetParryChance)
            local block = SafeCall(0, GetBlockChance)
            local total = SafeAdd(dodge, parry, dodge)
            total = SafeAdd(total, block, total)
            total = SafeMin(100, total, total)
            lines[#lines + 1] = Hex(COLOR.AVOID) .. "Melee Avoidance: " .. Pct(total) .. "|r"
        end
    end

    return lines
end

function SP:BuildDisplayLines()
    local lines = self:BuildLines()

    if self:GetStyle() == "HORIZONTAL" then
        if #lines == 0 then
            return { "" }
        end
        return { table.concat(lines, " | ") }
    end

    return lines
end

function SP:UpdateDragHandleReadout()
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

function SP:UpdateDragHandle()
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
                return SP:IsPositionUnlocked()
            end,
            getOffsets = function()
                return SP:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                SP:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                SP:StoreFlooredAnchorOffsetsFromFrame()
                SP:ApplyAnchorPoint()
                SP:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(SP, false))
                or function()
                    SP:SetPositionUnlocked(false)
                end,
        })
    end

    if not self.DragHandle then
        return
    end

    if self.DragHandle.SetElementName then
        self.DragHandle:SetElementName(self.AnchorDisplayName or "Element")
    end

    if self.DragHandle.RefreshFonts then
        self.DragHandle:RefreshFonts()
    end

    self:UpdateDragHandleReadout()

    local showHandle = self:IsPositionUnlocked()
    self.DragHandle:SetShown(showHandle)
    self.DragHandle:EnableMouse(showHandle)
end

function SP:HideAll()
    if self.Anchor then
        self.Anchor:Hide()
    end

    for i = 1, #self.LinePool do
        local line = self.LinePool[i]
        if line then
            line:Hide()
        end
    end

    if self.DragHandle then
        self.DragHandle:Hide()
        self.DragHandle:EnableMouse(false)
    end
end

function SP:UpdateAll()
    self:EnsureDB()

    if not self:IsEnabled() then
        self:EnsureAnchor()
        self:ApplyAnchorPoint()

        for i = 1, #self.LinePool do
            local line = self.LinePool[i]
            if line then
                line:Hide()
                line:SetText("")
            end
        end

        self.Anchor:SetShown(self:IsPositionUnlocked())
        self:UpdateDragHandle()
        return
    end

    local lines = self:BuildDisplayLines()
    self:EnsureAnchor()
    self:ApplyAnchorPoint()
    self:ApplyLineLayout(#lines)

    local maxLines = 7
    for i = 1, maxLines do
        self:SetLine(i, lines[i])
    end

    self.Anchor:Show()
    self:UpdateDragHandle()
end

function SP:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false

    self:UpdateAll()

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Stats+ position unlocked.")
    else
        print("|cffffd200Nexus:|r Stats+ position locked.")
    end
end

function SP:Toggle()
    local db = self:EnsureDB()
    db.enabled = not db.enabled
    self:OnSettingsChanged()

    local state = db.enabled and "enabled" or "disabled"
    print("|cffffd200Nexus:|r Stats+ " .. state .. ".")
end

function SP:HandleNxSlash(msg)
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
        print("|cffffd200Nexus:|r /nx stats, /nx stats lock, /nx stats unlock, /nx stats help")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx stats command. Use: /nx stats help")
    return true
end

function SP:ScheduleUpdate()
    if self.pendingRefresh then
        return
    end

    self.pendingRefresh = true
    C_Timer.After(UPDATE_THROTTLE_SECONDS, function()
        SP.pendingRefresh = false
        SP:UpdateAll()
    end)
end

function SP:ScheduleAuraRecheck()
    if self.pendingAuraRecheck then
        return
    end

    self.pendingAuraRecheck = true
    C_Timer.After(0.4, function()
        SP.pendingAuraRecheck = false
        SP:UpdateAll()
    end)
end

function SP:OnSettingsChanged()
    self:UpdateAll()
end

function SP:OnSettingsClosed()
    self:SetPositionUnlocked(false, true)
end

function SP:Init()
    self:EnsureDB()

    if self.EventFrame then
        self:UpdateAll()
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterUnitEvent("UNIT_STATS", "player")
    frame:RegisterUnitEvent("UNIT_RESISTANCES", "player")
    frame:RegisterEvent("COMBAT_RATING_UPDATE")
    frame:RegisterEvent("MASTERY_UPDATE")

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then
            return
        end
        if event == "UNIT_AURA" and unit and unit ~= "player" then
            return
        end
        SP:ScheduleUpdate()
        if event == "UNIT_AURA" then
            SP:ScheduleAuraRecheck()
        end
    end)

    self.EventFrame = frame

    C_Timer.After(0, function()
        SP:UpdateAll()
    end)
end



