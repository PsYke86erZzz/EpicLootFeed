--[[
    Design: Fire
    Brennendes Design mit Flammen-Effekten
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    row:SetSize(300, 56)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    row:SetBackdropColor(0.15, 0.05, 0.02, 0.95)
    row:SetBackdropBorderColor(1, 0.4, 0.1, 0.9)
    
    -- Fire glow background
    local fireGlow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    fireGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    fireGlow:SetGradient("VERTICAL", CreateColor(0.4, 0.1, 0, 0.8), CreateColor(0.1, 0.02, 0, 0.2))
    fireGlow:SetPoint("TOPLEFT", 4, -4)
    fireGlow:SetPoint("BOTTOMRIGHT", -4, 4)
    row.fireGlow = fireGlow
    
    -- Top flame line
    local flameLine = row:CreateTexture(nil, "ARTWORK")
    flameLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    flameLine:SetHeight(2)
    flameLine:SetPoint("TOPLEFT", 8, -5)
    flameLine:SetPoint("TOPRIGHT", -8, -5)
    flameLine:SetVertexColor(1, 0.5, 0, 0.8)
    row.flameLine = flameLine
    
    -- Ember particles
    local ember1 = row:CreateTexture(nil, "OVERLAY")
    ember1:SetTexture("Interface\\Cooldown\\star4")
    ember1:SetSize(12, 12)
    ember1:SetPoint("TOPRIGHT", -15, -8)
    ember1:SetVertexColor(1, 0.6, 0.2)
    ember1:SetBlendMode("ADD")
    row.ember1 = ember1
    
    local ember2 = row:CreateTexture(nil, "OVERLAY")
    ember2:SetTexture("Interface\\Cooldown\\star4")
    ember2:SetSize(8, 8)
    ember2:SetPoint("TOP", -20, -6)
    ember2:SetVertexColor(1, 0.4, 0.1)
    ember2:SetBlendMode("ADD")
    row.ember2 = ember2
    
    -- Icon frame
    local iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconFrame:SetSize(42, 42)
    iconFrame:SetPoint("LEFT", 10, 0)
    iconFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    iconFrame:SetBackdropBorderColor(1, 0.4, 0, 1)
    row.iconFrame = iconFrame
    
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Header
    local header = row:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    header:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -3)
    header:SetTextColor(1, 0.7, 0.3)
    row.header = header
    
    -- Item name
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    itemName:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    itemName:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetShadowOffset(1, -1)
    row.itemName = itemName
    
    -- Count
    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    row.count = count
    
    -- Ember animation
    row.animTime = 0
    row:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self.animTime = (self.animTime or 0) + elapsed * 3
        local flicker1 = 0.3 + 0.7 * math.abs(math.sin(self.animTime * 1.5))
        local flicker2 = 0.3 + 0.7 * math.abs(math.sin(self.animTime * 2.1 + 1))
        if self.ember1 then self.ember1:SetAlpha(flicker1 * self:GetAlpha()) end
        if self.ember2 then self.ember2:SetAlpha(flicker2 * self:GetAlpha()) end
    end)
    
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
    
    row.animTime = 0
end

ELF:RegisterDesign(4, {
    name = "Fire",
    description = "Brennende Flammen",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
