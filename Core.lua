--[[
    EpicLootFeed v5.0 - Modular Design System
    
    Designs sind eigene Module in /Designs/
    Einfach neue Designs hinzufügen!
]]

local ADDON_NAME, ELF = ...
_G.EpicLootFeed = ELF
ELF.version = "5.3.1"
ELF.debugMode = false

-- ============================================================
-- DESIGN REGISTRY - Hier registrieren sich alle Designs
-- ============================================================
ELF.Designs = {}

function ELF:RegisterDesign(id, designData)
    --[[
        designData = {
            name = "Anzeigename",
            description = "Beschreibung",
            CreateRow = function() return frame end,  -- Erstellt die Row
            ApplyStyle = function(row, quality, color, isMoney) end,  -- Wendet Styling an
        }
    ]]
    self.Designs[id] = designData
    print("|cff00ff00EpicLootFeed|r: Design '" .. designData.name .. "' registriert")
end

function ELF:GetDesign(id)
    return self.Designs[id]
end

function ELF:GetDesignList()
    local list = {}
    for id, data in pairs(self.Designs) do
        table.insert(list, {id = id, name = data.name, description = data.description})
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- ============================================================
-- DEFAULTS & STORAGE
-- ============================================================
local defaults = {
    enabled = true,
    design = 1,
    maxRows = 6,
    rowSpacing = 10,  -- Abstand zwischen Popups (zusätzlich zur Frame-Höhe)
    fadeTime = 5,
    scale = 1.0,
    minimumQuality = 0,
    showMoney = true,
    showGroupLoot = true,  -- Zeige Loot von Gruppenmitgliedern
    showMinimapButton = true,
    buttonX = 400,
    buttonY = 300,
    anchorX = -150,
    anchorY = 0,
    growUp = true,
}

local QualityColors = {
    [0] = {r = 0.62, g = 0.62, b = 0.62},
    [1] = {r = 1.00, g = 1.00, b = 1.00},
    [2] = {r = 0.12, g = 1.00, b = 0.00},
    [3] = {r = 0.00, g = 0.44, b = 0.87},
    [4] = {r = 0.64, g = 0.21, b = 0.93},
    [5] = {r = 1.00, g = 0.50, b = 0.00},
    [6] = {r = 0.90, g = 0.80, b = 0.50},
    [7] = {r = 0.00, g = 0.80, b = 1.00},
}
ELF.QualityColors = QualityColors

local rowPools = {}  -- Pool per design
local activeRows = {}
local anchorFrame = nil
local db = nil

-- ============================================================
-- INITIALIZE
-- ============================================================
local function InitDB()
    if not EpicLootFeedDB then EpicLootFeedDB = {} end
    for k, v in pairs(defaults) do
        if EpicLootFeedDB[k] == nil then
            EpicLootFeedDB[k] = v
        end
    end
    db = EpicLootFeedDB
    ELF.db = db
end

local function CreateAnchor()
    if anchorFrame then return end
    anchorFrame = CreateFrame("Frame", "ELF_Anchor", UIParent)
    anchorFrame:SetSize(320, 10)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or -150, db.anchorY or 0)
    anchorFrame:SetFrameStrata("HIGH")
    ELF.anchorFrame = anchorFrame
end

-- ============================================================
-- ROW MANAGEMENT
-- ============================================================
local function GetRow(designId)
    local design = ELF:GetDesign(designId)
    if not design then
        designId = 1
        design = ELF:GetDesign(1)
    end
    if not design then return nil end
    
    -- Pool per design
    if not rowPools[designId] then rowPools[designId] = {} end
    
    local row = table.remove(rowPools[designId])
    if not row then
        row = design.CreateRow()
        row.designId = designId
    end
    return row
end

local function ReleaseRow(row)
    row:Hide()
    row:SetAlpha(1)
    row.isActive = false
    row.itemLink = nil
    
    local designId = row.designId or 1
    if not rowPools[designId] then rowPools[designId] = {} end
    table.insert(rowPools[designId], row)
end

local function ClearAllRows()
    for _, row in ipairs(activeRows) do
        ReleaseRow(row)
    end
    activeRows = {}
end

