local NX = Nexus
NX.Common = NX.Common or {}
local CM = NX.Common
CM.LowDurability = CM.LowDurability or {}
local LD = CM.LowDurability
local FN = NX.Functions

local LD_TEXT = "Durability Low"
local LD_OUTLINE = "OUTLINE"
local LD_DEFAULT_FONT_SIZE = 48
local LD_DEFAULT_THRESHOLD = 20
local LD_DEFAULT_COLOR = "#FFFF00"
local LD_DEFAULT_ANCHOR_X = 0
local LD_DEFAULT_ANCHOR_Y = 0
local LD_ANCHOR_WIDTH = 800
local LD_ANCHOR_HEIGHT = 96
local LD_ANCHOR_STEP_PX = 1
local LD_ANCHOR_EXTRA_VERTICAL_PADDING = 24
local LD_ANCHOR_LABEL_FONT_SIZE = 16

local LD_FLASH_MIN_A  = 0.15
local LD_FLASH_MAX_A  = 1.00
local LD_FLASH_PERIOD = 0.60

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

    { hex = "#FFBBBB", name = "Light Salmon Pink",  r = 255, g = 187, b = 187 },
    { hex = "#FFDDBB", name = "Peach",              r = 255, g = 221, b = 187 },
    { hex = "#FFFFBB", name = "Pale Yellow (Soft)", r = 255, g = 255, b = 187 },
    { hex = "#DDFFBB", name = "Pale Green (Soft)",  r = 221, g = 255, b = 187 },
    { hex = "#BBFFBB", name = "Pale Turquoise (Soft)", r = 187, g = 255, b = 187 },
    { hex = "#BBFFDD", name = "Light Sea Green",    r = 187, g = 255, b = 221 },
    { hex = "#BBFFFF", name = "Light Cyan (Soft)",  r = 187, g = 255, b = 255 },
    { hex = "#BBDDFF", name = "Light Sky Blue",     r = 187, g = 221, b = 255 },
    { hex = "#BBBBFF", name = "Light Steel Blue",   r = 187, g = 187, b = 255 },
    { hex = "#DDBBFF", name = "Lavender",           r = 221, g = 187, b = 255 },
    { hex = "#FFBBFF", name = "Light Pink (Soft)",  r = 255, g = 187, b = 255 },
    { hex = "#FFBBDD", name = "Misty Rose",         r = 255, g = 187, b = 221 },

    { hex = "#AA5555", name = "Indian Red",         r = 170, g = 85,  b = 85  },
    { hex = "#AA7755", name = "Copper",             r = 170, g = 119, b = 85  },
    { hex = "#AAAA55", name = "Olive Drab",         r = 170, g = 170, b = 85  },
    { hex = "#77AA55", name = "Dark Olive Green",   r = 119, g = 170, b = 85  },
    { hex = "#55AA55", name = "Forest Green",       r = 85,  g = 170, b = 85  },
    { hex = "#55AA77", name = "Cadet Blue",         r = 85,  g = 170, b = 119 },
    { hex = "#55AAAA", name = "Medium Aquamarine",  r = 85,  g = 170, b = 170 },
    { hex = "#5577AA", name = "Light Slate Gray",   r = 85,  g = 119, b = 170 },
    { hex = "#5555AA", name = "Medium Slate Blue",  r = 85,  g = 85,  b = 170 },
    { hex = "#7755AA", name = "Slate Blue (Deep)",  r = 119, g = 85,  b = 170 },
    { hex = "#AA55AA", name = "Medium Orchid",      r = 170, g = 85,  b = 170 },
    { hex = "#AA5577", name = "Rose",               r = 170, g = 85,  b = 119 },
}

function LD:GetColorList()
    return COLORS
end

LD._inited = LD._inited or false
LD._shown = LD._shown or false
LD._elapsed = LD._elapsed or 0
LD._preview = LD._preview or false

LD._frame = LD._frame or nil
LD._text = LD._text or nil
LD._flash = LD._flash or nil
LD._anchor = LD._anchor or nil
LD._dragHandle = LD._dragHandle or nil
LD.AnchorDisplayName = "Low Durability"

