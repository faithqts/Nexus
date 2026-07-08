local NX = Nexus
NX.MouseCursor = NX.MouseCursor or {}

local M = NX.MouseCursor
local FN = NX.Functions

local ADDON = tostring(NX.name or "Nexus")
local DEFAULT_TEXTURE = "circle.tga"
local TEXTURE_PATHS = {
    ["circle.tga"] = "Interface\\AddOns\\" .. ADDON .. "\\media\\textures\\mouse\\circle.tga",
    ["spiked.tga"] = "Interface\\AddOns\\" .. ADDON .. "\\media\\textures\\mouse\\spiked.tga",
}

local cursorFrame
local runtimeConfig
local accum = 0
local lastX, lastY
local effectTime = 0

local PULSE_SCALE_DELTA = 0.08
local FLASH_MIN_MULT = 0.35

local DEFAULT_PULSE_SPEED_HZ = 2.2
local DEFAULT_FLASH_SPEED_HZ = 4.0
local DEFAULT_ROTATE_RPS = 0.5

local function Clamp01(v)
    return FN:ClampNumber(v, 0, 1)
end

local function NormalizeHexColor(hex)
    if type(hex) ~= "string" then
        return "#FFFFFF"
    end

    local text = string.upper(hex:gsub("%s+", ""))
    if not text:match("^#") then
        text = "#" .. text
    end

    local n = #text - 1
    if n ~= 6 and n ~= 8 then
        return "#FFFFFF"
    end

    if not text:match("^#%x+$") then
        return "#FFFFFF"
    end

    return text
end

local function ParseHexColor(hex)
    local text = NormalizeHexColor(hex):gsub("#", "")

    local r = tonumber(text:sub(1, 2), 16) or 255
    local g = tonumber(text:sub(3, 4), 16) or 255
    local b = tonumber(text:sub(5, 6), 16) or 255
    local a = 255

    if #text == 8 then
        a = tonumber(text:sub(7, 8), 16) or 255
    end

    return r / 255, g / 255, b / 255, a / 255
end

local function NormalizeTextureName(textureName)
    local name = string.lower(tostring(textureName or ""))
    name = string.match(name, "^%s*(.-)%s*$") or ""
    if name == "circle" then name = "circle.tga" end
    if name == "spiked" then name = "spiked.tga" end
    if TEXTURE_PATHS[name] then
        return name
    end
    return DEFAULT_TEXTURE
end

function M:EnsureDB()
    NX.DB.combat = NX.DB.combat or {}
    NX.DB.combat.mouseCursor = NX.DB.combat.mouseCursor or {}

    local db = NX.DB.combat.mouseCursor
    if db.enabled == nil then db.enabled = false end
    if db.size == nil then db.size = 32 end
    if db.alpha == nil then db.alpha = 1.0 end
    if db.strata == nil then db.strata = "TOOLTIP" end
    if db.color == nil then db.color = "#FFFFFF" end
    if db.hz == nil then db.hz = 120 end
    if db.texture == nil then db.texture = DEFAULT_TEXTURE end
    if db.animationsEnabled == nil then db.animationsEnabled = false end
    if db.pulsing == nil then db.pulsing = false end
    if db.flashing == nil then db.flashing = false end
    if db.rotating == nil then db.rotating = false end
    if db.pulseSpeedHz == nil then db.pulseSpeedHz = DEFAULT_PULSE_SPEED_HZ end
    if db.flashSpeedHz == nil then db.flashSpeedHz = DEFAULT_FLASH_SPEED_HZ end
    if db.rotateRps == nil then db.rotateRps = DEFAULT_ROTATE_RPS end

    db.enabled = db.enabled and true or false
    db.size = math.floor(FN:ClampNumber(tonumber(db.size) or 32, 0, 100) / 2 + 0.5) * 2
    db.alpha = Clamp01(tonumber(db.alpha) or 1.0)
    db.strata = tostring(db.strata or "TOOLTIP")
    db.color = NormalizeHexColor(db.color)
    db.hz = math.floor(FN:ClampNumber(tonumber(db.hz) or 120, 30, 600) / 5 + 0.5) * 5
    db.texture = NormalizeTextureName(db.texture)
    db.animationsEnabled = db.animationsEnabled and true or false
    db.pulsing = db.pulsing and true or false
    db.flashing = db.flashing and true or false
    db.rotating = db.rotating and true or false
    db.pulseSpeedHz = FN:ClampNumber(tonumber(db.pulseSpeedHz) or DEFAULT_PULSE_SPEED_HZ, 0.2, 8.0)
    db.flashSpeedHz = FN:ClampNumber(tonumber(db.flashSpeedHz) or DEFAULT_FLASH_SPEED_HZ, 0.2, 12.0)
    db.rotateRps = FN:ClampNumber(tonumber(db.rotateRps) or DEFAULT_ROTATE_RPS, 0.1, 5.0)

    return db
