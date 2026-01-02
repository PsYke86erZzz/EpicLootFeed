# EpicLootFeed - Modulares Design System

## Neues Design erstellen

1. Erstelle eine neue Datei in `/Designs/MeinDesign.lua`
2. Füge die Datei zur `EpicLootFeed.toc` hinzu
3. Fertig!

## Design Template

```lua
--[[
    Design: MeinDesign
    Beschreibung hier
]]

local _, ELF = ...

-- CreateRow: Erstellt das Frame mit allen Elementen
local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    row:SetSize(300, 56)  -- Breite, Höhe
    row:SetFrameStrata("HIGH")
    row:SetFrameLevel(100)
    
    -- Hintergrund/Border
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    row:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    
    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    
    -- Header Text (optional)
    local header = row:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    header:SetTextColor(0.9, 0.8, 0.4)
    row.header = header
    
    -- Item Name (PFLICHT!)
    local itemName = row:CreateFontString(nil, "OVERLAY")
    itemName:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    itemName:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    itemName:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    itemName:SetJustifyH("LEFT")
    row.itemName = itemName
    
    -- Count Text (optional)
    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    row.count = count
    
    -- Tooltip (empfohlen)
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

-- ApplyStyle: Wendet Daten auf die Row an
-- row: Das Frame
-- iconTex: Icon Textur Pfad
-- name: Item Name
-- count: Anzahl (kann nil sein)
-- quality: Qualität 0-7
-- color: {r=, g=, b=} Qualitätsfarbe
-- isMoney: true wenn Geld
local function ApplyStyle(row, iconTex, name, count, quality, color, isMoney)
    row.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    
    row.header:SetText("Du hast erhalten")
    
    -- Name mit Qualitätsfarbe
    local nameText = string.format("|cff%02x%02x%02x%s|r", 
        color.r * 255, color.g * 255, color.b * 255, name or "Unbekannt")
    row.itemName:SetText(nameText)
    
    -- Count
    if count and count > 1 then
        row.count:SetText("x" .. count)
    else
        row.count:SetText("")
    end
end

-- Design registrieren
-- ID: Eindeutige Nummer (nächste freie nehmen)
-- name: Anzeigename im Config
-- description: Tooltip Beschreibung
ELF:RegisterDesign(99, {
    name = "MeinDesign",
    description = "Beschreibung für Tooltip",
    CreateRow = CreateRow,
    ApplyStyle = ApplyStyle,
})
```

## Verfügbare Qualitätsfarben

```lua
local color = ELF.QualityColors[quality]
-- color.r, color.g, color.b (0-1)

-- 0 = Grau (Poor)
-- 1 = Weiß (Common)
-- 2 = Grün (Uncommon)
-- 3 = Blau (Rare)
-- 4 = Lila (Epic)
-- 5 = Orange (Legendary)
-- 6 = Gold (Artifact)
-- 7 = Hellblau (Heirloom)
```

## Tipps

- Für Animationen: `row:SetScript("OnUpdate", function(self, elapsed) ... end)`
- Für Partikel: `row:CreateTexture()` mit `SetBlendMode("ADD")`
- Nutze `row.animTime` für Animation-Timer
- Teste mit `/elf test`
