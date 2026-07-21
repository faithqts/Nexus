local NX = Nexus
NX.ClickableBuffs = NX.ClickableBuffs or {}
local CB = NX.ClickableBuffs
local FN = NX.Functions

local DEFAULT_BUTTON_SIZE = 48
local DEFAULT_TEXT_SIZE = 18
local DEFAULT_ICON_ZOOM_PCT = 15
local BUTTON_SPACING = 4
local MAX_PER_ROW = 12
local DEFAULT_ANCHOR_X = 0
local DEFAULT_ANCHOR_Y = 0
local TEXT_PADDING = 5
local ICON_BORDER_SIZE = 1
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16
local REFRESH_DEBOUNCE_SECONDS = 0.2

CB.Anchor = CB.Anchor or nil
CB.DragHandle = CB.DragHandle or nil
CB.Buttons = CB.Buttons or {}
CB.pendingRefresh = CB.pendingRefresh or false
CB.refreshScheduled = CB.refreshScheduled or false
CB.AnchorDisplayName = CB.AnchorDisplayName or "Clickable Buffs"

CB.tracked_spells_items = {
    { spellID = 462854, spellName = "Skyfury", text = "Skyfury", buff = true },
    {
        spellID = 364342,
        spellName = "Blessing of the Bronze",
        text = "Bronze",
        buff = true,
        altSpellIDs = {
            381732,
            381741,
            381746,
            381748,
            381749,
            381750,
            381751,
            381752,
            381753,
            381754,
            381756,
            381757,
            381758,
        },
    },
    { spellID = 1126, spellName = "Mark of the Wild", text = "MotW", buff = true },
    { spellID = 1459, spellName = "Arcane Intellect", text = "Arcane\nIntellect", buff = true },
    { spellID = 21562, spellName = "Power Word: Fortitude", text = "Fort", buff = true },
    { spellID = 6673, spellName = "Battle Shout", text = "Battle\nShout", buff = true },
    { spellID = 465, spellName = "Devotion Aura", text = "Devotion\nAura", buff = true, auraGroup = "PALADIN_AURA" },
    { spellID = 317920, spellName = "Concentration Aura", text = "Concentration\nAura", buff = true, auraGroup = "PALADIN_AURA" },

    { spellID = 318038, spellName = "Flametongue Weapon", text = "Flametongue\nWeapon", imbue = true, preferredHand = "OFF" },
    { spellID = 33757, spellName = "Windfury Weapon", text = "Windfury\nWeapon", imbue = true, preferredHand = "MAIN" },

    { spellID = 394328, spellName = "Amplifying Poison", text = "Amplifying\nPoison", poison = true, lethal = true },
    { spellID = 5763, spellName = "Mind-numbing Poison", text = "Numbing\nPoison", poison = true, lethal = true },
    { spellID = 2823, spellName = "Deadly Poison", text = "Deadly\nPoison", poison = true, lethal = true },
    { spellID = 315584, spellName = "Instant Poison", text = "Instant\nPoison", poison = true, lethal = true },
    { spellID = 8679, spellName = "Wound Poison", text = "Wound\nPoison", poison = true, lethal = true },

    { spellID = 5761, spellName = "Numbing Poison", text = "Numbing\nPoison", poison = true, lethal = false },
    { spellID = 381637, spellName = "Atrophic Poison", text = "Atrophic\nPoison", poison = true, lethal = false },
    { spellID = 3408, spellName = "Crippling Poison", text = "Crippling\nPoison", poison = true, lethal = false },

    { spellID = 433568, spellName = "Rite of Sanctification", text = "Sanctification", imbue = true, preferredHand = "MAIN" },
    { spellID = 433583, spellName = "Rite of Adjuration", text = "Adjuration", imbue = true, preferredHand = "MAIN" },

    { itemID = 241313, spellID = 1239755, spellName = "Haranir Phial of Ingenuity", text = "Ingenuity", flask = true },
    { itemID = 241317, spellID = 1236763, spellName = "Haranir Phial of Perception", text = "Perception", flask = true },
    { itemID = 241311, spellID = 1236767, spellName = "Haranir Phial of Finesse", text = "Finesse", flask = true },
    { itemID = 241325, spellID = 1235110, spellName = "Flask of the Blood Knights", text = "Haste", flask = true },
    { itemID = 241323, spellID = 1235108, spellName = "Flask of the Magisters", text = "Mastery", flask = true },
    { itemID = 241327, spellID = 1235111, spellName = "Flask of the Shattered Sun", text = "Crit", flask = true },
    { itemID = 241321, spellID = 1235057, spellName = "Flask of Thalassian Resistance", text = "Vers", flask = true },

    { itemID = 242273, spellName = "Blooming Feast", text = "Stat", food = true },
    { itemID = 255846, spellName = "Harandar Celebration", text = "Primary", food = true },
    { itemID = 242272, spellName = "Quel'dorei Medley", text = "Stat", food = true },
    { itemID = 255845, spellName = "Silvermoon Parade", text = "Primary", food = true },
    { itemID = 242275, spellName = "Royal Roast", text = "Primary", food = true },
    { itemID = 255847, spellName = "Impossibly Royal Roast", text = "Primary", food = true },
    { itemID = 255848, spellName = "Flora Frenzy", text = "Stat", food = true },
    { itemID = 242274, spellName = "Champion's Bento", text = "Stat", food = true },
    { itemID = 242745, spellName = "Hearty Blooming Feast", text = "Hearty\nStat", food = true },
    { itemID = 266996, spellName = "Hearty Harandar Celebration", text = "Hearty\nPrimary", food = true },
    { itemID = 242744, spellName = "Hearty Quel'dorei Medley", text = "Hearty\nStat", food = true },
    { itemID = 266986, spellName = "Hearty Quel'dorei Medley", text = "Hearty\nStat", food = true },
    { itemID = 266985, spellName = "Hearty Silvermoon Parade", text = "Hearty\nPrimary", food = true },
    { itemID = 242747, spellName = "Hearty Royal Roast", text = "Hearty\nPrimary", food = true },
    { itemID = 268679, spellName = "Hearty Impossibly Royal Roast", text = "Hearty\nPrimary", food = true },
    { itemID = 267000, spellName = "Hearty Flora Frenzy", text = "Hearty\nStat", food = true },
    { itemID = 268680, spellName = "Hearty Flora Frenzy", text = "Hearty\nStat", food = true },
    { itemID = 242746, spellName = "Hearty Champion's Bento", text = "Hearty\nStat", food = true },

    { itemID = 243733, spellName = "Thalassian Phoenix Oil", text = "Weapon\nBuff", oil = true },
    { itemID = 243737, spellName = "Smuggler's Enchanted Edge", text = "Weapon\nBuff", oil = true },
    { itemID = 243735, spellName = "Oil of Dawn", text = "Weapon\nBuff", oil = true },
    { itemID = 237367, spellName = "Refulgent Weightstone", text = "Weapon\nBuff", oil = true },
    { itemID = 237372, spellName = "Refulgent Razorstone", text = "Weapon\nBuff", oil = true },
    { itemID = 237370, spellName = "Refulgent Whetstone", text = "Weapon\nBuff", oil = true },
    { itemID = 222503, spellName = "Refulgent Whetstone", text = "Weapon\nBuff", oil = true },
}