-- ============================================================
-- POSITION UPDATE
-- ============================================================
local function UpdatePositions()
    if not anchorFrame then return end
    local direction = db.growUp and 1 or -1
    local spacing = db.rowSpacing or 10  -- Benutzer-einstellbarer Abstand
    local currentY = 0
    
    for i, row in ipairs(activeRows) do
        row:ClearAllPoints()
        row:SetPoint("CENTER", anchorFrame, "CENTER", 0, currentY * direction)
        -- Dynamischer Abstand basierend auf Frame-Höhe + Benutzer-Spacing
        local rowHeight = row:GetHeight() or 96
        currentY = currentY + rowHeight + spacing
    end
end

-- ============================================================
-- SHOW LOOT - Main Function
-- ============================================================
function ELF:ShowLoot(iconTex, name, count, quality, itemLink, isMoney, looterName)
    if ELF.debugMode then
        print("|cff00ffffShowLoot:|r name=" .. tostring(name) .. " Q=" .. tostring(quality))
    end
    
    if not db or not db.enabled then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r db/enabled") end
        return 
    end
    if not anchorFrame then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r anchorFrame nil!") end
        return 
    end
    if not isMoney and quality < (db.minimumQuality or 0) then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r quality " .. tostring(quality) .. " < min " .. tostring(db.minimumQuality)) end
        return 
    end
    
    local designId = db.design or 1
    local design = self:GetDesign(designId)
    if not design then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r Design " .. tostring(designId) .. " nicht gefunden!") end
        return 
    end
    
    if ELF.debugMode then
        print("|cff00ff00ShowLoot:|r Design=" .. design.name .. " erstelle Row...")
    end
    
    -- Limit rows
    while #activeRows >= (db.maxRows or 6) do
        local old = table.remove(activeRows, 1)
        if old then ReleaseRow(old) end
    end
    
    local row = GetRow(designId)
    if not row then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r GetRow gab nil zurück!") end
        return 
    end
    
    local color = QualityColors[quality] or QualityColors[1]
    
    row.itemLink = itemLink
    row.quality = quality
    row.isActive = true
    row.looterName = looterName
    
    -- Apply design styling
    design.ApplyStyle(row, iconTex, name, count, quality, color, isMoney, looterName)
    
    -- Scale
    row:SetScale(db.scale or 1.0)
    
    -- Show with fade in
    row:SetAlpha(0)
    row:Show()
    table.insert(activeRows, 1, row)
    UpdatePositions()
    
    if ELF.debugMode then
        print("|cff00ff00ShowLoot OK:|r Row angezeigt! activeRows=" .. #activeRows)
    end
    
    -- Fade in animation
    local elapsed = 0
    row:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.25 then
            self:SetAlpha(elapsed / 0.25)
        else
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        end
    end)
    
    -- Sound
    if not isMoney and quality >= 5 then
        PlaySound(8455, "Master")
    elseif not isMoney and quality >= 4 then
        PlaySound(8454, "Master")
    end
    
    -- Fade out timer
    C_Timer.After(db.fadeTime or 5, function()
        if row.isActive then
            local fadeElapsed = 0
            row:SetScript("OnUpdate", function(self, dt)
                fadeElapsed = fadeElapsed + dt
                local alpha = 1 - (fadeElapsed / 0.5)
                if alpha <= 0 then
                    self:SetScript("OnUpdate", nil)
                    for i, r in ipairs(activeRows) do
                        if r == self then
                            table.remove(activeRows, i)
                            break
                        end
                    end
                    ReleaseRow(self)
                    UpdatePositions()
                else
                    self:SetAlpha(alpha)
                end
            end)
        end
    end)
end

-- ============================================================
-- MONEY HANDLING
-- ============================================================
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local parts = {}
    if gold > 0 then table.insert(parts, "|cffffd700" .. gold .. " Gold|r") end
    if silver > 0 then table.insert(parts, "|cffc0c0c0" .. silver .. " Silber|r") end
    if cop > 0 or (gold == 0 and silver == 0) then table.insert(parts, "|cffeda55f" .. cop .. " Kupfer|r") end
    return table.concat(parts, ", ")
end

function ELF:ShowMoney(copper)
    if not db or not db.enabled or not db.showMoney then return end
    self:ShowLoot("Interface\\Icons\\INV_Misc_Coin_01", FormatMoney(copper), nil, 1, nil, true)
end

-- ============================================================
-- LOOT EVENT HANDLERS
-- ============================================================
local recentLoot = {}

