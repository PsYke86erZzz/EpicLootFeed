--[[
    EpicLootFeed v6.0.0 - Advanced Loot Notification System
    
    Features:
    - 3 Display-Modi: Feed / Floating Text / Both
    - Professionelles WoW-Global Pattern-Matching (wie pretty_lootalert)
    - Epic+ Popup System
    - Umfangreiches Minimap-Einstellungsmenü
    - Frame-Pooling für Performance
    - 8 modulare Designs
    
    Inspiriert von: RPGLootFeed, Looti, pretty_lootalert, CC_LootMaster
]]

local ADDON_NAME, ELF = ...
_G.EpicLootFeed = ELF
ELF.version = "6.3.1"
ELF.debugMode = false

-- ============================================================
-- DESIGN REGISTRY - Hier registrieren sich alle Designs
-- ============================================================
ELF.Designs = {}

function ELF:RegisterDesign(id, designData)
    self.Designs[id] = designData
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
    rowSpacing = 20,
    fadeTime = 5,
    scale = 1.0,
    minimumQuality = 0,
    showMoney = true,
    showGroupLoot = true,
    showCrafting = true,
    showGathering = true,
    playSounds = true,
    showMinimapButton = true,
    buttonX = 400,
    buttonY = 300,
    -- Position
    anchorX = -150,
    anchorY = 0,
    growUp = true,
    -- Gruppen-Fenster
    separateGroupWindow = true,
    groupAnchorX = 150,
    groupAnchorY = 0,
    groupGrowUp = true,
    groupMaxRows = 6,
    groupScale = 1.0,
    groupFadeTime = 5,
    -- === Epic Popup ===
    showEpicPopup = true,
    epicPopupMinQuality = 4,
    epicPopupDuration = 4,
    epicPopupScale = 1.5,
    -- === Sounds ===
    soundEpic = true,
    soundRare = false,
    soundRollWon = true,
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
local activeGroupRows = {}  -- Separate Liste für Gruppen-Fenster
local anchorFrame = nil
local groupAnchorFrame = nil  -- Separater Anker für Gruppen
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
    
    -- WICHTIG: Stelle sicher dass Gruppen-Loot standardmäßig AN ist
    if db.showGroupLoot == nil then
        db.showGroupLoot = true
    end
end

local function CreateAnchor()
    -- === FEED ANKER (Eigenes Fenster) ===
    if not anchorFrame then
        anchorFrame = CreateFrame("Frame", "ELF_Anchor", UIParent, "BackdropTemplate")
        anchorFrame:SetSize(320, 10)
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or -150, db.anchorY or 0)
        anchorFrame:SetFrameStrata("HIGH")
        ELF.anchorFrame = anchorFrame
        
        -- === DRAGGABLE MOVER (grünes Kästchen) ===
        local mover = CreateFrame("Frame", "ELF_FeedMover", UIParent, "BackdropTemplate")
        mover:SetSize(120, 30)
        mover:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
        mover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        mover:SetBackdropColor(0, 0.6, 0, 0.8)
        mover:SetBackdropBorderColor(0, 1, 0, 1)
        mover:SetFrameStrata("DIALOG")
        mover:SetMovable(true)
        mover:EnableMouse(true)
        mover:RegisterForDrag("LeftButton")
        mover:SetClampedToScreen(true)
        mover:Hide()
        
        local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        moverText:SetPoint("CENTER")
        moverText:SetText("|cffffffffFeed|r")
        
        mover:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        
        mover:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Position speichern (relativ zur Bildschirmmitte)
            local x, y = self:GetCenter()
            local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
            db.anchorX = math.floor(x - screenW/2)
            db.anchorY = math.floor(y - screenH/2)
            -- Anker aktualisieren
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX, db.anchorY)
            -- Config-Slider aktualisieren falls offen
            if configFrame and configFrame:IsShown() and configFrame.UpdateSliders then
                configFrame.UpdateSliders()
            end
        end)
        
        mover:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine("Feed Position", 0, 1, 0)
            GameTooltip:AddLine("Ziehen zum Verschieben", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("X: " .. (db.anchorX or 0) .. "  Y: " .. (db.anchorY or 0), 1, 1, 1)
            GameTooltip:Show()
        end)
        mover:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        ELF.feedMover = mover
    end
    
    -- === GRUPPEN-ANKER ===
    if not groupAnchorFrame then
        groupAnchorFrame = CreateFrame("Frame", "ELF_GroupAnchor", UIParent, "BackdropTemplate")
        groupAnchorFrame:SetSize(320, 10)
        groupAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.groupAnchorX or 150, db.groupAnchorY or 0)
        groupAnchorFrame:SetFrameStrata("HIGH")
        ELF.groupAnchorFrame = groupAnchorFrame
        
        -- === DRAGGABLE MOVER für Gruppen ===
        local groupMover = CreateFrame("Frame", "ELF_GroupMover", UIParent, "BackdropTemplate")
        groupMover:SetSize(120, 30)
        groupMover:SetPoint("CENTER", groupAnchorFrame, "CENTER", 0, 0)
        groupMover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        groupMover:SetBackdropColor(0.6, 0.4, 0, 0.8)
        groupMover:SetBackdropBorderColor(1, 0.7, 0, 1)
        groupMover:SetFrameStrata("DIALOG")
        groupMover:SetMovable(true)
        groupMover:EnableMouse(true)
        groupMover:RegisterForDrag("LeftButton")
        groupMover:SetClampedToScreen(true)
        groupMover:Hide()
        
        local groupMoverText = groupMover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        groupMoverText:SetPoint("CENTER")
        groupMoverText:SetText("|cffffffffGruppe|r")
        
        groupMover:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        
        groupMover:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local x, y = self:GetCenter()
            local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
            db.groupAnchorX = math.floor(x - screenW/2)
            db.groupAnchorY = math.floor(y - screenH/2)
            groupAnchorFrame:ClearAllPoints()
            groupAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.groupAnchorX, db.groupAnchorY)
            if configFrame and configFrame:IsShown() and configFrame.UpdateSliders then
                configFrame.UpdateSliders()
            end
        end)
        
        groupMover:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine("Gruppen-Feed Position", 1, 0.7, 0)
            GameTooltip:AddLine("Ziehen zum Verschieben", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("X: " .. (db.groupAnchorX or 0) .. "  Y: " .. (db.groupAnchorY or 0), 1, 1, 1)
            GameTooltip:Show()
        end)
        groupMover:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        ELF.groupMover = groupMover
    end
