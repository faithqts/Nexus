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
    NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
    if NX.DB.interface.waypointTracking.autoTrackMapPins == nil then
        NX.DB.interface.waypointTracking.autoTrackMapPins = true
    end
    if NX.DB.interface.waypointTracking.unlimitedMapPinDistance == nil then
        NX.DB.interface.waypointTracking.unlimitedMapPinDistance = false
    end
    if NX.DB.interface.waypointTracking.highlightedQuestMarker == nil then
        NX.DB.interface.waypointTracking.highlightedQuestMarker = false
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

    if NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.unlimitedMapPinDistance then
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
    if not NX.DB or not NX.DB.interface.waypointTracking or not NX.DB.interface.waypointTracking.autoTrackMapPins then return end
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

    local enabled = NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker
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
    if NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.highlightedQuestMarker then
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


