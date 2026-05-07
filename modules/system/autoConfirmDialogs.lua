local NX = Nexus

NX.AutoConfirmDialogs = NX.AutoConfirmDialogs or {}

local M = NX.AutoConfirmDialogs
local popupHooked

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

local function GetPreferredButtonIndex(which)
    if which == "REPLACE_ENCHANT" then
        return 2
    end

    return 1
end

local function GetPopupButton(frame, index)
    if not frame or not index then
        return nil
    end

    local btn = frame["button" .. tostring(index)] or (frame.GetButton and frame:GetButton(index))
    if btn then
        return btn
    end

    if frame.GetName then
        local name = frame:GetName()
        if name and name ~= "" then
            return _G[string.format("%sButton%d", name, index)]
        end
    end

    return nil
end

local function HandleAutoConfirmDialog(frame)
    if not frame or not frame.which then return end
    if not ShouldAutoConfirm(frame.which) then return end

    local preferredIndex = GetPreferredButtonIndex(frame.which)
    local btn = GetPopupButton(frame, preferredIndex)
    if not btn then
        btn = GetPopupButton(frame, 1)
    end

    if btn and btn.Click then
        btn:Click()
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
    EnsurePopupHooks()
end

function M:OnSettingsChanged()
    self:Apply()
end

function M:Init()
    self:Apply()
end