local function BuildPlayerAuraSnapshot()
    if not (AuraUtil and AuraUtil.ForEachAura) then
        return nil
    end

    local snapshot = {
        spellIDs = {},
        names = {},
    }

    local ok = pcall(function()
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(auraData, ...)
            if type(auraData) ~= "table" then
                local name = auraData
                local spellID = select(9, ...)
                if spellID then
                    snapshot.spellIDs[spellID] = true
                end
                if name then
                    snapshot.names[name] = true
                end
                return false
            end
            if auraData.spellId then
                snapshot.spellIDs[auraData.spellId] = true
            end
            if auraData.name then
                snapshot.names[auraData.name] = true
            end
            return false
        end, true)
    end)

    if not ok then
        return nil
    end

    return snapshot
end

local function HasPlayerAuraBySpellID(spellID, snapshot)
    if not spellID then
        return false
    end

    if snapshot then
        return snapshot.spellIDs[spellID] == true
    end

    if GetPlayerAuraBySpellID then
        local ok, aura = pcall(GetPlayerAuraBySpellID, spellID)
        if ok and aura then
            return true
        end
    end

    if AuraUtil and AuraUtil.ForEachAura then
        local found = false
        local ok = pcall(function()
            AuraUtil.ForEachAura("player", "HELPFUL", nil, function(auraData)
                if type(auraData) == "table" and auraData.spellId == spellID then
                    found = true
                    return true
                end
                return false
            end, true)
        end)
        if ok and found then
            return true
        end
    end

    return false
