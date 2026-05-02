-- Main UI Frame with split-view: list + detail panel
local FRAME_WIDTH = 800
local FRAME_HEIGHT = 500
local LIST_WIDTH = 350
local DETAIL_WIDTH = 400
local ROW_HEIGHT = 24
local ICON_SIZE = 20
local REAGENT_ICON_MARGIN = 80
-- Material count colors
local COLOR_SUFFICIENT = {r = 0.0, g = 1.0, b = 0.0, a = 1}
local COLOR_INSUFFICIENT = {r = 1.0, g = 0.3, b = 0.3, a = 1}
local selectedRow = nil
local selectedItemData = nil
local currentSearchText = ""
local itemRows = {}
local searchBox = nil
local listPanel = nil
local scrollFrame = nil
local scrollChild = nil
local itemCount = nil
local currentTab = 1  -- luacheck: ignore 231 (will be used for state tracking)
local showCraftersTab = true -- Option to show/hide Crafters tab
-- Forward declaration for RebuildItemList
local RebuildItemList
-- Get localized item name using WoW API
local function getLocalizedItemName(itemData)
    if itemData.id and Craftpad.Utils and Craftpad.Utils.GetItemName then
        return Craftpad.Utils.GetItemName(itemData.id, itemData.name)
    end
    return itemData.name
end
-- Count items in warband bank tabs by iterating slots (language-agnostic)
local function count_in_warband_bank(itemID)
    if not itemID or not Enum.BagIndex or not Enum.BagIndex.AccountBankTab_1 then
        return 0
    end
    local total = 0
    for tabOffset = 0, 3 do
        local bagIndex = Enum.BagIndex.AccountBankTab_1 + tabOffset
        local numSlots = C_Container and C_Container.GetContainerNumSlots(bagIndex) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagIndex, slot)
            if info and info.itemID == itemID then
                total = total + (info.stackCount or 1)
            end
        end
    end
    return total
end

-- Get total item count across bags, personal bank, and warband bank.
-- Requires an itemID (number) for language-agnostic results.
-- Name-based fallback only works when the client locale matches the database (enUS).
local function get_total_item_count(itemNameOrID)
    local itemID = tonumber(itemNameOrID)

    if itemID then
        -- ID path: fully locale-independent, includes all storage
        local count = 0
        if C_Item and C_Item.GetItemCount then
            -- includeBank=true, includeUses=false, includeReagentBank=false, includeWarband=true
            count = C_Item.GetItemCount(itemID, true, false, false, true) or 0
        else
            count = GetItemCount(itemID, true) or 0
        end
        -- Belt-and-suspenders: also scan warband bank manually in case the 5th param
        -- is not yet supported on this client version
        local wbCount = count_in_warband_bank(itemID)
        return math.max(count, wbCount > 0 and count + wbCount or count)
    end

    -- Name path (English name only — returns 0 on non-enUS clients)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemNameOrID, true) or 0
    end
    return GetItemCount(itemNameOrID, true) or 0
end
-- Filter items based on search text (delegates to Search module)
local function FilterItems(searchText)
    local allItems = Craftpad.Data.GetHousingItems()
    return Craftpad.Search.search_items(allItems, searchText)
