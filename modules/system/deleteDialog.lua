local NX = Nexus

NX.DeleteDialog = NX.DeleteDialog or {}

local M = NX.DeleteDialog
local popupHooked

local function HandleDeleteDialog(frame)
    if not frame or not frame.which then return end
    if not NX.DB or not NX.DB.system.deleteDialog or not NX.DB.system.deleteDialog.enabled then return end

    if frame.which ~= "DELETE_GOOD_ITEM" and frame.which ~= "DELETE_GOOD_QUEST_ITEM" then
        return
    end

    local editBox = frame.editBox or (frame.GetEditBox and frame:GetEditBox())
    if not editBox or not editBox.SetText then return end

    editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
    if editBox.ClearFocus then editBox:ClearFocus() end
    if editBox.SetAutoFocus then editBox:SetAutoFocus(false) end
end

local function EnsurePopupHooks()
    if popupHooked then return end
    popupHooked = true

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup.HookScript then
            popup:HookScript("OnShow", function(self)
                C_Timer.After(0, function()
                    HandleDeleteDialog(self)
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

