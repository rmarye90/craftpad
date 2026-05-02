-- Community Profession Sync
-- Automatically broadcasts and receives profession data across communities
Craftpad.Community = {}
local ADDON_PREFIX = "CRAFTPAD_PROF"
local CACHE_TTL_HOURS = 24
local THROTTLE_SECONDS = 5
-- Profession cache: [playerName-realm] = { professions = {...}, timestamp = time() }
-- Will be loaded from SavedVariables
local professionCache = {}
local lastBroadcastTime = 0

local EXPANSION_NAMES = {
    [0] = "Classic",
    [1] = "The Burning Crusade",
    [2] = "Wrath of the Lich King",
    [3] = "Cataclysm",
    [4] = "Mists of Pandaria",
    [5] = "Warlords of Draenor",
    [6] = "Legion",
    [7] = "Battle for Azeroth",
    [8] = "Shadowlands",
    [9] = "Dragonflight",
    [10] = "The War Within",
    [11] = "Midnight",
}

function Craftpad.Community.GetExpansionName(expansionID)
    return EXPANSION_NAMES[expansionID] or "Unknown"
end

-- Initialize SavedVariables
local function init_saved_variables()
    if not CraftpadDB then
        CraftpadDB = {}
    end
    if not CraftpadDB.professionCache then
        CraftpadDB.professionCache = {}
    end
    professionCache = CraftpadDB.professionCache
end

-- Get player's current professions with expansion data
local function get_player_professions()
    local professions = {}

    -- Prefer C_TradeSkillUI for expansion-specific data (Dragonflight+)
    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local allLines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if allLines then
            for _, skillLineID in ipairs(allLines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                if info and info.isPrimaryProfession
                    and info.currentSkillLevel and info.currentSkillLevel > 0 then
                    table.insert(professions, {
                        name        = info.displayName or info.professionName or "",
                        icon        = info.icon or 0,
                        skillLevel  = info.currentSkillLevel,
                        maxSkillLevel = info.maxSkillLevel or 0,
                        skillLineID = skillLineID,
                        expansionID = info.expansionID or 0,
                    })
                end
            end
        end
    end

    -- Fallback: GetProfessions() without expansion data
    if #professions == 0 then
        local prof1, prof2 = GetProfessions()
        for _, profIndex in ipairs({prof1, prof2}) do
            if profIndex then
                local name, icon, skillLevel, maxSkillLevel, _, _, skillLine =
                    GetProfessionInfo(profIndex)
                if name and skillLine then
                    table.insert(professions, {
                        name        = name,
                        icon        = icon,
                        skillLevel  = skillLevel,
                        maxSkillLevel = maxSkillLevel,
                        skillLineID = skillLine,
                        expansionID = 0,
                    })
                end
            end
        end
    end

    return professions
end

-- Serialize profession data for transmission
-- Format: skillLineID:skillLevel:maxSkillLevel:name:icon:expansionID
local function serialize_profession_data(professions)
    local parts = {}
    for _, prof in ipairs(professions) do
        table.insert(parts, string.format("%d:%d:%d:%s:%s:%d",
            prof.skillLineID,
            prof.skillLevel,
            prof.maxSkillLevel,
            prof.name,
            tostring(prof.icon),
            prof.expansionID or 0
        ))
    end
    return table.concat(parts, "|")
end

-- Deserialize profession data from transmission (backward compatible)
local function deserialize_profession_data(data)
    local professions = {}
    for profString in string.gmatch(data, "[^|]+") do
        local skillLineID, skillLevel, maxSkillLevel, name, icon, expansionID =
            string.match(profString, "(%d+):(%d+):(%d+):([^:]+):([^:]+):?(%d*)")
        if skillLineID then
            table.insert(professions, {
                skillLineID   = tonumber(skillLineID),
                skillLevel    = tonumber(skillLevel),
                maxSkillLevel = tonumber(maxSkillLevel),
                name          = name,
                icon          = icon,
                expansionID   = tonumber(expansionID) or 0,
            })
        end
    end
    return professions
end
-- Broadcast professions to all communities
local function broadcast_professions()
    -- Throttle broadcasts
    local now = time()
    if now - lastBroadcastTime < THROTTLE_SECONDS then
        return
    end
    lastBroadcastTime = now
    local professions = get_player_professions()
    if #professions == 0 then
        return -- No professions to share
    end
    local serialized = serialize_profession_data(professions)
    if not serialized or serialized == "" then
        return
    end
    -- Register addon message prefix if not already registered
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(ADDON_PREFIX) then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
    end
    -- Broadcast to all communities
    local clubs = C_Club.GetSubscribedClubs()
    for _, club in pairs(clubs) do
        if club.clubType == Enum.ClubType.Character then -- Only communities, not guilds
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, serialized, "CHANNEL", club.clubId)
        end
    end
