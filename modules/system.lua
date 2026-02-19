local NX = Nexus
local CV = NX.CVars
local FN = NX.Functions

local function SetCVarBool(name, enabled)
    if FN and FN.SetCVarBool then
        FN:SetCVarBool(name, enabled)
        return
    end
    if CV and CV.SetBool then
        CV:SetBool(name, enabled)
    end
end

local function GetCVarBool(name, fallback)
    if FN and FN.GetCVarBool then
        return FN:GetCVarBool(name, fallback)
    end
    if CV and CV.GetBool then
        return CV:GetBool(name, fallback)
    end
    return fallback and true or false
end

NX.CVarStateSync = NX.CVarStateSync or {}
do
    local M = NX.CVarStateSync
    local frame

    local tracked = {
        scriptErrors = true,
        showTutorials = true,
        autoDismount = true,
        autoDismountFlying = true,
        AutoPushSpellToActionBar = true,
    }

    local function SyncOne(name)
        if not NX.DB then return end

        if name == "scriptErrors" then
            NX.DB.luaErrors = NX.DB.luaErrors or {}
            NX.DB.luaErrors.enabled = GetCVarBool("scriptErrors", NX.DB.luaErrors.enabled == true)
            return
        end

        if name == "showTutorials" then
            NX.DB.tutorials = NX.DB.tutorials or {}
            NX.DB.tutorials.disabled = not GetCVarBool("showTutorials", NX.DB.tutorials.disabled ~= true)
            return
        end

        if name == "autoDismount" then
            NX.DB.autoDismount = NX.DB.autoDismount or {}
            NX.DB.autoDismount.enabled = GetCVarBool("autoDismount", NX.DB.autoDismount.enabled ~= false)
            return
        end

        if name == "autoDismountFlying" then
            NX.DB.autoDismount = NX.DB.autoDismount or {}
            NX.DB.autoDismount.flying = GetCVarBool("autoDismountFlying", NX.DB.autoDismount.flying ~= false)
            return
        end

        if name == "AutoPushSpellToActionBar" then
            NX.DB.autoPlaceSpells = NX.DB.autoPlaceSpells or {}
            NX.DB.autoPlaceSpells.enabled = GetCVarBool("AutoPushSpellToActionBar", NX.DB.autoPlaceSpells.enabled == true)
            return
        end
    end

    local function SyncAll()
        SyncOne("scriptErrors")
        SyncOne("showTutorials")
        SyncOne("autoDismount")
        SyncOne("autoDismountFlying")
        SyncOne("AutoPushSpellToActionBar")
    end

    function M:Init()
        SyncAll()

        if frame then return end
        frame = CreateFrame("Frame")
        frame:RegisterEvent("CVAR_UPDATE")
        frame:SetScript("OnEvent", function(_, _, cvarName)
            if tracked[cvarName] then
                SyncOne(cvarName)
            end
        end)
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
        local showTutorials = not (NX.DB.tutorials.disabled == true)
        SetCVarBool("showTutorials", showTutorials)
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

