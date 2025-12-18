# Notenübersicht kompakter und ruhiger gestalten

## Problem / Goal

Die aktuelle Notenübersicht ist **überfrachtet, zu groß und unruhig**. Lehrer verlieren schnell den Überblick über die wichtigsten Informationen. Die UI wirkt erschlagend und nicht fokussiert auf die Kernaufgabe: **Schneller Überblick über Schülernoten**.

**Business Value:**
- **Bessere UX**: Lehrer finden Informationen schneller
- **Weniger Scrolling**: Kompaktere Darstellung = mehr Daten auf einem Blick
- **Ruhigeres Design**: Reduzierte visuelle Komplexität = weniger kognitive Last
- **Effizienz**: Schnellere Notenerfassung und -verwaltung

## Scope

### In Scope
- Redesign der Notenübersicht (kompakter, ruhiger, fokussierter)
- Reduzierung visueller Elemente (weniger Borders, Shadows, Colors)
- Optimierung der Informationsdichte (mehr Daten, weniger Platz)
- Verbesserte Typografie (Hierarchie, Lesbarkeit)
- Optimierte Tabellen-Darstellung (DataTables)
- Optional: Gruppierung/Filterung für bessere Übersicht

### Out of Scope
- Komplett neue Features (z.B. Noteneingabe-Modi)
- Performance-Optimierungen (nur UI-Design)
- Export-Funktionen (separates Issue)
- Mobile-Optimierung (erstmal nur Web)

## Aktuelle Probleme (Screenshots/Analyse erforderlich)

**Zu klären:**
1. Welche Screen ist betroffen? (Dashboard, Schüler-Detailansicht, Klassen-Notenübersicht?)
2. Was ist konkret "überfrachtet"? (zu viele Spalten, zu viele Buttons, zu viele Farben?)
3. Welche Informationen sind **Muss** vs. **Nice-to-Have**?

## Design-Ziele

### 1. Kompaktheit
- **Kleinere Schriftgrößen** (wo sinnvoll)
- **Reduzierter Padding/Spacing** (8px statt 16px)
- **Kondensierte Tabellen** (weniger Row-Height)
- **Icon-Buttons** statt Text-Buttons (wo möglich)

### 2. Ruhe & Klarheit
- **Weniger Farben** (nur für wichtige Highlights)
- **Weniger Borders** (subtilere Trennung)
- **Keine Shadows** (flacheres Design)
- **Monochrome Icons** (einheitlicher Look)

### 3. Fokus & Hierarchie
- **Wichtige Infos hervorheben** (z.B. Durchschnitt, kritische Noten)
- **Unwichtige Infos ausblenden** (z.B. Timestamps in Tooltip)
- **Visuelle Hierarchie** (größer = wichtiger)

## Vorschläge für Verbesserungen

### Tabellen-Optimierung
```
Vorher:
┌─────────────────────────────────────────────────────────────┐
│ Name          │ Note 1 │ Note 2 │ Note 3 │ Durchschnitt │ Aktion │
├─────────────────────────────────────────────────────────────┤
│ Max Mustermann│  1,5   │  2,0   │  1,0   │     1,5      │ [Edit] │
│               │        │        │        │              │ [Del]  │
└─────────────────────────────────────────────────────────────┘

Nachher:
┌─────────────────────────────────────────────┐
│ Name              Note1  Note2  Note3  Ø   │
├─────────────────────────────────────────────┤
│ Mustermann, Max    1.5    2.0    1.0  1.5  │  [⋯]
└─────────────────────────────────────────────┘
```

**Änderungen:**
- Nachname, Vorname (kompakter)
- Dezimalpunkt statt Komma
- Keine "Aktion"-Spalte (Dropdown-Menü am Zeilenende)
- Kleinere Fonts, weniger Padding

### Farb-Schema
```
Vorher:
- Viele bunte Farben (rot, grün, gelb, blau)
- Jede Note hat eine Farbe
- Buttons in verschiedenen Farben

Nachher:
- Nur kritische Noten rot (z.B. 5.0, 6.0)
- Durchschnitt fett (ohne Farbe)
- Buttons monochrom (Icon-only)
```

### Layout-Struktur
```
Vorher:
┌─────────────────────────────────────┐
│  Große Überschrift                  │
│  Beschreibung Beschreibung          │
│                                     │
│  [Button] [Button] [Button]         │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Große Tabelle mit Borders   │  │
│  │   und viel Padding            │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Nachher:
┌─────────────────────────────────────┐
│  Überschrift              [⋯]       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Name              N1  N2  N3   Ø   │
│  Mustermann, Max   1.5 2.0 1.0  1.5 │
│  Schmidt, Anna     2.0 1.0 2.5  1.8 │
└─────────────────────────────────────┘
```

## Implementierungsplan

### Phase 1: Analyse (2 Tasks)
- [ ] Screenshots der aktuellen Notenübersicht machen
- [ ] Feedback von Lehrern einholen: Was ist konkret störend?

### Phase 2: Design (5 Tasks)
- [ ] Mockups erstellen (kompakte vs. aktuelle Version)
- [ ] Farb-Schema reduzieren (nur kritische Highlights)
- [ ] Typografie-System definieren (kleinere Fonts, Hierarchie)
- [ ] Spacing-System anpassen (8px statt 16px)
- [ ] Icon-Set für Aktionen definieren (Edit, Delete, More)

### Phase 3: Implementierung (8 Tasks)
- [ ] DataTable-Theme anpassen (kleinere Row-Height, weniger Padding)
- [ ] Spalten optimieren (Nachname, Vorname; Dezimalpunkt)
- [ ] Farb-Highlighting nur für kritische Noten (5.0, 6.0)
- [ ] Action-Buttons durch Dropdown-Menü ersetzen
- [ ] Überschriften kompakter gestalten
- [ ] Borders/Shadows reduzieren
- [ ] Optional: Filter/Gruppierung hinzufügen (z.B. nach Fach)
- [ ] Responsive-Test (funktioniert auch bei vielen Spalten?)

### Phase 4: Testing & Feedback (3 Tasks)
- [ ] A/B-Test mit Lehrern (alte vs. neue Version)
- [ ] Usability-Test: Finden Lehrer Informationen schneller?
- [ ] Anpassungen basierend auf Feedback

## Akzeptanzkriterien

### Muss-Kriterien
- [ ] Notenübersicht ist **mindestens 30% kompakter** (weniger Platz)
- [ ] Alle wichtigen Informationen sind **auf einen Blick** sichtbar (kein Scrolling)
- [ ] Design wirkt **ruhiger** (weniger visuelle Elemente)
- [ ] Kritische Noten (5.0, 6.0) sind **sofort erkennbar**
- [ ] Lehrer finden **schneller** zu den wichtigsten Infos

### Kann-Kriterien
- [ ] Filter/Gruppierung (z.B. nach Fach, Zeitraum)
- [ ] Sortierung (nach Name, Durchschnitt, etc.)
- [ ] Export-Funktion (PDF, Excel)

## Risiken & Notes

- **Risiko**: Zu kompakt = unleserlich
  - **Mitigation**: Usability-Tests mit echten Lehrern
- **Risiko**: Wichtige Infos werden übersehen
  - **Mitigation**: Klare Hierarchie, Highlighting
- **Note**: Design sollte mit Theme-System kompatibel sein (RBS + C64)

---

**Geschätzter Aufwand**: 8-12h (1 Entwickler)  
**Priorität**: High (verbessert tägliche UX für Lehrer)  
**Labels**: `enhancement`, `design`, `ux`, `notenübersicht`
