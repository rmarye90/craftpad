-- Craftpad Core
-- Global namespace
Craftpad = {}
Craftpad.Version = "1.0.0"
Craftpad.Data = {}
Craftpad.UI = {}
Craftpad.Search = {}

-- Warband bank constants (TWW)
local WARBAND_BANK_BAG_COUNT = 4
local WARBAND_BANK_START = Enum.BagIndex.AccountBankTab_1 or 13
local WARBAND_BANK_END = WARBAND_BANK_START + WARBAND_BANK_BAG_COUNT

-- Inventory event handler
local function handle_inventory_event(_, event, bagID)
    -- BAG_UPDATE includes bagID - only process warband bank bags
    if event == "BAG_UPDATE" then
        if not bagID or bagID < WARBAND_BANK_START or bagID > WARBAND_BANK_END then
            return
        end
    end

    -- Don't update during combat
    if UnitAffectingCombat("player") then
        return
    end

    -- Only update if frame exists, is shown, and has selected item
    if Craftpad.UI.MainFrame and Craftpad.UI.MainFrame:IsShown() and Craftpad.UI.MainFrame.selectedItemData then
        Craftpad.UI.UpdateDetailPanel(Craftpad.UI.MainFrame.selectedItemData)
    end
end

-- Event Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Craftpad" then
        print("Craftpad: Addon loaded (v" .. Craftpad.Version .. ")")

        -- Create inventory event frame (after addon is fully loaded)
        local success, err = pcall(function()
            Craftpad.InventoryEventFrame = CreateFrame("Frame")
            Craftpad.InventoryEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
            Craftpad.InventoryEventFrame:RegisterEvent("BAG_UPDATE")
            Craftpad.InventoryEventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
            Craftpad.InventoryEventFrame:SetScript("OnEvent", handle_inventory_event)
        end)

        if not success then
            print("Craftpad ERROR: Failed to create inventory event frame: " .. tostring(err))
        end

    elseif event == "PLAYER_LOGIN" then
        print("Craftpad: Type /cp to open housing items list")
    end
end)
