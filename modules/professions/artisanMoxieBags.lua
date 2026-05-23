local NX = Nexus

NX.ArtisanMoxieBags = NX.ArtisanMoxieBags or {}
do
    local M = NX.ArtisanMoxieBags
    local FN = NX.Functions

    local frame
    local pendingRefresh = false

    local DEFAULTS = {
        enabled = true,
        textSize = 22,
        anchorX = 0,
        anchorY = 220,
        positionUnlocked = false,
    }

    local BAZAAR_MAP_ID = 2393
    local REQUIRED_MOXIE = 600

    local ANCHOR_WIDTH = 620
    local MIN_ANCHOR_HEIGHT = 72
    local MAX_LINES = 11
    local LINE_PADDING_X = 12
    local LINE_PADDING_Y = 10
    local LINE_SPACING = 4

    local ANCHOR_STEP_PX = 1
    local ANCHOR_EXTRA_VERTICAL_PADDING = 20
    local ANCHOR_LABEL_FONT_SIZE = 16

    local FALLBACK_ICON = 134400
    local TEXT_COLOR = "FFE8A6"
    local PROFESSION_COLOR = "FFFFFF"

    local MOXIE_CURRENCIES = {
        { currencyID = 3256, professionName = "Alchemy" },
        { currencyID = 3260, professionName = "Herbalism" },
        { currencyID = 3264, professionName = "Mining" },
        { currencyID = 3258, professionName = "Enchanting" },
        { currencyID = 3257, professionName = "Blacksmithing" },
        { currencyID = 3265, professionName = "Skinning" },
        { currencyID = 3266, professionName = "Tailoring" },
        { currencyID = 3263, professionName = "Leatherworking" },
        { currencyID = 3262, professionName = "Jewelcrafting" },
        { currencyID = 3259, professionName = "Engineering" },
        { currencyID = 3261, professionName = "Inscription" },
    }

    local MOXIE_CURRENCY_SET = {}
    for _, entry in ipairs(MOXIE_CURRENCIES) do
        MOXIE_CURRENCY_SET[entry.currencyID] = true
    end

    M.Anchor = M.Anchor or nil
    M.DragHandle = M.DragHandle or nil
    M.LinePool = M.LinePool or {}
    M.AnchorDisplayName = M.AnchorDisplayName or "Artisan Moxie Bags"

    local function RoundNearest(value)
        local n = tonumber(value) or 0
        if n >= 0 then
            return math.floor(n + 0.5)
        end
        return math.ceil(n - 0.5)
    end

    local function GetCurrencyInfoSafe(currencyID)
        if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
            return nil
        end

        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
        if not ok or type(info) ~= "table" then
            return nil
        end

        return info
    end

    function M:EnsureDB()
        NX.DB.professions.artisanMoxieBags = NX.DB.professions.artisanMoxieBags or {}
        local db = NX.DB.professions.artisanMoxieBags

        if db.enabled == nil then db.enabled = DEFAULTS.enabled end
        if db.textSize == nil then db.textSize = DEFAULTS.textSize end
        if db.anchorX == nil then db.anchorX = DEFAULTS.anchorX end
        if db.anchorY == nil then db.anchorY = DEFAULTS.anchorY end
        if db.positionUnlocked == nil then db.positionUnlocked = DEFAULTS.positionUnlocked end

        db.enabled = db.enabled and true or false
        db.positionUnlocked = db.positionUnlocked and true or false

        local size = math.floor((tonumber(db.textSize) or DEFAULTS.textSize) + 0.5)
        if size < 10 then size = 10 end
        if size > 64 then size = 64 end
        db.textSize = size

        if FN and FN.RoundToNearestPixel then
            db.anchorX = FN:RoundToNearestPixel(db.anchorX)
            db.anchorY = FN:RoundToNearestPixel(db.anchorY)
        else
            db.anchorX = RoundNearest(db.anchorX)
            db.anchorY = RoundNearest(db.anchorY)
        end

        return db
    end

    function M:IsEnabled()
        return self:EnsureDB().enabled == true
    end

    function M:IsPositionUnlocked()
        return self:EnsureDB().positionUnlocked == true
    end

    function M:ApplyAnchorPoint()
        if not self.Anchor then
            return
        end

        local db = self:EnsureDB()
        self.Anchor:ClearAllPoints()
        self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
    end

    function M:GetFlooredAnchorOffsetsFromFrame()
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
            return RoundNearest(centerX - parentCenterX), RoundNearest(centerY - parentCenterY)
        end

        local _, _, _, x, y = self.Anchor:GetPoint(1)
        if FN and FN.RoundToNearestPixel then
            return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
        end

        return RoundNearest(x), RoundNearest(y)
    end

    function M:StoreFlooredAnchorOffsetsFromFrame()
        local db = self:EnsureDB()
        db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
        return db.anchorX, db.anchorY
    end

    function M:SetAnchorOffsets(x, y)
        local db = self:EnsureDB()
        if FN and FN.RoundToNearestPixel then
            db.anchorX = FN:RoundToNearestPixel(x)
            db.anchorY = FN:RoundToNearestPixel(y)
        else
            db.anchorX = RoundNearest(x)
            db.anchorY = RoundNearest(y)
        end

        self:ApplyAnchorPoint()
    end

    function M:EnsureAnchor()
        if self.Anchor then
            return self.Anchor
        end

        local anchor
        if FN and FN.CreateAnchorFrame then
            anchor = FN:CreateAnchorFrame(UIParent, ANCHOR_WIDTH, MIN_ANCHOR_HEIGHT, ANCHOR_WIDTH, MIN_ANCHOR_HEIGHT)
        else
            anchor = CreateFrame("Frame", nil, UIParent)
            anchor:SetSize(ANCHOR_WIDTH, MIN_ANCHOR_HEIGHT)
        end

        self.Anchor = anchor
        self:ApplyAnchorPoint()
        return anchor
    end

    function M:EnsureLine(index)
        local line = self.LinePool[index]
        if line then
            return line
        end

        local anchor = self:EnsureAnchor()
        line = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        line:SetText("")
        line:SetJustifyH("LEFT")
        line:SetJustifyV("TOP")
        self.LinePool[index] = line
        return line
    end

    function M:IsInBazaar()
        if C_Map and C_Map.GetBestMapForUnit then
            local uiMapID = C_Map.GetBestMapForUnit("player")
            if uiMapID == BAZAAR_MAP_ID then
                return true
            end
        end

        if GetSubZoneText then
            local subZone = GetSubZoneText()
            if type(subZone) == "string" and subZone == "The Bazaar" then
                return true
            end
        end

        return false
    end

    function M:BuildReminderLines()
        local lines = {}

        if not self:IsEnabled() then
            return lines
        end

        if not self:IsInBazaar() then
            return lines
        end

        for _, entry in ipairs(MOXIE_CURRENCIES) do
            local info = GetCurrencyInfoSafe(entry.currencyID)
            local quantity = tonumber(info and info.quantity) or 0
            if quantity >= REQUIRED_MOXIE then
                local icon = tonumber(info and info.iconFileID) or FALLBACK_ICON
                lines[#lines + 1] = string.format(
                    "|T%d:17:17:0:0|t |cff%sCollect Moxie Bag for|r |cff%s%s|r",
                    icon,
                    TEXT_COLOR,
                    PROFESSION_COLOR,
                    entry.professionName
                )
            end
        end

        return lines
    end

    function M:ResizeAnchorForLines(visibleCount)
        local db = self:EnsureDB()
        local lineCount = math.max(1, math.min(MAX_LINES, tonumber(visibleCount) or 1))
        local rowHeight = (tonumber(db.textSize) or DEFAULTS.textSize) + LINE_SPACING
        local height = (LINE_PADDING_Y * 2) + (lineCount * rowHeight)
        if height < MIN_ANCHOR_HEIGHT then
            height = MIN_ANCHOR_HEIGHT
        end

        local anchor = self:EnsureAnchor()
        if FN and FN.SetAnchorSize then
            FN:SetAnchorSize(anchor, ANCHOR_WIDTH, height, ANCHOR_WIDTH, MIN_ANCHOR_HEIGHT)
        else
            anchor:SetSize(ANCHOR_WIDTH, height)
        end
    end

    function M:ApplyLineLayout()
        local db = self:EnsureDB()
        local textSize = db.textSize or DEFAULTS.textSize

        for index = 1, MAX_LINES do
            local line = self:EnsureLine(index)
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", self.Anchor, "TOPLEFT", LINE_PADDING_X, -(LINE_PADDING_Y + ((index - 1) * (textSize + LINE_SPACING))))
            line:SetPoint("RIGHT", self.Anchor, "RIGHT", -LINE_PADDING_X, 0)
            local fontApplied = false
            if FN and FN.ApplyAddonFont then
                fontApplied = FN:ApplyAddonFont(line, textSize, "OUTLINE") and true or false
            end
            if not fontApplied then
                local fallbackPath = "Fonts\\FRIZQT__.TTF"
                if FN and FN.GetAddonFontPath then
                    local customPath = FN:GetAddonFontPath()
                    if type(customPath) == "string" and customPath ~= "" then
                        fallbackPath = customPath
                    end
                end
                line:SetFont(fallbackPath, textSize, "OUTLINE")
            end
            line:SetShadowOffset(1, -1)
            line:SetShadowColor(0, 0, 0, 0.9)
        end
    end

    function M:UpdateDragHandleReadout()
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

    function M:UpdateDragHandle()
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
                    return M:IsPositionUnlocked()
                end,
                getOffsets = function()
                    return M:GetFlooredAnchorOffsetsFromFrame()
                end,
                setOffsets = function(x, y)
                    M:SetAnchorOffsets(x, y)
                end,
                onDragStop = function()
                    M:StoreFlooredAnchorOffsetsFromFrame()
                    M:ApplyAnchorPoint()
                    M:UpdateDragHandleReadout()
                end,
                onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(M, false))
                    or function()
                        M:SetPositionUnlocked(false)
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

        local showHandle = self:IsPositionUnlocked()
        self.DragHandle:SetShown(showHandle)
        self.DragHandle:EnableMouse(showHandle)

        self:UpdateDragHandleReadout()
    end

    function M:UpdateDisplay()
        self:EnsureDB()

        local lines = self:BuildReminderLines()
        local lineCount = #lines

        self:EnsureAnchor()
        self:ApplyAnchorPoint()
        self:ResizeAnchorForLines(lineCount)
        self:ApplyLineLayout()

        for index = 1, MAX_LINES do
            local line = self:EnsureLine(index)
            local value = lines[index]
            if value then
                line:SetText(value)
                line:Show()
            else
                line:SetText("")
                line:Hide()
            end
        end

        self.Anchor:SetShown(self:IsPositionUnlocked() or lineCount > 0)
        self:UpdateDragHandle()
    end

    function M:SetPositionUnlocked(unlocked, suppressPrint)
        local db = self:EnsureDB()
        db.positionUnlocked = unlocked and true or false

        self:UpdateDisplay()

        if suppressPrint then
            return
        end

        if db.positionUnlocked then
            print("|cffffd200Nexus:|r Artisan Moxie Bags position unlocked.")
        else
            print("|cffffd200Nexus:|r Artisan Moxie Bags position locked.")
        end
    end

    function M:RefreshDisplayStyle()
        self:UpdateDisplay()
    end

    function M:ScheduleUpdate(force)
        if force then
            self:UpdateDisplay()
            return
        end

        if pendingRefresh then
            return
        end

        pendingRefresh = true
        C_Timer.After(0.1, function()
            pendingRefresh = false
            M:UpdateDisplay()
        end)
    end

    function M:OnSettingsChanged()
        self:ScheduleUpdate(true)
    end

    function M:OnSettingsClosed()
        self:SetPositionUnlocked(false, true)
    end

    function M:Init()
        self:EnsureDB()

        if frame then
            self:ScheduleUpdate(true)
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("ZONE_CHANGED")
        frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

        frame:SetScript("OnEvent", function(_, event, currencyID)
            if event == "CURRENCY_DISPLAY_UPDATE" then
                local id = tonumber(currencyID)
                if id and not MOXIE_CURRENCY_SET[id] then
                    return
                end
            end

            M:ScheduleUpdate(false)
        end)

        C_Timer.After(0.2, function()
            M:ScheduleUpdate(true)
        end)
    end
end
