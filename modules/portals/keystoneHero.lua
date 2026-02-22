local NX = Nexus
NX.Portals = NX.Portals or {}
local P = NX.Portals
local FN = NX.Functions

local WIDTH = 565
local UPDATE_HZ = 2

P.Anchor = P.Anchor or nil
P.Buttons = P.Buttons or {}
P.Ticker = P.Ticker or nil
P.pendingRefresh = P.pendingRefresh or false

P.List = {
    { spellID = 1254572, spellName = "Path of Devoted Magistry", text = "MGT", pinned = true },
    { spellID = 1254559, spellName = "Path of Cavernous Depths", text = "MAIS", pinned = true },
    { spellID = 1254563, spellName = "Path of the Fractured Core", text = "NPX", pinned = true },
    { spellID = 1254400, spellName = "Path of the Windrunners", text = "WRS", pinned = true },
    { spellID = 393273, spellName = "Path of the Draconic Diploma", text = "AA", pinned = true },
    { spellID = 1254551, spellName = "Path of Dark Dereliction", text = "SOTT", pinned = true },
    { spellID = 159898, spellName = "Path of the Skies", text = "SKY", pinned = true },
    { spellID = 1254557, spellName = "Path of the Crowning Pinnacle", text = "SKY", pinned = true },
    { spellID = 1254555, spellName = "Path of Unyielding Blight", text = "POS", pinned = true },

    { spellID = 410080, spellName = "Path of Wind's Domain", text = "VP" },
    { spellID = 424197, spellName = "Path of Twisted Time", text = "DOTI" },
    { spellID = 393262, spellName = "Path of the Windswept Plains", text = "NO" },
    { spellID = 467546, spellName = "Path of the Waterworks", text = "WW" },
    { spellID = 1237215, spellName = "Path of the Eco-Dome", text = "EDA" },
    { spellID = 393222, spellName = "Path of the Watcher's Legacy", text = "ULD" },
    { spellID = 445441, spellName = "Path of the Warding Candles", text = "DFC" },
    { spellID = 159897, spellName = "Path of the Vigilant", text = "AUCH" },
    { spellID = 159901, spellName = "Path of the Verdant", text = "EB" },
    { spellID = 354467, spellName = "Path of the Undefeated", text = "TOP" },
    { spellID = 445424, spellName = "Path of the Twilight Fortress", text = "GB" },
    { spellID = 393283, spellName = "Path of the Titanic Reservoir", text = "HOI" },
    { spellID = 424142, spellName = "Path of the Tidehunter", text = "TOT" },
    { spellID = 367416, spellName = "Path of the Streetwise Merchant", text = "TAZA" },
    { spellID = 131205, spellName = "Path of the Stout Brew", text = "SB" },
    { spellID = 354469, spellName = "Path of the Stone Warden", text = "SD" },
    { spellID = 354465, spellName = "Path of the Sinful Soul", text = "HOA" },
    { spellID = 131206, spellName = "Path of the Shado-Pan", text = "SPM" },
    { spellID = 131225, spellName = "Path of the Setting Sun", text = "GSS" },
    { spellID = 373274, spellName = "Path of the Scrappy Prince", text = "MECH" },
    { spellID = 354468, spellName = "Path of the Scheming Loa", text = "DOS" },
    { spellID = 131229, spellName = "Path of the Scarlet Mitre", text = "SM" },
    { spellID = 131231, spellName = "Path of the Scarlet Blade", text = "SH" },
    { spellID = 445417, spellName = "Path of the Ruined City", text = "ARAK" },
    { spellID = 445416, spellName = "Path of Nerubian Ascension", text = "THREAD" },
    { spellID = 393267, spellName = "Path of the Rotting Woods", text = "BH" },
    { spellID = 354463, spellName = "Path of the Plagued", text = "PF" },
    { spellID = 393276, spellName = "Path of the Obsidian Hoard", text = "NELT" },
    { spellID = 410078, spellName = "Path of the Earth-Warder", text = "NL" },
    { spellID = 424163, spellName = "Path of the Nightmare Lord", text = "DHT" },
    { spellID = 131232, spellName = "Path of the Necromancer", text = "SCHO" },
    { spellID = 131222, spellName = "Path of the Mogu King", text = "MSP" },
    { spellID = 354464, spellName = "Path of the Misty Forest", text = "MISTS" },
    { spellID = 445444, spellName = "Path of the Light's Reverence", text = "PRIO" },
    { spellID = 131204, spellName = "Path of the Jade Serpent", text = "TJS" },
    { spellID = 159896, spellName = "Path of the Iron Prow", text = "ID" },
    { spellID = 393766, spellName = "Path of the Grand Magistrix", text = "COS" },
    { spellID = 424187, spellName = "Path of the Golden Tomb", text = "ATAL" },
    { spellID = 410071, spellName = "Path of the Freebooter", text = "FREE" },
    { spellID = 445440, spellName = "Path of the Flaming Brewery", text = "CBM" },
    { spellID = 445443, spellName = "Path of the Fallen Stormriders", text = "ROOK" },
    { spellID = 159900, spellName = "Path of the Dark Rail", text = "GRD" },
    { spellID = 159899, spellName = "Path of the Crescent Moon", text = "SBG" },
    { spellID = 354462, spellName = "Path of the Courageous", text = "NW" },
    { spellID = 445269, spellName = "Path of the Corrupted Foundry", text = "STONE" },
    { spellID = 1216786, spellName = "Path of the Circuit Breaker", text = "FLOOD" },
    { spellID = 159902, spellName = "Path of the Burning Mountain", text = "UBRS" },
    { spellID = 159895, spellName = "Path of the Bloodmaul", text = "BSM" },
    { spellID = 131228, spellName = "Path of the Black Ox", text = "NZAO" },
    { spellID = 445418, spellName = "Path of the Besieged Harbor", text = "BOR" },
    { spellID = 464256, spellName = "Path of the Besieged Harbor", text = "BOR" },
    { spellID = 467553, spellName = "Path of the Azerite Refinery", text = "ML" },
    { spellID = 467555, spellName = "Path of the Azerite Refinery", text = "ML" },
    { spellID = 354466, spellName = "Path of the Ascendant", text = "SOA" },
    { spellID = 445414, spellName = "Path of the Arathi Flagship", text = "DAWN" },
    { spellID = 393764, spellName = "Path of Proven Worth", text = "HOV" },
    { spellID = 424167, spellName = "Path of Heart's Bane", text = "WM" },
    { spellID = 410074, spellName = "Path of Festering Rot", text = "UNDER" },
    { spellID = 393279, spellName = "Path of Arcane Secrets", text = "AV" },
    { spellID = 424153, spellName = "Path of Ancient Horrors", text = "BRH" },

    { spellID = 373190, spellName = "Path of the Sire", text = "CN" },
    { spellID = 373191, spellName = "Path of the Tormented Soul", text = "SOD" },
    { spellID = 373192, spellName = "Path of the First Ones", text = "SEP" },
    { spellID = 432254, spellName = "Path of the Primal Prison", text = "VOTI" },
    { spellID = 432257, spellName = "Path of the Bitter Legacy", text = "ABER" },
    { spellID = 432258, spellName = "Path of the Scorching Dream", text = "AMIR" },
    { spellID = 1226482, spellName = "Path of the Full House", text = "LOU" },
    { spellID = 1239155, spellName = "Path of the All-Devouring", text = "MFO" },
}

