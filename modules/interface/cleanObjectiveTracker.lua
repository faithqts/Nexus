local NX = Nexus
NX.CleanObjectiveTracker = NX.CleanObjectiveTracker or {}
local OT = NX.CleanObjectiveTracker

local function EnsureDB()
    NX.DB.interface.cleanObjectiveTracker = NX.DB.interface.cleanObjectiveTracker or {}
    local db = NX.DB.interface.cleanObjectiveTracker
    if db.enabled == nil then db.enabled = false end
    if db.hideBackground == nil then db.hideBackground = true end
    if db.hideTitle == nil then db.hideTitle = true end
end

function OT:Apply()
    if not self._active then return end
    local f = _G.ObjectiveTrackerFrame
    if not f or not f.Header then return end

    local db = NX.DB.interface.cleanObjectiveTracker

    if f.Header.Background then
        if db.hideBackground then f.Header.Background:Hide() else f.Header.Background:Show() end
    end
    if f.Header.Text then
        if db.hideTitle then f.Header.Text:Hide() else f.Header.Text:Show() end
    end
end

function OT:Restore()
    local f = _G.ObjectiveTrackerFrame
    if not f or not f.Header then return end
    if f.Header.Background then f.Header.Background:Show() end
    if f.Header.Text then f.Header.Text:Show() end
end

function OT:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
    end)

    self:Apply()
end

function OT:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    self:Restore()
end

function OT:ApplyConfig()
    EnsureDB()
    if NX.DB.interface.cleanObjectiveTracker.enabled then
        self:Enable()
        self:Apply()
    else
        self:Disable()
    end
end

function OT:Init()
    EnsureDB()
    self:ApplyConfig()
end

function OT:OnSettingsChanged()
    self:ApplyConfig()
end


