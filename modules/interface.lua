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
    SetBool(false)
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
    SetBool(true)
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
    local targetFont = (NX.Functions and NX.Functions.GetAddonFontPath and NX.Functions:GetAddonFontPath()) or font
    if not UIErrorsFrame:SetFont(targetFont, db.fontSize, useFlags) then
        UIErrorsFrame:SetFont(font, db.fontSize, useFlags)
    end
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
local questMarkerTicker
local questMarkerFrame
local questMarkerTexture
local questMarkerDistanceReparented

local function WT_EnsureDB()
    NX.DB.waypointTracking = NX.DB.waypointTracking or {}
    if NX.DB.waypointTracking.autoTrackMapPins == nil then
        NX.DB.waypointTracking.autoTrackMapPins = true
    end
    if NX.DB.waypointTracking.unlimitedMapPinDistance == nil then
        NX.DB.waypointTracking.unlimitedMapPinDistance = false
    end
    if NX.DB.waypointTracking.highlightedQuestMarker == nil then
        NX.DB.waypointTracking.highlightedQuestMarker = false
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

local function WT_EnsureQuestMarkerVisual()
    if questMarkerFrame or not UIParent then
        return
    end

    questMarkerFrame = CreateFrame("Frame", nil, UIParent)
    questMarkerFrame:SetSize(65, 65)
    questMarkerFrame:SetIgnoreParentAlpha(true)
    questMarkerFrame:SetFrameStrata("HIGH")
    questMarkerFrame:SetFrameLevel(30)
    questMarkerFrame:Hide()

    questMarkerTexture = questMarkerFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    questMarkerTexture:SetAllPoints(questMarkerFrame)
    if questMarkerTexture.SetAtlas then
        questMarkerTexture:SetAtlas("charactercreate-ring-select", true)
    else
        questMarkerTexture:SetTexture("charactercreate-ring-select")
    end
    questMarkerTexture:SetBlendMode("ADD")
    questMarkerTexture:SetDesaturated(true)
    questMarkerTexture:SetVertexColor(1.0, 0.8196079, 0.0, 1.0)
end

function WT:UpdateHighlightedQuestMarker()
    WT_EnsureDB()

    local enabled = NX.DB and NX.DB.waypointTracking and NX.DB.waypointTracking.highlightedQuestMarker
    local stf = SuperTrackedFrame
    local distanceText = stf and stf.DistanceText

    local shouldShow = false
    if enabled and stf and stf.IsVisible and stf.GetAlpha then
        shouldShow = stf:IsVisible() and stf:GetAlpha() > 0.1
    end

    if shouldShow then
        WT_EnsureQuestMarkerVisual()
        if questMarkerFrame and stf then
            questMarkerFrame:ClearAllPoints()
            questMarkerFrame:SetPoint("CENTER", stf, "CENTER", 0, 0)
            questMarkerFrame:Show()
        end

        if distanceText and distanceText.SetParent and distanceText.GetParent and distanceText:GetParent() ~= UIParent then
            distanceText:SetParent(UIParent)
            questMarkerDistanceReparented = true
        end
        return
    end

    if questMarkerFrame then
        questMarkerFrame:Hide()
    end

    if questMarkerDistanceReparented and distanceText and distanceText.SetParent then
        distanceText:SetParent(stf)
        questMarkerDistanceReparented = false
    end
end

function WT:StopHighlightedQuestMarker()
    if questMarkerTicker and questMarkerTicker.Cancel then
        questMarkerTicker:Cancel()
    end
    questMarkerTicker = nil
    self:UpdateHighlightedQuestMarker()
end

function WT:StartHighlightedQuestMarker()
    if questMarkerTicker then
        return
    end

    questMarkerTicker = C_Timer.NewTicker(0.25, function()
        self:UpdateHighlightedQuestMarker()
    end)

    self:UpdateHighlightedQuestMarker()
end

function WT:ApplyHighlightedQuestMarker()
    WT_EnsureDB()
    if NX.DB and NX.DB.waypointTracking and NX.DB.waypointTracking.highlightedQuestMarker then
        self:StartHighlightedQuestMarker()
    else
        self:StopHighlightedQuestMarker()
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
    self:ApplyHighlightedQuestMarker()
end

function WT:OnSettingsChanged()
    WT_EnsureDB()
    self:ApplyUnlimitedMapPinDistance()
    self:ApplyHighlightedQuestMarker()