local function HandleLoot(message, playerName, ...)
    -- Debug-Modus - IMMER zuerst, vor allen anderen Checks
    if ELF.debugMode then
        print("|cffff00ffHandleLoot aufgerufen:|r msg=" .. tostring(message):sub(1, 50) .. " db=" .. tostring(db) .. " enabled=" .. tostring(db and db.enabled))
    end
    
    if not message then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r message ist nil") end
        return 
    end
    if not db then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r db ist nil") end
        return 
    end
    if not db.enabled then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r db.enabled ist false") end
        return 
    end
    
    local itemLink = message:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r Kein Item-Link in: " .. message:sub(1,60)) end
        return 
    end
    
    local itemId = itemLink:match("item:(%d+)")
    if not itemId then return end
    
    -- IGNORIERE nur echte Roll-Nachrichten
    if message:find("würfelt") or message:find("Würfelt") then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r Würfel-Nachricht ignoriert") end
        return 
    end
    if message:find("rolls") or message:find("Rolls") then return end
    
    local myName = UnitName("player")
    local looterName = nil
    
    -- Versuche den Namen aus der Nachricht zu extrahieren
    local extractedName = message:match("^(.+) erhält")
                       or message:match("^(.+) bekommt")
                       or message:match("^(.+) receives")
                       or message:match("^(.+) gets")
    
    if extractedName and extractedName ~= myName then
        if not db.showGroupLoot then 
            if ELF.debugMode then print("|cffff0000DEBUG:|r Gruppen-Loot deaktiviert") end
            return 
        end
        if not (IsInGroup() or IsInRaid()) then 
            if ELF.debugMode then print("|cffff0000DEBUG:|r Nicht in Gruppe") end
            return 
        end
        looterName = extractedName
    end
    
    -- Duplikat-Check (2 Sekunden)
    local lootKey = itemId .. (looterName or "")
    local now = GetTime()
    for k, v in pairs(recentLoot) do
        if now - v > 2 then recentLoot[k] = nil end
    end
    if recentLoot[lootKey] then 
        if ELF.debugMode then print("|cffff0000DEBUG:|r Duplikat ignoriert") end
        return 
    end
    recentLoot[lootKey] = now
    
    local count = tonumber(message:match("x(%d+)")) or 1
    local itemName, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    
    if ELF.debugMode then
        print("|cff00ff00DEBUG:|r Zeige: " .. (itemName or "?") .. " Q:" .. (quality or "?") .. " von:" .. (looterName or "DU"))
    end
    
    if itemName then
        ELF:ShowLoot(itemTexture, itemName, count, quality, itemLink, false, looterName)
    else
        local savedLooter = looterName
        C_Timer.After(0.2, function()
            local name, _, qual, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
            if name then ELF:ShowLoot(tex, name, count, qual, itemLink, false, savedLooter) end
        end)
    end
end

local function HandleMoney(message)
    if not message or not db or not db.showMoney then return end
    local gold = tonumber(message:match("(%d+)%s*[Gg]old")) or 0
    local silver = tonumber(message:match("(%d+)%s*[Ss]il[bv]er")) or 0
    local copper = tonumber(message:match("(%d+)%s*[KkCc][ou]p[fp]er")) or 0
    local total = (gold * 10000) + (silver * 100) + copper
    if total > 0 then ELF:ShowMoney(total) end
end

-- ============================================================
-- TEST FUNCTION
-- ============================================================
function ELF:TestLoot()
    ClearAllRows()
    
    local items = {
        {name = "Leinenstoff", quality = 1, icon = "Interface\\Icons\\INV_Fabric_Linen_01", count = 5},
        {name = "Grüner Kristall", quality = 2, icon = "Interface\\Icons\\INV_Misc_Gem_Emerald_01"},
        {name = "Schwert der Wahrheit", quality = 3, icon = "Interface\\Icons\\INV_Sword_04"},
        {name = "Helm des Donners", quality = 4, icon = "Interface\\Icons\\INV_Helmet_03"},
        {name = "Donnerzorn", quality = 5, icon = "Interface\\Icons\\INV_Sword_39"},
    }
    
    for i, item in ipairs(items) do
        C_Timer.After(i * 0.15, function()
            self:ShowLoot(item.icon, item.name, item.count, item.quality, nil, false, item.looter)
        end)
    end
end