local function EnsureChallengesLoaded()
    local isLoaded
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLoaded = C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI")
    elseif IsAddOnLoaded then
        isLoaded = IsAddOnLoaded("Blizzard_ChallengesUI")
    end

    if isLoaded then return end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_ChallengesUI")
    elseif LoadAddOn then
        LoadAddOn("Blizzard_ChallengesUI")
    end
end

local function IsSpellKnownForPlayer(spellID)
    if not spellID then return false end
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    if C_Spell and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellID)
    end
    return false
end

local function GetSpellLabel(spellID, fallbackName, fallbackText)
    local name, icon
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            name = info.name
            icon = info.iconID
        end
    elseif GetSpellInfo then
        name, _, icon = GetSpellInfo(spellID)
    end

    if name then
        return name, icon
    end
    return (fallbackName or fallbackText or ("Spell " .. tostring(spellID))), 134400
end

local function GetSpellCooldownCompat(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spellID)
        if cd then
            return cd.startTime, cd.duration, cd.isEnabled
        end
    elseif GetSpellCooldown then
        return GetSpellCooldown(spellID)
    end

    return 0, 0, 0
end

local function BuildNoCombatCastMacro(spellID, spellName)
    if spellName and spellName ~= "" then
        return "/cast [nocombat] " .. spellName
    end
    return "/cast [nocombat] spell:" .. tostring(spellID or 0)
end

