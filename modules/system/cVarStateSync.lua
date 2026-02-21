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
            NX.DB.system.luaErrors = NX.DB.system.luaErrors or {}
            NX.DB.system.luaErrors.enabled = GetCVarBool("scriptErrors", NX.DB.system.luaErrors.enabled == true)
            return
        end

        if name == "showTutorials" then
            NX.DB.system.tutorials = NX.DB.system.tutorials or {}
            NX.DB.system.tutorials.disabled = not GetCVarBool("showTutorials", NX.DB.system.tutorials.disabled ~= true)
            return
        end

        if name == "autoDismount" then
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.enabled = GetCVarBool("autoDismount", NX.DB.system.autoDismount.enabled ~= false)
            return
        end

        if name == "autoDismountFlying" then
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.flying = GetCVarBool("autoDismountFlying", NX.DB.system.autoDismount.flying ~= false)
            return
        end

        if name == "AutoPushSpellToActionBar" then
            NX.DB.system.autoPlaceSpells = NX.DB.system.autoPlaceSpells or {}
            NX.DB.system.autoPlaceSpells.enabled = GetCVarBool("AutoPushSpellToActionBar", NX.DB.system.autoPlaceSpells.enabled == true)
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


