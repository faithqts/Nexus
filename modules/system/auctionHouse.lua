local NX = Nexus
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