-- Test mit Gruppen-Loot
function ELF:TestGroupLoot()
    ClearAllRows()
    
    local items = {
        {name = "Leinenstoff", quality = 1, icon = "Interface\\Icons\\INV_Fabric_Linen_01", count = 5, looter = "Legolas"},
        {name = "Grüner Kristall", quality = 2, icon = "Interface\\Icons\\INV_Misc_Gem_Emerald_01", looter = "Thrall"},
        {name = "Schwert der Wahrheit", quality = 3, icon = "Interface\\Icons\\INV_Sword_04", looter = nil},  -- Du selbst
        {name = "Helm des Donners", quality = 4, icon = "Interface\\Icons\\INV_Helmet_03", looter = "Jaina"},
        {name = "Donnerzorn", quality = 5, icon = "Interface\\Icons\\INV_Sword_39", looter = "Arthas"},
    }
    
    for i, item in ipairs(items) do
        C_Timer.After(i * 0.15, function()
            self:ShowLoot(item.icon, item.name, item.count, item.quality, nil, false, item.looter)
        end)
    end
end

-- ============================================================
-- CONFIGURATION PANEL
-- ============================================================
local configFrame = nil

local function CreateConfigPanel()
    if configFrame then return configFrame end
    
    local f = CreateFrame("Frame", "ELF_Config", UIParent, "BackdropTemplate")
    f:SetSize(300, 520)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 24,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    f:SetBackdropColor(0.1, 0.08, 0.05, 0.95)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cff00ff00Epic|r|cffffd700Loot|r|cffff00ffFeed|r")
    
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    
    local y = -45
    
    -- Checkbox helper
    local function MakeCheck(label, key, yPos)
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yPos)
        cb.text:SetText(label)
        cb.text:SetFontObject("GameFontHighlight")
        cb:SetChecked(db[key])
        cb:SetScript("OnClick", function(self) db[key] = self:GetChecked() end)
        return cb
    end
    
    -- Slider helper
    local function MakeSlider(label, key, minV, maxV, step, yPos, callback)
        local frame = CreateFrame("Frame", nil, f)
        frame:SetSize(260, 32)
        frame:SetPoint("TOPLEFT", 20, yPos)
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetText(label)
        
        local val = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        val:SetPoint("TOPRIGHT", 0, 0)
        val:SetTextColor(1, 0.8, 0)
        
        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 0, -14)
        slider:SetWidth(260)
        slider:SetMinMaxValues(minV, maxV)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(db[key] or minV)
        slider.Low:SetText("")
        slider.High:SetText("")
        slider.Text:SetText("")
        
        local function Update(v)
            db[key] = v
            if step >= 1 then val:SetText(string.format("%d", v)) else val:SetText(string.format("%.1f", v)) end
            if callback then callback(v) end
        end
        Update(db[key] or minV)
        slider:SetScript("OnValueChanged", function(_, v) Update(v) end)
        return slider
    end
    
    MakeCheck("Aktiviert", "enabled", y)
    y = y - 25
    MakeCheck("Geld anzeigen", "showMoney", y)
    y = y - 25
    MakeCheck("Gruppen-Loot anzeigen", "showGroupLoot", y)
    y = y - 25
    MakeCheck("Nach oben wachsen", "growUp", y)
    y = y - 35
    
    MakeSlider("Größe", "scale", 0.6, 1.5, 0.1, y, function(v)
        for _, row in ipairs(activeRows) do row:SetScale(v) end
    end)
    y = y - 40
    MakeSlider("Anzeigedauer", "fadeTime", 2, 10, 1, y)
    y = y - 40
    MakeSlider("Max. Einträge", "maxRows", 3, 10, 1, y)
    y = y - 40
    MakeSlider("Zeilen-Abstand", "rowSpacing", -40, 50, 5, y, function(v)
        UpdatePositions()  -- Sofort aktualisieren
    end)
    y = y - 40
    MakeSlider("Position X", "anchorX", -600, 600, 10, y, function(v)
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", v, db.anchorY or 0)
        end
    end)
    y = y - 40
    MakeSlider("Position Y", "anchorY", -400, 400, 10, y, function(v)
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or -150, v)
        end
    end)
    y = y - 40
    
    -- Design selector
    local designLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    designLabel:SetPoint("TOPLEFT", 20, y)
    designLabel:SetText("|cffffd700Design:|r")
    y = y - 5
    
    -- Design buttons container
    local designContainer = CreateFrame("Frame", nil, f)
    designContainer:SetSize(260, 60)
    designContainer:SetPoint("TOPLEFT", 20, y - 15)
    f.designContainer = designContainer
    f.designButtons = {}
    
    -- Will be populated when designs are loaded
    local function RefreshDesignButtons()
        -- Clear old buttons
        for _, btn in ipairs(f.designButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        f.designButtons = {}
        
        local designs = ELF:GetDesignList()
        local col = 0
        local row = 0
        
        for i, design in ipairs(designs) do
            local btn = CreateFrame("Button", nil, designContainer, "BackdropTemplate")
            btn:SetSize(82, 24)
            btn:SetPoint("TOPLEFT", col * 86, -row * 28)
            btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
            
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btnText:SetPoint("CENTER")
            btn.btnText = btnText
            btn.designId = design.id
            
            local function UpdateBtn()
                if db.design == btn.designId then
                    btn:SetBackdropColor(0, 0.4, 0, 1)
                    btn:SetBackdropBorderColor(0, 1, 0, 1)
                    btnText:SetText("|cff00ff00" .. design.name .. "|r")
                else
                    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
                    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                    btnText:SetText(design.name)
                end
            end
            
            btn:SetScript("OnClick", function()
                db.design = btn.designId
                ClearAllRows()
                for _, b in ipairs(f.designButtons) do
                    if db.design == b.designId then
                        b:SetBackdropColor(0, 0.4, 0, 1)
                        b:SetBackdropBorderColor(0, 1, 0, 1)
                        b.btnText:SetText("|cff00ff00" .. ELF:GetDesign(b.designId).name .. "|r")
                    else
                        b:SetBackdropColor(0.15, 0.15, 0.15, 1)
                        b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                        b.btnText:SetText(ELF:GetDesign(b.designId).name)
                    end
                end
                ELF:TestLoot()
            end)
            
            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:AddLine(design.name, 1, 1, 1)
                GameTooltip:AddLine(design.description or "", 0.7, 0.7, 0.7)
                GameTooltip:Show()
                if db.design ~= btn.designId then btn:SetBackdropColor(0.25, 0.25, 0.25, 1) end
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
                UpdateBtn()
            end)
            
            UpdateBtn()
            table.insert(f.designButtons, btn)
            
            col = col + 1
            if col >= 3 then
                col = 0
                row = row + 1
            end
        end
    end
    
    f.RefreshDesignButtons = RefreshDesignButtons
    
    y = y - 75
    
    -- Quality
    local qualLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    qualLabel:SetPoint("TOPLEFT", 20, y)
    qualLabel:SetText("Min. Qualität:")
    
    local qualNames = {[0]="Alle", [1]="Weiß", [2]="Grün", [3]="Blau", [4]="Lila", [5]="Orange"}
    local qualColors = {[0]="|cff9d9d9d", [1]="|cffffffff", [2]="|cff1eff00", [3]="|cff0070dd", [4]="|cffa335ee", [5]="|cffff8000"}
    
    local qualBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    qualBtn:SetSize(80, 22)
    qualBtn:SetPoint("LEFT", qualLabel, "RIGHT", 10, 0)
    local function UpdateQual()
        local q = db.minimumQuality or 0
        qualBtn:SetText(qualColors[q] .. qualNames[q] .. "|r")
    end
    f.UpdateQual = UpdateQual
    qualBtn:SetScript("OnClick", function()
        db.minimumQuality = ((db.minimumQuality or 0) + 1) % 6
        UpdateQual()
    end)
    
    y = y - 35
    
    -- Buttons
    local testBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    testBtn:SetSize(120, 26)
    testBtn:SetPoint("TOPLEFT", 20, y)
    testBtn:SetText("Test")
    testBtn:SetScript("OnClick", function() ELF:TestLoot() end)
    
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 26)
    resetBtn:SetPoint("TOPRIGHT", -20, y)
    resetBtn:SetText("Position Reset")
    resetBtn:SetScript("OnClick", function()
        db.anchorX = -150
        db.anchorY = 0
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", -150, 0)
        end
    end)
    
    configFrame = f
    return f