end

local function HasPlayerAuraByName(name, snapshot)
    if not name or name == "" then
        return false
    end

    if snapshot then
        return snapshot.names[name] == true
    end

    if not AuraUtil or not AuraUtil.FindAuraByName then
        return false
    end

    local ok, aura = pcall(AuraUtil.FindAuraByName, name, "player", "HELPFUL")
    return ok and aura ~= nil
end

local function HasPlayerAuraForEntry(entry, snapshot)
    if type(entry) ~= "table" then
        return false
    end

    if entry.spellID and HasPlayerAuraBySpellID(entry.spellID, snapshot) then
        return true
    end

    if type(entry.altSpellIDs) == "table" then
        for _, spellID in ipairs(entry.altSpellIDs) do
            if type(spellID) == "number" and HasPlayerAuraBySpellID(spellID, snapshot) then
                return true
            end
        end
    end

    return false
end

local function IsSpellKnownForPlayer(spellID)
    if not spellID then
        return false
    end

    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end

    if C_Spell and C_Spell.IsSpellKnown then
        local ok, known = pcall(C_Spell.IsSpellKnown, spellID)
        if ok and known then
            return true
        end
    end

    return false
end

local function HasItemInBags(itemID)
    if not itemID then
        return false
    end

    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false)
        return ok and (count or 0) > 0
    end

    return false
end

local function GetWeaponEnchantState()
    if not GetWeaponEnchantInfo then
        return false, false, 0
    end

    local hasMain, _, _, _, hasOff = GetWeaponEnchantInfo()
    local count = 0
    if hasMain then
        count = count + 1
    end
    if hasOff then
        count = count + 1
    end
    return hasMain and true or false, hasOff and true or false, count
end

local function IsWeaponEquipLocation(equipLoc)
    return equipLoc == "INVTYPE_WEAPON"
        or equipLoc == "INVTYPE_WEAPONMAINHAND"
        or equipLoc == "INVTYPE_WEAPONOFFHAND"
        or equipLoc == "INVTYPE_2HWEAPON"
end

local function IsWeaponInSlot(slotID)
    if not GetInventoryItemID or not (C_Item and C_Item.GetItemInfoInstant) then
        return slotID == 16
    end

    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then
        return false
    end

    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemID)
    return IsWeaponEquipLocation(equipLoc)
end

local function GetSpellVisual(spellID, fallbackName)
    local name
    local icon

    if C_Spell then
        if C_Spell.GetSpellName then
            name = C_Spell.GetSpellName(spellID)
        end
        if C_Spell.GetSpellTexture then
            icon = C_Spell.GetSpellTexture(spellID)
        end

        if (not name or not icon) and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                name = name or info.name
                icon = icon or info.iconID
            end
        end
    end

    if name then
        return name, icon or 134400
    end

    return fallbackName or ("Spell " .. tostring(spellID or 0)), icon or 134400
end

local function GetItemVisual(itemID, fallbackName)
    local icon
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    end

    if not icon and C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, itemIcon = C_Item.GetItemInfoInstant(itemID)
        icon = itemIcon
    end

    local name = fallbackName
    if C_Item and C_Item.GetItemInfo then
        local n = C_Item.GetItemInfo(itemID)
        if n and n ~= "" then
            name = n
        end
    end

    return name or ("Item " .. tostring(itemID or 0)), icon or 134400
end

local function GetActionMacroText(entry, resolvedSpellName)
    if entry.itemID then
        return "/use [nocombat] item:" .. tostring(entry.itemID)
    end

    if entry.spellID then
        local spellName = resolvedSpellName or entry.spellName
        if spellName and spellName ~= "" then
            return "/cast [nocombat,@player] " .. spellName
        end
        return nil
    end

    return nil
end

local function IsSafeToShow()
    if FN and FN.PassesCommonNonCombatRules then
        return FN:PassesCommonNonCombatRules()
    end

    return not (InCombatLockdown and InCombatLockdown())