end

-- Funktion um Mover zu zeigen/verstecken
function ELF:ToggleMovers(show)
    if show then
        -- Feed Mover immer zeigen
        if ELF.feedMover then 
            ELF.feedMover:ClearAllPoints()
            ELF.feedMover:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or -150, db.anchorY or 0)
            ELF.feedMover:Show() 
            print("|cff00ff00EpicLootFeed|r: |cff00ff00Feed-Mover|r - Ziehe das grüne Kästchen!")
        end
        -- Gruppen Mover immer zeigen (damit man es positionieren kann)
        if ELF.groupMover then 
            ELF.groupMover:ClearAllPoints()
            ELF.groupMover:SetPoint("CENTER", UIParent, "CENTER", db.groupAnchorX or 150, db.groupAnchorY or 0)
            ELF.groupMover:Show() 
            print("|cff00ff00EpicLootFeed|r: |cffFFAA00Gruppen-Mover|r - Ziehe das orange Kästchen!")
        end
    else
        if ELF.feedMover then ELF.feedMover:Hide() end
        if ELF.groupMover then ELF.groupMover:Hide() end
    end
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
    
    for _, row in ipairs(activeGroupRows) do
        ReleaseRow(row)
    end
    activeGroupRows = {}
end

-- ============================================================
-- POSITION UPDATE
-- ============================================================
local function UpdatePositions()
    if not anchorFrame then return end
    
    -- Eigenes Fenster
    local direction = db.growUp and 1 or -1
    local spacing = db.rowSpacing or 10
    local currentY = 0
    
    for i, row in ipairs(activeRows) do
        row:ClearAllPoints()
        row:SetPoint("CENTER", anchorFrame, "CENTER", 0, currentY * direction)
        local rowHeight = row:GetHeight() or 96
        currentY = currentY + rowHeight + spacing
    end
    
    -- Gruppen-Fenster (wenn aktiviert)
    if db.separateGroupWindow and groupAnchorFrame then
        local groupDirection = db.groupGrowUp and 1 or -1
        local groupY = 0
        
        for i, row in ipairs(activeGroupRows) do
            row:ClearAllPoints()
            row:SetPoint("CENTER", groupAnchorFrame, "CENTER", 0, groupY * groupDirection)
            local rowHeight = row:GetHeight() or 96
            groupY = groupY + rowHeight + spacing
        end
    end
end

-- ============================================================
-- SHOW LOOT - Main Function
-- ============================================================
function ELF:ShowLoot(iconTex, name, count, quality, itemLink, isMoney, looterName, customLabel)
    if ELF.debugMode then
        print("|cff00ffffShowLoot:|r name=" .. tostring(name) .. " Q=" .. tostring(quality) .. " looter=" .. tostring(looterName))
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
    
    -- Entscheide: Eigenes oder Gruppen-Fenster?
    local isGroupItem = (looterName ~= nil)
    local useGroupWindow = isGroupItem and db.separateGroupWindow and groupAnchorFrame
    
    -- Ziel-Listen und Anker bestimmen
    local targetRows, targetAnchor, targetMaxRows, targetScale
    if useGroupWindow then
        targetRows = activeGroupRows
        targetAnchor = groupAnchorFrame
        targetMaxRows = db.groupMaxRows or 6
        targetScale = db.groupScale or 1.0
    else
        targetRows = activeRows
        targetAnchor = anchorFrame
        targetMaxRows = db.maxRows or 6
        targetScale = db.scale or 1.0
    end
    
    local designId = db.design or 1
    local design = self:GetDesign(designId)
    if not design then 
        if ELF.debugMode then print("|cffff0000ShowLoot STOP:|r Design " .. tostring(designId) .. " nicht gefunden!") end
        return 
    end
    
    if ELF.debugMode then
        print("|cff00ff00ShowLoot:|r Design=" .. design.name .. " → " .. (useGroupWindow and "GRUPPEN" or "EIGEN") .. " (" .. #targetRows .. " rows)")
    end
    
    -- Limit rows für das jeweilige Fenster
    while #targetRows >= targetMaxRows do
        local old = table.remove(targetRows, 1)
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
    row.customLabel = customLabel
    row.isGroupItem = isGroupItem
    row.useGroupWindow = useGroupWindow  -- Merken für fade out
    
    -- Apply design styling
    design.ApplyStyle(row, iconTex, name, count, quality, color, isMoney, looterName, customLabel)
    
    -- Scale
    row:SetScale(targetScale)
    
    -- Show with fade in
    row:SetAlpha(0)
    row:Show()
    table.insert(targetRows, 1, row)
    UpdatePositions()
    
    if ELF.debugMode then
        print("|cff00ff00ShowLoot OK:|r Rows=" .. #targetRows)
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
                    -- Aus der richtigen Liste entfernen
                    if row.useGroupWindow then
                        for i, r in ipairs(activeGroupRows) do
                            if r == self then
                                table.remove(activeGroupRows, i)
                                break
                            end
                        end
                    else
                        for i, r in ipairs(activeRows) do
                            if r == self then
                                table.remove(activeRows, i)
                                break
                            end
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
-- EPIC POPUP SYSTEM (für Epic+ Items)
-- ============================================================
local epicPopupFrame = nil

local function CreateEpicPopup()
    local f = CreateFrame("Frame", "EpicLootFeedEpicPopup", UIParent, "BackdropTemplate")
    f:SetSize(350, 80)
    f:SetPoint("TOP", UIParent, "TOP", 0, -150)
    f:SetFrameStrata("DIALOG")
    
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 24,
        insets = {left = 6, right = 6, top = 6, bottom = 6}
    })
    
    -- Glow hinter dem Popup
    f.glow = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    f.glow:SetSize(400, 120)
    f.glow:SetPoint("CENTER")
    f.glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    f.glow:SetBlendMode("ADD")
    f.glow:SetAlpha(0.5)
    
    -- Icon Container
    f.iconFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.iconFrame:SetSize(56, 56)
    f.iconFrame:SetPoint("LEFT", 15, 0)
    f.iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    f.iconFrame:SetBackdropColor(0, 0, 0, 0.8)
    
    f.icon = f.iconFrame:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(48, 48)
    f.icon:SetPoint("CENTER")
    
    -- "Epic Loot!" Header
    f.header = f:CreateFontString(nil, "OVERLAY")
    f.header:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    f.header:SetPoint("TOPLEFT", f.iconFrame, "TOPRIGHT", 12, -2)
    f.header:SetTextColor(1, 0.84, 0)
    f.header:SetText("EPIC LOOT!")
    
    -- Item Name
    f.itemName = f:CreateFontString(nil, "OVERLAY")
    f.itemName:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    f.itemName:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 0, -4)
    f.itemName:SetWidth(260)
    f.itemName:SetJustifyH("LEFT")
    
    -- Stars/Sparkle decoration
    f.star1 = f:CreateTexture(nil, "OVERLAY")
    f.star1:SetSize(20, 20)
    f.star1:SetPoint("TOPRIGHT", -10, -10)
    f.star1:SetTexture("Interface\\AddOns\\EpicLootFeed\\assets\\toast-star.blp")
    f.star1:SetBlendMode("ADD")
    
    f.star2 = f:CreateTexture(nil, "OVERLAY")
    f.star2:SetSize(16, 16)
    f.star2:SetPoint("BOTTOMRIGHT", -15, 15)
    f.star2:SetTexture("Interface\\AddOns\\EpicLootFeed\\assets\\toast-star-2.blp")
    f.star2:SetBlendMode("ADD")
    
    f:EnableMouse(true)
    f:Hide()
    
    return f