end

local function BuildRuntimeConfig(db)
    local r, g, b, aHex = ParseHexColor(db.color)
    local alpha = Clamp01((db.alpha or 1.0) * (aHex or 1.0))
    local hz = math.floor(FN:ClampNumber(tonumber(db.hz) or 120, 30, 600) / 5 + 0.5) * 5
    local textureName = NormalizeTextureName(db.texture)

    return {
        enabled = db.enabled == true,
        size = db.size,
        alpha = alpha,
        strata = db.strata,
        textureName = textureName,
        texturePath = TEXTURE_PATHS[textureName] or TEXTURE_PATHS[DEFAULT_TEXTURE],
        hz = hz,
        step = 1 / hz,
        animationsEnabled = db.animationsEnabled == true,
        pulsing = db.pulsing == true,
        flashing = db.flashing == true,
        rotating = db.rotating == true,
        pulseSpeedHz = db.pulseSpeedHz,
        flashSpeedHz = db.flashSpeedHz,
        rotateRps = db.rotateRps,
        r = r,
        g = g,
        b = b,
    }
end

function M:RefreshConfig()
    runtimeConfig = BuildRuntimeConfig(self:EnsureDB())
    return runtimeConfig
end

function M:ApplySettings()
    if not cursorFrame then
        return
    end

    local cfg = runtimeConfig or self:RefreshConfig()
    cursorFrame:SetSize(cfg.size, cfg.size)
    cursorFrame:SetFrameStrata(cfg.strata)

    cursorFrame.tex:SetTexture(cfg.texturePath)
    cursorFrame.tex:ClearAllPoints()
    cursorFrame.tex:SetPoint("CENTER", cursorFrame, "CENTER", 0, 0)
    cursorFrame.tex:SetSize(cfg.size, cfg.size)

    cursorFrame.tex:SetVertexColor(cfg.r, cfg.g, cfg.b, cfg.alpha)
    cursorFrame.tex:SetRotation(0)
end

function M:ApplyVisualEffects(elapsed)
    if not cursorFrame or not cursorFrame.tex then
        return
    end

    local cfg = runtimeConfig or self:RefreshConfig()
    if not cfg.animationsEnabled then
        return
    end

    effectTime = effectTime + (tonumber(elapsed) or 0)

    local finalSize = cfg.size
    if cfg.pulsing then
        local pulseWave = math.sin(effectTime * math.pi * 2 * cfg.pulseSpeedHz)
        finalSize = cfg.size * (1 + (PULSE_SCALE_DELTA * pulseWave))
    end

    local finalAlpha = cfg.alpha
    if cfg.flashing then
        local flashWave = 0.5 + 0.5 * math.sin(effectTime * math.pi * 2 * cfg.flashSpeedHz)
        local flashMult = FLASH_MIN_MULT + ((1 - FLASH_MIN_MULT) * flashWave)
        finalAlpha = Clamp01(cfg.alpha * flashMult)
    end

    cursorFrame.tex:SetSize(finalSize, finalSize)
    cursorFrame.tex:SetVertexColor(cfg.r, cfg.g, cfg.b, finalAlpha)

    if cfg.rotating then
        local angle = (effectTime * math.pi * 2 * cfg.rotateRps) % (math.pi * 2)
        cursorFrame.tex:SetRotation(angle)
    else
        cursorFrame.tex:SetRotation(0)
    end
end

function M:EnsureFrame()
    if cursorFrame then
        return
    end

    cursorFrame = CreateFrame("Frame", nil, UIParent)
    cursorFrame:SetClampedToScreen(true)
    cursorFrame:EnableMouse(false)
    cursorFrame:SetFrameStrata("TOOLTIP")
    cursorFrame:SetFrameLevel(9999)

    cursorFrame:ClearAllPoints()
    cursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 0, 0)

    local tex = cursorFrame:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(cursorFrame)
    tex:SetBlendMode("BLEND")
    cursorFrame.tex = tex

    self:ApplySettings()
end

function M:UpdatePosition(force)
    local cfg = runtimeConfig or self:RefreshConfig()
    if not cursorFrame or not cfg.enabled then
        return
    end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local px = (x / scale)
    local py = (y / scale)

    if not force and lastX and lastY and math.abs(px - lastX) < 0.01 and math.abs(py - lastY) < 0.01 then
        return
    end

    lastX, lastY = px, py
    cursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
end