end

function CB:EnsureDB()
    NX.DB.interface.clickableBuffs = NX.DB.interface.clickableBuffs or {}
    local db = NX.DB.interface.clickableBuffs
    if db.enabled == nil then
        db.enabled = false
    end
    if db.anchorX == nil then
        db.anchorX = DEFAULT_ANCHOR_X
    end
    if db.anchorY == nil then
        db.anchorY = DEFAULT_ANCHOR_Y
    end
    if db.iconSize == nil then
        db.iconSize = DEFAULT_BUTTON_SIZE
    end
    if db.textSize == nil then
        db.textSize = DEFAULT_TEXT_SIZE
    end
    if db.iconZoomPct == nil then
        db.iconZoomPct = DEFAULT_ICON_ZOOM_PCT
    end
    if db.flashMissing == nil then
        db.flashMissing = false
    end
    if db.positionUnlocked == nil then
        db.positionUnlocked = false
    end

    db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULT_ANCHOR_X)
    db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULT_ANCHOR_Y)

    db.iconSize = math.floor((tonumber(db.iconSize) or DEFAULT_BUTTON_SIZE) + 0.5)
    if db.iconSize < 24 then db.iconSize = 24 end
    if db.iconSize > 96 then db.iconSize = 96 end

    db.textSize = math.floor((tonumber(db.textSize) or DEFAULT_TEXT_SIZE) + 0.5)
    if db.textSize < 10 then db.textSize = 10 end
    if db.textSize > 32 then db.textSize = 32 end

    db.iconZoomPct = tonumber(db.iconZoomPct) or DEFAULT_ICON_ZOOM_PCT
    db.iconZoomPct = math.floor((db.iconZoomPct / 5) + 0.5) * 5
    if db.iconZoomPct < 0 then db.iconZoomPct = 0 end
    if db.iconZoomPct > 100 then db.iconZoomPct = 100 end

    return db
end

function CB:GetButtonSize()
    local db = self:EnsureDB()
    return db.iconSize or DEFAULT_BUTTON_SIZE
end

function CB:GetTextSize()
    local db = self:EnsureDB()
    return db.textSize or DEFAULT_TEXT_SIZE
end

function CB:GetIconZoomPct()
    local db = self:EnsureDB()
    return db.iconZoomPct or DEFAULT_ICON_ZOOM_PCT
end

function CB:IsFlashMissingEnabled()
    local db = self:EnsureDB()
    return db.flashMissing == true
end

function CB:IsPositionUnlocked()
    local db = self:EnsureDB()
    return db.positionUnlocked == true
end

local function ApplyTextureZoom(texture, zoomPct)
    if not texture or not texture.SetTexCoord then
        return
    end

    local pct = tonumber(zoomPct) or 0
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end

    local zoomFactor = 1 + (pct / 100)
    local margin = (1 - (1 / zoomFactor)) * 0.5
    texture:SetTexCoord(margin, 1 - margin, margin, 1 - margin)
end

local function EnsureFlashAnimation(btn)
    if not btn or btn._nxFlashAnim then
        return
    end

    local ag = btn:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")

    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0.35)
    alpha:SetDuration(0.55)
    alpha:SetSmoothing("IN_OUT")

    btn._nxFlashAnim = ag
end

function CB:SetButtonFlashing(btn, enabled)
    if not btn then
        return
    end

    if enabled then
        EnsureFlashAnimation(btn)
        if btn._nxFlashAnim and not btn._nxFlashAnim:IsPlaying() then
            btn._nxFlashAnim:Play()
        end
        return
    end

    if btn._nxFlashAnim and btn._nxFlashAnim:IsPlaying() then
        btn._nxFlashAnim:Stop()
    end
    btn:SetAlpha(1)
end

function CB:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function CB:IsEnabled()
    local db = self:EnsureDB()
    return db.enabled == true
end

function CB:Toggle()
    local db = self:EnsureDB()
    db.enabled = not db.enabled
    self:OnSettingsChanged()

    local state = db.enabled and "enabled" or "disabled"
    print("|cffffd200Nexus:|r Clickable Buffs " .. state .. ".")
end

