--[[
    Design: Frost
    Eisiges Design mit Kristall-Effekten
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
    row:SetBackdropColor(0.02, 0.08, 0.15, 0.95)
    row:SetBackdropBorderColor(0.4, 0.7, 1, 0.9)
    
    -- Frost glow background
    local frostGlow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    frostGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    frostGlow:SetGradient("VERTICAL", CreateColor(0.1, 0.2, 0.4, 0.8), CreateColor(0.02, 0.05, 0.1, 0.2))
    frostGlow:SetPoint("TOPLEFT", 4, -4)
    frostGlow:SetPoint("BOTTOMRIGHT", -4, 4)
    row.frostGlow = frostGlow
    
    -- Top ice line
    local iceLine = row:CreateTexture(nil, "ARTWORK")
    iceLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    iceLine:SetHeight(2)
    iceLine:SetPoint("TOPLEFT", 8, -5)
    iceLine:SetPoint("TOPRIGHT", -8, -5)
    iceLine:SetVertexColor(0.5, 0.8, 1, 0.8)
    row.iceLine = iceLine
    
    -- Ice crystal particles
    local crystal1 = row:CreateTexture(nil, "OVERLAY")
    crystal1:SetTexture("Interface\\Cooldown\\star4")
    crystal1:SetSize(14, 14)
    crystal1:SetPoint("TOPRIGHT", -12, -6)
    crystal1:SetVertexColor(0.6, 0.9, 1)
    crystal1:SetBlendMode("ADD")
    row.crystal1 = crystal1
    
    local crystal2 = row:CreateTexture(nil, "OVERLAY")
    crystal2:SetTexture("Interface\\Cooldown\\star4")
    crystal2:SetSize(10, 10)
    crystal2:SetPoint("TOP", -30, -4)
    crystal2:SetVertexColor(0.4, 0.7, 1)
    crystal2:SetBlendMode("ADD")
    row.crystal2 = crystal2
    
    -- Icon frame
    local iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    iconFrame:SetSize(42, 42)
    iconFrame:SetPoint("LEFT", 10, 0)
    iconFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    iconFrame:SetBackdropBorderColor(0.4, 0.7, 1, 1)
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
    header:SetTextColor(0.7, 0.9, 1)
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
    
    -- Crystal shimmer animation
    row.animTime = 0
    row:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self.animTime = (self.animTime or 0) + elapsed * 2
        local shimmer1 = 0.4 + 0.6 * math.abs(math.sin(self.animTime * 0.8))
        local shimmer2 = 0.4 + 0.6 * math.abs(math.sin(self.animTime * 1.2 + 2))
        if self.crystal1 then self.crystal1:SetAlpha(shimmer1 * self:GetAlpha()) end
        if self.crystal2 then self.crystal2:SetAlpha(shimmer2 * self:GetAlpha()) end
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

ELF:RegisterDesign(5, {
    name = "Frost",
    description = "Eisige Kristalle",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
