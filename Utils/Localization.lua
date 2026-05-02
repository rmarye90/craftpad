-- Localization Module
-- Provides translations for categories and profession names
-- Falls back to English if translation not available

if not Craftpad then Craftpad = {} end
if not Craftpad.L10n then Craftpad.L10n = {} end

local locale = GetLocale()

-- Category translations
local categoryTranslations = {
    ["frFR"] = {
        ["Miscellaneous"] = "Divers",
        ["Wall Hangings"] = "Décorations murales",
        ["Large Structures"] = "Grandes structures",
        ["Ornamental"] = "Décoratif",
        ["Furniture"] = "Mobilier",
        ["Lighting"] = "Éclairage",
        ["Rugs"] = "Tapis",
        ["Sculptures"] = "Sculptures",
        ["Tables"] = "Tables",
        ["Chairs"] = "Chaises",
        ["Storage"] = "Rangement",
        ["Beds"] = "Lits",
        ["Plants"] = "Plantes",
        ["Windows"] = "Fenêtres",
        ["Doors"] = "Portes",
        ["Roofing"] = "Toiture",
        ["Flooring"] = "Sol",
        ["Walls"] = "Murs",
    },
    ["deDE"] = {
        ["Miscellaneous"] = "Verschiedenes",
        ["Wall Hangings"] = "Wandbehänge",
        ["Large Structures"] = "Große Strukturen",
        ["Ornamental"] = "Dekorativ",
        ["Furniture"] = "Möbel",
        ["Lighting"] = "Beleuchtung",
        ["Rugs"] = "Teppiche",
        ["Sculptures"] = "Skulpturen",
        ["Tables"] = "Tische",
        ["Chairs"] = "Stühle",
        ["Storage"] = "Lagerung",
        ["Beds"] = "Betten",
        ["Plants"] = "Pflanzen",
        ["Windows"] = "Fenster",
        ["Doors"] = "Türen",
        ["Roofing"] = "Dacheindeckung",
        ["Flooring"] = "Bodenbelag",
        ["Walls"] = "Wände",
    },
    ["esES"] = {
        ["Miscellaneous"] = "Varios",
        ["Wall Hangings"] = "Colgantes de pared",
        ["Large Structures"] = "Estructuras grandes",
        ["Ornamental"] = "Ornamental",
        ["Furniture"] = "Muebles",
        ["Lighting"] = "Iluminación",
        ["Rugs"] = "Alfombras",
        ["Sculptures"] = "Esculturas",
        ["Tables"] = "Mesas",
        ["Chairs"] = "Sillas",
        ["Storage"] = "Almacenamiento",
        ["Beds"] = "Camas",
        ["Plants"] = "Plantas",
        ["Windows"] = "Ventanas",
        ["Doors"] = "Puertas",
        ["Roofing"] = "Techado",
        ["Flooring"] = "Suelo",
        ["Walls"] = "Paredes",
    },
}

-- Profession name translations
local professionTranslations = {
    ["frFR"] = {
        ["Cataclysm Inscription"] = "Calligraphie (Cataclysm)",
        ["Outland Tailoring"] = "Couture (Outreterre)",
        ["Northrend Tailoring"] = "Couture (Norfendre)",
        ["Pandaria Jewelcrafting"] = "Joaillerie (Pandarie)",
        ["Legion Tailoring"] = "Couture (Légion)",
        ["Northrend Enchanting"] = "Enchantement (Norfendre)",
    },
    ["deDE"] = {
        ["Cataclysm Inscription"] = "Inschriftenkunde (Cataclysm)",
        ["Outland Tailoring"] = "Schneiderei (Scherbenwelt)",
        ["Northrend Tailoring"] = "Schneiderei (Nordend)",
        ["Pandaria Jewelcrafting"] = "Juwelierskunst (Pandaria)",
        ["Legion Tailoring"] = "Schneiderei (Legion)",
        ["Northrend Enchanting"] = "Verzauberkunst (Nordend)",
    },
    ["esES"] = {
        ["Cataclysm Inscription"] = "Inscripción (Cataclysm)",
        ["Outland Tailoring"] = "Sastrería (Terrallende)",
        ["Northrend Tailoring"] = "Sastrería (Rasganorte)",
        ["Pandaria Jewelcrafting"] = "Joyería (Pandaria)",
        ["Legion Tailoring"] = "Sastrería (Legión)",
        ["Northrend Enchanting"] = "Encantamiento (Rasganorte)",
    },
}

-- Get translated category name based on client locale
-- @param englishName string The English category name (e.g. "Miscellaneous")
-- @return string The localized category name, or English name if no translation available
function Craftpad.L10n.GetCategory(englishName)
    if not englishName then
        return ""
    end

    if categoryTranslations[locale] and categoryTranslations[locale][englishName] then
        return categoryTranslations[locale][englishName]
    end

    -- Fallback to English
    return englishName
end

-- Get translated profession name based on client locale
-- @param englishName string The English profession name (e.g. "Cataclysm Inscription")
-- @return string The localized profession name, or English name if no translation available
function Craftpad.L10n.GetProfession(englishName)
    if not englishName then
        return ""
    end

    if professionTranslations[locale] and professionTranslations[locale][englishName] then
        return professionTranslations[locale][englishName]
    end

    -- Fallback to English
    return englishName
end
