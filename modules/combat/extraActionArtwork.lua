local NX = Nexus
NX.ExtraActionArtwork = NX.ExtraActionArtwork or {}

local EAA = NX.ExtraActionArtwork

local extraPending
local extraFrame

local function ApplyExtraActionArtworkNow()
    if not NX.DB or not NX.DB.combat.extraActionArtwork then return end

    local hideArtwork = NX.DB.combat.extraActionArtwork.enabled == true

    if InCombatLockdown and InCombatLockdown() then
        extraPending = true
        return
    end

    local extraActionButton = _G.ExtraActionButton1
    local extraStyle = extraActionButton and extraActionButton.style
    if extraStyle then
        if hideArtwork then
            extraStyle:SetAlpha(0)
            extraStyle:Hide()
        else
            extraStyle:SetAlpha(1)
            extraStyle:Show()
        end
    end

    local zoneAbilityFrame = _G.ZoneAbilityFrame
    local zoneStyle = zoneAbilityFrame and zoneAbilityFrame.Style
    if zoneStyle then
        if hideArtwork then
            zoneStyle:SetAlpha(0)
            zoneStyle:Hide()
        else
            zoneStyle:SetAlpha(1)
            zoneStyle:Show()
        end
    end

    local extraActionBarFrame = _G.ExtraActionBarFrame
    if extraActionBarFrame and extraActionBarFrame.EnableMouse then
        extraActionBarFrame:EnableMouse(not hideArtwork)
    end

    extraPending = nil
end

function EAA:Apply()
    C_Timer.After(0, ApplyExtraActionArtworkNow)
end

function EAA:OnSettingsChanged()
    self:Apply()
end

function EAA:Init()
    if not extraFrame then
        extraFrame = CreateFrame("Frame")
        extraFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        extraFrame:SetScript("OnEvent", function()
            if extraPending then
                C_Timer.After(0, ApplyExtraActionArtworkNow)
            end
        end)
    end

    self:Apply()
end

