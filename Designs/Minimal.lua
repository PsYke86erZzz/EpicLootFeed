--[[
    Design: Minimal
    Nur schwebender Text ohne Hintergrund (MSBT Style)
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(350, 28)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Item name - saubere Schrift ohne dicken Rand
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    itemName:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemName:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetShadowOffset(1, -1)
    itemName:SetShadowColor(0, 0, 0, 0.8)
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

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney, looterName, customLabel)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    local countStr = ""
    if count and count > 1 then
        countStr = " x" .. count
    end
    
    -- Prefix für Label
    local prefix = ""
    if customLabel then
        prefix = "|cffcccccc" .. customLabel .. ":|r "
    elseif looterName then
        prefix = "|cffffcc00" .. looterName .. " erhält:|r "
    end
    
    local nameText = string.format("%s|cff%02x%02x%02x%s|r%s", 
        prefix, color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt", countStr)
    row.itemName:SetText(nameText)
end

ELF:RegisterDesign(7, {
    name = "Minimal",
    description = "Schwebender Text",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
