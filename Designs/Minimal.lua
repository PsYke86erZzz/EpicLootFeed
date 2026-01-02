--[[
    Design: Minimal
    Nur schwebender Text ohne Hintergrund (MSBT Style)
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(300, 24)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Icon (small)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Item name with shadow
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    itemName:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemName:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetShadowOffset(2, -2)
    itemName:SetShadowColor(0, 0, 0, 1)
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
    
    local countStr = ""
    if count and count > 1 then
        countStr = " x" .. count
    end
    
    local nameText = string.format("|cff%02x%02x%02x[%s]%s|r", 
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt", countStr)
    row.itemName:SetText(nameText)
end

ELF:RegisterDesign(7, {
    name = "Minimal",
    description = "Nur Text (MSBT Style)",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
