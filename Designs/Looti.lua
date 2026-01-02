--[[
    Design: Looti
    Kompaktes Design wie Looti Addon (schmal, dunkel)
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    row:SetSize(220, 24)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Dark compact background
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    row:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    row:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    
    -- Left color bar
    local colorBar = row:CreateTexture(nil, "ARTWORK")
    colorBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    colorBar:SetSize(3, 22)
    colorBar:SetPoint("LEFT", 1, 0)
    row.colorBar = colorBar
    
    -- Icon (small)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Item name (single line)
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    itemName:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemName:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetWordWrap(false)
    row.itemName = itemName
    
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

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.colorBar:SetVertexColor(color.r, color.g, color.b, 1)
    row:SetBackdropBorderColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.8)
    
    local countStr = ""
    if count and count > 1 then
        countStr = " x" .. count
    end
    
    local nameText = string.format("|cff%02x%02x%02x%s%s|r", 
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt", countStr)
    row.itemName:SetText(nameText)
end

ELF:RegisterDesign(3, {
    name = "Kompakt",
    description = "Schlankes Mini-Design",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
