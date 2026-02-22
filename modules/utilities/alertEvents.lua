local NX = Nexus
NX.AlertEvents = NX.AlertEvents or {}
NX.UtilityAlerts = NX.AlertEvents
local UA = NX.AlertEvents
local FN = NX.Functions

local EVENT_SOUND_FILES = {
    FEAST = "feast.ogg",
    POTION_CAULDRON = "potion_cauldron.ogg",
    FLASK_CAULDRON = "flask_cauldron.ogg",
    JEEVES = "jeeves.ogg",
    MAILBOX = "mailbox.ogg",
    AUTO_HAMMER = "repair_hammer.ogg",
    SOULWELL = "healthstones.ogg",
    MAGE_TABLE = "mage_table.ogg",
}

local DEFAULTS = {
    enabled = true,
    soundEnabled = true,
    textSize = 28,
    align = "CENTER",
    duration = 3,
    grow = "UP",
    voicePack = FN.VOICE_PACK_DEFAULT,
}

local EVENTS = {
    { key = "FEAST", label = "FEAST UP", color = { 1, 0.016, 0.976 }, spellIDs = { 1259656, 1232065 } },
    { key = "POTION_CAULDRON", label = "POTION CAULDRON UP", color = { 0.161, 1, 0.427 }, spellIDs = { 433294, 433293, 433292, 1240225 } },
    { key = "FLASK_CAULDRON", label = "FLASK CAULDRON UP", color = { 1, 0.337, 0 }, spellIDs = { 432879, 432878, 432877, 1240019 } },
    { key = "JEEVES", label = "JEEVES UP", color = { 1, 0.784, 0.09 }, spellIDs = { 67826 } },
    { key = "MAILBOX", label = "MAILBOX UP", color = { 1, 0.784, 0.09 }, spellIDs = { 156833, 1229295, 376664, 261602, 156756, 54710 } },
    { key = "AUTO_HAMMER", label = "AUTO-HAMMER UP", color = { 1, 0.678, 0 }, spellIDs = { 199109 } },
    { key = "SOULWELL", label = "SOULWELL UP", color = { 0.443, 0.341, 1 }, spellIDs = { 29893 } },
    { key = "MAGE_TABLE", label = "MAGE-TABLE UP", color = { 0.071, 0.541, 1 }, spellIDs = { 190336 } },
}

local EVENT_DEFAULTS = {}
for _, eventData in ipairs(EVENTS) do
    EVENT_DEFAULTS[eventData.key] = {
        enabled = true,
        flashing = false,
    }
end

local SPELL_ID_TO_EVENTS = {}
for _, eventData in ipairs(EVENTS) do
    for _, spellID in ipairs(eventData.spellIDs) do
        SPELL_ID_TO_EVENTS[spellID] = SPELL_ID_TO_EVENTS[spellID] or {}
        table.insert(SPELL_ID_TO_EVENTS[spellID], eventData)
    end
end

local function ResolveEventDataForSpell(spellID)
    local candidates = SPELL_ID_TO_EVENTS[tonumber(spellID)]
    if type(candidates) ~= "table" or #candidates == 0 then
        return nil
    end

    for _, eventData in ipairs(candidates) do
        if UA:IsEventEnabled(eventData.key) then
            return eventData
        end
    end

    return candidates[1]
end

local alertFrame
local eventFrame
local activeAlerts = {}
local nextAlertId = 1
local recentCastGuids = {}
local spellCooldownExpiresAt = {}

local EVENT_COOLDOWN_SECONDS = 10

local DEFAULT_ANCHOR_X = 0
local DEFAULT_ANCHOR_Y = 200
local ANCHOR_WIDTH = 420
local ANCHOR_HEIGHT = 220
local ANCHOR_STEP_PX = 1
local ANCHOR_EXTRA_VERTICAL_PADDING = 20
local ANCHOR_LABEL_FONT_SIZE = 16