end

function ELF:ShowEpicPopup(texture, itemName, quality, itemLink)
    if not db or not db.enabled or not db.showEpicPopup then return end
    
    if not epicPopupFrame then
        epicPopupFrame = CreateEpicPopup()
    end
    
    local f = epicPopupFrame
    local color = QualityColors[quality] or QualityColors[4]
    
    -- Setup
    f.icon:SetTexture(texture)
    f.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b)
    f.glow:SetVertexColor(color.r, color.g, color.b)
    
    -- Header je nach Qualität
    if quality == 5 then
        f.header:SetText("LEGENDARY LOOT!")
        f.header:SetTextColor(1, 0.5, 0)
    elseif quality == 4 then
        f.header:SetText("EPIC LOOT!")
        f.header:SetTextColor(0.64, 0.21, 0.93)
    else
        f.header:SetText("RARE LOOT!")
        f.header:SetTextColor(0, 0.44, 0.87)
    end
    
    f.itemName:SetText("|c" .. select(4, GetItemQualityColor(quality)) .. itemName .. "|r")
    
    -- Tooltip
    f.itemLink = itemLink
    f:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetScript("OnMouseDown", function(self)
        if self.itemLink and IsShiftKeyDown() then
            ChatEdit_InsertLink(self.itemLink)
        end
    end)
    
    -- Scale und Show
    local scale = db.epicPopupScale or 1.5
    f:SetScale(scale)
    f:SetAlpha(0)
    f:Show()
    
    -- Animation: Fade in, hold, fade out
    local elapsed = 0
    local duration = db.epicPopupDuration or 4
    local fadeInTime = 0.3
    local fadeOutTime = 0.5
    
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        
        -- Glow pulsieren
        local glowPulse = 0.3 + 0.2 * math.sin(elapsed * 4)
        self.glow:SetAlpha(glowPulse)
        
        -- Sterne rotieren
        local rot = elapsed * 30
        -- (WoW Classic unterstützt keine Rotation, also überspringen)
        
        -- Animation beenden wenn Zeit abgelaufen
        if elapsed >= duration then
            self:SetAlpha(0)
            self:Hide()
            self:SetScript("OnUpdate", nil)
            return
        end
        
        -- Alpha berechnen mit Clamping
        local alpha = 1
        if elapsed < fadeInTime then
            -- Fade in
            alpha = elapsed / fadeInTime
        elseif elapsed > duration - fadeOutTime then
            -- Fade out
            local fadeProgress = (elapsed - (duration - fadeOutTime)) / fadeOutTime
            alpha = 1 - fadeProgress
        end
        
        -- Clamp alpha to valid range
        alpha = math.max(0, math.min(1, alpha))
        self:SetAlpha(alpha)
    end)
end

-- ============================================================
-- MONEY HANDLING
-- ============================================================
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local kup = copper % 100
    local parts = {}
    if gold > 0 then table.insert(parts, "|cffffd700" .. gold .. "g|r") end
    if silver > 0 then table.insert(parts, "|cffc0c0c0" .. silver .. "s|r") end
    if kup > 0 or (gold == 0 and silver == 0) then table.insert(parts, "|cffeda55f" .. kup .. "k|r") end
    return table.concat(parts, " ")
end

-- Geld erhalten (grün)
function ELF:ShowMoneyGain(copper, source)
    if not db or not db.enabled or not db.showMoney then return end
    local text = "|cff00ff00+|r " .. FormatMoney(copper)
    if source then text = text .. " |cff888888(" .. source .. ")|r" end
    local label = "Geld erhalten"
    if source == "Verkauf" then
        label = "Verkauft"
    elseif source == "Quest" then
        label = "Quest-Belohnung"
    elseif source == "Post" then
        label = "Post erhalten"
    elseif source == "Anteil" then
        label = "Anteil erhalten"
    end
    self:ShowLoot("Interface\\Icons\\INV_Misc_Coin_01", text, nil, 2, nil, true, nil, label)
end

-- Geld ausgegeben (rot)
function ELF:ShowMoneyLoss(copper, source)
    if not db or not db.enabled or not db.showMoney then return end
    local text = "|cffff0000-|r " .. FormatMoney(copper)
    if source then text = text .. " |cff888888(" .. source .. ")|r" end
    local label = "Ausgegeben"
    if source == "Kauf" then
        label = "Gekauft"
    elseif source == "Reparatur" then
        label = "Repariert"
    elseif source == "Porto" then
        label = "Porto bezahlt"
    end
    self:ShowLoot("Interface\\Icons\\INV_Misc_Coin_01", text, nil, 0, nil, true, nil, label)  -- Qualität 0 = grau
