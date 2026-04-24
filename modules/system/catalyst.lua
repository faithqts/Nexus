local NX = Nexus

NX.Catalyst = NX.Catalyst or {}

local M = NX.Catalyst

local INTERACTION_TYPE_CATALYST = 44
local BUTTON_LABEL = "Catalyst Now"
local BUTTON_WIDTH = 120
local BUTTON_HEIGHT = 28
local BUTTON_GAP = 8
local BUTTON_EXTRA_LEFT = 20
local BUTTON_EXTRA_DOWN = -1
local TRANSFORM_LABEL = "Transform"

local function NormalizeLabel(text)
    local s = tostring(text or "")
    s = string.lower(s)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function CollectDescendantButtons(frame, out)
    if not frame or not frame.GetChildren then
        return
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if child and child.GetObjectType and child:GetObjectType() == "Button" then
            out[#out + 1] = child
        end
        CollectDescendantButtons(child, out)
    end
end

function M:GetTransformButton()
    if not ItemInteractionFrame then
        return nil
    end

    local candidates = {
        ItemInteractionFrame.CompleteButton,
        ItemInteractionFrame.Button,
        ItemInteractionFrame.ActionButton,
        _G.ItemInteractionFrameCompleteButton,
        _G.ItemInteractionFrameButton,
    }

    for _, button in ipairs(candidates) do
        if button and button.SetPoint and button.GetCenter then
            return button
        end
    end

    -- Fallback for client/template variations: find a button with Transform text.
    local allButtons = {}
    CollectDescendantButtons(ItemInteractionFrame, allButtons)

    local expectedLabel = NormalizeLabel(_G.ITEM_UPGRADE_FRAME_UPGRADE or TRANSFORM_LABEL)
    local fallbackLabel = NormalizeLabel(TRANSFORM_LABEL)

    for _, button in ipairs(allButtons) do
        if button ~= self.button and button.GetText then
            local label = NormalizeLabel(button:GetText())
            if label == expectedLabel or label == fallbackLabel then
                return button
            end
        end
    end

    return nil
end

function M:PositionButton(button)
    if not button or not ItemInteractionFrame then
        return
    end

    button:ClearAllPoints()

    local transformButton = self:GetTransformButton()
    if transformButton then
        button:SetPoint("RIGHT", transformButton, "LEFT", -(BUTTON_GAP + BUTTON_EXTRA_LEFT), -BUTTON_EXTRA_DOWN)
        return
    end

    button:SetPoint("BOTTOMLEFT", ItemInteractionFrame, "BOTTOMLEFT", 24 - BUTTON_EXTRA_LEFT, 8 - BUTTON_EXTRA_DOWN)
end

function M:EnsureDB()
    NX.DB.system = NX.DB.system or {}
    NX.DB.system.catalyst = NX.DB.system.catalyst or {}

    local db = NX.DB.system.catalyst
    if db.enabled == nil then
        db.enabled = false
    end

    return db
end

function M:IsEnabled()
    return self:EnsureDB().enabled == true
end

function M:IsCatalystInteraction(interactionType)
    local currentType = interactionType

    if currentType == nil and C_PlayerInteractionManager and C_PlayerInteractionManager.GetCurrentInteractionType then
        local ok, value = pcall(C_PlayerInteractionManager.GetCurrentInteractionType)
        if ok then
            currentType = value
        end
    end

    return currentType == INTERACTION_TYPE_CATALYST
end

function M:EnsureButton()
    if self.button then
        return self.button
    end

    if not ItemInteractionFrame then
        return nil
    end

    local button = CreateFrame("Button", nil, ItemInteractionFrame, "UIPanelButtonTemplate")
    button:SetText(BUTTON_LABEL)
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    self:PositionButton(button)

    button:SetScript("OnClick", function()
        if ItemInteractionFrame and ItemInteractionFrame.CompleteItemInteraction then
            ItemInteractionFrame:CompleteItemInteraction()
        end
    end)

    button:Hide()
    self.button = button
    return button
end

function M:ShowButton()
    local button = self:EnsureButton()
    if button then
        self:PositionButton(button)
        button:Show()
    end
end

function M:HideButton()
    if self.button then
        self.button:Hide()
    end
end

function M:RefreshVisibility(interactionType)
    if not self:IsEnabled() then
        self:HideButton()
        return
    end

    if self:IsCatalystInteraction(interactionType) then
        self:ShowButton()
    else
        self:HideButton()
    end
end

function M:OnEvent(event, interactionType)
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        self:RefreshVisibility(interactionType)
        return
    end

    if event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        self:HideButton()
    end
end

function M:OnSettingsChanged()
    self:RefreshVisibility(nil)
end

function M:Init()
    self:EnsureDB()

    if not self.frame then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
        frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
        frame:SetScript("OnEvent", function(_, event, ...)
            M:OnEvent(event, ...)
        end)
        self.frame = frame
    end

    self:RefreshVisibility(nil)
end
