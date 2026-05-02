# Craftpad
A World of Warcraft addon that provides a searchable database of housing items with crafting details.<br/>

[![Tests](https://github.com/florianbx/Craftpad/actions/workflows/test.yml/badge.svg)](https://github.com/florianbx/Craftpad/actions/workflows/test.yml)

<p align="center">
  <img width="480" height="480" alt="house" src="https://github.com/user-attachments/assets/4d373d9c-2b73-4d3f-8ece-988648ffd18f" />
</p>

## Features

- Search for any housing item by name, category, or profession
- See exactly what materials you have and what you need
- Material counts show as "2/8" (you have 2, need 8)
- Green color when ready to craft, red when you need more
- Auto-updates when you loot items or open your bank
- Works with bags, personal bank, and warband bank
- **Community Crafters**: See who in your communities can craft items (requires addon installed)
- **Multi-language Support**: Works automatically in English, French, German, Spanish, and more

<p align="center">
  <img width="585" height="381" alt="Screenshot 2026-02-11 at 02 41 03" src="https://github.com/user-attachments/assets/1a191e7f-db93-4e0e-a731-d7a10f43c231" />
</p>

## How to use

Type `/craftpad` or `/cp` in game to open the window.

Search for an item and click on it. The right side shows:
- The full recipe
- Your current materials (from bags and banks)
- What you still need
- **Community crafters** who can make the item (with their profession level)

Material counts update automatically while you play.

### Community Crafters Feature

The addon automatically shares your professions with other players in your communities who also have Craftpad installed. This happens:
- When you log in (5 seconds delay)
- When you learn or level up a profession

When you select an item, you'll see a list of players from your communities who can craft it, along with their skill level. No manual scanning needed - it's all automatic!

**Privacy**: Your profession data is only shared within WoW communities you're already a member of, and only with players who have Craftpad installed.

### Multi-Language Support

Craftpad automatically adapts to your game client's language. Item names are displayed in your client's locale (French, German, Spanish, etc.) using WoW's built-in localization system.

**Supported languages:**
- English (enUS, enGB)
- French (frFR)  
- German (deDE)
- Spanish (esES, esMX)
- And all other WoW client languages for item names

The addon uses WoW's API to fetch localized item names, so you'll see:
- Housing item names in your language
- Material names in your language
- Translated categories and profession names for major languages
- Search that works with localized text

No configuration needed - it just works based on your WoW client language!

## Installation

1. Download the addon
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload` in game

## License

MIT