UA.Anchor = UA.Anchor or nil
UA.DragHandle = UA.DragHandle or nil
UA.AnchorDisplayName = UA.AnchorDisplayName or "Utility Alerts"

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function NormalizeAlign(value)
    value = string.upper(tostring(value or "CENTER"))
    if value == "LEFT" or value == "CENTER" or value == "RIGHT" then
        return value
    end
    return "CENTER"
end

local function NormalizeGrow(value)
    value = string.upper(tostring(value or "UP"))
    if value == "UP" or value == "DOWN" then
        return value
    end
    return "UP"
end

local function Trim(value)
    local text = tostring(value or "")
    return string.match(text, "^%s*(.-)%s*$") or ""
end

local function ShouldProcessAlertCasts()
    if FN and FN.PassesCommonNonCombatRules then
        return FN:PassesCommonNonCombatRules()
    end

    return false
end

local function GetVoicePackSoundPaths(actor, eventKey)
    local filename = EVENT_SOUND_FILES[eventKey]
    if not filename then
        return nil
    end
    return FN:GetVoicePackSoundPaths(actor, filename, NX.name)
end

local function GetFontPath()
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

function UA:EnsureDB()
    NX.DB.alerts.alertEvents = NX.DB.alerts.alertEvents or {}
    local db = NX.DB.alerts.alertEvents
    CopyDefaults(db, DEFAULTS)

    db.enabled = db.enabled and true or false
    db.soundEnabled = db.soundEnabled and true or false
    db.textSize = math.floor(FN:ClampNumber(db.textSize, 8, 72) + 0.5)
    db.align = NormalizeAlign(db.align)
    db.duration = math.floor(FN:ClampNumber(db.duration, 1, 5) + 0.5)
    db.grow = NormalizeGrow(db.grow)
    db.voicePack = FN:NormalizeVoicePackActor(FN:GetSharedVoicePackActor() or db.voicePack)
    if db.anchorX == nil then db.anchorX = DEFAULT_ANCHOR_X end
    if db.anchorY == nil then db.anchorY = DEFAULT_ANCHOR_Y end
    if db.positionUnlocked == nil then db.positionUnlocked = false end
    db.sounds = nil

    db.events = db.events or {}
    for key, eventDefaults in pairs(EVENT_DEFAULTS) do
        db.events[key] = db.events[key] or {}
        local eventCfg = db.events[key]
        if eventCfg.enabled == nil then
            eventCfg.enabled = eventDefaults.enabled and true or false
        end
        if eventCfg.flashing == nil then
            eventCfg.flashing = eventDefaults.flashing and true or false
        end
        eventCfg.enabled = eventCfg.enabled and true or false
        eventCfg.flashing = eventCfg.flashing and true or false
    end

    if FN and FN.RoundToNearestPixel then
        db.anchorX = FN:RoundToNearestPixel(db.anchorX)
        db.anchorY = FN:RoundToNearestPixel(db.anchorY)
    else
        db.anchorX = math.floor(tonumber(db.anchorX) or DEFAULT_ANCHOR_X)
        db.anchorY = math.floor(tonumber(db.anchorY) or DEFAULT_ANCHOR_Y)
    end
    db.positionUnlocked = db.positionUnlocked and true or false

    if FN and FN.SetSharedVoicePackActor then
        FN:SetSharedVoicePackActor(db.voicePack)
    else
        NX.DB.settings = NX.DB.settings or {}
        NX.DB.settings.voicePack = NX.DB.settings.voicePack or {}
        NX.DB.settings.voicePack.actor = db.voicePack
    end

    return db
end

function UA:IsPositionUnlocked()
    local db = self:EnsureDB()
    return db.positionUnlocked == true
end

function UA:ApplyAnchorPoint()
    if not self.Anchor then
        return
    end

    local db = self:EnsureDB()
    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
end

function UA:GetFlooredAnchorOffsetsFromFrame()
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

function UA:StoreFlooredAnchorOffsetsFromFrame()
    local db = self:EnsureDB()
    db.anchorX, db.anchorY = self:GetFlooredAnchorOffsetsFromFrame()
    return db.anchorX, db.anchorY
end

function UA:SetAnchorOffsets(x, y)
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

function UA:UpdateDragHandleReadout()
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

