# Release Notes v0.30.0 - Phase 8: Feature-Flags & Notenübersicht kompakter

**Release Date:** 2025-12-30  
**Tag:** `v0.30.0`

## 🎯 Zusammenfassung

Diese Version implementiert **Feature-Flags für granulare Lehrer-Berechtigungen** und macht die **Notenübersicht kompakter und ruhiger** durch reduzierte Farbpalette und optimierte Layouts.

## ✨ Neue Features

### Feature-Flags System (Issue #46)

**FeatureFlags Model** mit 17 granularen Berechtigungen:
- **Stammdaten:** canCreate/Edit/DeleteSchueler, canCreate/Edit/DeleteKlassen, canCreate/Edit/DeleteFaecher
- **Leistungsnachweise:** canCreate/Edit/DeleteLeistungsnachweise
- **Export:** canExportPDF, canExportExcel, canExportNOI
- **Sonstiges:** canImportCSV, canToggleFavorites

**Admin Feature-Flags Screen:**
- Übersichtliche Toggle-UI für alle 17 Flags
- Kategorisiert nach Funktionsbereich
- Nur für Admin-Benutzer sichtbar

**Permission Guards:**
- Alle Stammdaten-Screens prüfen Feature-Flags
- Buttons werden ausgeblendet wenn nicht berechtigt
- Konsistente Benutzerführung

### Notenübersicht kompakter (Issue #47)

**NotenLayoutConstants** - Zentralisierte Layout-Werte:
```dart
NotenSpacing: xs=4, sm=6, md=8, lg=12
NotenTableDimensions: rowHeight=40px (statt 52px)
NotenFontSizes: 13px (statt 14px)
```

**NotenColors** - Reduzierte Farbpalette:
- Nur kritische Noten (5, 6) werden rot hervorgehoben
- Noten 1-4 sind neutral (dunkelgrau)
- Ruhigeres, weniger ablenkendenes Design

**Kompakte Note-Eingabe:**
- Kleinere Dropdowns und Tendenz-Buttons
- Konsistente Abstände und Schriftgrößen
- Responsive Anpassung an Bildschirmgröße

## 📦 Technische Details

**Neue Dateien:**
- `lib/models/feature_flags.dart` - FeatureFlags Model
- `lib/providers/feature_flags_provider.dart` - Firestore-Stream Provider
- `lib/features/admin/screens/feature_flags_screen.dart` - Admin UI
- `lib/features/noten/noten_layout_constants.dart` - Layout-Konstanten
- `docs/ISSUE_ADMIN_FEATURE_FLAGS.md` - Dokumentation
- `docs/ISSUE_NOTENÜBERSICHT_KOMPAKT.md` - Dokumentation

**Geänderte Dateien:**
- `lib/features/*/screens/*.dart` - Permission Guards hinzugefügt
- `lib/features/noten/widgets/*.dart` - Kompaktere Layouts

## ✅ Qualität

- **Tests:** 361 Unit-Tests + 9 Integration-Tests
- **Neue Tests:** 11 Tests für FeatureFlags Model
- **Coverage:** ≥50%
- **Linting:** 0 Warnungen

## 📋 Upgrade-Anleitung

1. `flutter pub get`
2. Firestore-Dokument `/settings/features` wird automatisch erstellt
3. Admin kann Feature-Flags unter Einstellungen → Feature-Flags konfigurieren
