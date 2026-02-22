local NX = Nexus
NX.WaypointAutoPinTracking = NX.WaypointAutoPinTracking or {}
local WAP = NX.WaypointAutoPinTracking

local waypointFrame

local function EnsureDB()
    NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
    if NX.DB.interface.waypointTracking.autoTrackMapPins == nil then
        NX.DB.interface.waypointTracking.autoTrackMapPins = true
    end
end

local function TrackWaypoint()
    if not NX.DB or not NX.DB.interface.waypointTracking or not NX.DB.interface.waypointTracking.autoTrackMapPins then
        return
    end
    if not (C_Map and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint()) then
        return
    end
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_Timer.After(0, function()
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end)
    end
end

function WAP:Init()
    EnsureDB()

    if waypointFrame then
        return
    end

    waypointFrame = CreateFrame("Frame")
    waypointFrame:RegisterEvent("USER_WAYPOINT_UPDATED")
    waypointFrame:SetScript("OnEvent", function()
        TrackWaypoint()
    end)
end

function WAP:OnSettingsChanged()
    EnsureDB()
    if NX.DB and NX.DB.interface and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.autoTrackMapPins then
        TrackWaypoint()
    end
end
