local NX = Nexus
NX.EnhancedErrorText = NX.EnhancedErrorText or {}
local ET = NX.EnhancedErrorText

local function EnsureDB()
    NX.DB.interface.enhancedErrorText = NX.DB.interface.enhancedErrorText or {}
    local db = NX.DB.interface.enhancedErrorText
    if db.enabled == nil then db.enabled = false end
    if db.fontSize == nil then db.fontSize = 22 end
    if db.width == nil then db.width = 800 end
    if db.height == nil then db.height = 120 end
    if db.offsetY == nil then db.offsetY = 0 end
    if db.outline == nil then db.outline = true end
end

local function CaptureFramePoints(frame)
    local points = {}
    if not frame or not frame.GetNumPoints or not frame.GetPoint then
        return points
    end

    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        points[#points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        }
    end

    return points
end

local function RestoreFramePoints(frame, points, offsetY)
    if not frame or not frame.ClearAllPoints or not frame.SetPoint then return end
    if type(points) ~= "table" or #points == 0 then return end

    frame:ClearAllPoints()

    for _, p in ipairs(points) do
        local x = tonumber(p.x) or 0
        local y = (tonumber(p.y) or 0) + (tonumber(offsetY) or 0)

        if p.relativeTo ~= nil then
            frame:SetPoint(p.point, p.relativeTo, p.relativePoint, x, y)
        else
            frame:SetPoint(p.point, UIParent, p.relativePoint, x, y)
        end
    end
end

local PLAYER_NAME = UnitName("player") or "Player"
local PREVIEW_TEXT = PLAYER_NAME .. " stood in bad, survived, then killed themselves: 1/1"

function ET:ShowPreview()
    if not UIErrorsFrame or not UIErrorsFrame.AddExternalWarningMessage then return end

    UIErrorsFrame:AddExternalWarningMessage(PREVIEW_TEXT)
end

function ET:Apply()
    if not self._active then return end
    if not UIErrorsFrame or not UIErrorsFrame.GetFont then return end

    local font, size, flags = UIErrorsFrame:GetFont()
    if not self._prev then
        self._prev = {
            font = font,
            size = size,
            flags = flags,
            width = UIErrorsFrame:GetWidth(),
            height = UIErrorsFrame:GetHeight(),
            points = CaptureFramePoints(UIErrorsFrame),
        }
    end

    local db = NX.DB.interface.enhancedErrorText
    local useFlags = db.outline and "OUTLINE" or (flags or "")
    local targetFont = (NX.Functions and NX.Functions.GetAddonFontPath and NX.Functions:GetAddonFontPath()) or font
    if not UIErrorsFrame:SetFont(targetFont, db.fontSize, useFlags) then
        UIErrorsFrame:SetFont(font, db.fontSize, useFlags)
    end
    UIErrorsFrame:SetWidth(db.width)
    UIErrorsFrame:SetHeight(db.height)
    RestoreFramePoints(UIErrorsFrame, self._prev.points, db.offsetY)
end

function ET:Restore()
    if not self._prev then return end
    if not UIErrorsFrame or not UIErrorsFrame.GetFont then return end
    UIErrorsFrame:SetFont(self._prev.font, self._prev.size, self._prev.flags)
    if self._prev.width then UIErrorsFrame:SetWidth(self._prev.width) end
    if self._prev.height then UIErrorsFrame:SetHeight(self._prev.height) end
    RestoreFramePoints(UIErrorsFrame, self._prev.points, 0)
end

function ET:Enable()
    if self._active then return end
    self._active = true

    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:SetScript("OnEvent", function()
        self:Apply()
    end)

    self:Apply()
end

function ET:Disable()
    if not self._active then return end
    self._active = false

    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
    end

    self:Restore()
    self._prev = nil
end

function ET:ApplyConfig()
    EnsureDB()
    if NX.DB.interface.enhancedErrorText.enabled then
        self:Enable()
        self:Apply()
    else
        self:Disable()
    end
end

function ET:Init()
    EnsureDB()
    self:ApplyConfig()
end

function ET:OnSettingsChanged()
    self:ApplyConfig()
end


