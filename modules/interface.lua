local NX = Nexus
NX.MotionSickness = NX.MotionSickness or {}
local MS = NX.MotionSickness
local CV = NX.CVars

local CVAR = "motionSicknessLandscapeDarkening"

local function EnsureDB()
    NX.DB.motionSickness = NX.DB.motionSickness or {}
    if NX.DB.motionSickness.enabled == nil then
        NX.DB.motionSickness.enabled = true
    end
end

local function GetBool()
    if CV and CV.GetBool then
        return CV:GetBool(CVAR, false)
    end
    return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(CVAR) == "1"
end

local function SetBool(v)
    if CV and CV.SetBool then
        CV:SetBool(CVAR, v)
        return
    end
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(CVAR, v and "1" or "0")
    end
end

function MS:Apply()
    if not self._active then return end
    local resolved = false
    if CV and CV.ReconcileBool then
        resolved = CV:ReconcileBool(CVAR, false)
    else
        SetBool(false)
    end

    if NX.DB and NX.DB.motionSickness then
        NX.DB.motionSickness.enabled = not resolved
    end
end

function MS:Enable()
    if self._active then return end
    self._active = true
    self._prev = GetBool()

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("CVAR_UPDATE")
    self.frame:SetScript("OnEvent", function(_, event, cvarName)
        if event == "PLAYER_LOGIN" then
            self:Apply()
        elseif event == "CVAR_UPDATE" and cvarName == CVAR then
            self:Apply()
        end
    end)

    self:Apply()
end

function MS:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._prev ~= nil then
        SetBool(self._prev)
    end
end

function MS:ApplyConfig()
    EnsureDB()
    if NX.DB.motionSickness.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function MS:Init()
    EnsureDB()
    self:ApplyConfig()
end

function MS:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.SkyridingEffects = NX.SkyridingEffects or {}
local SE = NX.SkyridingEffects

local SETTING_NAME = "DisableAdvancedFlyingFullScreenEffects"

local function EnsureDB()
    NX.DB.skyridingEffects = NX.DB.skyridingEffects or {}
    if NX.DB.skyridingEffects.enabled == nil then
        NX.DB.skyridingEffects.enabled = true
    end
end

function SE:Apply()
    if not self._active then return end

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting and not setting.locked then

        setting:ApplyValue(true)
        return
    end

    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, SETTING_NAME, "1")
    end
end

function SE:Enable()
    if self._active then return end
    self._active = true

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting then
        self._prev = setting:GetValue()
    end

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("SETTINGS_LOADED")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
    end)

    self:Apply()
end

function SE:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    local setting = Settings and Settings.GetSetting and Settings.GetSetting(SETTING_NAME)
    if setting and self._prev ~= nil then
        setting:ApplyValue(self._prev)
    end
end

function SE:ApplyConfig()
    EnsureDB()
    if NX.DB.skyridingEffects.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function SE:Init()
    EnsureDB()
    self:ApplyConfig()
end

function SE:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.AlwaysSharpen = NX.AlwaysSharpen or {}
local SH = NX.AlwaysSharpen

local CVAR = "ResampleAlwaysSharpen"

local function EnsureDB()
    NX.DB.alwaysSharpen = NX.DB.alwaysSharpen or {}
    if NX.DB.alwaysSharpen.enabled == nil then
        NX.DB.alwaysSharpen.enabled = true
    end
end

local function GetBool()
    if CV and CV.GetBool then
        return CV:GetBool(CVAR, false)
    end
    return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(CVAR) == "1"
end

local function SetBool(v)
    if CV and CV.SetBool then
        CV:SetBool(CVAR, v)
        return
    end
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(CVAR, v and "1" or "0")
    end
end

function SH:Apply()
    if not self._active then return end
    local resolved = true
    if CV and CV.ReconcileBool then
        resolved = CV:ReconcileBool(CVAR, true)
    else
        SetBool(true)
    end

    if NX.DB and NX.DB.alwaysSharpen then
        NX.DB.alwaysSharpen.enabled = resolved
    end
