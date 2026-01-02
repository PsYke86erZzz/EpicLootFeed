--[[
    Design: Ornate
    Goldener ornamentierter Rahmen (RPGLootFeed Style)
]]

local _, ELF = ...

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    row:SetSize(320, 64)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Gold ornate border
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 24,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    row:SetBackdropColor(0.1, 0.08, 0.05, 0.95)
    
    -- Inner gradient
    local innerBg = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    innerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    innerBg:SetGradient("HORIZONTAL", CreateColor(0.12, 0.1, 0.06, 0.9), CreateColor(0.05, 0.04, 0.02, 0.95))
    innerBg:SetPoint("TOPLEFT", 6, -6)
    innerBg:SetPoint("BOTTOMRIGHT", -6, 6)
    row.innerBg = innerBg
    
    -- Top decorative line
    local topLine = row:CreateTexture(nil, "ARTWORK")
    topLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    topLine:SetHeight(1)
    topLine:SetPoint("TOPLEFT", 12, -9)
    topLine:SetPoint("TOPRIGHT", -12, -9)
    topLine:SetVertexColor(0.8, 0.65, 0.3, 0.6)
    row.topLine = topLine
    
    -- Icon frame
    local iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconFrame:SetSize(48, 48)
    iconFrame:SetPoint("LEFT", 12, 0)
    iconFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    row.iconFrame = iconFrame
    
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(44, 44)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Icon glow
    local iconGlow = iconFrame:CreateTexture(nil, "OVERLAY")
    iconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconGlow:SetBlendMode("ADD")
    iconGlow:SetSize(70, 70)
    iconGlow:SetPoint("CENTER")
    iconGlow:SetAlpha(0)
    row.iconGlow = iconGlow
    
    -- Header
    local header = row:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    header:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 12, -4)
    header:SetTextColor(0.95, 0.78, 0.3)
    header:SetShadowOffset(1, -1)
    row.header = header
    
    -- Item name
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    itemName:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    itemName:SetPoint("RIGHT", row, "RIGHT", -14, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetShadowOffset(1, -1)
    row.itemName = itemName
    
    -- Count
    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
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

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    row:SetBackdropBorderColor(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1)
    row.topLine:SetVertexColor(color.r, color.g, color.b, 0.7)
    
    row.header:SetText("Du hast erhalten")
    
    local nameText = string.format("|cff%02x%02x%02x%s|r", 
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt")
    row.itemName:SetText(nameText)
    
    if count and count > 1 then
        row.count:SetText("x" .. count)
    else
        row.count:SetText("")
    end
    
    -- Glow for rare+
    if quality >= 3 then
        row.iconGlow:SetVertexColor(color.r, color.g, color.b)
        row.iconGlow:SetAlpha(0.7)
    else
        row.iconGlow:SetAlpha(0)
    end
end

ELF:RegisterDesign(2, {
    name = "Ornate",
    description = "Goldener Rahmen (RPGLootFeed)",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
