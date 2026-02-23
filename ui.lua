
local addonName, VPA = ...

VPAMerchants = VPAMerchants or {}
VPAItems = VPAItems or {}

local hbd = LibStub:GetLibrary("HereBeDragons-2.0")
VPTomTomData = {}
VPA.SearchIndex = {}
VPA.Results = {}
VPA.PendingSearchQuery = nil

VPA.Version = {
    major = 0,
    minor = 0,
    patch = 1
}


-- Main Frame
function VPA.CreateMainFrame()
    local frame = CreateFrame("Frame", "VPAFrame", UIParent, "PortraitFrameTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetTitle("Vendorpedia")
    frame:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Book_06")
    frame:Hide()
    tinsert(UISpecialFrames, "VPAFrame")
    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.Text:SetSize(340, 40)
    frame.Text:SetPoint("TOPLEFT", 64, -22)
    frame.Text:SetText("This is a bunch of useless text to make sure the fontstring has the correct size and all that good stuff so nothing to see here carry on.")
    frame:SetScript("OnHide", function() PlaySound(16346) end)
    VPA.Frame = frame
end

-- Search Box
function VPA.CreateSearchBox()
    local searchBox = CreateFrame("EditBox", "VPASearchBox", VPA.Frame, "SearchBoxTemplate")
    searchBox:SetSize(340, 20)
    searchBox:SetPoint("TOPLEFT", VPA.Frame, "TOPLEFT", 64, -52)
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        SearchBoxTemplate_OnTextChanged(self)
        local text = self:GetText()
        if VPA.Trim(text) == "" then
            VPA.ClearResults()
        else
            VPA.PendingSearchQuery = VPA.Trim(self:GetText())
            VPA.SearchDirty = true
        end
    end)
    searchBox:SetScale(1.2)
    VPA.SearchBox = searchBox
    SearchBoxTemplate_OnLoad(searchBox)
end

-- Results List
function VPA.CreateResultsInset()
    local inset = CreateFrame("Frame", "VPAResultsInset", VPA.Frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", VPA.Frame, "TOPLEFT", 15, -92)
    inset:SetPoint("BOTTOMRIGHT", VPA.Frame, "BOTTOMRIGHT", -15, 18)
    VPA.ResultsInset = inset
end

function VPA.CreateScrollArea()
    local scrollBox = CreateFrame("Frame", "VPAScrollBox", VPA.ResultsInset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", VPA.ResultsHeaders, "BOTTOMLEFT", 0, -2)
    scrollBox:SetPoint("BOTTOMRIGHT", -26, 4)
    local scrollBar = CreateFrame("EventFrame", "VPAScrollBar", VPA.ResultsInset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 16)
    VPA.ScrollBox = scrollBox
    VPA.ScrollBar = scrollBar
end

function VPA.CreateResultsHeaders()
    local headers = CreateFrame("Frame", nil, VPA.ResultsInset)
    headers:SetHeight(18)
    headers:SetPoint("TOPLEFT", 4, -4)
    headers:SetPoint("TOPRIGHT", -4, -4)
    headers.Item = headers:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headers.Item:SetPoint("LEFT", 6, 0)
    headers.Item:SetText("Item")
    headers.Distance = headers:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headers.Distance:SetWidth(150)
    headers.Distance:SetPoint("RIGHT", -172, 0)
    headers.Distance:SetJustifyH("RIGHT")
    headers.Distance:SetText("Distance")
    headers.Price = headers:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headers.Price:SetWidth(150)
    headers.Price:SetPoint("RIGHT", -30, 0)
    headers.Price:SetJustifyH("RIGHT")
    headers.Price:SetText("Price")
    VPA.ResultsHeaders = headers
end

function VPA.CreateResultRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(24)
    row:SetPoint("LEFT", 0, 0)
    row:SetPoint("RIGHT", 0, 0)
    row:EnableMouse(true)
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(20, 20)
    row.Icon:SetPoint("LEFT", 4, 0)
    row.ItemText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.ItemText:SetPoint("LEFT", 28, -1)
    row.ItemText:SetJustifyH("LEFT")
    row.DistanceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.DistanceText:SetPoint("LEFT", 270, -1)
    row.PriceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.PriceText:SetPoint("RIGHT", -6, -1)
    row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.Highlight:SetAllPoints()
    row.Highlight:SetColorTexture(1, 1, 1, 0.08)
    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 4, 0)
    line:SetPoint("BOTTOMRIGHT", -4, 0)
    line:SetColorTexture(1, 1, 1, 0.08)
    row:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
        if self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink)
        else
            GameTooltip:SetItemByID(self.itemID)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if not self.resultData then return end
        VPA.ScrollBox:Hide()
        VPA.ResultsHeaders:Hide()
        VPA.ShowItemDetails(self.resultData)
    end)
    return row
