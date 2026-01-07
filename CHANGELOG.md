# EpicLootFeed Changelog

---

## 🇬🇧 English

### v5.6.1 (2026-01-02)
**Bug Fixes:**
- Fixed "Post erhalten" showing incorrectly for group loot gold share
- Fixed variable scope issue with merchantOpen
- Added "Anteil erhalten" label for group gold distribution
- Improved context detection for mailbox vs. normal loot

**Complete Label Overview:**
| Context | Label |
|---------|-------|
| Normal loot | "Du hast erhalten" |
| Group member loots | "Spielername erhält" |
| Roll won (you) | "Gewonnen" |
| Roll won (other) | "Spielername - Gewonnen" |
| Mailbox item | "Post erhalten" |
| Quest reward | "Erhalten" |
| Sell to vendor | "Verkauft" |
| Buy from vendor | "Gekauft" |
| Group gold share | "Anteil erhalten" |
| Mail gold | "Post erhalten" |
| Postage | "Porto bezahlt" |
| Other spending | "Ausgegeben" |

---

### v5.6.0 (2026-01-02)
**New Features:**
- **Mailbox Support**: Items from mailbox now show with "Post erhalten" label
- **Mail Money**: Gold from mail shows "(Post)" source
- **Postage Tracking**: Sending mail costs show as "Porto bezahlt"
- **Roll Won Label**: Won items now show "Gewonnen" instead of generic label

**Labels:**
| Action | Label |
|--------|-------|
| Loot item | "Du hast erhalten" |
| Group loot | "Spielername erhält" |
| Won roll | "Gewonnen" |
| Mailbox item | "Post erhalten" |
| Sell to vendor | "Verkauft" |
| Buy from vendor | "Gekauft" |
| Mail gold received | "Post erhalten" |
| Postage paid | "Porto bezahlt" |

---

### v5.5.0 (2026-01-02)
**New Features:**
- **Buy/Sell Tracking**: Shows gold gained when selling items to vendors
- **Purchase Display**: Shows gold spent when buying from vendors
- Green "+5g 20s" popup when selling
- Red "-2g 50s" popup when buying
- Source indicator "(Verkauf)" or "(Kauf)" when at merchant

---

### v5.4.0 (2026-01-02)
**Bug Fixes:**
- **Fixed Roll Spam**: Items being rolled on no longer appear 3-4 times
- **Whitelist Approach**: Only valid loot messages are now shown:
  - "Ihr erhaltet Beute:" (you looted)
  - "Spielername erhält Beute:" (group member looted)
  - "Ihr habt gewonnen:" (you won roll)
  - "Spielername gewinnt:" (group member won roll)
- All roll messages (würfelt, Bedarf, Gier, gepasst) are now properly ignored
- **Improved Group Loot Detection**: Better extraction of player names

---

### v5.3.0 (2026-01-01)
**New Features:**
- **Group Loot Display**: Shows when party/raid members loot items
- New checkbox "Show Group Loot" in config panel
- Player name displayed in popup (e.g. "Thrall erhält" instead of "Du hast erhalten")
- New test command `/elf testgroup` to preview group loot display

**Changes:**
- Legendary items from group members show "PlayerName → Legendär!"

---

### v5.2.0 (2026-01-01)
**New Features:**
- Added "Row Spacing" slider (-40 to +50) for precise control over popup distances
- Dynamic spacing now adapts to each design's frame height automatically

**Changes:**
- Renamed "Pretty" design to "Epic"
- Renamed "Looti" design to "Kompakt"

**Fixes:**
- Fixed overlapping popups with larger frame designs
- Improved text positioning in Epic design
- Fixed "Legendäres Item!" label being cut off

---

### v5.1.0
**New Features:**
- Added "Epic" design (formerly "Pretty") with original pretty_lootalert textures
- Includes authentic .blp textures and sound effects
- Quality-specific icon borders (green, blue, purple, orange)
- Special legendary frame with golden dragon border
- Sound effects for Rare, Epic, and Legendary items

---

### v5.0.0 - Modular Design System
**Major Rewrite:**
- Complete modular architecture - each design is now a separate file
- Easy to add custom designs (just drop a .lua file in Designs/)
- Design Registry system for plugin-style extensibility