end

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
    NX.DB.lowDurability = NX.DB.lowDurability or {}
    local d = NX.DB.lowDurability

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

    if not self._dragHandle and NX.Functions and NX.Functions.CreateAnchorController then
        self._dragHandle = NX.Functions:CreateAnchorController({
            parent = self._anchor,
            moveFrame = self._anchor,
            elementName = self.AnchorDisplayName,
            nudgeStep = LD_ANCHOR_STEP_PX,
            extraVerticalPadding = LD_ANCHOR_EXTRA_VERTICAL_PADDING,
            labelFontSize = LD_ANCHOR_LABEL_FONT_SIZE,
            isBlocked = function()
                if InCombatLockdown and InCombatLockdown() then
                    LD:WarnMovementBlocked()
                    return true
                end
                return false
            end,
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
            onLock = (NX.Functions and NX.Functions.CreateLockOnClickHandler and NX.Functions:CreateLockOnClickHandler(LD, false))
                or function()
                    LD:SetPositionUnlocked(false)
                end,
        })
    end

    if not self._dragHandle then
        return
    end

    if self._dragHandle.SetElementName then
        self._dragHandle:SetElementName(self.AnchorDisplayName)
    end

    if self._dragHandle.RefreshFonts then
        self._dragHandle:RefreshFonts()
    end

    self:UpdateDragHandleReadout()

    local showHandle = self:IsPositionUnlocked()
    self._dragHandle:SetShown(showHandle)
    self._dragHandle:EnableMouse(showHandle)
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
    fontSize = LD_Clamp(fontSize, 1, 128)

    local threshold = tonumber(d.threshold) or LD_DEFAULT_THRESHOLD
    threshold = math.floor(threshold + 0.5)
    threshold = LD_Clamp(threshold, 1, 100)

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

    LD_ApplyFontDeferred(cfg.fontSize)

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

local NX = Nexus
NX.CatalystCharges = NX.CatalystCharges or {}
local CC = NX.CatalystCharges

local CATALYST_CURRENCY_ID = 3378
local CATALYST_FALLBACK_ICON = 5764926
local CATALYST_ICON_SIZE = 32
local CATALYST_TEXT_SIZE = 28
local CATALYST_TEXT_ICON_GAP = 6
local CATALYST_DEFAULT_MAX = 8

local function GetCatalystCurrencyInfo()
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then
        return 0, CATALYST_DEFAULT_MAX, CATALYST_FALLBACK_ICON
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(CATALYST_CURRENCY_ID)
    if type(info) ~= "table" then
        return 0, CATALYST_DEFAULT_MAX, CATALYST_FALLBACK_ICON
    end

    local quantity = tonumber(info.quantity) or 0
    local maxQuantity = tonumber(info.maxQuantity) or CATALYST_DEFAULT_MAX
    if maxQuantity < 1 then
        maxQuantity = CATALYST_DEFAULT_MAX
    end
    local icon = info.iconFileID or CATALYST_FALLBACK_ICON
    return quantity, maxQuantity, icon
end

local function GetClassColor()
    local _, classFile = UnitClass("player")
    local classColor = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end
    return 1, 0.82, 0
end

