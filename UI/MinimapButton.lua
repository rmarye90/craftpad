-- Minimap Button
function Craftpad.UI.CreateMinimapButton()
    local button = CreateFrame("Button", "CraftpadMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 1)
    button:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    -- Icon text (temporary until we add a texture)
    local icon = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetText("CP")
    icon:SetTextColor(1, 0.82, 0, 1) -- Gold color

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Craftpad", 1, 1, 1)
        GameTooltip:AddLine("Click to toggle housing items list", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handler
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            Craftpad.UI.ToggleMainFrame()
        end
    end)

    -- Make it draggable around minimap
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isMoving = true
    end)

    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isMoving = false
    end)

    button:SetScript("OnUpdate", function(self)
        if self.isMoving then
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.atan2(py - my, px - mx)
            local x = math.cos(angle) * 80
            local y = math.sin(angle) * 80

            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", x, y)
        end
    end)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    Craftpad.UI.MinimapButton = button
    return button
end

-- Initialize minimap button on load
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    Craftpad.UI.CreateMinimapButton()
end)