end

function ELF:ToggleConfig()
    local f = CreateConfigPanel()
    f.RefreshDesignButtons()
    f.UpdateQual()
    if f:IsShown() then f:Hide() else f:Show() end
end

-- ============================================================
-- MINIMAP BUTTON
-- ============================================================
local function CreateMinimapButton()
    local btn = CreateFrame("Button", "ELF_Button", UIParent, "BackdropTemplate")
    btn:SetSize(36, 36)
    btn:SetPoint("CENTER", UIParent, "CENTER", db.buttonX or 400, db.buttonY or 300)
    btn:SetFrameStrata("HIGH")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:EnableMouse(true)
    
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    btn:SetBackdropColor(0.1, 0.08, 0.05, 0.95)
    btn:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Green")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    local isDragging = false
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        isDragging = true
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        isDragging = false
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        db.buttonX = x - ux
        db.buttonY = y - uy
    end)
    btn:SetScript("OnMouseUp", function(self, button)
        if not isDragging and button == "LeftButton" then
            ELF:ToggleConfig()
        end
    end)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.8, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ff00Epic|r|cffffd700Loot|r|cffff00ffFeed|r v" .. ELF.version)
        GameTooltip:AddLine("|cffffffffKlick:|r Einstellungen", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffffffZiehen:|r Bewegen", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
        GameTooltip:Hide()
    end)
    
    if db.showMinimapButton then btn:Show() else btn:Hide() end
    ELF.minimapButton = btn