local function LD_EnsureDB()
    NX.DB.interface.lowDurability = NX.DB.interface.lowDurability or {}
    local d = NX.DB.interface.lowDurability

    if d.enabled == nil then d.enabled = false end
    if d.anchorX == nil then d.anchorX = LD_DEFAULT_ANCHOR_X end
    if d.anchorY == nil then
        if d.offsetY ~= nil then
            d.anchorY = d.offsetY
        else
            d.anchorY = LD_DEFAULT_ANCHOR_Y
        end
    end
    if d.positionUnlocked == nil then d.positionUnlocked = false end
    if d.fontSize == nil then d.fontSize = LD_DEFAULT_FONT_SIZE end
    if d.threshold == nil then d.threshold = LD_DEFAULT_THRESHOLD end
    if d.flashing == nil then d.flashing = true end
    if d.color == nil or d.color == "" then d.color = LD_DEFAULT_COLOR end

    d.anchorX = math.floor(tonumber(d.anchorX) or LD_DEFAULT_ANCHOR_X)
    d.anchorY = math.floor(tonumber(d.anchorY) or LD_DEFAULT_ANCHOR_Y)

    return d
end

local function LD_GetDB()
    if not NX or not NX.DB then return nil end
    return LD_EnsureDB()
end

local function LD_FindColor(hex)
    if type(hex) ~= "string" then return nil end
    for _, c in ipairs(COLORS) do
        if c.hex == hex then
            return c
        end
    end
    return nil
end