end

-- Alte Funktion für Kompatibilität
function ELF:ShowMoney(copper)
    self:ShowMoneyGain(copper, nil)
end

-- ============================================================
-- LOOT EVENT HANDLERS
-- ============================================================
local recentLoot = {}

--[[
    PROFESSIONELLES PATTERN-MATCHING SYSTEM
    Basierend auf cc_lootmaster und pretty_lootalert
    
    Verwendet WoW GlobalStrings die automatisch lokalisiert sind:
    - LOOT_ITEM_SELF = "Ihr erhaltet Beute: %s." (DE)
    - LOOT_ITEM = "%s erhält Beute: %s." (DE)
    etc.
]]

-- Pattern Cache für Performance (wie cc_lootmaster)
local PatternCache = {}

-- Konvertiert WoW Format-String zu Lua Pattern mit Caching
local function Deformat(str, format)
    if not str or not format then return nil end
    
    local pattern = PatternCache[format]
    if not pattern then
        -- Escape special Lua pattern characters
        pattern = format:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        -- Convert format specifiers to capture groups
        -- WICHTIG: Lazy matching (.-) statt greedy (.+) für korrekte Multi-Capture
        pattern = pattern:gsub("%%%%s", "(.-)")
        pattern = pattern:gsub("%%%%d", "(%%d+)")
        -- Entferne trailing Punkt falls vorhanden (WoW Globals enden oft mit .)
        pattern = pattern:gsub("%.$", "%.?")
        PatternCache[format] = pattern
    end
    
    return str:match(pattern)
end

-- Alle unterstützten Loot-Pattern-Funktionen
-- Reihenfolge wichtig: MULTIPLE vor SINGLE (spezifischer zuerst!)
local LootMessageFilters = {}