**8 Included Designs:**
1. Classic - Simple tooltip style
2. Ornate - Gold RPGLootFeed style
3. Kompakt - Slim minimal bars
4. Fire - Burning ember particles
5. Frost - Ice crystal effects
6. Void - Dark purple wisps
7. Minimal - Text-only MSBT style
8. Epic - Premium loot toast with original textures

**Config Panel:**
- Design selector with visual buttons
- All designs show in 3-column grid
- Click to switch + auto-test

---

### v4.0.0 - v4.1.0
- RPGLootFeed-style ornate popups
- German localization ("Du hast erhalten")
- Draggable minimap button
- Position controls (X/Y sliders)
- Grow up/down toggle
- Quality-based styling

---

### v3.0.0
- Initial floating bubble system
- Particle effects
- Basic config panel
- Minimap button

---

## 🇩🇪 Deutsch

### v5.6.1 (2026-01-02)
**Fehlerbehebungen:**
- "Post erhalten" wird nicht mehr fälschlich bei Gruppen-Gold-Aufteilung angezeigt
- Variable Scope Problem mit merchantOpen behoben
- "Anteil erhalten" Label für Gruppen-Gold-Verteilung hinzugefügt
- Verbesserte Kontext-Erkennung für Briefkasten vs. normaler Loot

**Komplette Label-Übersicht:**
| Kontext | Label |
|---------|-------|
| Normaler Loot | "Du hast erhalten" |
| Gruppenmitglied lootet | "Spielername erhält" |
| Roll gewonnen (du) | "Gewonnen" |
| Roll gewonnen (andere) | "Spielername - Gewonnen" |
| Briefkasten-Item | "Post erhalten" |
| Quest-Belohnung | "Erhalten" |
| An Händler verkaufen | "Verkauft" |
| Von Händler kaufen | "Gekauft" |
| Gruppen-Gold-Anteil | "Anteil erhalten" |
| Post-Gold | "Post erhalten" |
| Porto | "Porto bezahlt" |
| Sonstige Ausgaben | "Ausgegeben" |

---

### v5.6.0 (2026-01-02)
**Neue Features:**
- **Briefkasten-Unterstützung**: Items aus dem Briefkasten zeigen "Post erhalten" Label
- **Post-Geld**: Gold aus Post zeigt "(Post)" als Quelle
- **Porto-Tracking**: Porto-Kosten werden als "Porto bezahlt" angezeigt
- **Gewonnen-Label**: Gewürfelte Items zeigen "Gewonnen" statt Standard-Label

**Labels:**
| Aktion | Label |
|--------|-------|
| Item looten | "Du hast erhalten" |
| Gruppen-Loot | "Spielername erhält" |
| Roll gewonnen | "Gewonnen" |
| Briefkasten-Item | "Post erhalten" |
| An Händler verkaufen | "Verkauft" |
| Von Händler kaufen | "Gekauft" |
| Post-Gold erhalten | "Post erhalten" |
| Porto bezahlt | "Porto bezahlt" |

---

### v5.5.0 (2026-01-02)
**Neue Features:**
- **Kauf/Verkauf-Tracking**: Zeigt Gold-Gewinn beim Verkaufen an Händler
- **Kauf-Anzeige**: Zeigt ausgegebenes Gold beim Kaufen
- Grünes "+5g 20s" Popup beim Verkaufen
- Rotes "-2g 50s" Popup beim Kaufen
- Quell-Anzeige "(Verkauf)" oder "(Kauf)" bei Händlern

---

### v5.4.0 (2026-01-02)
**Fehlerbehebungen:**
- **Roll-Spam behoben**: Items beim Würfeln erscheinen nicht mehr 3-4 mal
- **Whitelist-Ansatz**: Nur gültige Loot-Nachrichten werden angezeigt:
  - "Ihr erhaltet Beute:" (du hast gelooted)
  - "Spielername erhält Beute:" (Gruppenmitglied hat gelooted)
  - "Ihr habt gewonnen:" (du hast Roll gewonnen)
  - "Spielername gewinnt:" (Gruppenmitglied hat Roll gewonnen)
