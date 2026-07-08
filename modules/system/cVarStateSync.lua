local NX = Nexus
local FN = NX.Functions

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
            NX.DB.system.luaErrors.enabled = FN:GetCVarBool("scriptErrors", NX.DB.system.luaErrors.enabled == true)
            return
        end

        if name == "showTutorials" then
            NX.DB.system.tutorials = NX.DB.system.tutorials or {}
            NX.DB.system.tutorials.disabled = not FN:GetCVarBool("showTutorials", NX.DB.system.tutorials.disabled ~= true)
            return
        end

        if name == "autoDismount" then
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.enabled = FN:GetCVarBool("autoDismount", NX.DB.system.autoDismount.enabled ~= false)
            return
        end

        if name == "autoDismountFlying" then
            NX.DB.system.autoDismount = NX.DB.system.autoDismount or {}
            NX.DB.system.autoDismount.flying = FN:GetCVarBool("autoDismountFlying", NX.DB.system.autoDismount.flying ~= false)
            return
        end

        if name == "AutoPushSpellToActionBar" then
            NX.DB.system.autoPlaceSpells = NX.DB.system.autoPlaceSpells or {}
            NX.DB.system.autoPlaceSpells.enabled = FN:GetCVarBool("AutoPushSpellToActionBar", NX.DB.system.autoPlaceSpells.enabled == true)
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