local function BuildLootFilters()
    local myName = UnitName("player")
    
    LootMessageFilters = {
        -- === EIGENER LOOT MIT ANZAHL (zuerst!) ===
        function(msg)
            if LOOT_ITEM_SELF_MULTIPLE then
                local item, count = Deformat(msg, LOOT_ITEM_SELF_MULTIPLE)
                if item then return myName, item, tonumber(count) or 1, "loot" end
            end
        end,
        
        -- === EIGENER LOOT (einzeln) ===
        function(msg)
            if LOOT_ITEM_SELF then
                local item = Deformat(msg, LOOT_ITEM_SELF)
                if item then return myName, item, 1, "loot" end
            end
        end,
        
        -- === GRUPPEN-LOOT MIT ANZAHL ===
        function(msg)
            if LOOT_ITEM_MULTIPLE then
                local player, item, count = Deformat(msg, LOOT_ITEM_MULTIPLE)
                if player and item then return player, item, tonumber(count) or 1, "group" end
            end
        end,
        
        -- === GRUPPEN-LOOT (einzeln) ===
        function(msg)
            if LOOT_ITEM then
                local player, item = Deformat(msg, LOOT_ITEM)
                if player and item then return player, item, 1, "group" end
            end
        end,
        
        -- === PUSHED ITEMS (Quest-Belohnungen etc.) MIT ANZAHL ===
        function(msg)
            if LOOT_ITEM_PUSHED_SELF_MULTIPLE then
                local item, count = Deformat(msg, LOOT_ITEM_PUSHED_SELF_MULTIPLE)
                if item then return myName, item, tonumber(count) or 1, "received" end
            end
        end,
        
        -- === PUSHED ITEMS (einzeln) ===
        function(msg)
            if LOOT_ITEM_PUSHED_SELF then
                local item = Deformat(msg, LOOT_ITEM_PUSHED_SELF)
                if item then return myName, item, 1, "received" end
            end
        end,
        
        -- === CRAFTING SELF MIT ANZAHL ===
        function(msg)
            if LOOT_ITEM_CREATED_SELF_MULTIPLE then
                local item, count = Deformat(msg, LOOT_ITEM_CREATED_SELF_MULTIPLE)
                if item then return myName, item, tonumber(count) or 1, "crafted" end
            end
        end,
        
        -- === CRAFTING SELF (einzeln) ===
        function(msg)
            if LOOT_ITEM_CREATED_SELF then
                local item = Deformat(msg, LOOT_ITEM_CREATED_SELF)
                if item then return myName, item, 1, "crafted" end
            end
        end,
        
        -- === CRAFTING OTHER (Gruppenmitglied) ===
        function(msg)
            if CREATED_ITEM then
                local player, item = Deformat(msg, CREATED_ITEM)
                if player and item then return player, item, 1, "crafted_group" end
            end
        end,
        
        -- === ROLL GEWONNEN ===
        function(msg)
            if LOOT_ROLL_YOU_WON then
                local item = Deformat(msg, LOOT_ROLL_YOU_WON)
                if item then return myName, item, 1, "won" end
            end
        end,
    }
    
    if ELF.debugMode then
        print("|cff00ff00EpicLootFeed:|r " .. #LootMessageFilters .. " Loot-Filter geladen")
    end
end

-- Tracking für Kontext
local mailboxOpen = false
local merchantOpen = false

-- Parst Loot-Nachricht und gibt Spieler, Item, Anzahl, Typ zurück
local function ParseLootMessage(message)
    if not message then return nil end
    
    -- Build filters on first call
    if #LootMessageFilters == 0 then
        BuildLootFilters()
    end
    
    -- Versuche jeden Filter der Reihe nach
    for _, filter in ipairs(LootMessageFilters) do
        local player, item, count, lootType = filter(message)
        if player and item then
            return player, item, count, lootType
        end
    end
    
    return nil
end

local function HandleLoot(message, playerName, ...)
    if not message or not db or not db.enabled then return end
    
    -- Debug output
    if ELF.debugMode then
        print("|cffff00ffLOOT MSG:|r " .. tostring(message):sub(1, 80))
    end
    
    -- Parse mit dem neuen System
    local player, itemMatch, count, lootType = ParseLootMessage(message)
    
    if not player then
        if ELF.debugMode then print("|cffff0000SKIP:|r Kein Pattern-Match") end
        return
    end
    
    -- Extract item link from message
    local itemLink = message:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        if ELF.debugMode then print("|cffff0000SKIP:|r Kein ItemLink") end
        return
    end
    
    local itemId = itemLink:match("item:(%d+)")
    if not itemId then return end
    
    local myName = UnitName("player")
    local isGroupLoot = (player ~= myName)
    
    -- Settings Check
    if isGroupLoot and db.showGroupLoot == false then
        if ELF.debugMode then print("|cffff0000SKIP:|r Gruppen-Loot deaktiviert") end
        return
    end
    
    if lootType == "crafted" and not db.showCrafting then return end
    if lootType == "crafted_group" and (not db.showCrafting or not db.showGroupLoot) then return end
    
    -- Duplikat-Check (3 Sekunden)
    local lootKey = itemId .. "-" .. player
    local now = GetTime()
    for k, v in pairs(recentLoot) do
        if now - v > 3 then recentLoot[k] = nil end
    end
    if recentLoot[lootKey] then
        if ELF.debugMode then print("|cffff0000SKIP:|r Duplikat") end
        return
    end
    recentLoot[lootKey] = now
    
    -- Get item info
    local itemName, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    
    -- Quality Check
    if quality and quality < (db.minimumQuality or 0) then
        if ELF.debugMode then print("|cffff0000SKIP:|r Qualität zu niedrig: " .. quality) end
        return
    end
    
    -- Label basierend auf Loot-Typ
    local customLabel = nil
    local looterName = isGroupLoot and player or nil
    
    if lootType == "won" then
        customLabel = "Gewonnen"
    elseif lootType == "crafted" then
        customLabel = "Hergestellt"
    elseif lootType == "crafted_group" then
        customLabel = player .. " stellt her"
    elseif lootType == "received" then
        customLabel = mailboxOpen and "Post erhalten" or "Erhalten"
    end
    
    if ELF.debugMode then
        print("|cff00ff00SHOW:|r " .. (itemName or "?") .. " Q:" .. (quality or "?") .. 
              " Type:" .. lootType .. " Player:" .. player .. " Label:" .. (customLabel or "-"))
    end
    
    -- Display Loot (nur Feed-Modus)
    local function DisplayLoot(tex, name, cnt, qual, link)
        -- Feed anzeigen
        ELF:ShowLoot(tex, name, cnt, qual, link, false, looterName, customLabel)
        
        -- === Epic Popup für Epic+ Items ===
        if db.showEpicPopup and qual and qual >= (db.epicPopupMinQuality or 4) and not isGroupLoot then
            ELF:ShowEpicPopup(tex, name, qual, link)
        end
        
        -- === Sounds ===
        if db.playSounds and not isGroupLoot then
            if lootType == "won" and db.soundRollWon then
                PlaySoundFile("Interface\\AddOns\\EpicLootFeed\\assets\\ui_loot_toast_lesser_item_won_01.ogg", "Master")
            elseif qual and qual >= 4 and db.soundEpic then
                PlaySoundFile("Interface\\AddOns\\EpicLootFeed\\assets\\ui_epicloot_toast_01.ogg", "Master")
            elseif qual and qual >= 3 and db.soundRare then
                PlaySoundFile("Interface\\AddOns\\EpicLootFeed\\assets\\ui_garrison_follower_trait_learned_02.ogg", "Master")
            end
        end
    end
    
    if itemName then
        DisplayLoot(itemTexture, itemName, count, quality, itemLink)
    else
        -- Item not cached, retry
        local savedPlayer = player
        local savedCount = count
        local savedLootType = lootType
        C_Timer.After(0.3, function()
            local name, _, qual, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
            if name and qual and qual >= (db.minimumQuality or 0) then
                DisplayLoot(tex, name, savedCount, qual, itemLink)
            end
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
        {name = "Leinenstoff", quality = 1, icon = "Interface\\Icons\\INV_Fabric_Linen_01", count = 5, looter = "Legolas", label = nil},
        {name = "Grüner Kristall", quality = 2, icon = "Interface\\Icons\\INV_Misc_Gem_Emerald_01", looter = "Thrall", label = nil},
        {name = "Schwert der Wahrheit", quality = 3, icon = "Interface\\Icons\\INV_Sword_04", looter = nil, label = nil},
        {name = "Helm des Donners", quality = 4, icon = "Interface\\Icons\\INV_Helmet_03", looter = "Jaina", label = nil},
        {name = "Donnerzorn", quality = 5, icon = "Interface\\Icons\\INV_Sword_39", looter = "Arthas", label = nil},
        {name = "Mithrilbarren", quality = 1, icon = "Interface\\Icons\\INV_Ingot_06", looter = "Gandalf", label = "Gandalf stellt her"},
    }
    
    for i, item in ipairs(items) do
        C_Timer.After(i * 0.2, function()
            self:ShowLoot(item.icon, item.name, item.count, item.quality, nil, false, item.looter, item.label)
        end)
    end
    print("|cff00ff00EpicLootFeed|r: Zeige 6 Test-Items (inkl. Gruppen-Loot)")
end

-- ============================================================
-- CONFIGURATION PANEL
-- ============================================================
local configFrame = nil

local function CreateConfigPanel()
    if configFrame then return configFrame end
    
    local f = CreateFrame("Frame", "ELF_Config", UIParent, "BackdropTemplate")
    f:SetSize(330, 680)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 6, right = 6, top = 6, bottom = 6},
    })
    f:SetBackdropColor(0.08, 0.06, 0.04, 0.97)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 55)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(280, 950)
    scrollFrame:SetScrollChild(content)
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cffA335EEEpic|r|cffFF8000Loot|r|cff1EFF00Feed|r |cff666666v" .. ELF.version .. "|r")
    
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetSize(26, 26)
    
    local y = 0
    local leftMargin = 5
    local contentWidth = 270
    
    -- ===== HELPER: Header =====
    local function AddHeader(text, yPos)
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", leftMargin, yPos)
        header:SetText("|cffFFD700" .. text .. "|r")
        return yPos - 18
    end
    
    -- ===== HELPER: Checkbox =====
    local function AddCheck(label, key, yPos, callback)
        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", leftMargin, yPos)
        cb:SetSize(22, 22)
        cb.text:SetText("  " .. label)
        cb.text:SetFontObject("GameFontNormalSmall")
        cb:SetChecked(db[key])
        cb:SetScript("OnClick", function(self)
            db[key] = self:GetChecked()
            if callback then callback(self:GetChecked()) end
        end)
        return yPos - 22
    end
    
    -- ===== HELPER: Slider =====
    local function AddSlider(label, key, minV, maxV, step, yPos, callback)
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", leftMargin, yPos)
        text:SetText(label)
        
        local val = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("TOPRIGHT", contentWidth, yPos)
        val:SetTextColor(1, 0.82, 0)
        
        local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", leftMargin, yPos - 12)
        slider:SetWidth(contentWidth - 10)
        slider:SetHeight(14)
        slider:SetMinMaxValues(minV, maxV)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(db[key] or minV)
        slider.Low:SetText("")
        slider.High:SetText("")
        slider.Text:SetText("")
        
        local function Update(v)
            db[key] = v
            if step >= 1 then 
                val:SetText(string.format("%d", v)) 
            else 
                val:SetText(string.format("%.1f", v)) 
            end
            if callback then callback(v) end
        end
        Update(db[key] or minV)
        slider:SetScript("OnValueChanged", function(_, v) Update(v) end)
        return yPos - 32, slider
    end
    
    -- ===== HELPER: Toggle Button Group =====
    -- Diese Funktion erstellt eine Gruppe von Buttons die wie Radio-Buttons funktionieren
    local function CreateToggleGroup(parent, yPos, options, dbKey, defaultValue)
        local btnWidth = math.floor((contentWidth - 10) / #options)
        local buttons = {}
        
        -- Update Funktion für alle Buttons dieser Gruppe
        local function UpdateButtons()
            local currentVal = db[dbKey] or defaultValue
            for i, btn in ipairs(buttons) do
                if currentVal == btn.value then
                    -- Aktiv
                    btn:SetBackdropColor(0.1, 0.5, 0.1, 1)
                    btn:SetBackdropBorderColor(0.3, 1, 0.3, 1)
                    btn.label:SetTextColor(0, 1, 0)
                else
                    -- Inaktiv
                    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
                    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                    btn.label:SetTextColor(0.6, 0.6, 0.6)
                end
            end
        end
        
        for i, opt in ipairs(options) do
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(btnWidth - 4, 22)
            btn:SetPoint("TOPLEFT", leftMargin + (i-1) * btnWidth, yPos)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8
            })
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            
            local label = btn:CreateFontString(nil, "OVERLAY")
            label:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            label:SetPoint("CENTER")
            label:SetText(opt.name)
            btn.label = label
            btn.value = opt.id
            
            btn:SetScript("OnClick", function(self)
                db[dbKey] = self.value
                UpdateButtons()
                if ELF.debugMode then
                    print("|cff00ff00ELF:|r " .. dbKey .. " = " .. tostring(self.value))
                end
            end)
            
            btn:SetScript("OnEnter", function(self)
                if db[dbKey] ~= self.value then
                    self:SetBackdropColor(0.25, 0.25, 0.25, 1)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                UpdateButtons()
            end)
            
            buttons[i] = btn
        end
        
        -- Initial Update
        UpdateButtons()
        
        return yPos - 28, buttons, UpdateButtons
    end
    
    -- ===== ALLGEMEIN =====
    y = AddHeader("Allgemein", y)
    y = AddCheck("Aktiviert", "enabled", y)
    y = AddCheck("Geld anzeigen", "showMoney", y)
    y = AddCheck("Gruppen-Loot anzeigen", "showGroupLoot", y)
    y = AddCheck("Sounds abspielen", "playSounds", y)
    y = AddCheck("Epic+ Popup anzeigen", "showEpicPopup", y)
    y = y - 10
    
    -- ===== FEED EINSTELLUNGEN =====
    y = AddHeader("Feed-Einstellungen", y)
    y = AddCheck("Nach oben wachsen", "growUp", y)
    y = AddSlider("Größe", "scale", 0.5, 1.5, 0.1, y)
    y = AddSlider("Anzeigedauer", "fadeTime", 2, 15, 1, y)
    y = AddSlider("Max. Einträge", "maxRows", 3, 12, 1, y)
    y = AddSlider("Zeilen-Abstand", "rowSpacing", -30, 50, 5, y, function() UpdatePositions() end)
    y = y - 5
    
    -- ===== POSITION (Drag & Drop) =====
    y = AddHeader("Position", y)
    
    -- MOVER BUTTON
    local moverBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    moverBtn:SetSize(contentWidth - 10, 26)
    moverBtn:SetPoint("TOPLEFT", leftMargin, y)
    moverBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10
    })
    moverBtn:SetBackdropColor(0, 0.4, 0, 1)
    moverBtn:SetBackdropBorderColor(0, 0.8, 0, 1)
    
    local moverText = moverBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moverText:SetPoint("CENTER")
    moverText:SetText("|cff00ff00Positionen anpassen|r")
    
    local moversVisible = false
    moverBtn:SetScript("OnClick", function()
        moversVisible = not moversVisible
        ELF:ToggleMovers(moversVisible)
        if moversVisible then
            moverText:SetText("|cffff6666Klicke wenn fertig|r")
            moverBtn:SetBackdropColor(0.4, 0.1, 0.1, 1)
            moverBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        else
            moverText:SetText("|cff00ff00Positionen anpassen|r")
            moverBtn:SetBackdropColor(0, 0.4, 0, 1)
            moverBtn:SetBackdropBorderColor(0, 0.8, 0, 1)
        end
    end)
    y = y - 32
    
    local sliderRefs = {}
    y, sliderRefs.anchorX = AddSlider("Feed X", "anchorX", -800, 800, 10, y, function(v)
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", v, db.anchorY or 0)
        end
    end)
    y, sliderRefs.anchorY = AddSlider("Feed Y", "anchorY", -500, 500, 10, y, function(v)
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or -150, v)
        end
    end)
    
    f.UpdateSliders = function()
        if sliderRefs.anchorX then sliderRefs.anchorX:SetValue(db.anchorX or -150) end
        if sliderRefs.anchorY then sliderRefs.anchorY:SetValue(db.anchorY or 0) end
        if sliderRefs.groupAnchorX then sliderRefs.groupAnchorX:SetValue(db.groupAnchorX or 150) end
        if sliderRefs.groupAnchorY then sliderRefs.groupAnchorY:SetValue(db.groupAnchorY or 0) end
    end
    y = y - 5
    
    -- ===== GRUPPEN-FENSTER =====
    y = AddHeader("Gruppen-Loot Fenster", y)
    y = AddCheck("Separates Fenster für Gruppen", "separateGroupWindow", y)
    y = AddSlider("Gruppen-Größe", "groupScale", 0.5, 1.5, 0.1, y)
    y = AddSlider("Gruppen-Dauer", "groupFadeTime", 2, 15, 1, y)
    y, sliderRefs.groupAnchorX = AddSlider("Gruppen X", "groupAnchorX", -800, 800, 10, y, function(v)
        if groupAnchorFrame then
            groupAnchorFrame:ClearAllPoints()
            groupAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", v, db.groupAnchorY or 0)
        end
    end)
    y, sliderRefs.groupAnchorY = AddSlider("Gruppen Y", "groupAnchorY", -500, 500, 10, y, function(v)
        if groupAnchorFrame then
            groupAnchorFrame:ClearAllPoints()
            groupAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", db.groupAnchorX or 150, v)
        end
    end)
    y = y - 5
    
    -- ===== DESIGN =====
    y = AddHeader("Design", y)
    
    local designContainer = CreateFrame("Frame", nil, content)
    designContainer:SetSize(contentWidth, 60)
    designContainer:SetPoint("TOPLEFT", leftMargin, y)
    f.designButtons = {}
    
    local function RefreshDesignButtons()
        for _, btn in ipairs(f.designButtons) do
            btn:Hide()
        end
        f.designButtons = {}
        
        local designs = ELF:GetDesignList()
        local btnWidth = 62
        local col, row = 0, 0
        
        for i, design in ipairs(designs) do
            local btn = CreateFrame("Button", nil, designContainer, "BackdropTemplate")
            btn:SetSize(btnWidth, 20)
            btn:SetPoint("TOPLEFT", col * (btnWidth + 2), -row * 22)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8
            })
            
            local btnText = btn:CreateFontString(nil, "OVERLAY")
            btnText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            btnText:SetPoint("CENTER")
            btn.label = btnText
            btn.designId = design.id
            
            local function UpdateBtn()
                if db.design == btn.designId then
                    btn:SetBackdropColor(0.1, 0.5, 0.1, 1)
                    btn:SetBackdropBorderColor(0.3, 1, 0.3, 1)
                    btnText:SetText("|cff00ff00" .. design.name .. "|r")
                else
                    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
                    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                    btnText:SetText("|cffaaaaaa" .. design.name .. "|r")
                end
            end
            
            btn:SetScript("OnClick", function()
                db.design = btn.designId
                ClearAllRows()
                RefreshDesignButtons()
                ELF:TestLoot()
            end)
            
            UpdateBtn()
            btn:Show()
            table.insert(f.designButtons, btn)
            
            col = col + 1
            if col >= 4 then
                col = 0
                row = row + 1
            end
        end
    end
    f.RefreshDesignButtons = RefreshDesignButtons
    
    y = y - 55
    
    -- ===== MIN QUALITY =====
    y = AddHeader("Min. Qualität", y)
    local qualY, qualButtons, UpdateQualButtons = CreateToggleGroup(content, y, {
        {id = 0, name = "Alle"},
        {id = 2, name = "Grün"},
        {id = 3, name = "Blau"},
        {id = 4, name = "Lila"},
    }, "minimumQuality", 0)
    y = qualY
    
    -- Override colors für Quality-Buttons
    local qualColors = {[0]={0.6,0.6,0.6}, [2]={0.12,1,0}, [3]={0,0.44,0.87}, [4]={0.64,0.21,0.93}}
    local function UpdateQualButtonColors()
        local current = db.minimumQuality or 0
        for _, btn in ipairs(qualButtons) do
            local col = qualColors[btn.value] or {0.6,0.6,0.6}
            if current == btn.value then
                btn:SetBackdropColor(col[1]*0.3, col[2]*0.3, col[3]*0.3, 1)
                btn:SetBackdropBorderColor(col[1], col[2], col[3], 1)
                btn.label:SetTextColor(col[1], col[2], col[3])
            else
                btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                btn.label:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end
    for _, btn in ipairs(qualButtons) do
        btn:SetScript("OnClick", function(self)
            db.minimumQuality = self.value
            UpdateQualButtonColors()
        end)
        btn:SetScript("OnLeave", function() UpdateQualButtonColors() end)
    end
    UpdateQualButtonColors()
    f.UpdateQual = UpdateQualButtonColors
    
    -- ===== BOTTOM BUTTONS =====
    local testBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    testBtn:SetSize(90, 28)
    testBtn:SetPoint("BOTTOMLEFT", 15, 12)
    testBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10
    })
    testBtn:SetBackdropColor(0.1, 0.3, 0.1, 1)
    testBtn:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
    local testText = testBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    testText:SetPoint("CENTER")
    testText:SetText("|cff00ff00Test|r")
    testBtn:SetScript("OnClick", function() ELF:TestLoot() end)
    
    local resetBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    resetBtn:SetSize(90, 28)
    resetBtn:SetPoint("BOTTOMRIGHT", -15, 12)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10
    })
    resetBtn:SetBackdropColor(0.3, 0.1, 0.1, 1)
    resetBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)
    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetText:SetPoint("CENTER")
    resetText:SetText("|cffff6666Reset|r")
    resetBtn:SetScript("OnClick", function()
        db.anchorX = -150
        db.anchorY = 0
        db.groupAnchorX = 150
        db.groupAnchorY = 0
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", -150, 0)
        end
        if groupAnchorFrame then
            groupAnchorFrame:ClearAllPoints()
            groupAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 150, 0)
        end
        if f.UpdateSliders then f.UpdateSliders() end
        print("|cff00ff00EpicLootFeed|r: Positionen zurückgesetzt!")
    end)
    
    -- Hide movers when config closes
    f:SetScript("OnHide", function()
        moversVisible = false
        ELF:ToggleMovers(false)
        moverText:SetText("|cff00ff00Positionen anpassen|r")
        moverBtn:SetBackdropColor(0, 0.4, 0, 1)
        moverBtn:SetBackdropBorderColor(0, 0.8, 0, 1)
    end)
    
    configFrame = f
    return f
