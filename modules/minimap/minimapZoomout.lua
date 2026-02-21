local NX = Nexus
NX.Minimap = NX.Minimap or {}

local M = NX.Minimap
local FN = NX.Functions

local DEFAULT_DELAY_SECONDS = 3
local DEFAULT_TARGET_ZOOM = 0

local frame = nil
local pendingTimer = nil

function M:EnsureDB()
    NX.DB.interface.minimap = NX.DB.interface.minimap or {}
    local db = NX.DB.interface.minimap

    if db.zoomoutEnabled == nil then db.zoomoutEnabled = false end
    if db.zoomoutDelaySeconds == nil then db.zoomoutDelaySeconds = DEFAULT_DELAY_SECONDS end
    if db.zoomoutTargetZoom == nil then db.zoomoutTargetZoom = DEFAULT_TARGET_ZOOM end

    db.zoomoutEnabled = db.zoomoutEnabled and true or false
    db.zoomoutDelaySeconds = FN:ClampNumber(db.zoomoutDelaySeconds, 0.1, 30)
    db.zoomoutTargetZoom = math.floor(FN:ClampNumber(db.zoomoutTargetZoom, 0, 5) + 0.5)

    return db
end

function M:CancelPendingTimer()
    if pendingTimer and pendingTimer.Cancel then
        pendingTimer:Cancel()
    end
    pendingTimer = nil
end

function M:ApplyZoomoutNow()
    local db = self:EnsureDB()
    if not db.zoomoutEnabled then
        return
    end

    if not Minimap or not Minimap.GetZoom or not Minimap.SetZoom then
        return
    end

    local currentZoom = Minimap:GetZoom()
    if currentZoom == db.zoomoutTargetZoom then
        return
    end

    Minimap:SetZoom(db.zoomoutTargetZoom)
end

function M:HandleZoomChanged()
    local db = self:EnsureDB()
    if not db.zoomoutEnabled then
        return
    end

    self:CancelPendingTimer()

    pendingTimer = C_Timer.NewTimer(db.zoomoutDelaySeconds, function()
        pendingTimer = nil
        M:ApplyZoomoutNow()
    end)
end

function M:OnSettingsChanged()
    local db = self:EnsureDB()
    if not db.zoomoutEnabled then
        self:CancelPendingTimer()
    end
end

function M:ToggleZoomout()
    local db = self:EnsureDB()
    db.zoomoutEnabled = not db.zoomoutEnabled
    self:OnSettingsChanged()
    print("|cffffd200Nexus:|r Minimap Auto Zoomout " .. (db.zoomoutEnabled and "enabled." or "disabled."))
end

function M:HandleNxSlash(msg)
    local text = string.lower(tostring(msg or ""))
    text = string.match(text, "^%s*(.-)%s*$") or ""

    if text == "" or text == "toggle" then
        self:ToggleZoomout()
        return true
    end

    local cmd, rest = string.match(text, "^(%S+)%s*(.-)%s*$")
    cmd = tostring(cmd or "")
    rest = tostring(rest or "")

    local db = self:EnsureDB()

    if cmd == "on" or cmd == "enable" or cmd == "enabled" then
        db.zoomoutEnabled = true
        self:OnSettingsChanged()
        print("|cffffd200Nexus:|r Minimap Auto Zoomout enabled.")
        return true
    end

    if cmd == "off" or cmd == "disable" or cmd == "disabled" then
        db.zoomoutEnabled = false
        self:OnSettingsChanged()
        print("|cffffd200Nexus:|r Minimap Auto Zoomout disabled.")
        return true
    end

    if cmd == "test" then
        self:ApplyZoomoutNow()
        print("|cffffd200Nexus:|r Minimap Auto Zoomout test executed.")
        return true
    end

    if cmd == "delay" then
        local value = tonumber(rest)
        if not value then
            print("|cffffd200Nexus:|r Invalid delay. Use: /nx minimap delay <1-30>")
            return true
        end
        db.zoomoutDelaySeconds = FN:ClampNumber(value, 1, 30)
        print("|cffffd200Nexus:|r Minimap Auto Zoomout delay = " .. tostring(db.zoomoutDelaySeconds) .. "s")
        return true
    end

    if cmd == "target" then
        local value = tonumber(rest)
        if not value then
            print("|cffffd200Nexus:|r Invalid target. Use: /nx minimap target <0-5>")
            return true
        end
        db.zoomoutTargetZoom = math.floor(FN:ClampNumber(value, 0, 5) + 0.5)
        print("|cffffd200Nexus:|r Minimap Auto Zoomout target = " .. tostring(db.zoomoutTargetZoom))
        return true
    end

    if cmd == "help" or cmd == "?" then
        print("|cffffd200Nexus:|r /nx minimap, /nx minimap on, /nx minimap off, /nx minimap test")
        print("|cffffd200Nexus:|r /nx minimap delay <1-30>, /nx minimap target <0-5>")
        return true
    end

    print("|cffffd200Nexus:|r Unknown /nx minimap command. Use: /nx minimap help")
    return true
end

function M:Init()
    self:EnsureDB()

    if frame then
        return
    end

    frame = CreateFrame("Frame")
    frame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
    frame:SetScript("OnEvent", function(_, event)
        if event == "MINIMAP_UPDATE_ZOOM" then
            M:HandleZoomChanged()
        end
    end)
end

