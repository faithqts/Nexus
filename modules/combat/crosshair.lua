local NX = Nexus
NX.Crosshair = NX.Crosshair or {}
local XH = NX.Crosshair
local FN = NX.Functions

local TEX = "Interface/Buttons/WHITE8x8"

local COLORS = {
    { hex = "#FF0000", name = "Red",                r = 255, g = 0,   b = 0   },
    { hex = "#FF8000", name = "Orange",             r = 255, g = 128, b = 0   },
    { hex = "#FFFF00", name = "Yellow",             r = 255, g = 255, b = 0   },
    { hex = "#80FF00", name = "Lime Green",         r = 128, g = 255, b = 0   },
    { hex = "#00FF00", name = "Green",              r = 0,   g = 255, b = 0   },
    { hex = "#00FF80", name = "Spring Green",       r = 0,   g = 255, b = 128 },
    { hex = "#00FFFF", name = "Cyan",               r = 0,   g = 255, b = 255 },
    { hex = "#0080FF", name = "Dodge Blue",         r = 0,   g = 128, b = 255 },
    { hex = "#0000FF", name = "Blue",               r = 0,   g = 0,   b = 255 },
    { hex = "#8000FF", name = "Purple",             r = 128, g = 0,   b = 255 },
    { hex = "#FF00FF", name = "Violet",             r = 255, g = 0,   b = 255 },
    { hex = "#FF0080", name = "Magenta",            r = 255, g = 0,   b = 128 },
    { hex = "#FF8888", name = "Coral",              r = 255, g = 136, b = 136 },
    { hex = "#FFCC88", name = "Light Salmon",       r = 255, g = 204, b = 136 },
    { hex = "#FFFF88", name = "Pale Yellow",        r = 255, g = 255, b = 136 },
    { hex = "#CCFF88", name = "Pale Green",         r = 204, g = 255, b = 136 },
    { hex = "#88FF88", name = "Pale Turquoise",     r = 136, g = 255, b = 136 },
    { hex = "#88FFCC", name = "Aquamarine",         r = 136, g = 255, b = 204 },
    { hex = "#88FFFF", name = "Light Cyan",         r = 136, g = 255, b = 255 },
    { hex = "#88CCFF", name = "Sky Blue",           r = 136, g = 204, b = 255 },
    { hex = "#8888FF", name = "Slate Blue",         r = 136, g = 136, b = 255 },
    { hex = "#CC88FF", name = "Medium Purple",      r = 204, g = 136, b = 255 },
    { hex = "#FF88FF", name = "Orchid",             r = 255, g = 136, b = 255 },
    { hex = "#FF88CC", name = "Light Pink",         r = 255, g = 136, b = 204 },

    { hex = "#FFBBBB", name = "Light Salmon Pink",  r = 255, g = 187, b = 187 },
    { hex = "#FFDDBB", name = "Peach",              r = 255, g = 221, b = 187 },
    { hex = "#FFFFBB", name = "Pale Yellow (Soft)", r = 255, g = 255, b = 187 },
    { hex = "#DDFFBB", name = "Pale Green (Soft)",  r = 221, g = 255, b = 187 },
    { hex = "#BBFFBB", name = "Pale Turquoise (Soft)", r = 187, g = 255, b = 187 },
    { hex = "#BBFFDD", name = "Light Sea Green",    r = 187, g = 255, b = 221 },
    { hex = "#BBFFFF", name = "Light Cyan (Soft)",  r = 187, g = 255, b = 255 },
    { hex = "#BBDDFF", name = "Light Sky Blue",     r = 187, g = 221, b = 255 },
    { hex = "#BBBBFF", name = "Light Steel Blue",   r = 187, g = 187, b = 255 },
    { hex = "#DDBBFF", name = "Lavender",           r = 221, g = 187, b = 255 },
    { hex = "#FFBBFF", name = "Light Pink (Soft)",  r = 255, g = 187, b = 255 },
    { hex = "#FFBBDD", name = "Misty Rose",         r = 255, g = 187, b = 221 },

    { hex = "#AA5555", name = "Indian Red",         r = 170, g = 85,  b = 85  },
    { hex = "#AA7755", name = "Copper",             r = 170, g = 119, b = 85  },
    { hex = "#AAAA55", name = "Olive Drab",         r = 170, g = 170, b = 85  },
    { hex = "#77AA55", name = "Dark Olive Green",   r = 119, g = 170, b = 85  },
    { hex = "#55AA55", name = "Forest Green",       r = 85,  g = 170, b = 85  },
    { hex = "#55AA77", name = "Cadet Blue",         r = 85,  g = 170, b = 119 },
    { hex = "#55AAAA", name = "Medium Aquamarine",  r = 85,  g = 170, b = 170 },
    { hex = "#5577AA", name = "Light Slate Gray",   r = 85,  g = 119, b = 170 },
    { hex = "#5555AA", name = "Medium Slate Blue",  r = 85,  g = 85,  b = 170 },
    { hex = "#7755AA", name = "Slate Blue (Deep)",  r = 119, g = 85,  b = 170 },
    { hex = "#AA55AA", name = "Medium Orchid",      r = 170, g = 85,  b = 170 },
    { hex = "#AA5577", name = "Rose",               r = 170, g = 85,  b = 119 },
}