local function CursorOnUpdate(_, elapsed)
    local cfg = runtimeConfig
    if not cfg or not cfg.enabled then
        return
    end

    if cfg.animationsEnabled then
        M:ApplyVisualEffects(elapsed)
    end

    accum = accum + elapsed
    if accum < cfg.step then
        return
    end
    accum = accum % cfg.step

    M:UpdatePosition(false)
end

function M:SetOnUpdateEnabled(enabled)
    if not cursorFrame then
        return
    end

    if enabled then
        cursorFrame:SetScript("OnUpdate", CursorOnUpdate)
    else
        cursorFrame:SetScript("OnUpdate", nil)
        accum = 0
    end
end

function M:SetEnabled(on)
    local db = self:EnsureDB()
    db.enabled = on and true or false
    self:RefreshConfig()

    self:EnsureFrame()
    if db.enabled then
        cursorFrame:Show()
        self:SetOnUpdateEnabled(true)
        self:UpdatePosition(true)
    else
        self:SetOnUpdateEnabled(false)
        cursorFrame:Hide()
    end
end

function M:OnSettingsChanged()
    self:RefreshConfig()
    self:EnsureFrame()
    self:ApplySettings()
    if runtimeConfig and runtimeConfig.animationsEnabled then
        self:ApplyVisualEffects(0)
    end
    self:SetEnabled(runtimeConfig and runtimeConfig.enabled)
end

function M:HandleNxSlash(msg)
    local text = string.match(tostring(msg or ""), "^%s*(.-)%s*$") or ""
    local cmd, rest = string.match(text, "^(%S+)%s*(.-)%s*$")
    cmd = string.lower(tostring(cmd or ""))
    rest = tostring(rest or "")

    local db = self:EnsureDB()

    if cmd == "" or cmd == "help" or cmd == "?" then
        print("/mouse on|off")
        print("/mouse size <pixels>")
        print("/mouse alpha <0-1>")
        print("/mouse color #RRGGBB[AA]")
        print("/mouse hz <30-600>")
        print("/mouse texture <circle|spiked>")
        return true
    end

    if cmd == "on" then
        self:SetEnabled(true)
        print("Mouse Cursor: enabled")
        return true
    end

    if cmd == "off" then
        self:SetEnabled(false)
        print("Mouse Cursor: disabled")
        return true
    end

    if cmd == "size" then
        local value = tonumber(rest)
        if not value then
            print("Usage: /mouse size <0-100>")
            return true
        end
        db.size = math.floor(FN:ClampNumber(value, 0, 100) / 2 + 0.5) * 2
        self:OnSettingsChanged()
        print("Mouse Cursor: size = " .. tostring(db.size))
        return true
    end

    if cmd == "alpha" then
        local value = tonumber(rest)
        if not value then
            print("Usage: /mouse alpha <0-1>")
            return true
        end
        db.alpha = Clamp01(value)
        self:OnSettingsChanged()
        print(string.format("Mouse Cursor: alpha = %.1f", db.alpha))
        return true
    end

    if cmd == "color" then
        local hex = string.match(rest, "^(#?[%x]+)$")
        if not hex then
            print("Usage: /mouse color #RRGGBB or #RRGGBBAA")
            return true
        end
        if not string.match(hex, "^#") then
            hex = "#" .. hex
        end
        local len = #hex - 1
        if len ~= 6 and len ~= 8 then
            print("Usage: /mouse color #RRGGBB or #RRGGBBAA")
            return true
        end
        db.color = NormalizeHexColor(hex)
        self:OnSettingsChanged()
        print("Mouse Cursor: color = " .. tostring(db.color))
        return true
    end

    if cmd == "hz" then
        local value = tonumber(rest)
        if not value then
            print("Usage: /mouse hz <30-600>")
            return true
        end
        db.hz = math.floor(FN:ClampNumber(value, 30, 600) / 5 + 0.5) * 5
        self:OnSettingsChanged()
        print("Mouse Cursor: hz = " .. tostring(db.hz))
        return true
    end

    if cmd == "texture" then
        local value = NormalizeTextureName(rest)
        db.texture = value
        self:OnSettingsChanged()
        print("Mouse Cursor: texture = " .. tostring(db.texture))
        return true
    end

    print("Usage: /mouse help")
    return true
end

function M:Init()
    self:RefreshConfig()
    self:EnsureFrame()

    self:ApplySettings()
    self:SetEnabled(runtimeConfig and runtimeConfig.enabled)
end

SLASH_NEXUS_MOUSECURSOR1 = "/mouse"
SlashCmdList["NEXUS_MOUSECURSOR"] = function(msg)
    if NX.MouseCursor and NX.MouseCursor.HandleNxSlash then
        NX.MouseCursor:HandleNxSlash(msg)
    end
end
