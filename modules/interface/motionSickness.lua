local NX = Nexus
NX.MotionSickness = NX.MotionSickness or {}
local MS = NX.MotionSickness
local CV = NX.CVars

local CVAR = "motionSicknessLandscapeDarkening"

local function EnsureDB()
    NX.DB.interface.motionSickness = NX.DB.interface.motionSickness or {}
    if NX.DB.interface.motionSickness.enabled == nil then
        NX.DB.interface.motionSickness.enabled = true
    end
end

local function GetBool()
    if CV and CV.GetBool then
        return CV:GetBool(CVAR, false)
    end
    return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(CVAR) == "1"
end

local function SetBool(v)
    if CV and CV.SetBool then
        CV:SetBool(CVAR, v)
        return
    end
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(CVAR, v and "1" or "0")
    end
end

function MS:Apply()
    if not self._active then return end
    SetBool(false)
end

function MS:Enable()
    if self._active then return end
    self._active = true
    self._prev = GetBool()

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("CVAR_UPDATE")
    self.frame:SetScript("OnEvent", function(_, event, cvarName)
        if event == "PLAYER_LOGIN" then
            self:Apply()
        elseif event == "CVAR_UPDATE" and cvarName == CVAR then
            self:Apply()
        end
    end)

    self:Apply()
end

function MS:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    if self._prev ~= nil then
        SetBool(self._prev)
    end
end

function MS:ApplyConfig()
    EnsureDB()
    if NX.DB.interface.motionSickness.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function MS:Init()
    EnsureDB()
    self:ApplyConfig()
end

function MS:OnSettingsChanged()
    self:ApplyConfig()
end