end

function ELF:ToggleConfig()
    local f = CreateConfigPanel()
    f.RefreshDesignButtons()
    if f.UpdateQual then f.UpdateQual() end
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
    elseif cmd == "testepic" or cmd == "epic" then
        -- Test Epic Popup
        ELF:ShowEpicPopup("Interface\\Icons\\INV_Sword_39", "Ashkandi, Schwert der Bruderschaft", 4, nil)
    elseif cmd == "move" or cmd == "unlock" then
        -- Toggle Mover Frames
        local isShown = ELF.feedMover and ELF.feedMover:IsShown()
        ELF:ToggleMovers(not isShown)
        if not isShown then
            print("|cff00ff00EpicLootFeed|r: |cff00ff00Mover AN|r - Ziehe die Kästchen!")
        else
            print("|cff00ff00EpicLootFeed|r: |cffff6666Mover AUS|r - Position gespeichert")
        end
    elseif cmd == "lock" then
        ELF:ToggleMovers(false)
        print("|cff00ff00EpicLootFeed|r: |cffff6666Mover AUS|r - Position gespeichert")
    elseif cmd == "debug" then
        ELF.debugMode = not ELF.debugMode
        print("|cff00ff00EpicLootFeed|r Debug: " .. (ELF.debugMode and "AN" or "AUS"))
    elseif cmd == "status" then
        print("|cff00ff00EpicLootFeed|r v" .. ELF.version .. " Status:")
        print("  showGroupLoot: " .. tostring(db.showGroupLoot))
        print("  separateGroupWindow: " .. tostring(db.separateGroupWindow))
        print("  showEpicPopup: " .. tostring(db.showEpicPopup))
        print("  design: " .. tostring(db.design))
        print("  activeRows: " .. #activeRows)
    elseif cmd == "reset" then
        EpicLootFeedDB = {}
        for k, v in pairs(defaults) do
            EpicLootFeedDB[k] = v
        end
        db = EpicLootFeedDB
        ELF.db = db
        print("|cff00ff00EpicLootFeed|r: Einstellungen zurückgesetzt!")
        print("  Bitte /reload eingeben!")
    elseif cmd == "groupon" then
        db.showGroupLoot = true
        print("|cff00ff00EpicLootFeed|r: Gruppen-Loot AKTIVIERT")
    elseif cmd == "groupoff" then
        db.showGroupLoot = false
        print("|cff00ff00EpicLootFeed|r: Gruppen-Loot DEAKTIVIERT")
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
        print("  /elf - Einstellungen öffnen")
        print("  /elf |cff00ff00move|r - Position mit Maus anpassen")
        print("  /elf test - Test (Feed)")
        print("  /elf group - Test (Gruppen-Loot)")
        print("  /elf epic - Test (Epic Popup)")
        print("  /elf debug - Debug An/Aus")
        print("  /elf status - Status anzeigen")
        print("  /elf reset - Zurücksetzen")
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
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")

-- Geld-Tracking Variablen
local lastMoney = 0
local lastMoneyChangeTime = 0

local function HandleMoneyChange()
    if not db or not db.enabled or not db.showMoney then return end
    
    local currentMoney = GetMoney()
    local diff = currentMoney - lastMoney
    local now = GetTime()
    
    -- Ignoriere sehr kleine Änderungen in kurzer Zeit (Duplikate vermeiden)
    if now - lastMoneyChangeTime < 0.1 then
        lastMoney = currentMoney
        return
    end
    lastMoneyChangeTime = now
    
    if diff > 0 then
        -- Geld erhalten - Priorität: Merchant > Gruppe > Briefkasten > Normal
        local source = nil
        if merchantOpen then
            source = "Verkauf"
        elseif (IsInGroup() or IsInRaid()) and not mailboxOpen then
            source = "Anteil"  -- Gruppen-Geld-Aufteilung hat Vorrang!
        elseif mailboxOpen then
            source = "Post"
        end
        ELF:ShowMoneyGain(diff, source)
        
        if ELF.debugMode then
            print("|cff00ff00GELD +|r " .. diff .. " Kupfer" .. (source and " ("..source..")" or "") .. " [merchant=" .. tostring(merchantOpen) .. " mail=" .. tostring(mailboxOpen) .. " group=" .. tostring(IsInGroup()) .. "]")
        end
    elseif diff < 0 then
        -- Geld ausgegeben
        local source = nil
        if merchantOpen then
            source = "Kauf"
        elseif mailboxOpen then
            source = "Porto"
        end
        ELF:ShowMoneyLoss(-diff, source)
        
        if ELF.debugMode then
            print("|cffff0000GELD -|r " .. (-diff) .. " Kupfer" .. (source and " ("..source..")" or ""))
        end
    end
    
    lastMoney = currentMoney
end

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
            -- Initialisiere Geld-Tracking
            lastMoney = GetMoney()
            print("|cff00ff00EpicLootFeed|r v" .. ELF.version .. " geladen! /elf für Einstellungen")
            
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
        -- Ignorieren - wir nutzen PLAYER_MONEY stattdessen für bessere Kontrolle
        -- HandleMoney(...)
    elseif event == "PLAYER_MONEY" then
        HandleMoneyChange()
    elseif event == "MERCHANT_SHOW" then
        merchantOpen = true
        lastMoney = GetMoney()
        if ELF.debugMode then
            print("|cff00ffffMERCHANT OPEN|r - Geld: " .. lastMoney)
        end
    elseif event == "MERCHANT_CLOSED" then
        merchantOpen = false
        if ELF.debugMode then
            print("|cff00ffffMERCHANT CLOSED|r")
        end
    elseif event == "MAIL_SHOW" then
        mailboxOpen = true
        lastMoney = GetMoney()
        if ELF.debugMode then
            print("|cff00ffffMAIL OPEN|r - Geld: " .. lastMoney)
        end
    elseif event == "MAIL_CLOSED" then
        mailboxOpen = false
        if ELF.debugMode then
            print("|cff00ffffMAIL CLOSED|r")
        end
    end
end)