local function LD_ApplyFontDeferred(size)
    local tries = 0
    local function try()
        tries = tries + 1
        local fontPath = (FN and FN.GetAddonFontPath and FN:GetAddonFontPath())
            or ((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF")
        if LD._text and LD._text.SetFont and LD._text:SetFont(fontPath, size, LD_OUTLINE) then
            return
        end
        if tries < 5 then
            C_Timer.After(0, try)
        else
            if LD._text and LD._text.SetFont then
                LD._text:SetFont((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF", size, LD_OUTLINE)
            end
        end
    end
    try()
end

function LD:IsPositionUnlocked()
    local db = LD_GetDB()
    return db and db.positionUnlocked == true or false
end

function LD:WarnMovementBlocked()
    local now = GetTime and GetTime() or 0
    local last = self._lastMovementBlockedWarningAt or 0
    if (now - last) < 0.25 then
        return
    end
    self._lastMovementBlockedWarningAt = now
    print("|cffffd200Nexus:|r Low Durability movement is blocked in combat state.")
end

function LD:ApplyAnchorPoint()
    if not self._anchor then
        return
    end

    local db = LD_GetDB()
    self._anchor:ClearAllPoints()
    self._anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function LD:GetFlooredAnchorOffsetsFromFrame()
    local db = LD_GetDB()

    if not self._anchor then
        return FN:RoundToNearestPixel(db.anchorX), FN:RoundToNearestPixel(db.anchorY)
    end

    local centerX, centerY = self._anchor:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if centerX and centerY and parentCenterX and parentCenterY then
        return FN:RoundToNearestPixel(centerX - parentCenterX), FN:RoundToNearestPixel(centerY - parentCenterY)
    end

    local _, _, _, x, y = self._anchor:GetPoint(1)
    return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
end

function LD:StoreFlooredAnchorOffsetsFromFrame()
    local db = LD_GetDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function LD:SetAnchorOffsets(x, y)
    local db = LD_GetDB()
    db.anchorX = FN:RoundToNearestPixel(x)
    db.anchorY = FN:RoundToNearestPixel(y)
    self:ApplyAnchorPoint()
end

function LD:UpdateDragHandleReadout()
    if not self._dragHandle then
        return
    end

    local x, y = self:GetFlooredAnchorOffsetsFromFrame()
    if self._dragHandle.CoordLabel then
        self._dragHandle.CoordLabel:SetText(string.format("%d, %d", x, y))
    end
    if self._dragHandle.NameLabel then
        self._dragHandle.NameLabel:SetText(self.AnchorDisplayName or "Element")
    end
end

function LD:UpdateDragHandle()
    if not self._anchor then
        return
    end

    if not self._dragHandle and FN and FN.CreateAnchorController then
        self._dragHandle = FN:CreateAnchorController({
            parent = self._anchor,
            moveFrame = self._anchor,
            elementName = self.AnchorDisplayName,
            nudgeStep = LD_ANCHOR_STEP_PX,
            extraVerticalPadding = LD_ANCHOR_EXTRA_VERTICAL_PADDING,
            labelFontSize = LD_ANCHOR_LABEL_FONT_SIZE,
            isMoveEnabled = function()
                return LD:IsPositionUnlocked()
            end,
            getOffsets = function()
                return LD:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                LD:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                LD:StoreFlooredAnchorOffsetsFromFrame()
                LD:ApplyAnchorPoint()
                LD:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(LD, false))
                or function()
                    LD:SetPositionUnlocked(false)
                end,
        })
    end

    if not self._dragHandle then
        return
    end

    if self._dragHandle.SetElementName then
        self._dragHandle:SetElementName(self.AnchorDisplayName or "Element")
    end

    self._dragHandle:SetShown(self:IsPositionUnlocked())
    self:UpdateDragHandleReadout()
end

function LD:UpdateAnchorVisibility()
    if not self._anchor then
        return
    end

    local showAnchor = self:IsPositionUnlocked() or (self._text and self._text:IsShown())
    self._anchor:SetShown(showAnchor)
    self:UpdateDragHandle()
end

function LD:GetConfig()
    local d = LD_GetDB() or {}

    local enabled  = (d.enabled == true)

    local fontSize = tonumber(d.fontSize) or LD_DEFAULT_FONT_SIZE
    fontSize = math.floor(fontSize + 0.5)
    fontSize = FN:ClampNumber(fontSize, 1, 128)

    local threshold = tonumber(d.threshold) or LD_DEFAULT_THRESHOLD
    threshold = math.floor(threshold + 0.5)
    threshold = FN:ClampNumber(threshold, 1, 100)

    local flashing = (d.flashing ~= false)

    local anchorX = math.floor(tonumber(d.anchorX) or LD_DEFAULT_ANCHOR_X)
    local anchorY = math.floor(tonumber(d.anchorY) or LD_DEFAULT_ANCHOR_Y)
    local positionUnlocked = (d.positionUnlocked == true)

    local colorHex = (type(d.color) == "string" and d.color ~= "") and d.color or LD_DEFAULT_COLOR
    local color = LD_FindColor(colorHex) or LD_FindColor(LD_DEFAULT_COLOR) or { r = 255, g = 255, b = 0 }

    return {
        enabled = enabled,
        fontSize = fontSize,
        threshold = threshold,
        flashing = flashing,
        anchorX = anchorX,
        anchorY = anchorY,
        positionUnlocked = positionUnlocked,
        colorHex = colorHex,
        color = color,
    }
end

function LD:Init()
    if self._inited then
        self:ApplyConfig()
        self:UpdateState()
        return
    end

    self._inited = true

    local anchor = FN:CreateAnchorFrame(UIParent, LD_ANCHOR_WIDTH, LD_ANCHOR_HEIGHT)
    self._anchor = anchor

    local text = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)
    text:SetText(LD_TEXT)
    text:Hide()
    self._text = text

    local ag = text:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")

    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(LD_FLASH_MAX_A)
    a:SetToAlpha(LD_FLASH_MIN_A)
    a:SetDuration(LD_FLASH_PERIOD)
    a:SetSmoothing("IN_OUT")

    self._flash = ag

    local f = CreateFrame("Frame")
    self._frame = f

    f:SetScript("OnEvent", function()
        self:UpdateState()
    end)

    f:SetScript("OnUpdate", function(_, dt)
        self._elapsed = (self._elapsed or 0) + (dt or 0)
        if self._elapsed >= 1.0 then
            self._elapsed = 0
            self:UpdateState()
        end
    end)

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("BAG_UPDATE_DELAYED")

    self:ApplyAnchorPoint()
    self:ApplyConfig()
    self:UpdateState()
end

local function LD_ApplyAndMaybeRefresh(self)
    if self.ApplyConfig then
        self:ApplyConfig()
    end
    if self.IsPreviewActive and self:IsPreviewActive() then
        if self.RefreshPreview then
            self:RefreshPreview()
        end
    end
end

function LD:OnSettingsChanged()
    LD_ApplyAndMaybeRefresh(self)
end

function LD:OnSettingsClosed()
    self:SetPositionUnlocked(false, true)
    self:StopPreview()
end

function LD:SetPositionUnlocked(unlocked, suppressPrint)
    if not self._inited then
        self:Init()
    end

    local db = LD_GetDB()
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
        print("|cffffd200Nexus:|r Low Durability position unlocked.")
    else
        print("|cffffd200Nexus:|r Low Durability position locked.")
    end
end

function LD:HandleNxSlash(msg)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffffd200Nexus:|r Slash command blocked in combat state.")
        return true
    end

    if not self._inited then
        self:Init()
    end

    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "toggle" then
        local db = LD_GetDB()
        db.enabled = not db.enabled
        self:OnSettingsChanged()
        print("|cffffd200Nexus:|r Low Durability " .. (db.enabled and "enabled." or "disabled."))
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
        print("|cffffd200Nexus:|r /nx durability, /nx durability lock, /nx durability unlock, /nx durability help")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx durability command. Use: /nx durability help")
    return true
end

function LD:ApplyConfig()
    if not self._text then return end
    local cfg = self:GetConfig()

    self:ApplyAnchorPoint()
    self:UpdateDragHandle()

    local appliedFontSize = cfg.fontSize
    LD_ApplyFontDeferred(appliedFontSize)

    local c = cfg.color
    if c then
        self._text:SetTextColor((c.r or 255) / 255, (c.g or 255) / 255, (c.b or 0) / 255)
    end

    if self._preview then
        return
    end

    if not cfg.enabled then
        self:HideWarning()
        return
    end

    if self._shown then
        if cfg.flashing then
            self:StartFlash()
        else
            self:StopFlash(1.0)
        end
    end

    self:UpdateAnchorVisibility()
end

function LD:IsLowDurability()
    local cfg = self:GetConfig()
    local threshold = (cfg.threshold or 20) / 100.0

    for slot = 1, 18 do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            if (cur / max) <= threshold then
                return true
            end
        end
    end

    return false
end

function LD:StartFlash()
    if not self._flash or not self._text then return end
    self._text:SetAlpha(LD_FLASH_MAX_A)
    if not self._flash:IsPlaying() then
        self._flash:Play()
    end
end

function LD:StopFlash(alpha)
    if not self._flash or not self._text then return end
    if self._flash:IsPlaying() then
        self._flash:Stop()
    end
    self._text:SetAlpha(type(alpha) == "number" and alpha or 1.0)
end

function LD:ShowWarning()
    if not self._text then return end
    self._shown = true
    self._text:Show()

    local cfg = self:GetConfig()
    if cfg.flashing then
        self:StartFlash()
    else
        self:StopFlash(1.0)
    end

    self:UpdateAnchorVisibility()
end

function LD:HideWarning()
    self._shown = false
    if self._flash and self._flash:IsPlaying() then
        self._flash:Stop()
    end
    if self._text then
        self._text:Hide()
    end

    self:UpdateAnchorVisibility()
end

function LD:UpdateState()
    if not self._text then return end

    if self._preview then
        self:ShowWarning()
        return
    end

    local cfg = self:GetConfig()

    if not cfg.enabled then
        if self._shown then
            self:HideWarning()
        end
        return
    end

    local shouldShow = self:IsLowDurability()

    if shouldShow and not self._shown then
        self:ShowWarning()
    elseif (not shouldShow) and self._shown then
        self:HideWarning()
    elseif shouldShow and self._shown then
        if cfg.flashing then
            self:StartFlash()
        else
            self:StopFlash(1.0)
        end
    end
end

function LD:IsPreviewActive()
    return self._preview == true
end

function LD:TestPreview()
    if not self._text then
        self:Init()
    end
    self._preview = true
    self:ApplyConfig()
    self:ShowWarning()
end

function LD:RefreshPreview()
    if not self._preview then return end
    self:TestPreview()
end

function LD:StopPreview()
    self._preview = false
    self:UpdateState()
end

function LD:TogglePreview()
    if self:IsPreviewActive() then
        self:StopPreview()
    else
        self:TestPreview()
    end
end

