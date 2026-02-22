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

local function Pct(x)
    return string.format("%.2f%%", tonumber(x) or 0)
end

local function IsTankRole()
    local spec = GetSpecialization and GetSpecialization() or nil
    if spec and GetSpecializationRole and GetSpecializationRole(spec) == "TANK" then
        return true
    end
    return UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK"
end

local function GetPrimaryStat()
    local str = select(2, UnitStat("player", 1)) or 0
    local agi = select(2, UnitStat("player", 2)) or 0
    local intl = select(2, UnitStat("player", 4)) or 0

    if agi >= str and agi >= intl then
        return "Agility", agi
    end
    if str >= agi and str >= intl then
        return "Strength", str
    end
    return "Intellect", intl
end

local function GetArmorValue()
    local base, effective = UnitArmor("player")
    return effective or base or 0
end

local function GetArmorReductionPct(armorValue)
    local armor = tonumber(armorValue) or 0
    if armor < 0 then
        armor = 0
    end

    local attackerLevel = UnitLevel and UnitLevel("player") or 0
    attackerLevel = math.max(1, tonumber(attackerLevel) or 1)

    if PaperDollFrame_GetArmorReduction then
        local ok, reduction = pcall(PaperDollFrame_GetArmorReduction, armor, attackerLevel)
        if ok and type(reduction) == "number" then
            return math.max(0, reduction)
        end
    end

    return 0
end

function SP:EnsureDB()
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
end

function SP:SetLine(index, text)
    local line = self:EnsureLine(index)
    local value = text or ""
    if self.LastText[index] ~= value then
        self.LastText[index] = value
        line:SetText(value)
    end
    if value == "" then
        line:Hide()
    else
        line:Show()
    end
end

function SP:BuildLines()
    local db = self:EnsureDB()
    local lines = {}

    if db.showPrimaryStat then
        local statName, statValue = GetPrimaryStat()
        lines[#lines + 1] = Hex(COLOR.PRIMARY) .. statName .. ": " .. tostring(statValue) .. "|r"
    end

    if db.showHaste then
        local hasteRating = GetCombatRating and (GetCombatRating(CR_HASTE_SPELL) or 0) or 0
        local hastePct = UnitSpellHaste and (UnitSpellHaste("player") or 0) or 0
        lines[#lines + 1] = Hex(COLOR.HASTE) .. "Haste: " .. tostring(hasteRating) .. " - " .. Pct(hastePct) .. "|r"
    end

    if db.showMastery then
        local masteryRating = GetCombatRating and (GetCombatRating(CR_MASTERY) or 0) or 0
        local masteryPct = GetMasteryEffect and (GetMasteryEffect() or 0) or 0
        lines[#lines + 1] = Hex(COLOR.MASTERY) .. "Mastery: " .. tostring(masteryRating) .. " - " .. Pct(masteryPct) .. "|r"
    end

    if db.showCriticalStrike then
        local critRating = GetCombatRating and (GetCombatRating(CR_CRIT_SPELL) or 0) or 0
        local critPct = GetCritChance and (GetCritChance() or 0) or 0
        lines[#lines + 1] = Hex(COLOR.CRIT) .. "Crit: " .. tostring(critRating) .. " - " .. Pct(critPct) .. "|r"
    end

    if db.showVersatility then
        local versRating = GetCombatRating and (GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) or 0) or 0
        local versDoneExtra = GetVersatilityBonus and (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) or 0) or 0
        local versTakenExtra = GetVersatilityBonus and (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN) or versDoneExtra) or versDoneExtra
        local versDonePct = (GetCombatRatingBonus and (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0) or 0) + versDoneExtra
        local versTakenPct = (GetCombatRatingBonus and (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0) or 0) + versTakenExtra
        lines[#lines + 1] = Hex(COLOR.VERS)
            .. "Vers: " .. tostring(versRating)
            .. " - " .. Pct(versDonePct)
            .. " / " .. Pct(versTakenPct)
            .. "|r"
    end

    if IsTankRole() then
        if db.showArmor then
            local armor = GetArmorValue()
            local reductionPct = GetArmorReductionPct(armor)
            lines[#lines + 1] = Hex(COLOR.ARMOR)
                .. "Armor: " .. tostring(armor)
                .. " - " .. Pct(reductionPct)
                .. "|r"
        end

        if db.showMeleeAvoidance then
            local dodge = GetDodgeChance and (GetDodgeChance() or 0) or 0
            local parry = GetParryChance and (GetParryChance() or 0) or 0
            local block = GetBlockChance and (GetBlockChance() or 0) or 0
            local total = math.min(100, dodge + parry + block)
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
        self:SetLine(i, lines[i] or "")
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