end
-- Cache received profession data
local function cache_profession_data(sender, professions)
    if not sender or not professions or #professions == 0 then
        return
    end
    professionCache[sender] = {
        professions = professions,
        timestamp = time()
    }
    -- Persist to SavedVariables
    if CraftpadDB and CraftpadDB.professionCache then
        CraftpadDB.professionCache = professionCache
    end
end
-- Clean expired cache entries
local function clean_cache()
    local now = time()
    local ttl = CACHE_TTL_HOURS * 3600
    for player, data in pairs(professionCache) do
        if now - data.timestamp > ttl then
            professionCache[player] = nil
        end
    end
end
-- Find crafters for a specific item
function Craftpad.Community.FindCraftersForItem(itemData)
    if not itemData or not itemData.profession then
        return {}
    end
    clean_cache()
    local crafters = {}
    local requiredProfName = itemData.profession.name
    local requiredSkillLevel = itemData.profession.rank or 0
    for playerName, data in pairs(professionCache) do
        for _, prof in ipairs(data.professions) do
            -- Match by profession name
            if string.find(prof.name, requiredProfName, 1, true) then
                -- Check if skill level is sufficient
                if prof.skillLevel >= requiredSkillLevel then
                    table.insert(crafters, {
                        playerName = playerName,
                        profession = prof.name,
                        skillLevel = prof.skillLevel,
                        maxSkillLevel = prof.maxSkillLevel,
                        icon = prof.icon,
                        timestamp = data.timestamp
                    })
                end
            end
        end
    end
    -- Sort by skill level descending
    table.sort(crafters, function(a, b)
        return a.skillLevel > b.skillLevel
    end)
    return crafters
end
-- Get total number of cached players
function Craftpad.Community.GetCachedPlayerCount()
    clean_cache()
    local count = 0
    for _ in pairs(professionCache) do
        count = count + 1
    end
    return count
end

-- Return all cached players as a sorted list
function Craftpad.Community.GetAllCachedPlayers()
    clean_cache()
    local players = {}
    for playerName, data in pairs(professionCache) do
        table.insert(players, {
            playerName  = playerName,
            professions = data.professions,
            timestamp   = data.timestamp,
        })
    end
    table.sort(players, function(a, b) return a.playerName < b.playerName end)
    return players
end

-- Re-broadcast our professions immediately (ignores throttle)
function Craftpad.Community.RequestSync()
    lastBroadcastTime = 0
    broadcast_professions()
end
-- Event handler for profession changes
local function handle_profession_change()
    -- Delay broadcast slightly to ensure data is updated
    C_Timer.After(1, broadcast_professions)
end
-- Event handler for addon messages
local function handle_addon_message(prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then
        return
    end
    -- Don't cache our own messages
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    if sender == playerName then
        return
    end
    local professions = deserialize_profession_data(message)
    if professions and #professions > 0 then
        cache_profession_data(sender, professions)
    end
end
-- Initialize sync system
local function initialize()
    -- Initialize SavedVariables
    init_saved_variables()
    -- Register addon message prefix
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
    -- Create event frame
    local syncFrame = CreateFrame("Frame")
    syncFrame:RegisterEvent("PLAYER_LOGIN")
    syncFrame:RegisterEvent("SKILL_LINES_CHANGED")
    syncFrame:RegisterEvent("CHAT_MSG_ADDON")
    syncFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            -- Broadcast professions after login (with delay to ensure everything is loaded)
            C_Timer.After(5, broadcast_professions)
        elseif event == "SKILL_LINES_CHANGED" then
            handle_profession_change()
        elseif event == "CHAT_MSG_ADDON" then
            local prefix, message, channel, sender = ...
            handle_addon_message(prefix, message, channel, sender)
        end
    end)
end
-- Initialize on load
initialize()
