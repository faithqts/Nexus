local NX = Nexus
NX.MoneyFrameFix = NX.MoneyFrameFix or {}

local M = NX.MoneyFrameFix
local RELOAD_POPUP_KEY = "NEXUS_RELOAD_MONEY_FRAME_FIX"

local function EnsureDB()
    NX.DB.interface.moneyFrameFix = NX.DB.interface.moneyFrameFix or {}

    if NX.DB.interface.moneyFrameFix.enabled == nil then
        NX.DB.interface.moneyFrameFix.enabled = false
    end

    return NX.DB.interface.moneyFrameFix
end

if StaticPopupDialogs and not StaticPopupDialogs[RELOAD_POPUP_KEY] then
    StaticPopupDialogs[RELOAD_POPUP_KEY] = {
        text = "Money Frame Fix requires a UI Reload.",
        button1 = "Reload Now",
        button2 = "Cancel",
        OnAccept = function()
            if ConsoleExec then
                ConsoleExec("reloadui")
            elseif C_UI and C_UI.Reload then
                C_UI.Reload()
            elseif ReloadUI then
                ReloadUI()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function M:ApplyFix()
    if type(SetTooltipMoney) ~= "function" then
        return false
    end

    if self._isApplied then
        return true
    end

    SetTooltipMoney = function(frame, money, type, prefixText, suffixText)
        if not frame or not frame.AddLine then
            return
        end

        frame:AddLine((prefixText or "") .. "  " .. GetCoinTextureString(money or 0) .. " " .. (suffixText or ""), 0, 1, 1)
    end

    self._isApplied = true
    return true
end

function M:ShowReloadPrompt()
    if StaticPopup_Show then
        StaticPopup_Show(RELOAD_POPUP_KEY)
    else
        print("|cffffd200Nexus:|r Money Frame Fix enabled. Please run /reload.")
    end
end

function M:SetEnabled(enabled, showReloadPrompt)
    local db = EnsureDB()
    local oldEnabled = db.enabled == true
    local newEnabled = enabled and true or false

    db.enabled = newEnabled

    if showReloadPrompt and oldEnabled ~= newEnabled and newEnabled then
        self:ShowReloadPrompt()
    end

    return newEnabled
end

function M:ApplyConfig()
    local db = EnsureDB()

    if db.enabled then
        self:ApplyFix()
    end
end

function M:Init()
    EnsureDB()
    self:ApplyConfig()
end

function M:OnSettingsChanged()
    self:ApplyConfig()
end
