local NX = Nexus
local CV = NX.CVars
local FN = NX.Functions

local function SetCVarBool(name, enabled)
    if FN and FN.SetCVarBool then
        FN:SetCVarBool(name, enabled)
        return
    end
    if CV and CV.SetBool then
        CV:SetBool(name, enabled)
    end
end

local function GetCVarBool(name, fallback)
    if FN and FN.GetCVarBool then
        return FN:GetCVarBool(name, fallback)
    end
    if CV and CV.GetBool then
        return CV:GetBool(name, fallback)
    end
    return fallback and true or false
end

NX.Currencies = NX.Currencies or {}
do
    local M = NX.Currencies

    local DEFAULTS = {
        parent = UIParent,
        selfPoint = "TOPLEFT",
        characterFramePoint = "TOPRIGHT",
        x = 0,
        y = 0,
        scale = 1.0,

        padding = 8,
        rowGap = 8,
        textGap = 5,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        lineGap = 2,

        showBackground = false,
        bgColor = { 0, 0, 0, 0.35 },
    }

    local REQUIRED_CURRENCIES = {
        { id = 3378, text = "Catalyst Charges" },
        { id = 3383, text = "Adventurer Dawncrest" },
        { id = 3341, text = "Veteran Dawncrest" },
        { id = 3343, text = "Champion Dawncrest" },
        { id = 3345, text = "Hero Dawncrest" },
        { id = 3347, text = "Myth Dawncrest" },
        { id = 3316, text = "Voidlight Marl" },
    }

    local function SetBackdropColor(frame, bgColor)
        if not frame or not frame.SetBackdrop then return end
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = nil,
            tile = false,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    end

    local function SafeGetCurrencyInfo(currencyID)
        if not currencyID then return nil end
        if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return nil end
        return C_CurrencyInfo.GetCurrencyInfo(currencyID)
    end

    local function CreateRow(parent, opts)
        local row = CreateFrame("Frame", nil, parent)
        row:EnableMouse(true)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)

        row.iconBorder = CreateFrame("Frame", nil, row, BackdropTemplateMixin and "BackdropTemplate" or nil)
        row.iconBorder:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -2, 2)
        row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 2, -2)
        if row.iconBorder.SetBackdrop then
            row.iconBorder:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            row.iconBorder:SetBackdropBorderColor(0, 0, 0, 1)
        end

        row.line1 = row:CreateFontString(nil, "OVERLAY")
        row.line1:SetFont(opts.font, opts.fontSize, opts.fontFlags)
        row.line1:SetJustifyH("LEFT")
        row.line1:SetShadowOffset(1, -1)
        row.line1:SetShadowColor(0, 0, 0, 1)

        row.line2 = row:CreateFontString(nil, "OVERLAY")
        row.line2:SetFont(opts.font, opts.fontSize, opts.fontFlags)
        row.line2:SetJustifyH("LEFT")
        row.line2:SetShadowOffset(1, -1)
        row.line2:SetShadowColor(0, 0, 0, 1)

        row.line1:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", opts.textGap, 0)
        row.line2:SetPoint("TOPLEFT", row.line1, "BOTTOMLEFT", 0, -opts.lineGap)

        row:SetScript("OnEnter", function(self)
            if not self.currencyID then return end
            if not GameTooltip then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip.SetCurrencyByID then
                GameTooltip:SetCurrencyByID(self.currencyID)
            else
                local info = SafeGetCurrencyInfo(self.currencyID)
                if info and info.name then
                    GameTooltip:AddLine(info.name)
                    GameTooltip:Show()
                end
            end
        end)

        row:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        return row
    end

    local Tracker = {}
    Tracker.__index = Tracker

    function Tracker:_ComputeIconSize()
        return (self.opts.fontSize * 2) + self.opts.lineGap
    end

    function Tracker:_TryAttach()
        local cf = _G.CharacterFrame
        if not cf then return false end
        self.frame:ClearAllPoints()
        self.frame:SetPoint(self.opts.selfPoint, cf, self.opts.characterFramePoint, self.opts.x, self.opts.y)
        return true
    end

    function Tracker:_SetRowText(i)
        local entry = self.currencies[i]
        local row = self.rows[i]
        if not entry or not row then return end

        row.currencyID = entry.id

        local info = SafeGetCurrencyInfo(entry.id)
        if not info then
            row.icon:SetTexture(nil)
            row.line1:SetText(entry.text or ("Currency " .. tostring(entry.id)))
            row.line2:SetText("N/A")
            return
        end

        row.icon:SetTexture(info.iconFileID or 0)

        local name = entry.text or info.name or ("Currency " .. tostring(entry.id))
        row.line1:SetText(name)

        local current = info.quantity or 0
        local maxQty = info.maxQuantity or 0
        if maxQty and maxQty > 0 then
            row.line2:SetText(("%d/%d"):format(current, maxQty))
        else
            row.line2:SetText(("%d"):format(current))
        end
    end

    function Tracker:_Layout()
        local iconSize = self:_ComputeIconSize()
        local rowHeight = iconSize

        local maxTextWidth = 0
        local totalHeight = self.opts.padding * 2

        for i, row in ipairs(self.rows) do
            row.icon:SetSize(iconSize, iconSize)
            row:SetHeight(rowHeight)

            row:ClearAllPoints()
            if i == 1 then
                row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.opts.padding, -self.opts.padding)
                row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -self.opts.padding, -self.opts.padding)
            else
                row:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -self.opts.rowGap)
                row:SetPoint("TOPRIGHT", self.rows[i - 1], "BOTTOMRIGHT", 0, -self.opts.rowGap)
            end

            local w1 = row.line1:GetStringWidth() or 0
            local w2 = row.line2:GetStringWidth() or 0
            maxTextWidth = math.max(maxTextWidth, w1, w2)

            totalHeight = totalHeight + rowHeight + (i > 1 and self.opts.rowGap or 0)
        end

        local totalWidth = (self.opts.padding * 2) + iconSize + self.opts.textGap + maxTextWidth
        self.frame:SetSize(totalWidth, totalHeight)
    end

    function Tracker:UpdateAll()
        for i = 1, #self.currencies do
            self:_SetRowText(i)
        end
        self:_Layout()
    end

    function Tracker:SetCurrencies(currencies)
        self.currencies = currencies or {}

        for _, row in ipairs(self.rows or {}) do
            row:Hide()
        end
        self.rows = {}

        for i = 1, #self.currencies do
            self.rows[i] = CreateRow(self.frame, self.opts)
        end

        self:UpdateAll()
    end

    function Tracker:_OnEvent(event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "Blizzard_CharacterUI" then
                self:_TryAttach()
                self:_HookCharacterFrameVisibility()
            end
            return
        end

        if event == "PLAYER_LOGIN" then
            self:_TryAttach()
            return
        end

        if event == "CURRENCY_DISPLAY_UPDATE" then
            local currencyType = ...
            if type(currencyType) ~= "number" then
                self:UpdateAll()
                return
            end
            for i = 1, #self.currencies do
                if self.currencies[i].id == currencyType then
                    self:_SetRowText(i)
                    self:_Layout()
                    return
                end
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            self:UpdateAll()
            return
        end
    end

    function Tracker:_HookCharacterFrameVisibility()
        local cf = _G.CharacterFrame
        if not cf then return end
        if self._hooked then return end
        self._hooked = true

        self.frame:Hide()

        cf:HookScript("OnShow", function()
            self:_TryAttach()
            local shouldShow = true
            if type(self.opts.shouldShowFn) == "function" then
                shouldShow = self.opts.shouldShowFn() and true or false
            end

            if shouldShow then
                self.frame:Show()
                self:UpdateAll()
            else
                self.frame:Hide()
            end
        end)

        cf:HookScript("OnHide", function()
            self.frame:Hide()
        end)
    end

    function Tracker:RefreshOpts(newOpts)
        if type(newOpts) ~= "table" then return end

        for k, v in pairs(newOpts) do
            if k == "bgColor" and type(v) == "table" then
                self.opts.bgColor = {
                    tonumber(v[1]) or 0,
                    tonumber(v[2]) or 0,
                    tonumber(v[3]) or 0,
                    tonumber(v[4]) or 0.35,
                }
            else
                self.opts[k] = v
            end
        end

        self.frame:SetScale(self.opts.scale)
        if self.opts.showBackground then
            SetBackdropColor(self.frame, self.opts.bgColor)
        else
            self.frame:SetBackdrop(nil)
        end

        self:_TryAttach()
        self:UpdateAll()
    end

    function Tracker.New(opts)
        opts = opts or {}
        local o = setmetatable({}, Tracker)

        o.opts = {}
        for k, v in pairs(DEFAULTS) do
            if k == "bgColor" and type(v) == "table" then
                local copy = {}
                for i = 1, #v do copy[i] = v[i] end
                o.opts[k] = copy
            else
                o.opts[k] = v
            end
        end
        for k, v in pairs(opts) do
            o.opts[k] = v
        end

        local f = CreateFrame("Frame", nil, o.opts.parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        o.frame = f
        f:SetScale(o.opts.scale)
        f:SetFrameStrata("MEDIUM")
        if o.opts.showBackground then SetBackdropColor(f, o.opts.bgColor) end
        f:SetScript("OnEvent", function(_, event, ...) o:_OnEvent(event, ...) end)

        o.rows = {}
        o:SetCurrencies(opts.currencies or {})

        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("ADDON_LOADED")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

        o:_TryAttach()
        o:_HookCharacterFrameVisibility()

        local cf = _G.CharacterFrame
        local shouldShow = true
        if type(o.opts.shouldShowFn) == "function" then
            shouldShow = o.opts.shouldShowFn() and true or false
        end

        if cf and cf:IsShown() and shouldShow then
            o.frame:Show()
            o:UpdateAll()
        else
            o.frame:Hide()
        end

        return o
    end

    function M:EnsureDB()
        NX.DB.system.currencies = NX.DB.system.currencies or {}
        local db = NX.DB.system.currencies

        if db.enabled == nil then db.enabled = false end
        if type(db.selfPoint) ~= "string" or db.selfPoint == "" then db.selfPoint = "TOPLEFT" end
        if type(db.characterFramePoint) ~= "string" or db.characterFramePoint == "" then db.characterFramePoint = "TOPRIGHT" end
        db.x = tonumber(db.x) or 0
        db.y = tonumber(db.y) or 0
        db.scale = tonumber(db.scale) or 1
        if db.scale < 0.5 then db.scale = 0.5 end
        if db.scale > 2 then db.scale = 2 end
        db.fontSize = math.floor((tonumber(db.fontSize) or 12) + 0.5)
        if db.fontSize < 8 then db.fontSize = 8 end
        if db.fontSize > 32 then db.fontSize = 32 end
        if db.showBackground == nil then db.showBackground = false end

        if db.selfPoint == "LEFT" and db.characterFramePoint == "RIGHT" and db.x == 0 and db.y == 0 then
            db.selfPoint = "TOPLEFT"
            db.characterFramePoint = "TOPRIGHT"
        elseif db.selfPoint == "TOPLEFT" and db.characterFramePoint == "TOPLEFT" and db.x == 0 and db.y == 0 then
            db.characterFramePoint = "TOPRIGHT"
        end

        if type(db.list) ~= "table" then
            db.list = {}
        end

        local byId = {}
        for _, entry in ipairs(db.list) do
            local id = tonumber(entry and entry.id)
            if id and id > 0 then
                byId[math.floor(id + 0.5)] = entry
            end
        end

        for _, entry in ipairs(REQUIRED_CURRENCIES) do
            local existing = byId[entry.id]
            if existing then
                existing.text = entry.text
            else
                db.list[#db.list + 1] = { id = entry.id, text = entry.text }
            end
        end

        return db
    end

    function M:GetSanitizedCurrencies()
        local db = self:EnsureDB()
        local out = {}
        for _, entry in ipairs(db.list) do
            local id = tonumber(entry and entry.id)
            if id and id > 0 then
                out[#out + 1] = {
                    id = math.floor(id + 0.5),
                    text = type(entry.text) == "string" and entry.text or nil,
                }
            end
        end
        return out
    end

    function M:GetTrackerOptions()
        local db = self:EnsureDB()
        return {
            selfPoint = db.selfPoint,
            characterFramePoint = db.characterFramePoint,
            x = db.x,
            y = db.y,
            scale = db.scale,
            fontSize = db.fontSize,
            showBackground = db.showBackground == true,
            font = NX.DB.media.fonts.addonFontPath or DEFAULTS.font,
            shouldShowFn = function()
                return NX.DB and NX.DB.system.currencies and NX.DB.system.currencies.enabled == true
            end,
            currencies = self:GetSanitizedCurrencies(),
        }
    end

    function M:Apply()
        local db = self:EnsureDB()

        if not self._tracker then
            self._tracker = Tracker.New(self:GetTrackerOptions())
        end

        local opts = self:GetTrackerOptions()
        self._tracker:RefreshOpts(opts)
        self._tracker:SetCurrencies(opts.currencies)

        if db.enabled then
            if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
                self._tracker.frame:Show()
            end
            self._tracker:UpdateAll()
            return
        end

        self._tracker.frame:Hide()
    end

    function M:SetEnabled(enabled)
        local db = self:EnsureDB()
        db.enabled = enabled and true or false
        self:Apply()
    end

    function M:Toggle()
        local db = self:EnsureDB()
        self:SetEnabled(not db.enabled)
        print(string.format("|cffffd200Nexus:|r Currencies %s.", db.enabled and "enabled" or "disabled"))
    end

    function M:OnSettingsChanged()
        self:Apply()
    end

    function M:Init()
        self:EnsureDB()
        self:Apply()
    end

    function M:HandleNxSlash(msg)
        local text = string.lower(tostring(msg or ""))
        text = string.match(text, "^%s*(.-)%s*$") or ""

        if text == "" then
            self:Toggle()
            return true
        end

        if text == "help" or text == "?" then
            print("|cffffd200Nexus:|r /nx currency")
            print("|cffffd200Nexus:|r /nx currency on")
            print("|cffffd200Nexus:|r /nx currency off")
            print("|cffffd200Nexus:|r /nx currency toggle")
            return true
        end

        if text == "on" or text == "enable" or text == "enabled" then
            self:SetEnabled(true)
            print("|cffffd200Nexus:|r Currencies enabled.")
            return true
        end

        if text == "off" or text == "disable" or text == "disabled" then
            self:SetEnabled(false)
            print("|cffffd200Nexus:|r Currencies disabled.")
            return true
        end

        if text == "toggle" then
            self:Toggle()
            return true
        end

        print("|cffffd200Nexus:|r Unknown /nx currency command. Use: /nx currency help")
        return true
    end
end