function CB:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false

    self:UpdateAll()

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Clickable Buffs position unlocked.")
    else
        print("|cffffd200Nexus:|r Clickable Buffs position locked.")
    end
end

function CB:HandleNxSlash(msg)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd200Nexus:|r Clickable Buffs toggle is blocked in combat state.")
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
        print("|cffffd200Nexus:|r /nx buffs, /nx buffs lock, /nx buffs unlock, /nx buffs help")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx buffs command. Use: /nx buffs help")
    return true
end

function CB:GetFlooredAnchorOffsetsFromFrame()
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

function CB:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function CB:SetAnchorOffsets(x, y)
    local db = self:EnsureDB()
    db.anchorX = FN:RoundToNearestPixel(x)
    db.anchorY = FN:RoundToNearestPixel(y)
    self:ApplyAnchorPoint()
end

function CB:GetAnchorBaseSize()
    local buttonSize = self:GetButtonSize()
    local height = buttonSize + TEXT_PADDING + self:GetTextSize()
    local width = buttonSize
    return FN:ClampAnchorSize(width, height)
end

function CB:UpdateDragHandleReadout()
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

function CB:NudgeAnchor(dx, dy)
    if not self.Anchor then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if not self:IsPositionUnlocked() then
        return
    end

    local db = self:EnsureDB()
    local x = FN:RoundToNearestPixel(db.anchorX)
    local y = FN:RoundToNearestPixel(db.anchorY)
    self:SetAnchorOffsets(x + (dx or 0), y + (dy or 0))
    self:UpdateDragHandleReadout()
end

function CB:UpdateDragHandle()
    if not self.Anchor then
        return
    end

    if not self.DragHandle then
        if FN and FN.CreateAnchorController then
            self.DragHandle = FN:CreateAnchorController({
                parent = self.Anchor,
                moveFrame = self.Anchor,
                elementName = self.AnchorDisplayName,
                nudgeStep = ANCHOR_STEP_PX,
                extraVerticalPadding = ANCHOR_EXTRA_VERTICAL_PADDING,
                labelFontSize = ANCHOR_LABEL_FONT_SIZE,
                isMoveEnabled = function()
                    return CB:IsPositionUnlocked()
                end,
                getOffsets = function()
                    return CB:GetFlooredAnchorOffsetsFromFrame()
                end,
                setOffsets = function(x, y)
                    CB:SetAnchorOffsets(x, y)
                end,
                onDragStop = function()
                    CB:StoreFlooredAnchorOffsetsFromFrame()
                    CB:ApplyAnchorPoint()
                    CB:UpdateDragHandleReadout()
                end,
                onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(CB, false))
                    or function()
                        CB:SetPositionUnlocked(false)
                    end,
            })
        end
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

    local showHandle = self:IsPositionUnlocked() and self:IsEnabled()
    self.DragHandle:SetShown(showHandle)
    self.DragHandle:EnableMouse(showHandle)
end

function CB:ApplyCombatVisibilityDriver()
    if self.Anchor and not self._combatVisibilityDriverRegistered then
        if RegisterStateDriver then
            RegisterStateDriver(self.Anchor, "visibility", "[combat] hide; show")
            self._combatVisibilityDriverRegistered = true
        elseif RegisterAttributeDriver then
            RegisterAttributeDriver(self.Anchor, "state-visibility", "[combat] hide; show")
            self._combatVisibilityDriverRegistered = true
        end
    end
end

function CB:HideAll()
    local inCombat = InCombatLockdown and InCombatLockdown()

    if self.Anchor then
        if not inCombat then
            self.Anchor:Hide()
        end
    end

    for _, btn in ipairs(self.Buttons) do
        self:SetButtonFlashing(btn, false)
        if not inCombat then
            btn:Hide()
        end
    end

    if self.DragHandle then
        if inCombat then
            self.DragHandle:EnableMouse(false)
        else
            self.DragHandle:Hide()
            self.DragHandle:EnableMouse(false)
        end
    end
end

function CB:EnsureAnchor()
    if self.Anchor then
        self:ApplyCombatVisibilityDriver()
        self:ApplyAnchorPoint()
        return self.Anchor
    end

    local baseWidth, baseHeight = self:GetAnchorBaseSize()
    local anchor = FN:CreateAnchorFrame(UIParent, baseWidth, baseHeight)
    self.Anchor = anchor
    self:ApplyCombatVisibilityDriver()
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    return anchor
end

