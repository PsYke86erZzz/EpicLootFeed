--[[
    Design: Pretty
    Exakte Nachbildung von pretty_lootalert (s0h2x)
    https://github.com/s0h2x/pretty_lootalert
    
    Benutzt die Original-Texturen!
]]

local _, ELF = ...

local ASSETS = "Interface\\AddOns\\EpicLootFeed\\assets\\"

-- Icon Border TexCoords aus LootToastAtlas.BLP für jede Qualität
local BORDER_COORDS = {
    [0] = nil,  -- Poor: kein spezieller Border
    [1] = nil,  -- Common: kein spezieller Border
    [2] = {0.34082, 0.397461, 0.53125, 0.644531},      -- Uncommon (Grün)
    [3] = {0.272461, 0.329102, 0.785156, 0.898438},    -- Rare (Blau)
    [4] = {0.34082, 0.397461, 0.882812, 0.996094},     -- Epic (Lila)
    [5] = {0.34082, 0.397461, 0.765625, 0.878906},     -- Legendary (Orange)
    [6] = {0.272461, 0.329102, 0.667969, 0.78125},     -- Artifact (Gold)
    [7] = {0.34082, 0.397461, 0.648438, 0.761719},     -- Heirloom (Hellblau)
}

-- Sounds
local SOUNDS = {
    EPIC = ASSETS .. "ui_epicloot_toast_01.ogg",
    LEGENDARY = ASSETS .. "ui_legendary_item_toast.ogg",
    LESSER = ASSETS .. "ui_loot_toast_lesser_item_won_01.ogg",
}

local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(276, 96)
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Standard Hintergrund (loottoast.blp)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(ASSETS .. "loottoast")
    bg:SetSize(276, 96)
    bg:SetPoint("CENTER")
    bg:SetTexCoord(0.28222656, 0.55175781, 0.57812500, 0.95312500)
    row.bg = bg
    
    -- Legendary Hintergrund (LegendaryToast.blp) - versteckt bis gebraucht
    local legendaryBg = row:CreateTexture(nil, "ARTWORK")
    legendaryBg:SetTexture(ASSETS .. "LegendaryToast")
    legendaryBg:SetSize(302, 119)
    legendaryBg:SetPoint("CENTER", -12, -4)
    legendaryBg:SetTexCoord(0.396484, 0.986328, 0.00195312, 0.234375)
    legendaryBg:Hide()
    row.legendaryBg = legendaryBg
    
    -- Glow Effekt (LootToastAtlas)
    local glow = row:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(ASSETS .. "LootToastAtlas")
    glow:SetSize(286, 109)
    glow:SetPoint("CENTER")
    glow:SetTexCoord(0.000976562, 0.280273, 0.00195312, 0.214844)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0)
    row.glow = glow
    
    -- Icon Container für bessere Positionierung
    local iconAnchor = CreateFrame("Frame", nil, row)
    iconAnchor:SetSize(52, 52)
    iconAnchor:SetPoint("LEFT", 23, -2)
    row.iconAnchor = iconAnchor
    
    -- Icon (52x52)
    local icon = row:CreateTexture(nil, "BORDER")
    icon:SetSize(52, 52)
    icon:SetAllPoints(iconAnchor)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon = icon
    
    -- Icon Border (LootToastAtlas) - 58x58
    local iconBorder = row:CreateTexture(nil, "ARTWORK")
    iconBorder:SetTexture(ASSETS .. "LootToastAtlas")
    iconBorder:SetSize(58, 58)
    iconBorder:SetPoint("CENTER", iconAnchor, "CENTER", 0, 0)
    iconBorder:SetTexCoord(0.34082, 0.397461, 0.53125, 0.644531) -- Default: Grün
    row.iconBorder = iconBorder
    
    -- Stack Count
    local count = row:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", iconAnchor, "BOTTOMRIGHT", -2, 2)
    count:SetJustifyH("RIGHT")
    row.count = count
    
    -- "Du erhältst" Label (oben)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetSize(180, 16)
    label:SetPoint("TOPLEFT", iconAnchor, "TOPRIGHT", 10, 2)
    label:SetJustifyH("LEFT")
    label:SetText("Du erhältst")
    row.label = label
    
    -- Item Name (mehr mittig)
    local itemName = row:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
    itemName:SetSize(180, 30)
    itemName:SetPoint("LEFT", iconAnchor, "RIGHT", 10, -8)
    itemName:SetJustifyH("LEFT")
    itemName:SetJustifyV("MIDDLE")
    itemName:SetWordWrap(true)
    row.itemName = itemName
    
    -- Animation: Glow einblenden
    row.glowAnim = 0
    
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
    row:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" and IsShiftKeyDown() and self.itemLink then
            ChatEdit_InsertLink(self.itemLink)
        end
    end)
    
    row:Hide()
    return row
