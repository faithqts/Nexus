local NX = Nexus
NX.PersonalCraftingOrders = NX.PersonalCraftingOrders or {}
do
    local PCO = NX.PersonalCraftingOrders
    local FN = NX.Functions
    local frame
    local NEW_ORDER_ANCHOR_WIDTH = 700
    local NEW_ORDER_ANCHOR_HEIGHT = 48
    local NEW_ORDER_ANCHOR_STEP_PX = 1
    local NEW_ORDER_ANCHOR_EXTRA_VERTICAL_PADDING = 20
    local NEW_ORDER_ANCHOR_LABEL_FONT_SIZE = 16
    local NEW_ORDER_SOUND_FILE = "new_personal_crafting_order.ogg"
    PCO.lastKnownPersonalOrderCount = PCO.lastKnownPersonalOrderCount

    local DEFAULTS = {
        textAlertEnabled = false,
        newOrderAlertEnabled = false,
        soundAlertEnabled = false,
        voicePack = FN.VOICE_PACK_DEFAULT,
        currentOrdersFontSize = 20,
        currentOrdersColor = "#FFFFFF",
        newOrderAnchorX = 0,
        newOrderAnchorY = 220,
        newOrderPositionUnlocked = false,
        newOrderFontSize = 28,
        newOrderColor = "#FFD133",
        newOrderAlignment = "CENTER",
        newOrderFlashing = false,
        newOrderDuration = 4,
    }

    local NEW_ORDER_ALERT_TEXT = "NEW PERSONAL ORDER RECEIVED"

    local function BuildVoicePackSoundPaths(actor, filename)
        return FN:GetVoicePackSoundPaths(actor, filename, NX.name)
    end

    local function NormalizeNewOrderAlignment(value)
        value = string.upper(tostring(value or DEFAULTS.newOrderAlignment))
        if value == "LEFT" or value == "CENTER" or value == "RIGHT" then
            return value
        end
        return DEFAULTS.newOrderAlignment
    end

    local function NormalizeHexColor(value, fallback)
        local defaultColor = tostring(fallback or DEFAULTS.currentOrdersColor)
        if type(value) ~= "string" then
            return defaultColor
        end

        local hex = value:gsub("%s+", ""):upper()
        if not hex:match("^#") then
            hex = "#" .. hex
        end

        if #hex == 7 or #hex == 9 then
            return hex
        end

        return defaultColor
    end

    local function HexToRGB01(value, fallback)
        local hex = NormalizeHexColor(value, fallback):gsub("#", "")
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
        return 1, 1, 1
    end

    local function LoadProfessionsUI()
        if UIParentLoadAddOn then
            pcall(UIParentLoadAddOn, "Blizzard_Professions")
        elseif C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_Professions")
        end
    end

    local function GetAnchorFrame()
        local professionsFrame = _G.ProfessionsFrame
        if professionsFrame and professionsFrame.TabSystem then
            return professionsFrame.TabSystem
        end
        return nil
    end

    local function GetTotalPersonalOrders()
        if not (C_CraftingOrders and C_CraftingOrders.GetPersonalOrdersInfo) then
            return 0
        end

        local ok, infos = pcall(C_CraftingOrders.GetPersonalOrdersInfo)
        if not ok or type(infos) ~= "table" then
            return 0
        end

        local total = 0
        for _, professionInfo in pairs(infos) do
            if type(professionInfo) == "table" then
                local count = tonumber(professionInfo.numPersonalOrders)
                if count and count > 0 then
                    total = total + count
                end
            end
        end

        return total
    end

    local function ClampOrderCount(total)
        total = tonumber(total) or 0
        if total < 0 then
            total = 0
        end
        return total
    end

    function PCO:EnsureDB()
        NX.DB.professions.personalCraftingOrders = NX.DB.professions.personalCraftingOrders or {}
        local db = NX.DB.professions.personalCraftingOrders

        if db.textAlertEnabled == nil then
            if db.enabled ~= nil then
                db.textAlertEnabled = db.enabled and true or false
            else
                db.textAlertEnabled = DEFAULTS.textAlertEnabled
            end
        end

        if db.voicePack == nil then
            db.voicePack = DEFAULTS.voicePack
        end

        if db.newOrderAlertEnabled == nil then
            db.newOrderAlertEnabled = DEFAULTS.newOrderAlertEnabled
        end

        if db.soundAlertEnabled == nil then
            db.soundAlertEnabled = DEFAULTS.soundAlertEnabled
        end

        db.textAlertEnabled = db.textAlertEnabled and true or false
        db.newOrderAlertEnabled = db.newOrderAlertEnabled and true or false
        db.soundAlertEnabled = db.soundAlertEnabled and true or false

        db.voicePack = FN:NormalizeVoicePackActor(FN:GetSharedVoicePackActor() or db.voicePack)

        db.soundAlertFile = nil

        db.newOrderAnchorX = math.floor(tonumber(db.newOrderAnchorX) or DEFAULTS.newOrderAnchorX)
        db.newOrderAnchorY = math.floor(tonumber(db.newOrderAnchorY) or DEFAULTS.newOrderAnchorY)
        db.newOrderPositionUnlocked = db.newOrderPositionUnlocked and true or false
        db.currentOrdersFontSize = math.floor((tonumber(db.currentOrdersFontSize) or DEFAULTS.currentOrdersFontSize) + 0.5)
        if db.currentOrdersFontSize < 8 then db.currentOrdersFontSize = 8 end
        if db.currentOrdersFontSize > 96 then db.currentOrdersFontSize = 96 end
        db.currentOrdersColor = NormalizeHexColor(db.currentOrdersColor, DEFAULTS.currentOrdersColor)
        db.newOrderFontSize = math.floor((tonumber(db.newOrderFontSize) or DEFAULTS.newOrderFontSize) + 0.5)
        if db.newOrderFontSize < 8 then db.newOrderFontSize = 8 end
        if db.newOrderFontSize > 96 then db.newOrderFontSize = 96 end
        db.newOrderColor = NormalizeHexColor(db.newOrderColor, DEFAULTS.newOrderColor)
        db.newOrderAlignment = NormalizeNewOrderAlignment(db.newOrderAlignment)
        db.newOrderFlashing = db.newOrderFlashing and true or false
        db.newOrderDuration = math.floor((tonumber(db.newOrderDuration) or DEFAULTS.newOrderDuration) + 0.5)
        if db.newOrderDuration < 1 then db.newOrderDuration = 1 end
        if db.newOrderDuration > 30 then db.newOrderDuration = 30 end

        if FN and FN.SetSharedVoicePackActor then
            FN:SetSharedVoicePackActor(db.voicePack)
        else
            NX.DB.settings = NX.DB.settings or {}
            NX.DB.settings.voicePack = NX.DB.settings.voicePack or {}
            NX.DB.settings.voicePack.actor = db.voicePack
        end

        return db
    end

    function PCO:ApplyNewOrderTextStyle()
        if not self.NewOrderDisplay or not self.NewOrderDisplay.Text then
            return
        end

        local db = self:EnsureDB()
        local text = self.NewOrderDisplay.Text

        local fontPath = (FN and FN.GetAddonFontPath and FN:GetAddonFontPath())
            or ((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF")
        local fontSize = tonumber(db.newOrderFontSize) or DEFAULTS.newOrderFontSize
        local alignment = NormalizeNewOrderAlignment(db.newOrderAlignment)
        local justifyPoint = "CENTER"
        local pointInsetX = 0

        if alignment == "LEFT" then
            justifyPoint = "LEFT"
            pointInsetX = 8
        elseif alignment == "RIGHT" then
            justifyPoint = "RIGHT"
            pointInsetX = -8
        end

        text:ClearAllPoints()
        text:SetPoint(justifyPoint, self.NewOrderDisplay, justifyPoint, pointInsetX, 0)

        text:SetWidth(0)
        text:SetJustifyH(alignment)
        text:SetJustifyV("MIDDLE")
        text:SetFont(fontPath, fontSize, "OUTLINE")
        local r, g, b = HexToRGB01(db.newOrderColor, DEFAULTS.newOrderColor)
        text:SetTextColor(r, g, b, 1)
        text:SetText(NEW_ORDER_ALERT_TEXT)
    end

    function PCO:IsNewOrderPositionUnlocked()
        local db = self:EnsureDB()
        return db.newOrderPositionUnlocked == true
    end

    function PCO:ApplyNewOrderAnchorPoint()
        if not self.NewOrderDisplay then
            return
        end

        local db = self:EnsureDB()
        self.NewOrderDisplay:ClearAllPoints()
        self.NewOrderDisplay:SetPoint("CENTER", UIParent, "CENTER", db.newOrderAnchorX, db.newOrderAnchorY)
    end

    function PCO:GetNewOrderFlooredAnchorOffsetsFromFrame()
        local db = self:EnsureDB()
        if not self.NewOrderDisplay then
            return db.newOrderAnchorX, db.newOrderAnchorY
        end

        local centerX, centerY = self.NewOrderDisplay:GetCenter()
        local parentCenterX, parentCenterY = UIParent:GetCenter()

        if centerX and centerY and parentCenterX and parentCenterY then
            if FN and FN.RoundToNearestPixel then
                return FN:RoundToNearestPixel(centerX - parentCenterX), FN:RoundToNearestPixel(centerY - parentCenterY)
            end
            return math.floor((centerX - parentCenterX) + 0.5), math.floor((centerY - parentCenterY) + 0.5)
        end

        local _, _, _, x, y = self.NewOrderDisplay:GetPoint(1)
        if FN and FN.RoundToNearestPixel then
            return FN:RoundToNearestPixel(x), FN:RoundToNearestPixel(y)
        end
        return math.floor((tonumber(x) or 0) + 0.5), math.floor((tonumber(y) or 0) + 0.5)
    end

    function PCO:StoreNewOrderAnchorOffsetsFromFrame()
        local db = self:EnsureDB()
        db.newOrderAnchorX, db.newOrderAnchorY = self:GetNewOrderFlooredAnchorOffsetsFromFrame()
        return db.newOrderAnchorX, db.newOrderAnchorY
    end

    function PCO:UpdateNewOrderDragHandle()
        if not self.NewOrderDisplay then
            return
        end

        if not self.NewOrderDragHandle and FN and FN.CreateAnchorController then
            self.NewOrderDragHandle = FN:CreateAnchorController({
                parent = self.NewOrderDisplay,
                moveFrame = self.NewOrderDisplay,
                elementName = "New Personal Order Received",
                nudgeStep = NEW_ORDER_ANCHOR_STEP_PX,
                extraVerticalPadding = NEW_ORDER_ANCHOR_EXTRA_VERTICAL_PADDING,
                labelFontSize = NEW_ORDER_ANCHOR_LABEL_FONT_SIZE,
                isMoveEnabled = function()
                    return PCO:IsNewOrderPositionUnlocked()
                end,
                getOffsets = function()
                    return PCO:GetNewOrderFlooredAnchorOffsetsFromFrame()
                end,
                setOffsets = function(x, y)
                    local db = PCO:EnsureDB()
                    if FN and FN.RoundToNearestPixel then
                        db.newOrderAnchorX = FN:RoundToNearestPixel(x)
                        db.newOrderAnchorY = FN:RoundToNearestPixel(y)
                    else
                        db.newOrderAnchorX = math.floor((tonumber(x) or 0) + 0.5)
                        db.newOrderAnchorY = math.floor((tonumber(y) or 0) + 0.5)
                    end
                    PCO:ApplyNewOrderAnchorPoint()
                end,
                onDragStop = function()
                    PCO:StoreNewOrderAnchorOffsetsFromFrame()
                    PCO:ApplyNewOrderAnchorPoint()
                end,
                onLock = function()
                    PCO:SetNewOrderPositionUnlocked(false)
                end,
            })
        end

        if self.NewOrderDragHandle then
            if self.NewOrderDragHandle.SetElementName then
                self.NewOrderDragHandle:SetElementName("New Personal Order Received")
            end
            self.NewOrderDragHandle:SetShown(self:IsNewOrderPositionUnlocked())
            if self.NewOrderDragHandle.CoordLabel then
                local x, y = self:GetNewOrderFlooredAnchorOffsetsFromFrame()
                self.NewOrderDragHandle.CoordLabel:SetText(string.format("%d, %d", x, y))
            end
        end
    end

    function PCO:SetNewOrderPositionUnlocked(unlocked, suppressPrint)
        local db = self:EnsureDB()
        db.newOrderPositionUnlocked = unlocked and true or false
        self:EnsureNewOrderDisplay()
        self:UpdateNewOrderDisplayVisibility(false)

        if suppressPrint then
            return
        end

        if db.newOrderPositionUnlocked then
            print("|cffffd200Nexus:|r New Personal Order Received anchor is unlocked.")
        else
            print("|cffffd200Nexus:|r New Personal Order Received anchor is locked.")
        end
    end

    function PCO:EnsureNewOrderDisplay()
        if self.NewOrderDisplay then
            return self.NewOrderDisplay
        end

        local alert
        if FN and FN.CreateAnchorFrame then
            alert = FN:CreateAnchorFrame(UIParent, NEW_ORDER_ANCHOR_WIDTH, NEW_ORDER_ANCHOR_HEIGHT)
        else
            alert = CreateFrame("Frame", "NexusNewPersonalOrderReceivedDisplay", UIParent)
            alert:SetSize(NEW_ORDER_ANCHOR_WIDTH, NEW_ORDER_ANCHOR_HEIGHT)
        end
        alert:SetClampedToScreen(true)
        alert:Hide()

        local text = alert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", alert, "CENTER", 0, 0)

        alert.Text = text
        alert.Flash = text:CreateAnimationGroup()
        alert.Flash:SetLooping("BOUNCE")

        local fadeOut = alert.Flash:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0.35)
        fadeOut:SetDuration(0.35)
        fadeOut:SetSmoothing("IN_OUT")

        local fadeIn = alert.Flash:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.35)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.35)
        fadeIn:SetSmoothing("IN_OUT")

        self.NewOrderDisplay = alert

        self:ApplyNewOrderTextStyle()
        self:ApplyNewOrderAnchorPoint()
        self:UpdateNewOrderDragHandle()
        self:UpdateNewOrderDisplayVisibility(false)

        return alert
    end

    function PCO:UpdateNewOrderDisplayVisibility(showNow)
        local db = self:EnsureDB()
        local alert = self:EnsureNewOrderDisplay()
        local shouldShow = db.newOrderPositionUnlocked or showNow

        alert:SetShown(shouldShow)
        if not self.NewOrderDragHandle then
            alert:SetMovable(db.newOrderPositionUnlocked)
            alert:EnableMouse(db.newOrderPositionUnlocked)
        end
        self:UpdateNewOrderDragHandle()

        self:ApplyNewOrderTextStyle()

        if alert.Flash and alert.Flash.IsPlaying and alert.Flash:IsPlaying() then
            alert.Flash:Stop()
        end
        if alert.Text then
            alert.Text:SetAlpha(1)
        end

        if showNow and db.newOrderFlashing and alert.Flash and alert.Flash.Play then
            alert.Flash:Play()
        end

        if self.NewOrderHideTimer then
            self.NewOrderHideTimer:Cancel()
            self.NewOrderHideTimer = nil
        end

        if showNow and not db.newOrderPositionUnlocked then
            local duration = tonumber(db.newOrderDuration) or DEFAULTS.newOrderDuration
            if duration < 1 then duration = 1 end
            if duration > 30 then duration = 30 end
            self.NewOrderHideTimer = C_Timer.NewTimer(duration, function()
                if not PCO.NewOrderDisplay then
                    return
                end
                PCO:UpdateNewOrderDisplayVisibility(false)
            end)
        end
    end

    function PCO:ShowNewOrderTextAlert()
        self:EnsureDB()
        self:EnsureNewOrderDisplay()
        self:UpdateNewOrderDisplayVisibility(true)
    end

    function PCO:EnsureDisplay()
        if self.Display then
            return self.Display
        end

        local display = CreateFrame("Frame", "NexusPersonalCraftingOrdersDisplay", UIParent)
        display:SetSize(240, 24)
        display:Hide()

        local text = display:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", display, "TOPLEFT", 2, -2)
        text:SetJustifyH("LEFT")
        text:SetFont("Fonts\\FRIZQT__.TTF", DEFAULTS.currentOrdersFontSize, "OUTLINE")
        text:SetTextColor(1, 1, 1, 1)

        display.Text = text

        self.Display = display
        return display
    end

    function PCO:ApplyAnchor()
        local display = self:EnsureDisplay()
        local professionsFrame = _G.ProfessionsFrame
        local tabSystem = GetAnchorFrame()

        display:ClearAllPoints()

        if professionsFrame and tabSystem then
            display:SetParent(professionsFrame)
            if professionsFrame.GetFrameStrata then
                display:SetFrameStrata(professionsFrame:GetFrameStrata() or "HIGH")
                display:SetFrameLevel((professionsFrame:GetFrameLevel() or 0) + 10)
            else
                display:SetFrameStrata("HIGH")
            end
            display:SetPoint("TOPLEFT", tabSystem, "BOTTOMLEFT", 2, -2)
            return true
        end

        if professionsFrame then
            display:SetParent(professionsFrame)
            if professionsFrame.GetFrameStrata then
                display:SetFrameStrata(professionsFrame:GetFrameStrata() or "HIGH")
                display:SetFrameLevel((professionsFrame:GetFrameLevel() or 0) + 10)
            else
                display:SetFrameStrata("HIGH")
            end
            display:SetPoint("BOTTOMLEFT", professionsFrame, "BOTTOMLEFT", 20, -36)
            return true
        end

        display:SetParent(UIParent)
        return false
    end

    function PCO:Update()
        local db = self:EnsureDB()
        local display = self:EnsureDisplay()
        if display.Text then
            local fontPath = (FN and FN.GetAddonFontPath and FN:GetAddonFontPath())
                or ((FN and FN.DEFAULT_FONT_PATH) or "Fonts\\FRIZQT__.TTF")
            local fontSize = tonumber(db.currentOrdersFontSize) or DEFAULTS.currentOrdersFontSize
            display.Text:SetFont(fontPath, fontSize, "OUTLINE")
            local r, g, b = HexToRGB01(db.currentOrdersColor)
            display.Text:SetTextColor(r, g, b, 1)
        end

        if not db.textAlertEnabled then
            display:Hide()
            return
        end

        local anchored = self:ApplyAnchor()
        if not anchored then
            display:Hide()
            return
        end

        local total = ClampOrderCount(GetTotalPersonalOrders())

        display.Text:SetText(string.format("%d Open Personal Orders", total))
        display:Show()
    end

    function PCO:EnsureHooks()
        if self._hooksInstalled then
            return
        end

        local professionsFrame = _G.ProfessionsFrame
        if not professionsFrame then
            return
        end

        professionsFrame:HookScript("OnShow", function()
            PCO:Update()
        end)

        self._hooksInstalled = true
    end

    function PCO:OnSettingsChanged()
        self:Apply()
    end

    function PCO:SetEnabled(enabled)
        local db = self:EnsureDB()
        db.textAlertEnabled = enabled and true or false
        self:Apply()
    end

    function PCO:Toggle()
        local db = self:EnsureDB()
        self:SetEnabled(not db.textAlertEnabled)
    end

    function PCO:HandlePersonalOrderCountUpdate()
        local total = ClampOrderCount(GetTotalPersonalOrders())

        if self.lastKnownPersonalOrderCount == nil then
            self.lastKnownPersonalOrderCount = total
            return
        end

        local previous = self.lastKnownPersonalOrderCount
        self.lastKnownPersonalOrderCount = total

        if total <= previous then
            return
        end

        local db = self:EnsureDB()
        if not db.newOrderAlertEnabled then
            return
        end

        self:ShowNewOrderTextAlert()
        self:PlayAlertSound()
    end

    function PCO:PlayAlertSound()
        local db = self:EnsureDB()

        if not db.soundAlertEnabled then
            return false
        end

        local soundPaths = BuildVoicePackSoundPaths(db.voicePack, NEW_ORDER_SOUND_FILE)
        if type(soundPaths) ~= "table" or #soundPaths == 0 then
            return false
        end
        if PlaySoundFile then
            for _, soundPath in ipairs(soundPaths) do
                if type(soundPath) == "string" and soundPath ~= "" then
                    local ok = pcall(PlaySoundFile, soundPath, "Master")
                    if ok then
                        return true
                    end
                end
            end
        end
        return false
    end

    function PCO:Apply()
        self:EnsureDB()
        if self.lastKnownPersonalOrderCount == nil then
            self.lastKnownPersonalOrderCount = ClampOrderCount(GetTotalPersonalOrders())
        end
        self:EnsureHooks()
        self:Update()
        self:EnsureNewOrderDisplay()
        self:UpdateNewOrderDisplayVisibility(false)
    end

    function PCO:HandleNxSlash(msg)
        local text = string.lower(tostring(msg or ""))
        text = string.match(text, "^%s*(.-)%s*$") or ""

        if text == "" or text == "toggle" then
            self:Toggle()
            return true
        end

        if text == "on" or text == "enable" or text == "enabled" then
            self:SetEnabled(true)
            return true
        end

        if text == "off" or text == "disable" or text == "disabled" then
            self:SetEnabled(false)
            return true
        end

        if text == "help" or text == "?" then
            return true
        end

        return true
    end

    function PCO:Init()
        self:EnsureDB()

        if frame then
            self:Apply()
            return
        end

        LoadProfessionsUI()

        frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("UI_SCALE_CHANGED")

        frame:SetScript("OnEvent", function(_, event, arg1)
            if event == "CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS" then
                PCO:HandlePersonalOrderCountUpdate()
                PCO:Apply()
                return
            end

            if event == "ADDON_LOADED" then
                if arg1 == "Blizzard_Professions" then
                    C_Timer.After(0, function()
                        PCO:Apply()
                    end)
                end
                return
            end

            PCO:Apply()
        end)

        C_Timer.After(0, function()
            PCO:Apply()
        end)
    end
end

