-- Test: Utils/ItemInfo.lua
-- Tests for item name localization utility
require("test_helpers.WowApiMock")

describe("ItemInfo Utility", function()
    local ItemInfo

    before_each(function()
        -- Reset namespace
        _G.Craftpad = {}
        _G.Craftpad.Utils = {}

        -- Load the module
        dofile("Utils/ItemInfo.lua")
        ItemInfo = Craftpad.Utils
    end)

    after_each(function()
        ItemInfo.ClearItemCache()
    end)

    describe("GetItemName", function()
        it("returns fallback name when itemID is nil", function()
            local result = ItemInfo.GetItemName(nil, "Fallback Name")
            assert.are.equal("Fallback Name", result)
        end)

        it("returns empty string when itemID is nil and no fallback", function()
            local result = ItemInfo.GetItemName(nil)
            assert.are.equal("", result)
        end)

        it("returns cached item name on second call", function()
            -- Mock GetItemInfo to return an item name
            _G.GetItemInfo = function(itemID)
                if itemID == 12345 then
                    return "Test Item"
                end
                return nil
            end

            -- First call caches the value
            local result1 = ItemInfo.GetItemName(12345, "Fallback")
            -- Second call should return cached value
            local result2 = ItemInfo.GetItemName(12345, "Different Fallback")
            assert.are.equal(result1, result2)
            assert.are.equal("Test Item", result2)
        end)

        it("returns fallback when GetItemInfo returns nil", function()
            -- Mock GetItemInfo to return nil
            _G.GetItemInfo = function() return nil end

            local result = ItemInfo.GetItemName(99999, "Fallback Item")
            assert.are.equal("Fallback Item", result)
        end)

        it("returns item name from GetItemInfo when available", function()
            -- Mock GetItemInfo to return an item name
            _G.GetItemInfo = function(itemID)
                if itemID == 12345 then
                    return "Mocked Item Name"
                end
                return nil
            end

            local result = ItemInfo.GetItemName(12345, "Fallback")
            assert.are.equal("Mocked Item Name", result)
        end)

        it("caches item name from GetItemInfo", function()
            local callCount = 0
            _G.GetItemInfo = function(itemID)
                callCount = callCount + 1
                if itemID == 12345 then
                    return "Mocked Item"
                end
                return nil
            end

            ItemInfo.GetItemName(12345, "Fallback")
            ItemInfo.GetItemName(12345, "Fallback")

            -- GetItemInfo should only be called once due to caching
            assert.are.equal(1, callCount)
        end)
    end)

    describe("GetItemNameModern", function()
        it("uses C_Item.GetItemInfo when available", function()
            _G.C_Item = {
                GetItemInfo = function(itemID)
                    if itemID == 12345 then
                        return "Modern API Item"
                    end
                    return nil
                end
            }

            local result = ItemInfo.GetItemNameModern(12345, "Fallback")
            assert.are.equal("Modern API Item", result)
        end)

        it("falls back to classic GetItemInfo when C_Item not available", function()
            _G.C_Item = nil
            _G.GetItemInfo = function(itemID)
                if itemID == 12345 then
                    return "Classic API Item"
                end
                return nil
            end

            local result = ItemInfo.GetItemNameModern(12345, "Fallback")
            assert.are.equal("Classic API Item", result)
        end)
    end)

    describe("PreloadItemInfo", function()
        it("calls GetItemInfo to trigger async loading", function()
            local called = false
            _G.GetItemInfo = function()
                called = true
                return nil
            end

            ItemInfo.PreloadItemInfo(12345)
            assert.is_true(called)
        end)

        it("does not preload if itemID is nil", function()
            local called = false
            _G.GetItemInfo = function()
                called = true
                return nil
            end

            ItemInfo.PreloadItemInfo(nil)
            assert.is_false(called)
        end)

        it("does not preload if item is already cached", function()
            -- Cache an item first
            _G.GetItemInfo = function() return "Cached Item" end
            ItemInfo.GetItemName(12345, "Fallback")

            -- Try to preload - should not call GetItemInfo again
            local callCount = 0
            _G.GetItemInfo = function()
                callCount = callCount + 1
                return "Item"
            end

            ItemInfo.PreloadItemInfo(12345)
            assert.are.equal(0, callCount)
        end)
    end)

    describe("ClearItemCache", function()
        it("clears the cache", function()
            -- Cache an item
            _G.GetItemInfo = function() return "Cached Item" end
            local result1 = ItemInfo.GetItemName(12345, "Fallback")

            -- Clear cache
            ItemInfo.ClearItemCache()

            -- Next call should not use cached value
            _G.GetItemInfo = function() return "New Item" end
            local result2 = ItemInfo.GetItemName(12345, "Fallback")

            assert.are_not.equal(result1, result2)
            assert.are.equal("New Item", result2)
        end)
    end)

    describe("GetClientLocale", function()
        it("returns the client locale from WoW API", function()
            _G.GetLocale = function() return "frFR" end
            local result = ItemInfo.GetClientLocale()
            assert.are.equal("frFR", result)
        end)

        it("returns enUS when GetLocale returns enUS", function()
            _G.GetLocale = function() return "enUS" end
            local result = ItemInfo.GetClientLocale()
            assert.are.equal("enUS", result)
        end)
    end)
end)
