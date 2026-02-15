local NX = Nexus

local function SetCVarBool(name, enabled)
    if type(name) ~= "string" then return end
    local value = enabled and "1" or "0"
    if C_CVar and C_CVar.SetCVar then
        pcall(C_CVar.SetCVar, name, value)
        return
    end
    if SetCVar then
        pcall(SetCVar, name, value)
    end
end

NX.LuaErrors = NX.LuaErrors or {}
do
    local M = NX.LuaErrors
    function M:Apply()
        if not NX.DB or not NX.DB.luaErrors then return end
        SetCVarBool("scriptErrors", NX.DB.luaErrors.enabled == true)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.Tutorials = NX.Tutorials or {}
do
    local M = NX.Tutorials
    function M:Apply()
        if not NX.DB or not NX.DB.tutorials then return end
        local disabled = NX.DB.tutorials.disabled == true
        SetCVarBool("showTutorials", not disabled)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.AutoDismount = NX.AutoDismount or {}
do
    local M = NX.AutoDismount
    function M:Apply()
        if not NX.DB or not NX.DB.autoDismount then return end
        local cfg = NX.DB.autoDismount
        SetCVarBool("autoDismount", cfg.enabled ~= false)
        SetCVarBool("autoDismountFlying", cfg.flying ~= false)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.AutoPlaceSpells = NX.AutoPlaceSpells or {}
do
    local M = NX.AutoPlaceSpells
    function M:Apply()
        if not NX.DB or not NX.DB.autoPlaceSpells then return end
        SetCVarBool("AutoPushSpellToActionBar", NX.DB.autoPlaceSpells.enabled == true)
    end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.AuctionHouse = NX.AuctionHouse or {}
do
    local M = NX.AuctionHouse
    local frame

    local function Apply()
        if not NX.DB or not NX.DB.auctionHouse then return end
        if not NX.DB.auctionHouse.currentExpansionOnly then return end

        local ah = _G.AuctionHouseFrame
        if not ah or not ah.SearchBar or not ah.SearchBar.FilterButton then return end

        local fb = ah.SearchBar.FilterButton
        if not fb.filters then return end

        if Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly then
            fb.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
        end

        if ah.SearchBar.UpdateClearFiltersButton then
            ah.SearchBar:UpdateClearFiltersButton()
        end
    end

    function M:Init()
        if frame then return end
        frame = CreateFrame("Frame")
        frame:RegisterEvent("AUCTION_HOUSE_SHOW")
        frame:SetScript("OnEvent", function()
            C_Timer.After(0, Apply)
        end)
    end

    function M:Apply() Apply() end
    function M:OnSettingsChanged() self:Apply() end
end

NX.HideTalkingHead = NX.HideTalkingHead or {}
do
    local M = NX.HideTalkingHead
    local hooked

    local function Apply()
        if not NX.DB or not NX.DB.hideTalkingHead then return end
        if not NX.DB.hideTalkingHead.enabled then return end

        local th = _G.TalkingHeadFrame
        if not th then return end

        th:Hide()

        if hooked or not th.HookScript then return end
        hooked = true

        if th.PlayCurrent then
            hooksecurefunc(th, "PlayCurrent", function(self)
                if NX.DB and NX.DB.hideTalkingHead and NX.DB.hideTalkingHead.enabled then
                    self:Hide()
                end
            end)
            return
        end

        th:HookScript("OnShow", function(self)
            if NX.DB and NX.DB.hideTalkingHead and NX.DB.hideTalkingHead.enabled then
                self:Hide()
            end
        end)
    end

    function M:Apply() C_Timer.After(0, Apply) end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.HideScreenshotStatus = NX.HideScreenshotStatus or {}
do
    local M = NX.HideScreenshotStatus

    function M:Apply()
        if not NX.DB or not NX.DB.hideScreenshotStatus then return end
        local enabled = NX.DB.hideScreenshotStatus.enabled == true

        local actionStatus = _G.ActionStatus
        if not actionStatus or not actionStatus.UnregisterEvent or not actionStatus.RegisterEvent then return end

        if enabled then
            actionStatus:UnregisterEvent("SCREENSHOT_STARTED")
            actionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
            actionStatus:UnregisterEvent("SCREENSHOT_FAILED")
            if actionStatus.Hide then actionStatus:Hide() end
            return
        end

        actionStatus:RegisterEvent("SCREENSHOT_STARTED")
        actionStatus:RegisterEvent("SCREENSHOT_SUCCEEDED")
        actionStatus:RegisterEvent("SCREENSHOT_FAILED")
    end

    function M:OnSettingsChanged() self:Apply() end
    function M:Init() C_Timer.After(0, function() self:Apply() end) end
