local NX = Nexus
NX.WaypointUnlimitedPinDistance = NX.WaypointUnlimitedPinDistance or {}
local WUPD = NX.WaypointUnlimitedPinDistance

local updateAlphaHooked

local function EnsureDB()
    NX.DB.interface.waypointTracking = NX.DB.interface.waypointTracking or {}
    if NX.DB.interface.waypointTracking.unlimitedMapPinDistance == nil then
        NX.DB.interface.waypointTracking.unlimitedMapPinDistance = false
    end
end

local function IsNavigationEnabled()
    return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("showInGameNavigation") == "1"
end

local function IsEnabled()
    return NX.DB
        and NX.DB.interface
        and NX.DB.interface.waypointTracking
        and NX.DB.interface.waypointTracking.unlimitedMapPinDistance == true
end

local function ReassertSuperTrackedAlpha(frame)
    if not frame or not IsEnabled() then
        return
    end

    if not IsNavigationEnabled() then
        frame:SetAlpha(0)
        return
    end

    if C_Navigation and C_Navigation.HasValidScreenPosition and not C_Navigation.HasValidScreenPosition() then
        frame:SetAlpha(0)
        return
    end

    frame:SetAlpha(1)
end

local function EnsureUpdateAlphaHook()
    if updateAlphaHooked or not hooksecurefunc then
        return
    end

    if SuperTrackedFrameMixin and SuperTrackedFrameMixin.UpdateAlpha then
        hooksecurefunc(SuperTrackedFrameMixin, "UpdateAlpha", function(self)
            ReassertSuperTrackedAlpha(self)
        end)
        updateAlphaHooked = true
    elseif SuperTrackedFrame and SuperTrackedFrame.UpdateAlpha then
        hooksecurefunc(SuperTrackedFrame, "UpdateAlpha", function(self)
            ReassertSuperTrackedAlpha(self)
        end)
        updateAlphaHooked = true
    end
end

function WUPD:Apply()
    EnsureDB()

    if not SuperTrackedFrame then
        return
    end

    EnsureUpdateAlphaHook()

    if SuperTrackedFrame.UpdateAlpha then
        pcall(function()
            SuperTrackedFrame:UpdateAlpha()
        end)
    end
    ReassertSuperTrackedAlpha(SuperTrackedFrame)
end

function WUPD:Init()
    self:Apply()
end

function WUPD:OnSettingsChanged()
    self:Apply()
end