local function NormalizeHex(hex)
    if type(hex) ~= "string" then return "#FFFFFF" end
    hex = hex:gsub("%s+", ""):upper()
    if not hex:match("^#") then hex = "#" .. hex end
    if #hex == 7 or #hex == 9 then return hex end
    return "#FFFFFF"
end

local function HexToRGB01(hex)
    hex = NormalizeHex(hex):gsub("#", "")

    if #hex == 6 then
        local r = tonumber(hex:sub(1,2), 16) or 255
        local g = tonumber(hex:sub(3,4), 16) or 255
        local b = tonumber(hex:sub(5,6), 16) or 255
        return r/255, g/255, b/255
    end
    if #hex == 8 then
        local r = tonumber(hex:sub(3,4), 16) or 255
        local g = tonumber(hex:sub(5,6), 16) or 255
        local b = tonumber(hex:sub(7,8), 16) or 255
        return r/255, g/255, b/255
    end
    return 1, 1, 1
end

local function EnsureDB()
    if not NX.DB then return nil end
    NX.DB.combat.crosshair = NX.DB.combat.crosshair or {}
    return NX.DB.combat.crosshair
end

local frame
local hTex, vTex

local function CreateUI()
    if frame then return end

    frame = CreateFrame("Frame", "NEXUSCrosshairFrame", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(9999)
    frame:EnableMouse(false)
    frame:SetClampedToScreen(false)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(256, 256)

    hTex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    vTex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    hTex:SetTexture(TEX)
    vTex:SetTexture(TEX)
    hTex:SetBlendMode("BLEND")
    vTex:SetBlendMode("BLEND")
end

function XH:ApplyConfig()
    local db = EnsureDB()
    if not db then return end

    CreateUI()

    local show = db.show and true or false
    local size = FN:ClampNumber(tonumber(db.size) or 18, 0, 48)
    local thickness = FN:ClampNumber(tonumber(db.thickness) or 2, 1, 10)
    local alpha = FN:ClampNumber(tonumber(db.alpha) or 1.0, 0, 1)

    local color = NormalizeHex(db.color)
    local r, g, b = HexToRGB01(color)

    hTex:ClearAllPoints()
    hTex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    hTex:SetSize(size, thickness)
    hTex:SetVertexColor(r, g, b, alpha)

    vTex:ClearAllPoints()
    vTex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    vTex:SetSize(thickness, size)
    vTex:SetVertexColor(r, g, b, alpha)

    frame:SetShown(show)
end

function XH:OnSettingsChanged()
    self:ApplyConfig()
end

function XH:GetColorList()
    return COLORS
end

function XH:Init()
    EnsureDB()
    self:ApplyConfig()
end