end

function VPA.CreateDetailPanel()
    local panel = CreateFrame("Frame", "VPADetailPanel", VPA.Frame, "InsetFrameTemplate")
    panel:SetPoint("TOPLEFT", VPA.ResultsInset, "TOPLEFT", 4, -4)
    panel:SetPoint("BOTTOMRIGHT", VPA.ResultsInset, "BOTTOMRIGHT", -4, 4)    panel.Title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.Title:SetPoint("TOPLEFT", 10, -10)
    panel.Title:SetText("Details")
    panel.ItemName = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    panel.ItemName:SetPoint("TOPLEFT", panel.Title, "BOTTOMLEFT", 0, -8)
    panel.ItemName:SetJustifyH("LEFT")
    panel.Vendor = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.Vendor:SetPoint("TOPLEFT", panel.ItemName, "BOTTOMLEFT", 0, -12)
    panel.Zone = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.Zone:SetPoint("TOPLEFT", panel.Vendor, "BOTTOMLEFT", 0, -6)
    panel.Faction = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.Faction:SetPoint("TOPLEFT", panel.Zone, "BOTTOMLEFT", 0, -6)
    panel.Price = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.Price:SetPoint("TOPLEFT", panel.Faction, "BOTTOMLEFT", 0, -6)
    panel.BackButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.BackButton:SetSize(80, 22)
    panel.BackButton:SetPoint("TOPRIGHT", -10, -8)
    panel.BackButton:SetText("Back")
    panel.BackButton:SetScript("OnClick", function()
        panel:Hide()
        VPA.ScrollBox:ScrollToBegin()
        VPA.ScrollBox:Show()
        VPA.ResultsHeaders:Show()
    end)
    panel:Hide()
    VPA.DetailPanel = panel
end

