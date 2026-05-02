-- Test: Utils/Localization.lua
-- Tests for category and profession localization
require("test_helpers.WowApiMock")

describe("Localization Utility", function()
    local L10n

    before_each(function()
        -- Reset namespace
        _G.Craftpad = {}
        _G.Craftpad.L10n = {}
    end)

    describe("GetCategory", function()
        it("returns English category when locale is enUS", function()
            _G.GetLocale = function() return "enUS" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("Miscellaneous")
            assert.are.equal("Miscellaneous", result)
        end)

        it("returns French category when locale is frFR", function()
            _G.GetLocale = function() return "frFR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("Miscellaneous")
            assert.are.equal("Divers", result)
        end)

        it("returns German category when locale is deDE", function()
            _G.GetLocale = function() return "deDE" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("Furniture")
            assert.are.equal("Möbel", result)
        end)

        it("returns Spanish category when locale is esES", function()
            _G.GetLocale = function() return "esES" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("Tables")
            assert.are.equal("Mesas", result)
        end)

        it("returns English as fallback for unknown locale", function()
            _G.GetLocale = function() return "ptBR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("Chairs")
            assert.are.equal("Chairs", result)
        end)

        it("returns empty string when input is nil", function()
            _G.GetLocale = function() return "enUS" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory(nil)
            assert.are.equal("", result)
        end)

        it("returns English for untranslated category", function()
            _G.GetLocale = function() return "frFR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetCategory("UnknownCategory")
            assert.are.equal("UnknownCategory", result)
        end)
    end)

    describe("GetProfession", function()
        it("returns English profession when locale is enUS", function()
            _G.GetLocale = function() return "enUS" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Cataclysm Inscription")
            assert.are.equal("Cataclysm Inscription", result)
        end)

        it("returns French profession when locale is frFR", function()
            _G.GetLocale = function() return "frFR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Cataclysm Inscription")
            assert.are.equal("Calligraphie (Cataclysm)", result)
        end)

        it("returns German profession when locale is deDE", function()
            _G.GetLocale = function() return "deDE" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Outland Tailoring")
            assert.are.equal("Schneiderei (Scherbenwelt)", result)
        end)

        it("returns Spanish profession when locale is esES", function()
            _G.GetLocale = function() return "esES" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Legion Tailoring")
            assert.are.equal("Sastrería (Legión)", result)
        end)

        it("returns English as fallback for unknown locale", function()
            _G.GetLocale = function() return "ptBR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Northrend Enchanting")
            assert.are.equal("Northrend Enchanting", result)
        end)

        it("returns empty string when input is nil", function()
            _G.GetLocale = function() return "enUS" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession(nil)
            assert.are.equal("", result)
        end)

        it("returns English for untranslated profession", function()
            _G.GetLocale = function() return "frFR" end
            dofile("Utils/Localization.lua")
            L10n = Craftpad.L10n

            local result = L10n.GetProfession("Unknown Profession")
            assert.are.equal("Unknown Profession", result)
        end)
    end)
end)