function CB:BuildVisibilityState(auraSnapshot)
    local state = {
        hasFlaskBuff = false,
        hasFoodBuff = false,
        hasMainWeaponEnchant = false,
        hasOffWeaponEnchant = false,
        hasLethalPoisonBuff = false,
        hasNonLethalPoisonBuff = false,
        hasMainWeaponSlot = false,
        hasOffWeaponSlot = false,
        maxWeaponEnchantSlots = 0,
        sharedWeaponBuffSlotsUsed = 0,
        activeAuraGroups = {},
    }

    for _, entry in ipairs(self.tracked_spells_items) do
        if entry.flask and entry.spellID and HasPlayerAuraBySpellID(entry.spellID, auraSnapshot) then
            state.hasFlaskBuff = true
            break
        end
    end

    state.hasFoodBuff = HasPlayerAuraByName("Well Fed", auraSnapshot) or HasPlayerAuraByName("Hearty Well Fed", auraSnapshot)

    for _, entry in ipairs(self.tracked_spells_items) do
        if entry.auraGroup and entry.spellID and HasPlayerAuraBySpellID(entry.spellID, auraSnapshot) then
            state.activeAuraGroups[entry.auraGroup] = true
        end

        if entry.poison and entry.spellID and HasPlayerAuraBySpellID(entry.spellID, auraSnapshot) then
            if entry.lethal == false then
                state.hasNonLethalPoisonBuff = true
            else
                state.hasLethalPoisonBuff = true
            end
        end
    end

    state.hasMainWeaponSlot = IsWeaponInSlot(16)
    state.hasOffWeaponSlot = IsWeaponInSlot(17)
    state.maxWeaponEnchantSlots = (state.hasMainWeaponSlot and 1 or 0) + (state.hasOffWeaponSlot and 1 or 0)

    local hasMain, hasOff, slotsUsed = GetWeaponEnchantState()
    state.hasMainWeaponEnchant = state.hasMainWeaponSlot and hasMain or false
    state.hasOffWeaponEnchant = state.hasOffWeaponSlot and hasOff or false
    state.sharedWeaponBuffSlotsUsed = slotsUsed

    return state
end

local function IsEntryHandMissing(entry, state)
    if not entry then
        return false
    end

    local hand = entry.preferredHand
    if hand == "MAIN" then
        return state.hasMainWeaponSlot and not state.hasMainWeaponEnchant
    end
    if hand == "OFF" then
        return state.hasOffWeaponSlot and not state.hasOffWeaponEnchant
    end

    return state.maxWeaponEnchantSlots > 0 and state.sharedWeaponBuffSlotsUsed < state.maxWeaponEnchantSlots
end