NX.CleanNamesInInstances = NX.CleanNamesInInstances or {}
do
    local M = NX.CleanNamesInInstances
    local frame

    local CVAR_PLAYER_TITLE = "UnitNamePlayerPVPTitle"
    local CVAR_PLAYER_GUILD = "UnitNamePlayerGuild"
    local CVAR_WORLDTEXT_SIZE = "WorldTextMinSize"
    local CVAR_WORLDTEXT_ALPHA = "WorldTextMinAlpha"
    local CVAR_UNIT_NAME_NPC = "UnitNameNPC"

    local function ToBool(value, fallback)
        if value == nil then
            return fallback and true or false
        end

        if type(value) == "boolean" then
            return value
        end

        local s = tostring(value)
        if s == "1" or s == "true" then
            return true
        end
        if s == "0" or s == "false" then
            return false
        end

        return fallback and true or false
    end

    local function ToNumber(value, fallback)
        local n = tonumber(value)
        if not n then
            return fallback
        end
        return n
    end

    local function GetCVarValue(name)
        if FN and FN.GetCVarValue then
            return FN:GetCVarValue(name)
        end
        return nil
    end

    local function SetCVarValue(name, value)
        if FN and FN.SetCVarValue then
            FN:SetCVarValue(name, value)
        end
    end

    function M:EnsureDB()
        NX.DB.cleanNamesInInstances = NX.DB.cleanNamesInInstances or {}
        local db = NX.DB.cleanNamesInInstances

        if db.enabled == nil then db.enabled = false end

        if db.inInstanceShowGuild == nil then db.inInstanceShowGuild = false end
        if db.inInstanceShowTitle == nil then db.inInstanceShowTitle = false end
        if db.inInstanceSize == nil then db.inInstanceSize = 12 end
        if db.inInstanceMinAlpha == nil then db.inInstanceMinAlpha = 1 end
        if db.unitNameNPC == nil then db.unitNameNPC = ToBool(GetCVarValue(CVAR_UNIT_NAME_NPC), true) end

        if db.outInstanceShowGuild == nil then db.outInstanceShowGuild = ToBool(GetCVarValue(CVAR_PLAYER_GUILD), true) end
        if db.outInstanceShowTitle == nil then db.outInstanceShowTitle = ToBool(GetCVarValue(CVAR_PLAYER_TITLE), true) end
        if db.outInstanceSize == nil then db.outInstanceSize = ToNumber(GetCVarValue(CVAR_WORLDTEXT_SIZE), 8) end
        if db.outInstanceMinAlpha == nil then db.outInstanceMinAlpha = ToNumber(GetCVarValue(CVAR_WORLDTEXT_ALPHA), 0.5) end

        return db
    end

    function M:SyncUnitNameNPCFromClient()
        local db = self:EnsureDB()
        db.unitNameNPC = ToBool(GetCVarValue(CVAR_UNIT_NAME_NPC), db.unitNameNPC)
    end

    function M:IsInInstanceNow()
        if not IsInInstance then
            return false
        end
        local inInstance = IsInInstance()
        return inInstance and true or false
    end

    function M:SyncOutOfInstanceDefaultsFromClient()
        if self:IsInInstanceNow() then
            return
        end

        local db = self:EnsureDB()

        db.outInstanceShowTitle = ToBool(GetCVarValue(CVAR_PLAYER_TITLE), db.outInstanceShowTitle)
        db.outInstanceShowGuild = ToBool(GetCVarValue(CVAR_PLAYER_GUILD), db.outInstanceShowGuild)
        db.outInstanceSize = ToNumber(GetCVarValue(CVAR_WORLDTEXT_SIZE), db.outInstanceSize)
        db.outInstanceMinAlpha = ToNumber(GetCVarValue(CVAR_WORLDTEXT_ALPHA), db.outInstanceMinAlpha)
    end

    local function ApplyProfile(db, inInstance)
        SetCVarValue(CVAR_PLAYER_TITLE, inInstance and db.inInstanceShowTitle or db.outInstanceShowTitle)
        SetCVarValue(CVAR_PLAYER_GUILD, inInstance and db.inInstanceShowGuild or db.outInstanceShowGuild)
        SetCVarValue(CVAR_WORLDTEXT_SIZE, inInstance and db.inInstanceSize or db.outInstanceSize)
        SetCVarValue(CVAR_WORLDTEXT_ALPHA, inInstance and db.inInstanceMinAlpha or db.outInstanceMinAlpha)
    end

    function M:ApplyNow()
        local db = self:EnsureDB()

        SetCVarValue(CVAR_UNIT_NAME_NPC, db.unitNameNPC)

        if InCombatLockdown and InCombatLockdown() then
            self._pending = true
            return
        end

        local inInstance = self:IsInInstanceNow()
        if not inInstance then
            self:SyncOutOfInstanceDefaultsFromClient()
        end

        if db.enabled then
            ApplyProfile(db, inInstance)
        elseif inInstance then
            ApplyProfile(db, false)
        end

        self._pending = false
    end

    function M:Apply()
        self:ApplyNow()
    end

    function M:SetEnabled(enabled)
        local db = self:EnsureDB()
        db.enabled = enabled and true or false
        self:ApplyNow()
    end

    function M:Toggle()
        local db = self:EnsureDB()
        self:SetEnabled(not db.enabled)
        print(string.format("|cffffd200Nexus:|r Clean Names in Instances %s.", db.enabled and "enabled" or "disabled"))
    end

    function M:OnSettingsChanged()
        self:ApplyNow()
    end

    function M:Init()
        self:EnsureDB()

        if frame then
            self:ApplyNow()
            return
        end

        frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("LOADING_SCREEN_DISABLED")
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("CVAR_UPDATE")
        frame:SetScript("OnEvent", function(_, event, arg1)
            if event == "CVAR_UPDATE" and arg1 == CVAR_UNIT_NAME_NPC then
                self:SyncUnitNameNPCFromClient()
                return
            end

            if event == "PLAYER_REGEN_ENABLED" then
                if self._pending then
                    self:ApplyNow()
                end
                return
            end

            self:ApplyNow()
        end)

        self:ApplyNow()
    end
end