end

function SH:Enable()
    if self._active then return end
    self._active = true
    self._prev = GetBool()

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("CVAR_UPDATE")
    self.frame:SetScript("OnEvent", function(_, event, cvarName)
        if event == "PLAYER_LOGIN" then
            self:Apply()
        elseif event == "CVAR_UPDATE" and cvarName == CVAR then
            self:Apply()
        end
    end)

    self:Apply()
end

function SH:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._prev ~= nil then
        SetBool(self._prev)
    end
end

function SH:ApplyConfig()
    EnsureDB()
    if NX.DB.alwaysSharpen.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function SH:Init()
    EnsureDB()
    self:ApplyConfig()
end

function SH:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.EnhancedErrorText = NX.EnhancedErrorText or {}
local ET = NX.EnhancedErrorText

local function EnsureDB()
    NX.DB.enhancedErrorText = NX.DB.enhancedErrorText or {}
    local db = NX.DB.enhancedErrorText
    if db.enabled == nil then db.enabled = false end
    if db.fontSize == nil then db.fontSize = 22 end
    if db.width == nil then db.width = 800 end
    if db.height == nil then db.height = 120 end
    if db.offsetY == nil then db.offsetY = 0 end
    if db.outline == nil then db.outline = true end
end

local function CaptureFramePoints(frame)
    local points = {}
    if not frame or not frame.GetNumPoints or not frame.GetPoint then
        return points
    end

    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        points[#points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        }
    end

    return points
end

local function RestoreFramePoints(frame, points, offsetY)
    if not frame or not frame.ClearAllPoints or not frame.SetPoint then return end
    if type(points) ~= "table" or #points == 0 then return end

    frame:ClearAllPoints()

    for _, p in ipairs(points) do
        local x = tonumber(p.x) or 0
        local y = (tonumber(p.y) or 0) + (tonumber(offsetY) or 0)

        if p.relativeTo ~= nil then
            frame:SetPoint(p.point, p.relativeTo, p.relativePoint, x, y)
        else
            frame:SetPoint(p.point, UIParent, p.relativePoint, x, y)
        end
    end
end

local PLAYER_NAME = UnitName("player") or "Player"
local PREVIEW_TEXT = PLAYER_NAME .. " stood in bad, survived, then killed themselves: 1/1"

function ET:ShowPreview()
    if not UIErrorsFrame or not UIErrorsFrame.AddExternalWarningMessage then return end

    UIErrorsFrame:AddExternalWarningMessage(PREVIEW_TEXT)
end

function ET:Apply()
    if not self._active then return end
    if not UIErrorsFrame or not UIErrorsFrame.GetFont then return end

    local font, size, flags = UIErrorsFrame:GetFont()
    if not self._prev then
        self._prev = {
            font = font,
            size = size,
            flags = flags,
            width = UIErrorsFrame:GetWidth(),
            height = UIErrorsFrame:GetHeight(),
            points = CaptureFramePoints(UIErrorsFrame),
        }
    end

    local db = NX.DB.enhancedErrorText
    local useFlags = db.outline and "OUTLINE" or (flags or "")
    UIErrorsFrame:SetFont(font, db.fontSize, useFlags)
    UIErrorsFrame:SetWidth(db.width)
    UIErrorsFrame:SetHeight(db.height)
    RestoreFramePoints(UIErrorsFrame, self._prev.points, db.offsetY)
end

function ET:Restore()
    if not self._prev then return end
    if not UIErrorsFrame or not UIErrorsFrame.GetFont then return end
    UIErrorsFrame:SetFont(self._prev.font, self._prev.size, self._prev.flags)
    if self._prev.width then UIErrorsFrame:SetWidth(self._prev.width) end
    if self._prev.height then UIErrorsFrame:SetHeight(self._prev.height) end
    RestoreFramePoints(UIErrorsFrame, self._prev.points, 0)
end

function ET:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
        self:ShowPreview()
    end)

    self:Apply()
    self:ShowPreview()