end
function Craftpad.UI.CreateMainFrame()
    -- Main Frame
    local frame = CreateFrame("Frame", "CraftpadMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Craftpad - Housing Items")
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    -- Item Count
    itemCount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemCount:SetPoint("TOP", title, "BOTTOM", 0, -5)
    local count = Craftpad.Data.GetItemCount()
    itemCount:SetText(count .. " items available - Click an item to view crafting details")
    -- LEFT PANEL: List of items
    listPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
    listPanel:SetSize(LIST_WIDTH, FRAME_HEIGHT - 100)
    listPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    listPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    listPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    -- Search Box
    searchBox = CreateFrame("EditBox", nil, listPanel, "InputBoxTemplate")
    searchBox:SetSize(LIST_WIDTH - 70, 30)
    searchBox:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 10, -10)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetFontObject("GameFontNormal")
    searchBox:SetTextInsets(8, 8, 0, 0)
    -- Placeholder text
    local placeholderText = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholderText:SetPoint("LEFT", searchBox, "LEFT", 8, 0)
    placeholderText:SetText("Search items...")
    placeholderText:SetTextColor(0.5, 0.5, 0.5, 1)
    searchBox:SetScript("OnEditFocusGained", function()
        placeholderText:Hide()
    end)
    searchBox:SetScript("OnEditFocusLost", function(box)
        if box:GetText() == "" then
            placeholderText:Show()
        end
    end)
    searchBox:SetScript("OnTextChanged", function(box)
        local text = box:GetText()
        if text == "" then
            placeholderText:Show()
        else
            placeholderText:Hide()
        end
        currentSearchText = text
        RebuildItemList()
    end)
    -- Clear Button
    local clearBtn = CreateFrame("Button", nil, listPanel)
    clearBtn:SetSize(20, 20)
    clearBtn:SetPoint("LEFT", searchBox, "RIGHT", 5, 0)
    clearBtn:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearBtn:SetHighlightTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        placeholderText:Show()
        currentSearchText = ""
        RebuildItemList()
    end)
    clearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Clear search")
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    -- Scroll Frame for list
    scrollFrame = CreateFrame("ScrollFrame", "CraftpadScrollFrame", listPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 5, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -25, 5)
    -- Scroll Child
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(LIST_WIDTH - 40, FRAME_HEIGHT - 150)
    -- RIGHT PANEL: Detail panel with tabs
    local detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    detailPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -70)
    detailPanel:SetSize(DETAIL_WIDTH, FRAME_HEIGHT - 100)
    detailPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    detailPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    detailPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    -- Tab buttons
    local tabs = {}
    local tabContents = {}
    local TAB_HEIGHT = 30
    local TAB_NAMES = {"Info", "Recipe", "Crafters"}
    local function switch_tab(tabIndex)
        currentTab = tabIndex
        for i, tab in ipairs(tabs) do
            if i == tabIndex then
                tab:SetBackdropColor(0.2, 0.4, 0.6, 0.9)
                tabContents[i]:Show()
            else
                tab:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
                tabContents[i]:Hide()
            end
        end
    end
    -- Create tab buttons
    for i, tabName in ipairs(TAB_NAMES) do
        if i <= 2 or (i == 3 and showCraftersTab) then
            local tab = CreateFrame("Button", nil, detailPanel, "BackdropTemplate")
            tab:SetSize(DETAIL_WIDTH / 3 - 5, TAB_HEIGHT)
            tab:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", (i-1) * (DETAIL_WIDTH / 3), 0)
            tab:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = false,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            tab:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
            tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
            tabText:SetText(tabName)
            tab:SetScript("OnClick", function()
                switch_tab(i)
            end)
            tabs[i] = tab
        end
    end
    -- Create tab content containers
    for i = 1, 3 do
        local content = CreateFrame("ScrollFrame", nil, detailPanel)
        content:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 5, -(TAB_HEIGHT + 5))
        content:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -5, 5)
        local tabScrollChild = CreateFrame("Frame", nil, content)
        content:SetScrollChild(tabScrollChild)
        tabScrollChild:SetSize(DETAIL_WIDTH - 20, FRAME_HEIGHT - 140)
        content.scrollChild = tabScrollChild
        tabContents[i] = content
        content:Hide()
    end
    -- Show first tab by default
    switch_tab(1)
    -- Default text for tab 1
    local defaultText = tabContents[1].scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    defaultText:SetPoint("CENTER", tabContents[1].scrollChild, "CENTER", 0, 0)
    defaultText:SetText("Select an item to view details")
    defaultText:SetTextColor(0.6, 0.6, 0.6, 1)
    -- Function to render Tab 1: Item Info
    local function render_info_tab(itemData)
        local tabScroll = tabContents[1].scrollChild
        tabScroll:Hide()
        tabScroll:SetParent(nil)
        tabScroll = CreateFrame("Frame", nil, tabContents[1])
        tabContents[1]:SetScrollChild(tabScroll)
        tabScroll:SetSize(DETAIL_WIDTH - 20, FRAME_HEIGHT - 140)
        tabContents[1].scrollChild = tabScroll
        local yOffset = -15
        -- Item icon (large)
        local itemIcon = tabScroll:CreateTexture(nil, "ARTWORK")
        itemIcon:SetSize(64, 64)
        itemIcon:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
        if itemData.icon and itemData.icon ~= "N/A" then
            itemIcon:SetTexture(tonumber(itemData.icon))
        else
            itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        yOffset = yOffset - 75
        -- Item name
        local itemName = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        itemName:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
        itemName:SetText(getLocalizedItemName(itemData))
        itemName:SetWidth(DETAIL_WIDTH - 30)
        itemName:SetWordWrap(true)
        yOffset = yOffset - 35
        -- Category
        local categoryText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        categoryText:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
        local localizedCategory = itemData.category
        if Craftpad.L10n and Craftpad.L10n.GetCategory then
            localizedCategory = Craftpad.L10n.GetCategory(itemData.category)
        end
        categoryText:SetText("Category: " .. localizedCategory)
        categoryText:SetTextColor(0.8, 0.8, 0.8, 1)
        yOffset = yOffset - 25
        -- Item ID
        local idText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        idText:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
        idText:SetText("Item ID: " .. itemData.id)
        idText:SetTextColor(0.6, 0.6, 0.6, 1)
    end
    -- Function to render Tab 2: Recipe (Profession + Materials)
    local function render_recipe_tab(itemData)
        local tabScroll = tabContents[2].scrollChild
        tabScroll:Hide()
        tabScroll:SetParent(nil)
        tabScroll = CreateFrame("Frame", nil, tabContents[2])
        tabContents[2]:SetScrollChild(tabScroll)
        tabScroll:SetSize(DETAIL_WIDTH - 20, FRAME_HEIGHT - 140)
        tabContents[2].scrollChild = tabScroll
        if not itemData.profession or not itemData.reagents then
            local noCraftText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noCraftText:SetPoint("CENTER", tabScroll, "CENTER", 0, 0)
            noCraftText:SetText("No crafting recipe available")
            noCraftText:SetTextColor(0.8, 0.5, 0.5, 1)
            return
        end
        local yOffset = -15
        -- Profession section
        local profLabel = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profLabel:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 10, yOffset)
        profLabel:SetText("Profession Required:")
        profLabel:SetTextColor(1, 0.82, 0, 1)
        yOffset = yOffset - 25
        -- Profession icon
        local profIcon = tabScroll:CreateTexture(nil, "ARTWORK")
        profIcon:SetSize(24, 24)
        profIcon:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 15, yOffset)
        profIcon:SetTexture("Interface\\Icons\\" .. itemData.profession.icon)
        -- Profession name and rank
        local profText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profText:SetPoint("LEFT", profIcon, "RIGHT", 10, 0)
        local localizedProfession = itemData.profession.name
        if Craftpad.L10n and Craftpad.L10n.GetProfession then
            localizedProfession = Craftpad.L10n.GetProfession(itemData.profession.name)
        end
        profText:SetText(localizedProfession .. " (Rank " .. itemData.profession.rank .. ")")
        yOffset = yOffset - 35
        -- Separator
        local separator = tabScroll:CreateTexture(nil, "ARTWORK")
        separator:SetTexture("Interface\\Buttons\\WHITE8x8")
        separator:SetSize(DETAIL_WIDTH - 40, 1)
        separator:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
        separator:SetColorTexture(0.4, 0.4, 0.4, 1)
        yOffset = yOffset - 15
        -- Materials section
        local matLabel = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        matLabel:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 10, yOffset)
        matLabel:SetText("Materials Required:")
        matLabel:SetTextColor(1, 0.82, 0, 1)
        yOffset = yOffset - 25
        -- Reagents list
        for _, reagent in ipairs(itemData.reagents) do
            local reagentIcon = tabScroll:CreateTexture(nil, "ARTWORK")
            reagentIcon:SetSize(20, 20)
            reagentIcon:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 20, yOffset)
            reagentIcon:SetTexture("Interface\\Icons\\" .. reagent.icon)
            -- Use itemID if available, otherwise fall back to name
            local itemIdentifier = reagent.itemID or reagent.name
            local currentCount = get_total_item_count(itemIdentifier)
            local requiredCount = reagent.quantity
            -- Get localized reagent name
            local reagentName = reagent.name
            if reagent.itemID and Craftpad.Utils and Craftpad.Utils.GetItemName then
                reagentName = Craftpad.Utils.GetItemName(reagent.itemID, reagent.name)
            end
            local reagentText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            reagentText:SetPoint("LEFT", reagentIcon, "RIGHT", 8, 0)
            reagentText:SetText(reagentName .. " " .. currentCount .. "/" .. requiredCount)
            reagentText:SetWidth(DETAIL_WIDTH - REAGENT_ICON_MARGIN)
            reagentText:SetJustifyH("LEFT")
            if currentCount >= requiredCount then
                reagentText:SetTextColor(
                    COLOR_SUFFICIENT.r, COLOR_SUFFICIENT.g,
                    COLOR_SUFFICIENT.b, COLOR_SUFFICIENT.a
                )
            else
                reagentText:SetTextColor(
                    COLOR_INSUFFICIENT.r, COLOR_INSUFFICIENT.g,
                    COLOR_INSUFFICIENT.b, COLOR_INSUFFICIENT.a
                )
            end
            yOffset = yOffset - 25
        end
    end
    -- Function to render Tab 3: Community Crafters
    local function render_crafters_tab(itemData)
        local tabScroll = tabContents[3].scrollChild
        tabScroll:Hide()
        tabScroll:SetParent(nil)
        tabScroll = CreateFrame("Frame", nil, tabContents[3])
        tabContents[3]:SetScrollChild(tabScroll)
        tabScroll:SetSize(DETAIL_WIDTH - 20, FRAME_HEIGHT - 140)
        tabContents[3].scrollChild = tabScroll
        local yOffset = -15
        -- Find crafters
        local crafters = Craftpad.Community.FindCraftersForItem(itemData)
        if #crafters == 0 then
            local noCraftersText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noCraftersText:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
            noCraftersText:SetText("No crafters found in your communities")
            noCraftersText:SetTextColor(0.7, 0.7, 0.7, 1)
            yOffset = yOffset - 30
            local helpText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            helpText:SetPoint("TOP", tabScroll, "TOP", 0, yOffset)
            helpText:SetText("Other players need Craftpad installed\nto share their professions")
            helpText:SetTextColor(0.6, 0.6, 0.6, 1)
            helpText:SetWidth(DETAIL_WIDTH - 30)
            helpText:SetWordWrap(true)
        else
            -- Header
            local headerText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            headerText:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 10, yOffset)
            headerText:SetText(#crafters .. " crafter(s) found:")
            headerText:SetTextColor(1, 0.82, 0, 1)
            yOffset = yOffset - 30
            -- Display each crafter
            for _, crafter in ipairs(crafters) do
                local crafterIcon = tabScroll:CreateTexture(nil, "ARTWORK")
                crafterIcon:SetSize(20, 20)
                crafterIcon:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 15, yOffset)
                crafterIcon:SetTexture("Interface\\Icons\\" .. crafter.icon)
                local crafterText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                crafterText:SetPoint("LEFT", crafterIcon, "RIGHT", 8, 0)
                crafterText:SetText(crafter.playerName)
                crafterText:SetTextColor(0.3, 1.0, 0.3, 1)
                local skillText = tabScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                skillText:SetPoint("TOPLEFT", tabScroll, "TOPLEFT", 45, yOffset - 15)
                local skillText_str = crafter.profession .. " (" ..
                    crafter.skillLevel .. "/" .. crafter.maxSkillLevel .. ")"
                skillText:SetText(skillText_str)
                skillText:SetTextColor(0.8, 0.8, 0.8, 1)
                yOffset = yOffset - 40
            end
        end
    end
    -- Main function to update detail panel
    local function UpdateDetailPanel(itemData)
        if not itemData then
            -- Clear all tabs and show default
            for i = 1, 3 do
                local clearScroll = tabContents[i].scrollChild
                clearScroll:Hide()
                clearScroll:SetParent(nil)
                clearScroll = CreateFrame("Frame", nil, tabContents[i])
                tabContents[i]:SetScrollChild(clearScroll)
                clearScroll:SetSize(DETAIL_WIDTH - 20, FRAME_HEIGHT - 140)
                tabContents[i].scrollChild = clearScroll
            end
            local emptyText = tabContents[1].scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            emptyText:SetPoint("CENTER", tabContents[1].scrollChild, "CENTER", 0, 0)
            emptyText:SetText("Select an item to view details")
            emptyText:SetTextColor(0.6, 0.6, 0.6, 1)
            switch_tab(1)
            return
        end
        -- Render all tabs with data
        render_info_tab(itemData)
        render_recipe_tab(itemData)
        render_crafters_tab(itemData)
    end
    -- Function to create a single item row
    local function CreateItemRow(item, index)
        local row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
        row:SetSize(LIST_WIDTH - 40, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(index-1) * ROW_HEIGHT)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })
        -- Alternate row colors
        if index % 2 == 0 then
            row:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
        else
            row:SetBackdropColor(0.2, 0.2, 0.2, 0.3)
        end
        row.normalColor = {row:GetBackdropColor()}
        row.hoverColor = {0.3, 0.3, 0.4, 0.5}
        row.selectedColor = {0.2, 0.4, 0.6, 0.7}
        row.itemData = item
        -- Icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        if item.icon and item.icon ~= "N/A" then
            icon:SetTexture(tonumber(item.icon))
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        -- Name text
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        text:SetText(getLocalizedItemName(item))
        text:SetJustifyH("LEFT")
        text:SetWidth(LIST_WIDTH - 100)
        -- Hover effect
        row:SetScript("OnEnter", function(self)
            if self ~= selectedRow then
                self:SetBackdropColor(unpack(self.hoverColor))
            end
        end)
        row:SetScript("OnLeave", function(self)
            if self ~= selectedRow then
                self:SetBackdropColor(unpack(self.normalColor))
            end
        end)
        -- Click handler
        row:SetScript("OnClick", function(self)
            -- Deselect previous row
            if selectedRow then
                selectedRow:SetBackdropColor(unpack(selectedRow.normalColor))
            end
            -- Select this row
            selectedRow = self
            selectedItemData = item
            self:SetBackdropColor(unpack(self.selectedColor))
            -- Store selected item on frame so inventory events can access it
            frame.selectedItemData = item
            -- Update detail panel
            UpdateDetailPanel(item)
        end)
        -- Re-select if this was the previously selected item
        if selectedItemData and selectedItemData.id == item.id then
            selectedRow = row
            row:SetBackdropColor(unpack(row.selectedColor))
        end
        return row
    end
    -- Function to rebuild the item list based on search
    function RebuildItemList()
        -- Clear existing rows
        for _, row in ipairs(itemRows) do
            row:Hide()
            row:SetParent(nil)
        end
        itemRows = {}
        selectedRow = nil
        -- Get filtered items
        local items = FilterItems(currentSearchText)
        -- Update item count
        local totalCount = Craftpad.Data.GetItemCount()
        if currentSearchText ~= "" then
            itemCount:SetText(#items .. " of " .. totalCount .. " items - Click an item to view crafting details")
        else
            itemCount:SetText(totalCount .. " items available - Click an item to view crafting details")
        end
        -- Handle no results
        if #items == 0 then
            scrollChild:SetSize(LIST_WIDTH - 40, 100)
            local noResultsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noResultsText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
            noResultsText:SetText("No items found")
            noResultsText:SetTextColor(0.6, 0.6, 0.6, 1)
            table.insert(itemRows, noResultsText)
            return
        end
        -- Update scroll child size
        scrollChild:SetSize(LIST_WIDTH - 40, ROW_HEIGHT * #items)
        -- Create rows for filtered items
        for i, item in ipairs(items) do
            local row = CreateItemRow(item, i)
            table.insert(itemRows, row)
        end
    end
    -- Initial population of the list
    RebuildItemList()
    Craftpad.UI.MainFrame = frame
    Craftpad.UI.UpdateDetailPanel = UpdateDetailPanel
    return frame
end
function Craftpad.UI.ToggleMainFrame()
    if not Craftpad.UI.MainFrame then
        Craftpad.UI.CreateMainFrame()
    end
    if Craftpad.UI.MainFrame:IsShown() then
        Craftpad.UI.MainFrame:Hide()
    else
        Craftpad.UI.MainFrame:Show()
    end
end
