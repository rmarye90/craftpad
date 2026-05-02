-- Item Info Utility
-- Provides localized item names using WoW API based on client locale
-- This allows the addon to work in any language without hard-coded translations

if not Craftpad then Craftpad = {} end
if not Craftpad.Utils then Craftpad.Utils = {} end

-- Cache for item names to reduce API calls
local itemNameCache = {}

-- Get localized item name from item ID
-- @param itemID number The WoW item ID
-- @param fallbackName string Optional fallback name if item not found
-- @return string The localized item name in client's locale, or fallback/empty string
function Craftpad.Utils.GetItemName(itemID, fallbackName)
    if not itemID then
        return fallbackName or ""
    end

    -- Check cache first
    if itemNameCache[itemID] then
        return itemNameCache[itemID]
    end

    -- Try to get item info from WoW API
    -- GetItemInfo returns: name, link, quality, iLevel, reqLevel, class, subclass,
    -- maxStack, equipSlot, texture, vendorPrice, classID, subclassID, bindType,
    -- expacID, setID, isCraftingReagent
    local itemName = GetItemInfo(itemID)

    if itemName then
        -- Cache the result
        itemNameCache[itemID] = itemName
        return itemName
    end

    -- If item info is not available yet (not in cache), WoW will load it asynchronously
    -- Return the fallback name for now
    return fallbackName or ""
end

-- Get localized item name using modern Item API (TWW)
-- Use this for compatibility with The War Within and newer expansions
-- For general use, GetItemName() works with classic API which is widely supported
-- @param itemID number The WoW item ID
-- @param fallbackName string Optional fallback name if item not found
-- @return string The localized item name in client's locale, or fallback/empty string
function Craftpad.Utils.GetItemNameModern(itemID, fallbackName)
    if not itemID then
        return fallbackName or ""
    end

    -- Check cache first
    if itemNameCache[itemID] then
        return itemNameCache[itemID]
    end

    -- Try modern API first (The War Within)
    if C_Item and C_Item.GetItemInfo then
        local itemName = C_Item.GetItemInfo(itemID)
        if itemName then
            itemNameCache[itemID] = itemName
            return itemName
        end
    end

    -- Fallback to classic API
    local itemName = GetItemInfo(itemID)
    if itemName then
        itemNameCache[itemID] = itemName
        return itemName
    end

    -- Return fallback
    return fallbackName or ""
end

-- Request item info to be loaded (for preloading)
-- This triggers WoW to load item data asynchronously
function Craftpad.Utils.PreloadItemInfo(itemID)
    if not itemID or itemNameCache[itemID] then
        return
    end

    -- Calling GetItemInfo with an ID triggers async loading
    GetItemInfo(itemID)
end

-- Clear the cache (useful for testing or after major game updates)
function Craftpad.Utils.ClearItemCache()
    itemNameCache = {}
end

-- Get the current client locale
-- Returns locale string like "enUS", "frFR", "deDE", etc.
function Craftpad.Utils.GetClientLocale()
    return GetLocale()
end