function UA:UpdateDragHandle()
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
                return UA:IsPositionUnlocked()
            end,
            getOffsets = function()
                return UA:GetFlooredAnchorOffsetsFromFrame()
            end,
            setOffsets = function(x, y)
                UA:SetAnchorOffsets(x, y)
            end,
            onDragStop = function()
                UA:StoreFlooredAnchorOffsetsFromFrame()
                UA:ApplyAnchorPoint()
                UA:UpdateDragHandleReadout()
            end,
            onLock = (FN and FN.CreateLockOnClickHandler and FN:CreateLockOnClickHandler(UA, false))
                or function()
                    UA:SetPositionUnlocked(false)
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

function UA:SetPositionUnlocked(unlocked, suppressPrint)
    local db = self:EnsureDB()
    db.positionUnlocked = unlocked and true or false
    self:RefreshAlertDisplay()

    if suppressPrint then
        return
    end

    if db.positionUnlocked then
        print("|cffffd200Nexus:|r Utility Alerts position unlocked.")
    else
        print("|cffffd200Nexus:|r Utility Alerts position locked.")
    end
end

function UA:IsEventEnabled(eventKey)
    local db = self:EnsureDB()
    local eventCfg = db.events and db.events[eventKey]
    if not eventCfg then
        return true
    end
    return eventCfg.enabled == true
end

function UA:IsEventFlashing(eventKey)
    local db = self:EnsureDB()
    local eventCfg = db.events and db.events[eventKey]
    if not eventCfg then
        return false
    end
    return eventCfg.flashing == true
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

function UA:EnsureFrame()
    if alertFrame then
        return alertFrame
    end

    if FN and FN.CreateAnchorFrame then
        alertFrame = FN:CreateAnchorFrame(UIParent, ANCHOR_WIDTH, ANCHOR_HEIGHT, 1, 1)
        alertFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    else
        alertFrame = CreateFrame("Frame", "NexusUtilityAlertsFrame", UIParent)
        alertFrame:SetSize(ANCHOR_WIDTH, ANCHOR_HEIGHT)
    end
    self.Anchor = alertFrame
    self:ApplyAnchorPoint()
    self:UpdateDragHandle()
    alertFrame:Hide()
    alertFrame.lines = {}

    return alertFrame
end