function VPA.InitializeScrollView()
    VPA.DataProvider = CreateDataProvider()
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(24)
    view:SetElementInitializer("Button", function(frame, elementData)
        if not frame.initialized then
            local newRow = VPA.CreateResultRow(frame)
            frame.Row = newRow
            frame.Icon = newRow.Icon
            frame.ItemText = newRow.ItemText
            frame.DistanceText = newRow.DistanceText
            frame.PriceText = newRow.PriceText
            frame.initialized = true
        end
        frame.Row.resultData = elementData
        frame.ItemText:SetText(elementData.name or "n/a")
        frame.DistanceText:SetText(elementData.distance or "n/a")
        frame.PriceText:SetText(elementData.price or "n/a")
        frame.itemID = elementData.itemID
        frame.Row.itemID = elementData.itemID
        if elementData.icon then
            frame.Icon:SetTexture(elementData.icon)
        else
            frame.Icon:SetTexture(134400)
        end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(VPA.ScrollBox, VPA.ScrollBar, view)
    VPA.ScrollBox:SetDataProvider(VPA.DataProvider)
end

function VPA.RefreshResults()
    if not VPA.DataProvider then return end
    VPA.DataProvider:Flush()
    if not VPA.Results then return end
    for _, result in ipairs(VPA.Results) do
        VPA.DataProvider:Insert({
            itemID = result.itemID,
            name = result.name,
            distance = result.distance,
            price = result.price,
            icon = result.icon,
        })
    end
end

function VPA.BuildUI()
    VPA.CreateMainFrame()
    VPA.CreateSearchBox()
    VPA.CreateResultsInset()
    VPA.CreateResultsHeaders()
    VPA.CreateScrollArea()
    VPA.InitializeScrollView()
    VPA.CreateDetailPanel()
end

function VPA.ShowItemDetails(data)
    if not VPA.DetailPanel then return end
    local panel = VPA.DetailPanel
    panel.ItemName:SetText(data.name or "Unknown Item")
    panel.Vendor:SetText("Vendor: " .. (data.vendor or "Unknown"))
    panel.Zone:SetText("Zone: " .. (data.zone or "Unknown"))
    panel.Faction:SetText("Faction: " .. (data.faction or "None"))
    panel.Price:SetText("Price: " .. (data.price or "—"))
    panel:Show()
end

local function Normalize(str)
    if not str then return "" end
    return str:lower()
end

function VPA.BuildSearchIndex()
    wipe(VPA.SearchIndex)
    local count = 0
    for itemID, itemData in pairs(VPAItems) do
        local name = itemData.name
        if not name then
            name = C_Item.GetItemNameByID(itemID)
        end
        table.insert(VPA.SearchIndex, {
            itemID = itemID,
            name = name,
            nameLower = Normalize(name),
            icon = itemData.icon,
            vendors = itemData.vendors
        })
        count = count + 1
    end
end

function VPA.RunSearch(query)
    query = VPA.Trim(query):lower()
    VPA.Results = {}
    if query == "" then
        VPA.ClearResults()
        return
    end
    for _, entry in ipairs(VPA.SearchIndex) do
        if entry.nameLower:find(query, 1, true) then
            table.insert(VPA.Results, entry)
        end
    end
    table.sort(VPA.Results, function(a, b)
        return a.name < b.name
    end)
    VPA.RefreshResults()
end

function VPA.ClearResults()
    if not VPA.DataProvider then
        return
    end

    VPA.DataProvider:Flush()

    if VPA.ScrollBox then
        VPA.ScrollBox:FullUpdate()
    end
end

function VPA.Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end

local debounceFrame = CreateFrame("Frame")

local delay = 0.5
local elapsed = 0

debounceFrame:SetScript("OnUpdate", function(_, dt)
    if not VPA.SearchDirty then return end
    elapsed = elapsed + dt
    if elapsed < delay then return end
    elapsed = 0
    VPA.SearchDirty = false
    VPA.RunSearch(VPA.PendingSearchQuery)
end)


VPA.BuildSearchIndex()
VPA.BuildUI()


function SlashCmdList.VENDORPEDIA(msg)
    if msg == "show" then
        VPA.Frame:Show()
    elseif msg == "hide" then
        VPA.Frame:Hide()
    elseif msg == "toggle" then
        if VPA.Frame:IsShown() then
            VPA.Frame:Hide()
        else
            VPA.Frame:Show()
        end
    else
        print("Usage:  /vpa show | hide | toggle")
    end
end


-- VPItemLinkText:HookScript("OnEnter", function()
--     if (VPItemLink) then
--         GameTooltip:SetOwner(VPItemLinkText, "ANCHOR_TOP")
--         GameTooltip:SetHyperlink(VPItemLink)
--         GameTooltip:Show()
--     end
-- end)
-- VPItemLinkText:HookScript("OnLeave", function() GameTooltip:Hide() end)



-- Function to extract a name from a link and put it in the search box
function VPA.InsertLink(link)
    -- Don't steal the link if chat edit box has focus (safe if ChatFrame1EditBox missing in 12.x)
    if not link or not VPA.SearchBox or not VPA.SearchBox:IsVisible() then
        return
    end
    if ChatFrame1EditBox and ChatFrame1EditBox:HasFocus() then
        return
    end

    local itemName
    if link:find("battlepet:") then
        -- battle‑pet links are already formatted [Name (rarity)], strip the brackets
        itemName = link:match("%[(.+)%]")
    elseif link:find("item:", 1, true) then
        -- regular item: try GetItemInfo first; in 12.x it can return nil until item is cached
        itemName = GetItemInfo(link)
        if not itemName then
            -- fallback: parse display name from link (e.g. |c...|Hitem:123:...|h[Name]|h|r)
            itemName = link:match("|h%[(.-)%]|h")
        end
    end

    if itemName and itemName ~= "" then
        StackSplitFrame:Hide()
        VPA.SearchBox:SetText(itemName)
        VPA.SearchBox:SetFocus()
        return true
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")

loader:SetScript("OnEvent", function()

    if ChatFrameUtil and ChatFrameUtil.InsertLink then
        local original_InsertLink = ChatFrameUtil.InsertLink

        function ChatFrameUtil.InsertLink(link)
            -- If Vendorpedia is open, consume the link
            if VPA.Frame and VPA.Frame:IsShown() then
                if VPA.InsertLink(link) then
                    return true -- STOP further processing
                end
            end

            return original_InsertLink(link)
        end
    end

    if ChatEdit_InsertLink then
        local original_ChatEditInsert = ChatEdit_InsertLink

        function ChatEdit_InsertLink(link)
            if VPA.Frame and VPA.Frame:IsShown() then
                if VPA.InsertLink(link) then
                    return true
                end
            end

            return original_ChatEditInsert(link)
        end
    end

end)

VPA.Frame:SetScript("OnShow", function(self)
    PlaySound(16347)
    VPA.SearchBox:SetText("")
end)

