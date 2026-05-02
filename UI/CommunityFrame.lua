-- Community Professions Frame
local FRAME_WIDTH  = 720
local FRAME_HEIGHT = 500
local ROW_HEIGHT   = 26
local ICON_SIZE    = 18

-- Column offsets (pixels from left of row)
local COL_PLAYER    = 8
local COL_ICON      = 210
local COL_PROF      = 234
local COL_LEVEL     = 430
local COL_EXPANSION = 515

local communityFrame = nil
local rowWidgets = {}

local function clear_rows()
    for _, w in ipairs(rowWidgets) do
        w:Hide()
        w:SetParent(nil)
    end
    rowWidgets = {}
end

local function build_list(scrollChild)
    clear_rows()

    local availWidth = FRAME_WIDTH - 55

    local players = Craftpad.Community.GetAllCachedPlayers()

    if #players == 0 then
        scrollChild:SetSize(availWidth, 80)
        local empty = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        empty:SetText("Aucun membre trouvé.\nLes autres joueurs doivent avoir Craftpad pour partager leurs métiers.")
        empty:SetTextColor(0.6, 0.6, 0.6, 1)
        empty:SetWidth(availWidth - 20)
        empty:SetJustifyH("CENTER")
        empty:SetWordWrap(true)
        table.insert(rowWidgets, empty)
        return
    end

    -- Flatten players × professions into rows
    local allRows = {}
    for _, playerData in ipairs(players) do
        for _, prof in ipairs(playerData.professions) do
            table.insert(allRows, { playerName = playerData.playerName, prof = prof })
        end
    end

    scrollChild:SetSize(availWidth, ROW_HEIGHT * math.max(#allRows, 1))

    for i, entry in ipairs(allRows) do
        local row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        row:SetSize(availWidth, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        if i % 2 == 0 then
            row:SetBackdropColor(0.08, 0.08, 0.12, 0.5)
        else
            row:SetBackdropColor(0.14, 0.14, 0.18, 0.5)
        end

        -- Player name
        local playerTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playerTxt:SetPoint("LEFT", row, "LEFT", COL_PLAYER, 0)
        playerTxt:SetText(entry.playerName)
        playerTxt:SetWidth(COL_ICON - COL_PLAYER - 4)
        playerTxt:SetJustifyH("LEFT")
        playerTxt:SetTextColor(0.4, 0.85, 1.0, 1)

        -- Profession icon
        local iconTex = row:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(ICON_SIZE, ICON_SIZE)
        iconTex:SetPoint("LEFT", row, "LEFT", COL_ICON, 0)
        local iconVal = tonumber(entry.prof.icon)
        if iconVal and iconVal > 0 then
            iconTex:SetTexture(iconVal)
        else
            iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        -- Profession name
        local profTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profTxt:SetPoint("LEFT", row, "LEFT", COL_PROF, 0)
        profTxt:SetText(entry.prof.name)
        profTxt:SetWidth(COL_LEVEL - COL_PROF - 8)
        profTxt:SetJustifyH("LEFT")

        -- Skill level  e.g. "100 / 100"
        local levelTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        levelTxt:SetPoint("LEFT", row, "LEFT", COL_LEVEL, 0)
        levelTxt:SetText(entry.prof.skillLevel .. " / " .. entry.prof.maxSkillLevel)
        levelTxt:SetWidth(COL_EXPANSION - COL_LEVEL - 6)
        levelTxt:SetTextColor(0.75, 0.75, 0.75, 1)

        -- Expansion name
        local expTxt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        expTxt:SetPoint("LEFT", row, "LEFT", COL_EXPANSION, 0)
        expTxt:SetText(Craftpad.Community.GetExpansionName(entry.prof.expansionID or 0))
        expTxt:SetWidth(availWidth - COL_EXPANSION - 4)
        expTxt:SetTextColor(1.0, 0.82, 0, 1)

        table.insert(rowWidgets, row)
    end
end

local function create_frame()
    local frame = CreateFrame("Frame", "CraftpadCommunityFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.92)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -18)
    title:SetText("Craftpad — Métiers de la Communauté")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Player count + last sync info
    local countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("TOP", title, "BOTTOM", 0, -4)
    countLabel:SetTextColor(0.65, 0.65, 0.65, 1)
    frame.countLabel = countLabel

    -- Refresh / Broadcast button
    local refreshBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(110, 22)
    refreshBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -38, -15)
    refreshBtn:SetText("Synchroniser")
    refreshBtn:SetScript("OnClick", function()
        Craftpad.Community.RequestSync()
        frame:Refresh()
    end)

    -- Column headers bar
    local headerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -52)
    headerBar:SetSize(FRAME_WIDTH - 36, 22)
    headerBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    headerBar:SetBackdropColor(0.12, 0.12, 0.22, 0.9)

    local function makeHeader(text, offsetX, width)
        local fs = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", headerBar, "LEFT", offsetX, 0)
        fs:SetText(text)
        fs:SetTextColor(1, 0.82, 0, 1)
        fs:SetWidth(width)
    end
    makeHeader("Joueur",      COL_PLAYER,    COL_ICON - COL_PLAYER - 4)
    makeHeader("Métier",      COL_PROF,      COL_LEVEL - COL_PROF - 8)
    makeHeader("Niveau",      COL_LEVEL,     COL_EXPANSION - COL_LEVEL - 6)
    makeHeader("Extension",   COL_EXPANSION, FRAME_WIDTH - 36 - COL_EXPANSION - 4)

    -- Scroll frame
    local scrollFrame = CreateFrame(
        "ScrollFrame", "CraftpadCommunityScroll", frame, "UIPanelScrollFrameTemplate"
    )
    scrollFrame:SetPoint("TOPLEFT",     frame, "TOPLEFT",     18, -78)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 12)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(FRAME_WIDTH - 55, FRAME_HEIGHT - 100)
    frame.scrollChild = scrollChild

    frame.Refresh = function()
        local count = Craftpad.Community.GetCachedPlayerCount()
        countLabel:SetText(count .. " joueur(s) dans le cache — cache valide 24h")
        build_list(scrollChild)
    end

    return frame
end

function Craftpad.Community.Frame.Toggle()
    if not communityFrame then
        communityFrame = create_frame()
    end

    if communityFrame:IsShown() then
        communityFrame:Hide()
    else
        communityFrame:Refresh()
        communityFrame:Show()
    end
end