end

-- ============================================================
-- SLASH COMMANDS
-- ============================================================
SLASH_ELF1 = "/elf"
SLASH_ELF2 = "/epiclootfeed"

SlashCmdList["ELF"] = function(msg)
    local cmd = (msg or ""):lower():trim()
    if cmd == "" or cmd == "config" then
        ELF:ToggleConfig()
    elseif cmd == "test" then
        ELF:TestLoot()
    elseif cmd == "testgroup" or cmd == "group" then
        ELF:TestGroupLoot()
    elseif cmd == "debug" then
        ELF.debugMode = not ELF.debugMode
        print("|cff00ff00EpicLootFeed|r Debug: " .. (ELF.debugMode and "AN" or "AUS"))
    elseif cmd == "status" then
        print("|cff00ff00EpicLootFeed|r Status:")
        print("  db: " .. (db and "OK" or "NIL!"))
        print("  db.enabled: " .. tostring(db and db.enabled))
        print("  db.design: " .. tostring(db and db.design))
        print("  anchorFrame: " .. (anchorFrame and "OK" or "NIL!"))
        print("  Designs geladen: " .. #ELF:GetDesignList())
    elseif cmd == "designs" then
        print("|cff00ff00EpicLootFeed|r Designs:")
        for _, d in ipairs(ELF:GetDesignList()) do
            local marker = (db.design == d.id) and " |cff00ff00<- aktiv|r" or ""
            print("  " .. d.id .. ". " .. d.name .. marker)
        end
    elseif cmd:match("^design%s*(%d+)$") then
        local id = tonumber(cmd:match("^design%s*(%d+)$"))
        if ELF:GetDesign(id) then
            db.design = id
            ClearAllRows()
            print("|cff00ff00EpicLootFeed|r: Design = " .. ELF:GetDesign(id).name)
            ELF:TestLoot()
        else
            print("|cff00ff00EpicLootFeed|r: Design " .. id .. " nicht gefunden!")
        end
    else
        print("|cff00ff00EpicLootFeed|r v" .. ELF.version)
        print("  /elf - Einstellungen")
        print("  /elf test - Test")
        print("  /elf testgroup - Test (Gruppen-Loot)")
        print("  /elf debug - Debug An/Aus")
        print("  /elf status - Status anzeigen")
        print("  /elf designs - Liste aller Designs")
        print("  /elf design [nummer] - Design wählen")
    end
end

-- ============================================================
-- EVENTS
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("CHAT_MSG_MONEY")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            InitDB()
        end
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            CreateAnchor()
            CreateMinimapButton()
            print("|cff00ff00EpicLootFeed|r v" .. ELF.version .. " - " .. #ELF:GetDesignList() .. " Designs geladen - /elf")
            
            -- FALLBACK: ChatFrame Hook für Loot-Nachrichten
            ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(self, event, msg, ...)
                if ELF.debugMode then
                    print("|cff00ff00CHATFRAME LOOT:|r " .. tostring(msg):sub(1,60))
                end
                -- Rufe HandleLoot auch hier auf als Backup
                if msg and db and db.enabled then
                    HandleLoot(msg, ...)
                end
                return false  -- Nachricht nicht blockieren
            end)
        end)
    elseif event == "CHAT_MSG_LOOT" then
        if ELF.debugMode then
            local msg = ...
            print("|cffff00ffEVENT LOOT:|r " .. tostring(msg):sub(1,60))
        end
        HandleLoot(...)
    elseif event == "CHAT_MSG_MONEY" then
        HandleMoney(...)
    end
end)
