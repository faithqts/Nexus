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
        NX.DB.system.cleanNamesInInstances = NX.DB.system.cleanNamesInInstances or {}
        local db = NX.DB.system.cleanNamesInInstances

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


