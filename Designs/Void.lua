--[[
    Design: Void
    Dunkles Void-Design mit violetten Energie-Effekten
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
    row:SetBackdropColor(0.08, 0.02, 0.12, 0.95)
    row:SetBackdropBorderColor(0.6, 0.2, 0.8, 0.9)
    
    -- Void glow background
    local voidGlow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    voidGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    voidGlow:SetGradient("HORIZONTAL", CreateColor(0.15, 0.05, 0.2, 0.8), CreateColor(0.05, 0.01, 0.08, 0.3))
    voidGlow:SetPoint("TOPLEFT", 4, -4)
    voidGlow:SetPoint("BOTTOMRIGHT", -4, 4)
    row.voidGlow = voidGlow
    
    -- Top void line
    local voidLine = row:CreateTexture(nil, "ARTWORK")
    voidLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    voidLine:SetHeight(2)
    voidLine:SetPoint("TOPLEFT", 8, -5)
    voidLine:SetPoint("TOPRIGHT", -8, -5)
    voidLine:SetVertexColor(0.7, 0.3, 1, 0.8)
    row.voidLine = voidLine
    
    -- Void wisp particles
    local wisp1 = row:CreateTexture(nil, "OVERLAY")
    wisp1:SetTexture("Interface\\Cooldown\\star4")
    wisp1:SetSize(12, 12)
    wisp1:SetPoint("TOPRIGHT", -14, -8)
    wisp1:SetVertexColor(0.8, 0.4, 1)
    wisp1:SetBlendMode("ADD")
    row.wisp1 = wisp1
    
    local wisp2 = row:CreateTexture(nil, "OVERLAY")
    wisp2:SetTexture("Interface\\Cooldown\\star4")
    wisp2:SetSize(8, 8)
    wisp2:SetPoint("TOP", -25, -5)
    wisp2:SetVertexColor(0.5, 0.2, 0.8)
    wisp2:SetBlendMode("ADD")
    row.wisp2 = wisp2
    
    -- Icon frame
    local iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconFrame:SetSize(42, 42)
    iconFrame:SetPoint("LEFT", 10, 0)
    iconFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    iconFrame:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
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
    header:SetTextColor(0.8, 0.5, 1)
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
    
    -- Wisp drift animation
    row.animTime = 0
    row:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self.animTime = (self.animTime or 0) + elapsed * 1.5
        local drift1 = 0.3 + 0.7 * math.abs(math.sin(self.animTime * 0.6))
        local drift2 = 0.3 + 0.7 * math.abs(math.sin(self.animTime * 0.9 + 1.5))
        if self.wisp1 then self.wisp1:SetAlpha(drift1 * self:GetAlpha()) end
        if self.wisp2 then self.wisp2:SetAlpha(drift2 * self:GetAlpha()) end
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

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    
    row.header:SetText("Du hast erhalten")
    
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

ELF:RegisterDesign(6, {
    name = "Void",
    description = "Dunkle Void-Energie",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
