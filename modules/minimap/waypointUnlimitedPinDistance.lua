local NX = Nexus
NX.WaypointUnlimitedPinDistance = NX.WaypointUnlimitedPinDistance or {}
local WUPD = NX.WaypointUnlimitedPinDistance

local originalGetTargetAlphaBaseValue

local function EnsureDB()
    NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
    if NX.DB.interface.waypointTracking.unlimitedMapPinDistance == nil then
        NX.DB.interface.waypointTracking.unlimitedMapPinDistance = false
    end
end

local function IsNavigationEnabled()
    return GetCVar and GetCVar("showInGameNavigation") == "1"
end

function WUPD:Apply()
    EnsureDB()

    if not SuperTrackedFrame then
        return
    end

    if not originalGetTargetAlphaBaseValue then
        originalGetTargetAlphaBaseValue = SuperTrackedFrame.GetTargetAlphaBaseValue
    end

    if NX.DB and NX.DB.interface.waypointTracking and NX.DB.interface.waypointTracking.unlimitedMapPinDistance then
        SuperTrackedFrame.GetTargetAlphaBaseValue = function()
            if not IsNavigationEnabled() then
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
        pcall(function()
            SuperTrackedFrame:UpdateAlpha()
        end)
    end
end

function WUPD:Init()
    self:Apply()
end

function WUPD:OnSettingsChanged()
    self:Apply()
end