end

local function ShouldAutoConfirm(which)
    if not which then return false end
    if not NX.DB or not NX.DB.autoConfirmDialogs then return false end
    local cfg = NX.DB.autoConfirmDialogs
    if not cfg.enabled then return false end

    if which == "REPLACE_ENCHANT" then
        return cfg.replaceEnchant == true
    end

    if which == "CONFIRM_ACCEPT_SOCKETS" then
        return cfg.acceptSockets == true
    end

    return false
end

local function HandleDeleteDialog(frame)
    if not frame or not frame.which then return end
    if not NX.DB or not NX.DB.deleteDialog or not NX.DB.deleteDialog.enabled then return end

    if frame.which ~= "DELETE_GOOD_ITEM" and frame.which ~= "DELETE_GOOD_QUEST_ITEM" then
        return
    end

    local editBox = frame.editBox or (frame.GetEditBox and frame:GetEditBox())
    if not editBox or not editBox.SetText then return end

    editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
    if editBox.ClearFocus then editBox:ClearFocus() end
    if editBox.SetAutoFocus then editBox:SetAutoFocus(false) end
end

local function HandleAutoConfirmDialog(frame)
    if not frame or not frame.which then return end
    if not ShouldAutoConfirm(frame.which) then return end

    local btn = frame.button1 or (frame.GetButton and frame:GetButton(1))
    if btn and btn.Click then
        btn:Click()
    end
end

local popupHooked
local function EnsurePopupHooks()
    if popupHooked then return end
    popupHooked = true

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup.HookScript then
            popup:HookScript("OnShow", function(self)
                C_Timer.After(0, function()
                    HandleDeleteDialog(self)
                    HandleAutoConfirmDialog(self)
                end)
            end)
        end
    end
end

NX.DeleteDialog = NX.DeleteDialog or {}
do
    local M = NX.DeleteDialog
    function M:Apply() EnsurePopupHooks() end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.AutoConfirmDialogs = NX.AutoConfirmDialogs or {}
do
    local M = NX.AutoConfirmDialogs
    function M:Apply() EnsurePopupHooks() end
    function M:OnSettingsChanged() self:Apply() end
    function M:Init() self:Apply() end
end

NX.QuestTrackerState = NX.QuestTrackerState or {}
do
    local M = NX.QuestTrackerState
    local hooked
    local frame

    local function ApplyState()
        if not NX.DB or not NX.DB.questTrackerState or not NX.DB.questTrackerState.enabled then return end

        local tracker = _G.ObjectiveTrackerFrame
        if not tracker or not tracker.IsCollapsed or not tracker.SetCollapsed then return end

        local saved = NX.DB.questTrackerState.collapsed
        if saved == nil then
            NX.DB.questTrackerState.collapsed = tracker:IsCollapsed() and true or false
            return
        end

        if tracker:IsCollapsed() ~= saved then
            tracker:SetCollapsed(saved)
        end
    end

    local function EnsureHook()
        if hooked then return end
        local tracker = _G.ObjectiveTrackerFrame
        if not tracker or not hooksecurefunc then return end

        hooked = true
        hooksecurefunc(tracker, "SetCollapsed", function(_, collapsed)
            if NX.DB and NX.DB.questTrackerState and NX.DB.questTrackerState.enabled then
                NX.DB.questTrackerState.collapsed = collapsed and true or false
            end
        end)
    end

    function M:Apply()
        C_Timer.After(0, function()
            EnsureHook()
            ApplyState()
        end)
    end

    function M:OnSettingsChanged() self:Apply() end
    function M:Init()
        if not frame then
            frame = CreateFrame("Frame")
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            frame:SetScript("OnEvent", function()
                self:Apply()
            end)
        end
        self:Apply()
    end
end