function CB:BuildVisibleEntries()
    local visible = {}
    local auraSnapshot = BuildPlayerAuraSnapshot()
    local state = self:BuildVisibilityState(auraSnapshot)

    for _, entry in ipairs(self.tracked_spells_items) do
        if entry.buff then
            local isKnown = entry.spellID and IsSpellKnownForPlayer(entry.spellID)
            local isMissing = not HasPlayerAuraForEntry(entry, auraSnapshot)
            local groupMissing = not entry.auraGroup or not state.activeAuraGroups[entry.auraGroup]
            if isKnown and isMissing and groupMissing then
                visible[#visible + 1] = entry
            end
        elseif entry.flask then
            if entry.itemID and HasItemInBags(entry.itemID) and not state.hasFlaskBuff then
                visible[#visible + 1] = entry
            end
        elseif entry.food then
            if entry.itemID and HasItemInBags(entry.itemID) and not state.hasFoodBuff then
                visible[#visible + 1] = entry
            end
        elseif entry.imbue then
            if entry.spellID and IsEntryHandMissing(entry, state) then
                local isKnown = IsSpellKnownForPlayer(entry.spellID)
                if isKnown then
                    visible[#visible + 1] = entry
                end
            end
        elseif entry.poison then
            local poisonMissing = (entry.lethal == false and not state.hasNonLethalPoisonBuff)
                or (entry.lethal ~= false and not state.hasLethalPoisonBuff)
            if entry.spellID and poisonMissing then
                local isKnown = IsSpellKnownForPlayer(entry.spellID)
                if isKnown then
                    visible[#visible + 1] = entry
                end
            end
        elseif entry.oil then
            if state.maxWeaponEnchantSlots > 0
                and state.sharedWeaponBuffSlotsUsed < state.maxWeaponEnchantSlots
                and entry.itemID
                and HasItemInBags(entry.itemID) then
                visible[#visible + 1] = entry
            end
        end
    end

    return visible
end

function CB:EnsureButton(index)
    local btn = self.Buttons[index]
    if btn then
        return btn
    end

    btn = CreateFrame("Button", nil, self.Anchor, "SecureActionButtonTemplate")
    btn:SetSize(self:GetButtonSize(), self:GetButtonSize())
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("type1", "macro")

    btn.BorderTop = btn:CreateTexture(nil, "BORDER")
    btn.BorderTop:SetColorTexture(0, 0, 0, 1)
    btn.BorderTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.BorderTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    btn.BorderTop:SetHeight(ICON_BORDER_SIZE)

    btn.BorderBottom = btn:CreateTexture(nil, "BORDER")
    btn.BorderBottom:SetColorTexture(0, 0, 0, 1)
    btn.BorderBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.BorderBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.BorderBottom:SetHeight(ICON_BORDER_SIZE)

    btn.BorderLeft = btn:CreateTexture(nil, "BORDER")
    btn.BorderLeft:SetColorTexture(0, 0, 0, 1)
    btn.BorderLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.BorderLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.BorderLeft:SetWidth(ICON_BORDER_SIZE)

    btn.BorderRight = btn:CreateTexture(nil, "BORDER")
    btn.BorderRight:SetColorTexture(0, 0, 0, 1)
    btn.BorderRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    btn.BorderRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.BorderRight:SetWidth(ICON_BORDER_SIZE)

    btn.Icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.Icon:SetPoint("TOPLEFT", btn, "TOPLEFT", ICON_BORDER_SIZE, -ICON_BORDER_SIZE)
    btn.Icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -ICON_BORDER_SIZE, ICON_BORDER_SIZE)
    ApplyTextureZoom(btn.Icon, self:GetIconZoomPct())

    btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.Text:SetPoint("TOP", btn, "BOTTOM", 0, -TEXT_PADDING)
    btn.Text:SetTextColor(1, 1, 1, 1)
    if FN and FN.ApplyAddonFont then
        FN:ApplyAddonFont(btn.Text, self:GetTextSize(), "OUTLINE")
    end
    btn.Text:SetShadowColor(0, 0, 0, 1)
    btn.Text:SetShadowOffset(1, -1)

    btn:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        local entry = self.entry
        if not entry then
            GameTooltip:Hide()
            return
        end

        local displayName = entry.spellName or entry.text or "Unknown"
        GameTooltip:AddLine(displayName, 1, 1, 1, true)
        if entry.spellID then
            GameTooltip:AddLine("ID: " .. tostring(entry.spellID), 0.8, 0.8, 0.8)
        end
        if entry.itemID then
            GameTooltip:AddLine("ID: " .. tostring(entry.itemID), 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    self.Buttons[index] = btn
    return btn
end

function CB:ApplyButtonEntry(btn, entry)
    if not btn or not entry then
        return
    end

    local label = entry.text or entry.spellName or "Buff"
    local macroText
    local displayName, icon
    local textSize = self:GetTextSize()

    if entry.itemID then
        displayName, icon = GetItemVisual(entry.itemID, entry.spellName)
    else
        displayName, icon = GetSpellVisual(entry.spellID, entry.spellName)
    end

    btn.entry = entry
    entry.spellName = displayName or entry.spellName
    macroText = GetActionMacroText(entry, entry.spellName)
    btn.Text:SetText(label)

    if FN and FN.ApplyAddonFont then
        FN:ApplyAddonFont(btn.Text, textSize, "OUTLINE")
    end

    btn.Icon:SetTexture(icon)
    ApplyTextureZoom(btn.Icon, self:GetIconZoomPct())

    btn:SetAttribute("macrotext", macroText)
    btn:SetAttribute("macrotext1", macroText)
    self:SetButtonFlashing(btn, self:IsFlashMissingEnabled())
    btn:Show()
end

function CB:LayoutButtons(visibleEntries)
    local count = #visibleEntries
    local perRow = MAX_PER_ROW
    local buttonSize = self:GetButtonSize()
    local textSize = self:GetTextSize()
    local rows = math.max(1, math.ceil(math.max(count, 1) / perRow))
    local rowStride = buttonSize + TEXT_PADDING + textSize + BUTTON_SPACING
    local maxCols = math.min(perRow, math.max(count, 1))
    local width = (maxCols * buttonSize) + ((maxCols - 1) * BUTTON_SPACING)
    local height = (rows * (buttonSize + TEXT_PADDING + textSize)) + ((rows - 1) * BUTTON_SPACING)
    width, height = FN:ClampAnchorSize(width, height)

    FN:SetAnchorSize(self.Anchor, width, height)

    for i, entry in ipairs(visibleEntries) do
        local btn = self:EnsureButton(i)
        self:ApplyButtonEntry(btn, entry)

        local row = math.floor((i - 1) / perRow)
        local rowIndex = ((i - 1) % perRow) + 1
        local rowFirst = (row * perRow) + 1
        local rowRemaining = count - rowFirst + 1
        local rowCount = math.min(perRow, rowRemaining)
        local rowWidth = (rowCount * buttonSize) + ((rowCount - 1) * BUTTON_SPACING)
        local rowStartX = (width - rowWidth) * 0.5
        local x = rowStartX + ((rowIndex - 1) * (buttonSize + BUTTON_SPACING))
        local y = -row * rowStride

        btn:ClearAllPoints()
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPoint("TOPLEFT", self.Anchor, "TOPLEFT", x, y)
    end

    for i = count + 1, #self.Buttons do
        self:SetButtonFlashing(self.Buttons[i], false)
        if not (InCombatLockdown and InCombatLockdown()) then
            self.Buttons[i]:Hide()
        end
    end
end

function CB:UpdateAll()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingRefresh = true
        self:HideAll()
        return
    end

    self:EnsureDB()

    if not self:IsEnabled() then
        self:HideAll()
        return
    end

    if not IsSafeToShow() then
        self.pendingRefresh = true
        self:HideAll()
        return
    end

    self:EnsureAnchor()

    local visibleEntries = self:BuildVisibleEntries()
    if #visibleEntries == 0 then
        for _, btn in ipairs(self.Buttons) do
            self:SetButtonFlashing(btn, false)
            btn:Hide()
        end
        if self:IsPositionUnlocked() then
            local baseWidth, baseHeight = self:GetAnchorBaseSize()
            FN:SetAnchorSize(self.Anchor, baseWidth, baseHeight)
            self.Anchor:Show()
            self:UpdateDragHandle()
        else
            self:HideAll()
        end
        return
    end

    self:LayoutButtons(visibleEntries)
    self.Anchor:Show()
    self:UpdateDragHandle()
    self.pendingRefresh = false
end

function CB:ScheduleUpdate()
    if self.refreshScheduled then
        return
    end

    self.refreshScheduled = true
    C_Timer.After(REFRESH_DEBOUNCE_SECONDS, function()
        CB.refreshScheduled = false
        CB:UpdateAll()
    end)
end

function CB:OnSettingsChanged()
    self:UpdateAll()
end

function CB:OnSettingsClosed()
    self:SetPositionUnlocked(false, true)
end

function CB:Init()
    self:EnsureDB()

    if self._eventFrame then
        self:UpdateAll()
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("CHALLENGE_MODE_START")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    frame:RegisterEvent("CHALLENGE_MODE_RESET")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            self.pendingRefresh = true
            self:HideAll()
            return
        end

        if event == "ENCOUNTER_START" or event == "CHALLENGE_MODE_START" then
            self.pendingRefresh = true
            self:HideAll()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            if self.pendingRefresh then
                self.pendingRefresh = false
            end
            self:UpdateAll()
            return
        end

        if event == "UNIT_AURA" or event == "BAG_UPDATE_DELAYED" or event == "SPELLS_CHANGED" then
            self:ScheduleUpdate()
            return
        end

        self:UpdateAll()
    end)

    self._eventFrame = frame

    C_Timer.After(0, function()
        self:UpdateAll()
    end)
end