end

function ET:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    self:Restore()
    self._prev = nil
end

function ET:ApplyConfig()
    EnsureDB()
    if NX.DB.enhancedErrorText.enabled then
        self:Enable()
        self:Apply()
        self:ShowPreview()
    else
        self:Disable()

        self:ShowPreview()
    end
end

function ET:Init()
    EnsureDB()
    self:ApplyConfig()
end

function ET:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.CleanObjectiveTracker = NX.CleanObjectiveTracker or {}
local OT = NX.CleanObjectiveTracker

local function EnsureDB()
    NX.DB.cleanObjectiveTracker = NX.DB.cleanObjectiveTracker or {}
    local db = NX.DB.cleanObjectiveTracker
    if db.enabled == nil then db.enabled = false end
    if db.hideBackground == nil then db.hideBackground = true end
    if db.hideTitle == nil then db.hideTitle = true end
end

function OT:Apply()
    if not self._active then return end
    local f = _G.ObjectiveTrackerFrame
    if not f or not f.Header then return end

    local db = NX.DB.cleanObjectiveTracker

    if f.Header.Background then
        if db.hideBackground then f.Header.Background:Hide() else f.Header.Background:Show() end
    end
    if f.Header.Text then
        if db.hideTitle then f.Header.Text:Hide() else f.Header.Text:Show() end
    end
end

function OT:Restore()
    local f = _G.ObjectiveTrackerFrame
    if not f or not f.Header then return end
    if f.Header.Background then f.Header.Background:Show() end
    if f.Header.Text then f.Header.Text:Show() end
end

function OT:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
    end)

    self:Apply()
end

function OT:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    self:Restore()
end

function OT:ApplyConfig()
    EnsureDB()
    if NX.DB.cleanObjectiveTracker.enabled then
        self:Enable()
        self:Apply()
    else
        self:Disable()
    end
end

function OT:Init()
    EnsureDB()
    self:ApplyConfig()
end

function OT:OnSettingsChanged()
    self:ApplyConfig()
end

local NX = Nexus
NX.WaypointTracking = NX.WaypointTracking or {}
local WT = NX.WaypointTracking

local waypointFrame
local originalGetTargetAlphaBaseValue

local function WT_EnsureDB()
    NX.DB.waypointTracking = NX.DB.waypointTracking or {}
    if NX.DB.waypointTracking.autoTrackMapPins == nil then
        NX.DB.waypointTracking.autoTrackMapPins = true
    end
    if NX.DB.waypointTracking.unlimitedMapPinDistance == nil then
        NX.DB.waypointTracking.unlimitedMapPinDistance = false
    end
end

local function WT_IsNavigationEnabled()
    return GetCVar and GetCVar("showInGameNavigation") == "1"
end

function WT:ApplyUnlimitedMapPinDistance()
    if not SuperTrackedFrame then return end

    if not originalGetTargetAlphaBaseValue then
        originalGetTargetAlphaBaseValue = SuperTrackedFrame.GetTargetAlphaBaseValue
    end

    if NX.DB and NX.DB.waypointTracking and NX.DB.waypointTracking.unlimitedMapPinDistance then
        SuperTrackedFrame.GetTargetAlphaBaseValue = function()
            if not WT_IsNavigationEnabled() then
                return 0
            end
            if C_Navigation and C_Navigation.HasValidScreenPosition and not C_Navigation.HasValidScreenPosition() then
                return 0
            end
            return 1
        end
    elseif originalGetTargetAlphaBaseValue then
        SuperTrackedFrame.GetTargetAlphaBaseValue = originalGetTargetAlphaBaseValue
    end

    if SuperTrackedFrame.UpdateAlpha then
        pcall(function() SuperTrackedFrame:UpdateAlpha() end)
    end