end

local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney, looterName, customLabel)
    row.quality = quality
    
    -- Label Text basierend auf customLabel, looterName, oder default
    local labelText = "Du erhältst"
    if customLabel then
        -- Custom Label hat Priorität (z.B. "Verkauft", "Gekauft", "Ausgegeben")
        labelText = customLabel
    elseif looterName then
        -- Kürze Namen wenn zu lang
        local shortName = looterName:len() > 12 and looterName:sub(1, 10) .. ".." or looterName
        labelText = shortName .. " erhält"
    end
    
    -- Icon
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    -- Legendary Item?
    if quality >= 5 then
        -- Zeige Legendary Background
        row.bg:Hide()
        row.legendaryBg:Show()
        row:SetSize(302, 119)
        
        -- Icon und Text neu positionieren für größeren Frame
        row.iconAnchor:ClearAllPoints()
        row.iconAnchor:SetPoint("LEFT", 30, 0)
        
        -- Legendary Sound
        if ELF.db and ELF.db.playSounds then
            PlaySoundFile(SOUNDS.LEGENDARY, "Master")
        end
        
        -- Label für Legendary (oben)
        if customLabel then
            row.label:SetText("|cffff8000" .. customLabel .. "|r")
        elseif looterName then
            local shortName = looterName:len() > 10 and looterName:sub(1, 8) .. ".." or looterName
            row.label:SetText("|cffff8000" .. shortName .. " → Legendär!|r")
        else
            row.label:SetText("|cffff8000Legendäres Item!|r")
        end
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", row.iconAnchor, "TOPRIGHT", 12, 6)
        
        -- Item Name (mehr mittig)
        row.itemName:ClearAllPoints()
        row.itemName:SetPoint("LEFT", row.iconAnchor, "RIGHT", 12, -8)
        row.itemName:SetSize(190, 40)
        
        -- Glow Animation starten
        row.glow:SetAlpha(0.8)
        row.glowAnim = GetTime()
        row:SetScript("OnUpdate", function(self, elapsed)
            local t = GetTime() - self.glowAnim
            if t < 0.5 then
                self.glow:SetAlpha(0.8 * (1 - t / 0.5) * self:GetAlpha())
            else
                self.glow:SetAlpha(0)
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif quality >= 4 then
        -- Epic
        row.bg:Show()
        row.legendaryBg:Hide()
        row:SetSize(276, 96)
        
        row.iconAnchor:ClearAllPoints()
        row.iconAnchor:SetPoint("LEFT", 23, 0)
        
        row.label:SetText(labelText)
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", row.iconAnchor, "TOPRIGHT", 10, 2)
        
        row.itemName:ClearAllPoints()
        row.itemName:SetPoint("LEFT", row.iconAnchor, "RIGHT", 10, -8)
        row.itemName:SetJustifyV("MIDDLE")
        
        row.glow:SetAlpha(0)
        
        -- Epic Sound
        if ELF.db and ELF.db.playSounds then
            PlaySoundFile(SOUNDS.EPIC, "Master")
        end
    else
        -- Normal
        row.bg:Show()
        row.legendaryBg:Hide()
        row:SetSize(276, 96)
        
        row.iconAnchor:ClearAllPoints()
        row.iconAnchor:SetPoint("LEFT", 23, 0)
        
        row.label:SetText(labelText)
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", row.iconAnchor, "TOPRIGHT", 10, 2)
        
        row.itemName:ClearAllPoints()
        row.itemName:SetPoint("LEFT", row.iconAnchor, "RIGHT", 10, -8)
        row.itemName:SetJustifyV("MIDDLE")
        
        row.glow:SetAlpha(0)
        
        -- Lesser Sound für Rare
        if quality >= 3 and ELF.db and ELF.db.playSounds then
            PlaySoundFile(SOUNDS.LESSER, "Master")
        end
    end
    
    -- Icon Border basierend auf Qualität
    local coords = BORDER_COORDS[quality]
    if coords then
        row.iconBorder:Show()
        row.iconBorder:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        -- Poor/Common: Einfacher grauer Border oder verstecken
        row.iconBorder:Hide()
    end
    
    -- Item Name in Qualitätsfarbe
    local nameText = string.format("|cff%02x%02x%02x%s|r",
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt")
    row.itemName:SetText(nameText)
    
    -- Stack Count
    if count and count > 1 then
        row.count:SetText(count)
    else
        row.count:SetText("")
    end
end

ELF:RegisterDesign(8, {
    name = "Epic",
    description = "Epischer Loot-Toast Style",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
