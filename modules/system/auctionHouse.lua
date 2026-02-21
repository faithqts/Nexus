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

NX.AuctionHouse = NX.AuctionHouse or {}
do
    local M = NX.AuctionHouse
    local frame

    local function Apply()
        if not NX.DB or not NX.DB.system.auctionHouse then return end
        if not NX.DB.system.auctionHouse.currentExpansionOnly then return end

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