end

local function WT_TrackWaypoint()
    if not NX.DB or not NX.DB.waypointTracking or not NX.DB.waypointTracking.autoTrackMapPins then return end
    if not (C_Map and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint()) then return end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_Timer.After(0, function()
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end)
    end
end

function WT:Init()
    WT_EnsureDB()

    if not waypointFrame then
        waypointFrame = CreateFrame("Frame")
        waypointFrame:RegisterEvent("USER_WAYPOINT_UPDATED")
        waypointFrame:SetScript("OnEvent", function()
            WT_TrackWaypoint()
        end)
    end

    self:ApplyUnlimitedMapPinDistance()
end

function WT:OnSettingsChanged()
    WT_EnsureDB()
    self:ApplyUnlimitedMapPinDistance()
end

local NX = Nexus
NX.Common = NX.Common or {}
local CM = NX.Common
CM.LowDurability = CM.LowDurability or {}
local LD = CM.LowDurability

local LD_TEXT = "Durability Low"
local LD_OUTLINE = "OUTLINE"
local LD_ANCHOR = "CENTER"

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

local function LD_GetDB()
    if not NX or not NX.DB then return nil end
    return NX.DB.lowDurability
end

local function LD_Clamp(v, lo, hi)
    v = tonumber(v)
    if not v then return lo end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
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

local function LD_ApplyFontDeferred(path, size)
    local tries = 0
    local function try()
        tries = tries + 1
        if LD._text and LD._text.SetFont and LD._text:SetFont(path, size, LD_OUTLINE) then
            return
        end
        if tries < 5 then
            C_Timer.After(0, try)
        else
            if LD._text and LD._text.SetFont then
                LD._text:SetFont("Fonts\\FRIZQT__.TTF", size, LD_OUTLINE)
            end
        end
    end
    try()
end

function LD:GetConfig()
    local d = LD_GetDB() or {}

    local enabled  = (d.enabled == true)
    local fontPath = (type(d.fontPath) == "string" and d.fontPath ~= "") and d.fontPath or "Fonts\\FRIZQT__.TTF"

    local fontSize = tonumber(d.fontSize) or 48
    fontSize = math.floor(fontSize + 0.5)
    fontSize = LD_Clamp(fontSize, 1, 128)

    local threshold = tonumber(d.threshold) or 20
    threshold = math.floor(threshold + 0.5)
    threshold = LD_Clamp(threshold, 1, 100)

    local flashing = (d.flashing ~= false)

    local offsetY = tonumber(d.offsetY) or 0
    offsetY = math.floor(offsetY + 0.5)
    local maxH = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 1080
    maxH = tonumber(maxH) or 1080
    maxH = math.floor(maxH + 0.5)
    offsetY = LD_Clamp(offsetY, -maxH, maxH)

    local colorHex = (type(d.color) == "string" and d.color ~= "") and d.color or "#FFFF00"
    local color = LD_FindColor(colorHex) or LD_FindColor("#FFFF00") or { r = 255, g = 255, b = 0 }

    return {
        enabled = enabled,
        fontPath = fontPath,
        fontSize = fontSize,
        threshold = threshold,
        flashing = flashing,
        offsetY = offsetY,
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

    local text = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
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
    self:StopPreview()
end

function LD:ApplyConfig()
    if not self._text then return end
    local cfg = self:GetConfig()

    self._text:ClearAllPoints()
    self._text:SetPoint(LD_ANCHOR, UIParent, LD_ANCHOR, 0, cfg.offsetY)

    LD_ApplyFontDeferred(cfg.fontPath, cfg.fontSize)

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
end

function LD:HideWarning()
    self._shown = false
    if self._flash and self._flash:IsPlaying() then
        self._flash:Stop()
    end
    if self._text then
        self._text:Hide()
    end
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