function UA:RefreshAlertDisplay()
    local db = self:EnsureDB()
    local host = self:EnsureFrame()

    local now = GetTime()
    for i = #activeAlerts, 1, -1 do
        if activeAlerts[i].expiresAt <= now then
            table.remove(activeAlerts, i)
        end
    end

    if not db.enabled or #activeAlerts == 0 then
        host:SetShown(self:IsPositionUnlocked())
        if host.lines then
            for _, line in ipairs(host.lines) do
                line:Hide()
                line:SetText("")
            end
        end
        self:UpdateDragHandle()
        return
    end

    host:Show()

    local fontPath = GetFontPath()
    local fontSize = db.textSize
    local justify = db.align
    local grow = db.grow

    local lineHeight = fontSize + 6

    for i, item in ipairs(activeAlerts) do
        local line = host.lines[i]
        if not line then
            line = host:CreateFontString(nil, "OVERLAY")
            host.lines[i] = line
        end

        line:SetFont(fontPath, fontSize, "OUTLINE")
        line:SetJustifyH(justify)
        line:SetJustifyV("MIDDLE")
        line:SetText(item.text)

        local color = item.color or { 1, 1, 1 }
        line:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, 1)

        line:ClearAllPoints()
        if i == 1 then
            line:SetPoint("CENTER", host, "CENTER", 0, 0)
        else
            local offset = (i - 1) * lineHeight
            if grow == "UP" then
                line:SetPoint("CENTER", host, "CENTER", 0, offset)
            else
                line:SetPoint("CENTER", host, "CENTER", 0, -offset)
            end
        end

        SetLineFlashing(line, item.flashing == true)

        line:Show()
    end

    for i = #activeAlerts + 1, #host.lines do
        SetLineFlashing(host.lines[i], false)
        host.lines[i]:Hide()
        host.lines[i]:SetText("")
    end

    host:SetShown(self:IsPositionUnlocked() or (#activeAlerts > 0 and db.enabled))
    self:UpdateDragHandle()
end

function UA:PlayConfiguredSound(eventKey)
    local db = self:EnsureDB()
    if db.soundEnabled == false then
        return false
    end

    local actor = FN:NormalizeVoicePackActor(FN:GetSharedVoicePackActor() or db.voicePack)
    local selectedPaths = GetVoicePackSoundPaths(actor, eventKey)
    if type(selectedPaths) ~= "table" or #selectedPaths == 0 then
        return false
    end

    if PlaySoundFile then
        for _, soundPath in ipairs(selectedPaths) do
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

function UA:AddAlert(text, color, eventKey, sourceSpellID)
    local db = self:EnsureDB()
    if not db.enabled then
        return
    end
    if eventKey and not self:IsEventEnabled(eventKey) then
        return
    end

    local cooldownSpellID = tonumber(sourceSpellID)
    if cooldownSpellID then
        local now = GetTime()
        local expiresAt = spellCooldownExpiresAt[cooldownSpellID] or 0
        if now < expiresAt then
            return
        end
        spellCooldownExpiresAt[cooldownSpellID] = now + EVENT_COOLDOWN_SECONDS
    end

    local duration = db.duration
    local now = GetTime()

    local alertId = nextAlertId
    nextAlertId = nextAlertId + 1

    table.insert(activeAlerts, {
        id = alertId,
        text = tostring(text or ""),
        color = color,
        flashing = eventKey and self:IsEventFlashing(eventKey) or false,
        expiresAt = now + duration,
    })

    self:PlayConfiguredSound(eventKey)
    self:RefreshAlertDisplay()

    C_Timer.After(duration, function()
        for i = #activeAlerts, 1, -1 do
            if activeAlerts[i].id == alertId then
                table.remove(activeAlerts, i)
                break
            end
        end
        UA:RefreshAlertDisplay()
    end)
end

function UA:ClearAlerts()
    wipe(activeAlerts)
    self:RefreshAlertDisplay()
end

local function IsGroupUnitToken(unitToken)
    if unitToken == "player" then
        return true
    end

    if type(unitToken) ~= "string" then
        return false
    end

    if string.match(unitToken, "^party%d+$") then
        return true
    end

    if string.match(unitToken, "^raid%d+$") then
        return true
    end

    return false
end

function UA:HandleUnitSpellcastSucceeded(unitToken, castGUID, spellID)
    if not ShouldProcessAlertCasts() then
        return
    end

    local db = self:EnsureDB()
    if not db.enabled then
        return
    end

    if not IsGroupUnitToken(unitToken) then
        return
    end

    if castGUID and recentCastGuids[castGUID] then
        return
    end
    if castGUID then
        recentCastGuids[castGUID] = true
        C_Timer.After(3, function()
            recentCastGuids[castGUID] = nil
        end)
    end

    local eventData = ResolveEventDataForSpell(spellID)
    if not eventData then
        return
    end
    if not self:IsEventEnabled(eventData.key) then
        return
    end

    self:AddAlert(eventData.label, eventData.color, eventData.key, spellID)
end

function UA:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitToken, castGUID, spellID = ...
        self:HandleUnitSpellcastSucceeded(unitToken, castGUID, spellID)
    end
end

function UA:OnSettingsChanged()
    self:EnsureDB()
    self:RefreshAlertDisplay()
end

function UA:OpenOptions()
    if NX.Settings and NX.Settings.Register then
        NX.Settings:Register()
    end

    if Settings and Settings.OpenToCategory and NX.Settings and type(NX.Settings.interfaceCategoryID) == "number" then
        Settings.OpenToCategory(NX.Settings.interfaceCategoryID)
        Settings.OpenToCategory(NX.Settings.interfaceCategoryID)
        return true
    end

    if NX.Settings and NX.Settings.Open then
        NX.Settings:Open()
        return true
    end

    return false
end

function UA:TestAlerts()
    self:AddAlert("FEAST UP", { 1, 0.016, 0.976 }, "FEAST")
    C_Timer.After(0.2, function() UA:AddAlert("FLASK CAULDRON UP", { 1, 0.337, 0 }, "FLASK_CAULDRON") end)
    C_Timer.After(0.4, function() UA:AddAlert("JEEVES UP", { 1, 0.784, 0.09 }, "JEEVES") end)
    C_Timer.After(0.6, function() UA:AddAlert("MAILBOX UP", { 1, 0.784, 0.09 }, "MAILBOX") end)
end

function UA:Toggle()
    local db = self:EnsureDB()
    db.enabled = not db.enabled

    if not db.enabled then
        self:ClearAlerts()
    else
        self:RefreshAlertDisplay()
    end

    print("|cffffd200Nexus:|r Utility Alerts " .. (db.enabled and "enabled" or "disabled") .. ".")
end

function UA:HandleNxSlash(msg)
    self:EnsureDB()

    local text = Trim(msg)
    text = string.lower(text)
    local cmd, rest = string.match(text, "^(%S+)%s*(.-)%s*$")
    cmd = string.lower(tostring(cmd or ""))

    if cmd == "" or cmd == "toggle" then
        self:Toggle()
        return true
    end

    local db = self:EnsureDB()

    if cmd == "on" or cmd == "enable" or cmd == "enabled" then
        db.enabled = true
        self:RefreshAlertDisplay()
        print("|cffffd200Nexus:|r Utility Alerts enabled.")
        return true
    end

    if cmd == "off" or cmd == "disable" or cmd == "disabled" then
        db.enabled = false
        self:ClearAlerts()
        print("|cffffd200Nexus:|r Utility Alerts disabled.")
        return true
    end

    if cmd == "help" or cmd == "?" then
        print("|cffffd200Nexus:|r /nx alerts, /nx alerts on, /nx alerts off, /nx alerts test")
        print("|cffffd200Nexus:|r /nx alerts lock, /nx alerts unlock")
        print("|cffffd200Nexus:|r /nx alerts options, /nx alerts duration <1-5>, /nx alerts size <8-72>")
        print("|cffffd200Nexus:|r /nx alerts align <left|center|right>, /nx alerts grow <up|down>")
        return true
    end

    if cmd == "lock" then
        self:SetPositionUnlocked(false)
        return true
    end

    if cmd == "unlock" then
        self:SetPositionUnlocked(true)
        return true
    end

    if cmd == "options" then
        self:OpenOptions()
        return true
    end

    if cmd == "test" then
        self:TestAlerts()
        return true
    end

    if cmd == "duration" then
        local value = tonumber(rest)
        if value then
            db.duration = math.floor(FN:ClampNumber(value, 1, 5) + 0.5)
            print("|cffffd200Nexus:|r Utility Alerts duration = " .. db.duration)
        else
            print("|cffffd200Nexus:|r Invalid duration. Use: /nx alerts duration <1-5>")
        end
        return true
    end

    if cmd == "size" then
        local value = tonumber(rest)
        if value then
            db.textSize = math.floor(FN:ClampNumber(value, 8, 72) + 0.5)
            self:RefreshAlertDisplay()
            print("|cffffd200Nexus:|r Utility Alerts text size = " .. db.textSize)
        else
            print("|cffffd200Nexus:|r Invalid size. Use: /nx alerts size <8-72>")
        end
        return true
    end

    if cmd == "align" then
        db.align = NormalizeAlign(rest)
        self:RefreshAlertDisplay()
        print("|cffffd200Nexus:|r Utility Alerts align = " .. db.align)
        return true
    end

    if cmd == "grow" then
        db.grow = NormalizeGrow(rest)
        self:RefreshAlertDisplay()
        print("|cffffd200Nexus:|r Utility Alerts grow = " .. db.grow)
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx alerts command. Use: /nx alerts help")
    return true
end

function UA:Init()
    self:EnsureDB()
    self:EnsureFrame()
    self:RefreshAlertDisplay()

    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(_, event, ...)
            UA:OnEvent(event, ...)
        end)
    end
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end