- Alle Roll-Nachrichten (würfelt, Bedarf, Gier, gepasst) werden jetzt ignoriert
- **Verbesserte Gruppen-Loot Erkennung**: Bessere Extraktion von Spielernamen

---

### v5.3.0 (2026-01-01)
**Neue Features:**
- **Gruppen-Loot Anzeige**: Zeigt wenn Party/Raid-Mitglieder Items looten
- Neue Checkbox "Gruppen-Loot anzeigen" im Einstellungs-Panel
- Spielername wird im Popup angezeigt (z.B. "Thrall erhält" statt "Du hast erhalten")
- Neuer Test-Befehl `/elf testgroup` um Gruppen-Loot Anzeige zu testen

**Änderungen:**
- Legendary Items von Gruppenmitgliedern zeigen "Spielername → Legendär!"

---

### v5.2.0 (2026-01-01)
**Neue Features:**
- "Zeilen-Abstand" Regler hinzugefügt (-40 bis +50) für präzise Kontrolle über Popup-Abstände
- Dynamischer Abstand passt sich jetzt automatisch an die Frame-Höhe jedes Designs an

**Änderungen:**
- "Pretty" Design umbenannt zu "Epic"
- "Looti" Design umbenannt zu "Kompakt"

**Fehlerbehebungen:**
- Überlappende Popups bei größeren Frame-Designs behoben
- Text-Positionierung im Epic Design verbessert
- "Legendäres Item!" Label wird nicht mehr abgeschnitten

---

### v5.1.0
**Neue Features:**
- "Epic" Design hinzugefügt (vorher "Pretty") mit Original pretty_lootalert Texturen
- Enthält authentische .blp Texturen und Sound-Effekte
- Qualitäts-spezifische Icon-Rahmen (grün, blau, lila, orange)
- Spezieller Legendary-Rahmen mit goldenem Drachen-Border
- Sound-Effekte für Rare, Epic und Legendary Items

---

### v5.0.0 - Modulares Design-System
**Große Überarbeitung:**
- Komplett modulare Architektur - jedes Design ist jetzt eine separate Datei
- Einfach eigene Designs hinzufügen (einfach .lua Datei in Designs/ ablegen)
- Design-Registry System für Plugin-artige Erweiterbarkeit

**8 Enthaltene Designs:**
1. Classic - Einfacher Tooltip-Stil
2. Ornate - Gold RPGLootFeed Stil
3. Kompakt - Schlanke minimale Balken
4. Fire - Brennende Glut-Partikel
5. Frost - Eiskristall-Effekte
6. Void - Dunkle lila Wisps
7. Minimal - Nur-Text MSBT Stil
8. Epic - Premium Loot-Toast mit Original-Texturen

**Einstellungs-Panel:**
- Design-Auswahl mit visuellen Buttons
- Alle Designs in 3-Spalten-Raster
- Klick zum Wechseln + Auto-Test

---

### v4.0.0 - v4.1.0
- RPGLootFeed-Stil verzierte Popups
- Deutsche Lokalisierung ("Du hast erhalten")
- Verschiebbarer Minimap-Button
- Positions-Kontrollen (X/Y Regler)
- Nach oben/unten wachsen Umschalter
- Qualitäts-basiertes Styling

---

### v3.0.0
- Erstes schwebendes Bubble-System
- Partikel-Effekte
- Einfaches Einstellungs-Panel
- Minimap-Button

---

## Commands / Befehle

| Command | Description / Beschreibung |
|---------|---------------------------|
| `/elf` | Open config panel / Einstellungen öffnen |
| `/elf test` | Show test items / Test-Items anzeigen |
| `/elf designs` | List all designs / Alle Designs auflisten |
| `/elf design [1-8]` | Switch design / Design wechseln |

---

## Credits

- Original textures from [pretty_lootalert](https://github.com/s0h2x/pretty_lootalert) by s0h2x
- Inspired by [RPGLootFeed](https://github.com/McTalian/RPGLootFeed) and [Looti](https://github.com/FinMckinnon/Looti)