function CC:EnsureWidget()
    if self.widget then
        return
    end

    local frame = CreateFrame("Frame", "NexusCatalystChargesWidget", UIParent)
    frame:SetSize(CATALYST_ICON_SIZE + CATALYST_TEXT_ICON_GAP + CATALYST_ICON_SIZE, CATALYST_ICON_SIZE)
    frame:SetFrameStrata("DIALOG")

    frame.IconBorder = frame:CreateTexture(nil, "BORDER")
    frame.IconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")

    frame.Icon = frame:CreateTexture(nil, "BACKGROUND")
    frame.Icon:SetDrawLayer("ARTWORK")
    frame.Icon:SetTexture(CATALYST_FALLBACK_ICON)

    frame.IconHitbox = CreateFrame("Frame", nil, frame)
    frame.IconHitbox:EnableMouse(true)
    frame.IconHitbox:SetScript("OnEnter", function(hitbox)
        if not GameTooltip then return end
        GameTooltip:SetOwner(hitbox, "ANCHOR_RIGHT")
        if GameTooltip.SetCurrencyByID then
            GameTooltip:SetCurrencyByID(CATALYST_CURRENCY_ID)
        else
            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(CATALYST_CURRENCY_ID)
            GameTooltip:SetText((info and info.name) or "Catalyst Charges")
            if info and info.quantity and info.maxQuantity then
                GameTooltip:AddLine(string.format("%d/%d", info.quantity, info.maxQuantity), 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end)
    frame.IconHitbox:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetJustifyV("MIDDLE")
    if FN and FN.ApplyAddonFont then
        FN:ApplyAddonFont(frame.Text, CATALYST_TEXT_SIZE, "OUTLINE")
    else
        frame.Text:SetFont("Fonts\\FRIZQT__.TTF", CATALYST_TEXT_SIZE, "OUTLINE")
    end
    frame.Text:SetText("0/8")

    frame:Hide()
    self.widget = frame
end

function CC:ApplyClassBorderColor()
    if not self.widget then
        return
    end

    local r, g, b = GetClassColor()
    self.widget.Icon:SetVertexColor(1, 1, 1, 1)
    if self.widget.IconBorder then
        self.widget.IconBorder:SetVertexColor(r, g, b, 1)
    end
    self.widget.Text:SetTextColor(r, g, b, 1)
end

function CC:LayoutWidget()
    if not self.widget then
        return
    end

    local textWidth = math.ceil(self.widget.Text:GetStringWidth() or 0)
    local totalWidth = CATALYST_ICON_SIZE + CATALYST_TEXT_ICON_GAP + textWidth
    local totalHeight = CATALYST_ICON_SIZE

    self.widget:SetSize(totalWidth, totalHeight)

    self.widget.Text:ClearAllPoints()
    self.widget.Text:SetPoint("LEFT", self.widget.Icon, "RIGHT", CATALYST_TEXT_ICON_GAP, 0)

    self.widget.Icon:ClearAllPoints()
    self.widget.Icon:SetPoint("LEFT", self.widget, "LEFT", 0, 0)
    self.widget.Icon:SetSize(CATALYST_ICON_SIZE, CATALYST_ICON_SIZE)

    if self.widget.IconHitbox then
        self.widget.IconHitbox:ClearAllPoints()
        self.widget.IconHitbox:SetPoint("TOPLEFT", self.widget.Icon, "TOPLEFT", 0, 0)
        self.widget.IconHitbox:SetPoint("BOTTOMRIGHT", self.widget.Icon, "BOTTOMRIGHT", 0, 0)
    end

    if self.widget.IconBorder then
        self.widget.IconBorder:ClearAllPoints()
        self.widget.IconBorder:SetPoint("TOPLEFT", self.widget.Icon, "TOPLEFT", -1, 1)
        self.widget.IconBorder:SetPoint("BOTTOMRIGHT", self.widget.Icon, "BOTTOMRIGHT", 1, -1)
    end
end

function CC:HookCharacterFrameOnShow()
    if self._characterShowHooked then
        return
    end
    if not CharacterFrame then
        return
    end

    CharacterFrame:HookScript("OnShow", function()
        self:Refresh()
    end)

    self._characterShowHooked = true
end

function CC:Attach()
    self:EnsureWidget()
    self:HookCharacterFrameOnShow()

    if not CharacterFrame then
        self.widget:Hide()
        return false
    end

    self.widget:SetParent(CharacterFrame)
    self.widget:SetFrameStrata("DIALOG")
    if CharacterFrame.GetFrameLevel and self.widget.SetFrameLevel then
        self.widget:SetFrameLevel((CharacterFrame:GetFrameLevel() or 1) + 50)
    end
    self.widget:ClearAllPoints()
    self.widget:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 10, -10)
    self.widget:Show()
    return true
end

function CC:Refresh()
    if not self:Attach() then
        return
    end

    local quantity, maxQuantity, icon = GetCatalystCurrencyInfo()
    quantity = math.max(0, quantity)

    self.widget.Icon:SetTexture(icon)
    self.widget.Text:SetText(string.format("%d/%d", quantity, maxQuantity))

    self:ApplyClassBorderColor()
    self:LayoutWidget()
end

function CC:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_CharacterUI" then
            C_Timer.After(0, function()
                self:Refresh()
            end)
        end
        return
    end

    if event == "CURRENCY_DISPLAY_UPDATE" then
        local currencyID = ...
        if currencyID and currencyID ~= CATALYST_CURRENCY_ID then
            return
        end
    end

    self:Refresh()
end

function CC:Init()
    self:EnsureWidget()

    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            self:OnEvent(event, ...)
        end)
    end

    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self.eventFrame:RegisterEvent("ADDON_LOADED")

    self:Refresh()
end
