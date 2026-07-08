local NX = Nexus

NX.AutoConfirmDialogs = NX.AutoConfirmDialogs or {}

local M = NX.AutoConfirmDialogs
local popupHooked

local function DismissPopup(which)
    if StaticPopup_Hide then
        StaticPopup_Hide(which)
    end
end

local function ShouldAutoConfirm(which)
    if not which then return false end
    if not NX.DB or not NX.DB.system.autoConfirmDialogs then return false end

    local cfg = NX.DB.system.autoConfirmDialogs
    if not cfg.enabled then return false end

    if which == "REPLACE_ENCHANT" then
        return cfg.replaceEnchant == true
    end

    if which == "CONFIRM_ACCEPT_SOCKETS" then
        return cfg.acceptSockets == true
    end

    return false
end

local function HandleAutoConfirmDialog(frame)
    if not frame or not frame.which then return end
    if not ShouldAutoConfirm(frame.which) then return end

    if frame.which == "REPLACE_ENCHANT" then
        if ReplaceEnchant then
            ReplaceEnchant()
            DismissPopup("REPLACE_ENCHANT")
        end
        return
    end

    if frame.which == "CONFIRM_ACCEPT_SOCKETS" then
        if C_ItemSocketInfo and C_ItemSocketInfo.AcceptSockets then
            C_ItemSocketInfo.AcceptSockets()
            DismissPopup("CONFIRM_ACCEPT_SOCKETS")
        end
    end
end

local function EnsurePopupHooks()
    if popupHooked then return end
    popupHooked = true

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup.HookScript then
            popup:HookScript("OnShow", function(self)
                C_Timer.After(0, function()
                    HandleAutoConfirmDialog(self)
                end)
            end)
        end
    end
end

function M:Apply()
    if NX.DB and NX.DB.system.autoConfirmDialogs and NX.DB.system.autoConfirmDialogs.enabled then
        EnsurePopupHooks()
    end
end

function M:OnSettingsChanged()
    self:Apply()
end

function M:Init()
    self:Apply()
end

