--[[
    Design: Classic
    Einfaches, sauberes Design mit Tooltip-Style
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    row:SetSize(300, 50)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    row:SetBackdropColor(0.1, 0.1, 0.12, 0.95)
    
    -- Icon
    local iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconFrame:SetSize(40, 40)
    iconFrame:SetPoint("LEFT", 8, 0)
    iconFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    row.iconFrame = iconFrame
    
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Header
    local header = row:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    header:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
    header:SetTextColor(0.9, 0.8, 0.4)
    row.header = header
    
    -- Item name
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    itemName:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    itemName:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetShadowOffset(1, -1)
    row.itemName = itemName
    
    -- Count
    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    row.count = count
    
    -- Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    row:Hide()
    return row
end

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney, looterName, customLabel)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    row:SetBackdropBorderColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.8)
    
    -- Label Text
    local labelText = "Du erhältst"
    if customLabel then
        labelText = customLabel
    elseif looterName then
        labelText = looterName .. " erhält"
    end
    row.header:SetText(labelText)
    
    local nameText = string.format("|cff%02x%02x%02x%s|r", 
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt")
    row.itemName:SetText(nameText)
    
    if count and count > 1 then
        row.count:SetText("x" .. count)
    else
        row.count:SetText("")
    end
end

-- Register Design
ELF:RegisterDesign(1, {
    name = "Classic",
    description = "Einfaches Tooltip-Design",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