local function BuildEquivalentSuppressionMap(entries)
    local groups = {}

    for i, entry in ipairs(entries) do
        if entry and entry.text then
            local key = tostring(entry.text)
            local group = groups[key]
            if not group then
                group = {}
                groups[key] = group
            end
            group[#group + 1] = i
        end
    end

    local suppress = {}
    for _, indices in pairs(groups) do
        if #indices > 1 then
            local chosen = indices[1]
            for _, idx in ipairs(indices) do
                local entry = entries[idx]
                if entry and entry.spellID and IsSpellKnownForPlayer(entry.spellID) then
                    chosen = idx
                    break
                end
            end

            for _, idx in ipairs(indices) do
                if idx ~= chosen then
                    suppress[idx] = true
                end
            end
        end
    end

    return suppress
end

local function IsSafeToRenderPortals()
    if FN and FN.PassesCommonNonCombatRules and not FN:PassesCommonNonCombatRules() then
        return false
    end

    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "raid" then
            return false
        end
    end

    return true
end

function P:EnsureDB()
    NX.DB.portals.portals = NX.DB.portals.portals or {}
    local db = NX.DB.portals.portals

    if db.enabled == nil then db.enabled = true end
    if db.showLegacyPortals == nil then db.showLegacyPortals = true end
    if db.anchorX == nil then db.anchorX = 0 end
    if db.anchorY == nil then db.anchorY = -35 end
    if db.topRowMax == nil then db.topRowMax = 8 end
    if db.topRowHeightPct == nil then db.topRowHeightPct = 80 end
    if db.perRow == nil then db.perRow = 12 end
    if db.smallRowHeightPct == nil then db.smallRowHeightPct = 80 end
    if db.spacing == nil then db.spacing = 2 end
end

function P:IsEnabled()
    self:EnsureDB()
    return NX.DB.portals.portals.enabled ~= false
end

function P:HideAll()
    if self.Anchor then
        self.Anchor:Hide()
    end

    for _, btn in ipairs(self.Buttons) do
        btn:Hide()
    end
end

function P:GetConfig()
    self:EnsureDB()
    local db = NX.DB.portals.portals

    local cfg = {}
    cfg.anchorX = FN:ClampNumber(math.floor((tonumber(db.anchorX) or 0) + 0.5), -500, 500)
    cfg.anchorY = FN:ClampNumber(math.floor((tonumber(db.anchorY) or -35) + 0.5), -500, 500)
    cfg.showLegacyPortals = (db.showLegacyPortals ~= false)
    cfg.topRowMax = FN:ClampNumber(math.floor((tonumber(db.topRowMax) or 8) + 0.5), 6, 8)
    cfg.topRowHeightPct = FN:ClampNumber(math.floor((tonumber(db.topRowHeightPct) or 80) + 0.5), 1, 100)
    cfg.perRow = FN:ClampNumber(math.floor((tonumber(db.perRow) or 12) + 0.5), 8, 12)
    cfg.smallRowHeightPct = FN:ClampNumber(math.floor((tonumber(db.smallRowHeightPct) or 80) + 0.5), 1, 100)

    local spacing = tonumber(db.spacing) or 2
    spacing = math.floor((spacing * 10) + 0.5) / 10
    cfg.spacing = FN:ClampNumber(spacing, 0, 5)

    return cfg
end

function P:CreateAnchor(cfg)
    local parent = PVEFrame or ChallengesFrame
    if not parent then return false end

    if not self.Anchor then
        self.Anchor = CreateFrame("Frame", nil, parent)
    else
        self.Anchor:SetParent(parent)
    end

    self.Anchor:ClearAllPoints()
    self.Anchor:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", cfg.anchorX, cfg.anchorY)
    self.Anchor:SetSize(WIDTH, 300)

    return true
end

function P:BuildButtons()
    if not self.Anchor then return end
    local suppressByIndex = BuildEquivalentSuppressionMap(self.List)

    for i, entry in ipairs(self.List) do
        local btn = self.Buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, self.Anchor, "SecureActionButtonTemplate")
            btn:EnableMouse(true)
            btn:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
            btn:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

                local spellID = self.spellID
                local spellName = nil
                if spellID then
                    if C_Spell and C_Spell.GetSpellInfo then
                        local info = C_Spell.GetSpellInfo(spellID)
                        if info then
                            spellName = info.name
                        end
                    elseif GetSpellInfo then
                        spellName = GetSpellInfo(spellID)
                    end
                end
                spellName = spellName or (self.entry and self.entry.spellName) or ("Spell " .. tostring(spellID or 0))

                GameTooltip:AddLine(spellName, 1, 1, 1, true)
                if spellID then
                    GameTooltip:AddLine("Spell ID: " .. spellID)
                    GameTooltip:AddLine(" ")
                    GameTooltip:SetHyperlink("|cff71d5ff|Hspell:" .. spellID .. "|h[" .. spellName .. "]|h|r")
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                if GameTooltip then
                    GameTooltip:Hide()
                end
            end)
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("type1", "macro")

            btn.Icon = btn:CreateTexture(nil, "BACKGROUND")
            btn.Icon:SetAllPoints()

            btn.Cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
            btn.Cooldown:SetAllPoints()
            if btn.Cooldown.SetMouseClickEnabled then
                btn.Cooldown:SetMouseClickEnabled(false)
            else
                btn.Cooldown:EnableMouse(false)
            end

            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.Text:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
            btn.Text:SetTextColor(1, 1, 1, 1)
            if FN and FN.ApplyAddonFont then
                FN:ApplyAddonFont(btn.Text, 16, "OUTLINE")
            end
            btn.Text:SetShadowColor(0, 0, 0, 1)
            btn.Text:SetShadowOffset(1, -1)

            self.Buttons[i] = btn
        end

        if suppressByIndex[i] then
            btn.entry = nil
            btn.spellID = nil
            btn:Hide()
        else
            btn.entry = entry
            btn.spellID = entry.spellID
            local realName, icon = GetSpellLabel(entry.spellID, entry.spellName, entry.text)
            local macroText = BuildNoCombatCastMacro(entry.spellID, realName or entry.spellName)
            btn:SetAttribute("macrotext", macroText)
            btn:SetAttribute("macrotext1", macroText)
            btn.Icon:SetTexture(icon)
            btn.Text:SetText(entry.text or realName)
            btn.Text:SetTextColor(1, 1, 1, 1)
            if FN and FN.ApplyAddonFont then
                FN:ApplyAddonFont(btn.Text, 16, "OUTLINE")
            end
            btn.Text:SetShadowColor(0, 0, 0, 1)
            btn.Text:SetShadowOffset(1, -1)
            btn:Show()
        end
    end

    for i = #self.List + 1, #self.Buttons do
        if self.Buttons[i] then
            self.Buttons[i]:Hide()
        end
    end
