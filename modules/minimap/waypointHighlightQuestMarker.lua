local NX = Nexus
NX.WaypointHighlightQuestMarker = NX.WaypointHighlightQuestMarker or {}
local WHQM = NX.WaypointHighlightQuestMarker

local questMarkerTicker
local questMarkerEventFrame
local questMarkerFrame
local questMarkerTexture
local questMarkerOutlineTexture

local WAYPOINT_MARKER_STYLE_DEFAULT = "default"
local WAYPOINT_MARKER_STYLE_HUNTERS_MARK = "huntersMark"
local WAYPOINT_HUNTERS_MARK_TEXTURE = "Interface\\AddOns\\Nexus\\media\\textures\\waypoint\\huntersMark.tga"
local WAYPOINT_MARKER_TICK_SECONDS = 2.0

local function NormalizeMarkerStyle(value)
    local style = tostring(value or WAYPOINT_MARKER_STYLE_DEFAULT)
    style = string.match(style, "^%s*(.-)%s*$") or WAYPOINT_MARKER_STYLE_DEFAULT
    style = string.lower(style)
    if style == string.lower(WAYPOINT_MARKER_STYLE_HUNTERS_MARK) then
        return WAYPOINT_MARKER_STYLE_HUNTERS_MARK
    end
    return WAYPOINT_MARKER_STYLE_DEFAULT
end

local function EnsureDB()
    NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
    if NX.DB.interface.waypointTracking.highlightedQuestMarker == nil then
        NX.DB.interface.waypointTracking.highlightedQuestMarker = false
    end
    if NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle == nil then
        NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle = WAYPOINT_MARKER_STYLE_DEFAULT
    end
    NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle = NormalizeMarkerStyle(NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle)
end

local function GetMarkerStyle()
    EnsureDB()
    return NormalizeMarkerStyle(NX.DB and NX.DB.interface and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarkerStyle)
end

local function ApplyQuestMarkerStyle(style)
    if not questMarkerFrame or not questMarkerTexture then
        return
    end

    local normalized = NormalizeMarkerStyle(style)
    if normalized == WAYPOINT_MARKER_STYLE_HUNTERS_MARK then
        questMarkerFrame:SetSize(64, 64)
        questMarkerTexture:ClearAllPoints()
        questMarkerTexture:SetPoint("CENTER", questMarkerFrame, "CENTER", 0, 0)
        questMarkerTexture:SetSize(64, 64)
        questMarkerTexture:SetTexture(WAYPOINT_HUNTERS_MARK_TEXTURE)
        questMarkerTexture:SetTexCoord(0, 1, 0, 1)
        questMarkerTexture:SetBlendMode("BLEND")
        questMarkerTexture:SetDesaturated(false)
        questMarkerTexture:SetVertexColor(1.0, 0.86, 0.0, 1.0)
        if questMarkerOutlineTexture then
            questMarkerOutlineTexture:ClearAllPoints()
            questMarkerOutlineTexture:SetPoint("CENTER", questMarkerTexture, "CENTER", 0, 0)
            questMarkerOutlineTexture:SetSize(74, 74)
            questMarkerOutlineTexture:SetTexture(WAYPOINT_HUNTERS_MARK_TEXTURE)
            questMarkerOutlineTexture:SetTexCoord(0, 1, 0, 1)
            questMarkerOutlineTexture:SetBlendMode("BLEND")
            questMarkerOutlineTexture:SetDesaturated(false)
            questMarkerOutlineTexture:SetVertexColor(0, 0, 0, 1)
            questMarkerOutlineTexture:Show()
        end
        return
    end

    questMarkerFrame:SetSize(65, 65)
    questMarkerTexture:ClearAllPoints()
    questMarkerTexture:SetAllPoints(questMarkerFrame)
    if questMarkerTexture.SetAtlas then
        questMarkerTexture:SetAtlas("charactercreate-ring-select", true)
    else
        questMarkerTexture:SetTexture("charactercreate-ring-select")
    end
    questMarkerTexture:SetBlendMode("ADD")
    questMarkerTexture:SetDesaturated(true)
    questMarkerTexture:SetVertexColor(1.0, 0.8196079, 0.0, 1.0)
    if questMarkerOutlineTexture then
        questMarkerOutlineTexture:Hide()
    end
end

local function EnsureQuestMarkerVisual()
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

    questMarkerOutlineTexture = questMarkerFrame:CreateTexture(nil, "OVERLAY", nil, 6)
    questMarkerOutlineTexture:SetAllPoints(questMarkerFrame)
    questMarkerOutlineTexture:Hide()

    ApplyQuestMarkerStyle(GetMarkerStyle())
end

function WHQM:UpdateHighlightedQuestMarker()
    EnsureDB()

    local enabled = NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker
    local stf = SuperTrackedFrame

    local shouldShow = false
    if enabled and stf and stf.IsVisible and stf.GetAlpha then
        shouldShow = stf:IsVisible() and stf:GetAlpha() > 0.1
    end

    if shouldShow then
        EnsureQuestMarkerVisual()
        if questMarkerFrame and stf then
            local style = GetMarkerStyle()
            ApplyQuestMarkerStyle(style)
            questMarkerFrame:ClearAllPoints()
            if style == WAYPOINT_MARKER_STYLE_HUNTERS_MARK then
                questMarkerFrame:SetPoint("CENTER", stf, "CENTER", 0, 48)
            else
                questMarkerFrame:SetPoint("CENTER", stf, "CENTER", 0, 0)
            end
            questMarkerFrame:Show()
        end
        return
    end

    if questMarkerFrame then
        questMarkerFrame:Hide()
    end
end

local function EnsureQuestMarkerEventFrame()
    if questMarkerEventFrame then
        return questMarkerEventFrame
    end

    questMarkerEventFrame = CreateFrame("Frame")
    questMarkerEventFrame:SetScript("OnEvent", function()
        WHQM:UpdateHighlightedQuestMarker()
    end)
    return questMarkerEventFrame
end

function WHQM:StopHighlightedQuestMarker()
    if questMarkerTicker and questMarkerTicker.Cancel then
        questMarkerTicker:Cancel()
    end
    questMarkerTicker = nil
    if questMarkerEventFrame then
        questMarkerEventFrame:UnregisterAllEvents()
    end
    self:UpdateHighlightedQuestMarker()
end

function WHQM:StartHighlightedQuestMarker()
    local frame = EnsureQuestMarkerEventFrame()
    frame:RegisterEvent("SUPER_TRACKING_CHANGED")
    frame:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
    frame:RegisterEvent("USER_WAYPOINT_UPDATED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    if not questMarkerTicker then
        questMarkerTicker = C_Timer.NewTicker(WAYPOINT_MARKER_TICK_SECONDS, function()
            self:UpdateHighlightedQuestMarker()
        end)
    end

    self:UpdateHighlightedQuestMarker()
end

function WHQM:Apply()
    EnsureDB()
    if NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker then
        self:StartHighlightedQuestMarker()
    else
        self:StopHighlightedQuestMarker()
    end
end

function WHQM:Init()
    self:Apply()
end

function WHQM:OnSettingsChanged()
    self:Apply()
end