end

function P:GetOrderedButtons(cfg)
    local pinned = {}
    local normal = {}

    for _, btn in ipairs(self.Buttons) do
        local e = btn.entry
        if btn:IsShown() and e and e.spellID then
            local known = IsSpellKnownForPlayer(e.spellID)
            if e.pinned then
                pinned[#pinned + 1] = btn
            elseif cfg.showLegacyPortals and known then
                normal[#normal + 1] = btn
            end
        end
    end

    table.sort(pinned, function(a, b)
        return (a.entry.text or "") < (b.entry.text or "")
    end)
    while #pinned > cfg.topRowMax do
        local moved = table.remove(pinned)
        if moved and moved.entry and IsSpellKnownForPlayer(moved.entry.spellID) then
            table.insert(normal, 1, moved)
        end
    end

    return pinned, normal
end

function P:ApplyButtonVisualState(btn)
    local entry = btn and btn.entry
    local known = entry and entry.spellID and IsSpellKnownForPlayer(entry.spellID)

    if btn.Icon and btn.Icon.SetDesaturated then
        btn.Icon:SetDesaturated(not known)
    end

    if btn.Icon and btn.Icon.SetVertexColor then
        if known then
            btn.Icon:SetVertexColor(1, 1, 1, 1)
        else
            btn.Icon:SetVertexColor(0.55, 0.55, 0.55, 1)
        end
    end

    if btn.Text then
        btn.Text:SetText(entry.text or "")
    end

    btn:Show()
end

function P:Layout()
    if not self.Anchor then return end

    local cfg = self:GetConfig()
    local pinned, normal = self:GetOrderedButtons(cfg)
    local visible = {}

    local spacing = cfg.spacing
    local topSlots = cfg.topRowMax
    local perRow = cfg.perRow

    local wTop = (WIDTH - ((topSlots - 1) * spacing)) / topSlots
    local hTop = wTop * (cfg.topRowHeightPct / 100)

    local wSmall = (WIDTH - ((perRow - 1) * spacing)) / perRow
    local hSmall = wSmall * (cfg.smallRowHeightPct / 100)
    local topCount = #pinned
    local topWidth = (topCount * wTop) + (math.max(topCount - 1, 0) * spacing)
    local topStartX = (WIDTH - topWidth) * 0.5

    for i, btn in ipairs(pinned) do
        btn:SetSize(wTop, hTop)

        local x = topStartX + ((i - 1) * (wTop + spacing))

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.Anchor, "TOPLEFT", x, 0)
        btn:Show()
        visible[btn] = true
    end

    local normalCount = #normal
    for idx, btn in ipairs(normal) do
        btn:SetSize(wSmall, hSmall)

        local col = ((idx - 1) % perRow) + 1
        local row = math.floor((idx - 1) / perRow)
        local rowCount = math.min(perRow, normalCount - (row * perRow))
        local rowWidth = (rowCount * wSmall) + (math.max(rowCount - 1, 0) * spacing)
        local rowStartX = (WIDTH - rowWidth) * 0.5

        local x = rowStartX + ((col - 1) * (wSmall + spacing))
        local y = -(hTop + spacing + (row * (hSmall + spacing)))

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.Anchor, "TOPLEFT", x, y)
        btn:Show()
        visible[btn] = true
    end

    for _, btn in ipairs(self.Buttons) do
        if visible[btn] and btn.entry and btn.entry.spellID then
            self:ApplyButtonVisualState(btn)
        else
            btn:Hide()
        end
    end

    local normalRows = math.ceil(#normal / perRow)
    local totalHeight = hTop
    if normalRows > 0 then
        totalHeight = totalHeight + spacing + (normalRows * hSmall) + ((normalRows - 1) * spacing)
    end
    self.Anchor:SetSize(WIDTH, math.max(totalHeight, hTop))
end

function P:UpdateCooldowns()
    if InCombatLockdown and InCombatLockdown() then
        for _, btn in ipairs(self.Buttons) do
            if btn:IsShown() and btn.Text and btn.entry then
                btn.Text:SetText(btn.entry.text or "")
            end
        end
        return
    end

    for _, btn in ipairs(self.Buttons) do
        local known = btn.spellID and IsSpellKnownForPlayer(btn.spellID)
        if btn:IsShown() and btn.spellID and known then
            local start, duration = GetSpellCooldownCompat(btn.spellID)
            if start ~= nil and duration ~= nil then
                btn.Cooldown:SetCooldown(start, duration)

                local hasSpellCooldown = false
                local ok = pcall(function()
                    hasSpellCooldown = (start > 0) and (duration > 1.5)
                end)
                if not ok then
                    hasSpellCooldown = false
                end

                if btn.Text then
                    if hasSpellCooldown then
                        btn.Text:SetText("")
                    else
                        btn.Text:SetText((btn.entry and btn.entry.text) or "")
                    end
                end
            else
                if btn.Cooldown.Clear then
                    btn.Cooldown:Clear()
                else
                    btn.Cooldown:SetCooldown(0, 0)
                end
                if btn.Text then
                    btn.Text:SetText((btn.entry and btn.entry.text) or "")
                end
            end
        elseif btn.Cooldown then
            if btn.Cooldown.Clear then
                btn.Cooldown:Clear()
            else
                btn.Cooldown:SetCooldown(0, 0)
            end
            if btn.Text and btn.entry and btn.entry.text then
                btn.Text:SetText(btn.entry.text)
            end
        end
    end
end

function P:UpdateAll()
    if not IsSafeToRenderPortals() then
        self.pendingRefresh = true
        self:HideAll()
        return
    end

    self:EnsureDB()
    if not self:IsEnabled() then
        self:HideAll()
        return
    end

    local cfg = self:GetConfig()
    EnsureChallengesLoaded()
    if not self:CreateAnchor(cfg) then return end
    self.Anchor:Show()

    self:BuildButtons()
    self:Layout()
    self:UpdateCooldowns()
end

function P:StartTicker()
    if self.Ticker then
        self.Ticker:Cancel()
        self.Ticker = nil
    end

    local interval = 1 / math.max(1, UPDATE_HZ)
    self.Ticker = C_Timer.NewTicker(interval, function()
        if not IsSafeToRenderPortals() then
            self.pendingRefresh = true
            self:HideAll()
            return
        end
        self:UpdateCooldowns()
    end)
end

function P:StopTicker()
    if self.Ticker then
        self.Ticker:Cancel()
        self.Ticker = nil
    end
end

function P:Init()
    self:EnsureDB()
    self:UpdateAll()
    if self:IsEnabled() then
        self:StartTicker()
    else
        self:StopTicker()
    end
end

function P:OnSettingsChanged()
    self:EnsureDB()
    if self:IsEnabled() then
        self:StartTicker()
    else
        self:StopTicker()
    end
    self:UpdateAll()
end

function P:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" or event == "ENCOUNTER_START" or event == "ENCOUNTER_END" then
        self:UpdateAll()
        return
    end

    if event == "ADDON_LOADED" and ... == "Blizzard_ChallengesUI" then
        self:UpdateAll()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if self.pendingRefresh then
            self.pendingRefresh = false
            self:UpdateAll()
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self.pendingRefresh = true
        self:UpdateCooldowns()
        return
    end
end



