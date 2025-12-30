# Release Notes v0.30.1 - Bugfix: Tendenzen & Noteneingabe

**Release Date:** 2025-12-30  
**Tag:** `v0.30.1`

## 🎯 Zusammenfassung

Diese Bugfix-Version korrigiert das **Tendenz-Verhalten** (nur Indikator, keine Berechnung) und macht die **Noteneingabe noch kompakter** mit verbessertem Kürzel-Handling.

## 🐛 Bugfixes

### Tendenzen nur als Indikator

**Problem:** Tendenzen (+/-) wurden in Durchschnittsberechnungen einbezogen (±0.3).

**Lösung:** Tendenzen sind jetzt rein visuelle Indikatoren:
- 2+ = 2.0 (nicht 1.7)
- 2- = 2.0 (nicht 2.3)
- Durchschnitte verwenden ausschließlich Ganzzahl-Noten

```dart
/// Tendenzen werden NICHT in die Berechnung einbezogen!
/// Sie dienen nur als visueller Indikator (+/-) für die Lehrkraft.
static double getNoteWithTendenz(int note, Tendenz tendenz) {
  return note.toDouble(); // Tendenz ignoriert
}
```

### Kürzel aus AppUser-Profil

**Problem:** Kürzel wurde aus E-Mail extrahiert (z.B. "AB" aus "alex.buchner@...").

**Lösung:** Neuer `currentUserKuerzelProvider` liest `AppUser.kuerzel` Feld:
- Verwendet gespeichertes Kürzel aus Firestore
- Fallback auf E-Mail-Extraktion nur wenn Kürzel leer

## 🎨 UI-Verbesserungen

### Noteneingabe noch kompakter

- **Dropdown ohne Rahmen:** Minimalistisches Design
- **Kritische Noten hervorgehoben:** Nur 5, 6 mit rotem Hintergrund
- **Tendenzen vertikal:** Buttons übereinander statt nebeneinander
  - Spart 44px Breite pro Zelle
  - 16x30px Gesamtgröße statt 60x36px

### Kompaktere Dimensionen

| Element | Vorher | Nachher |
|---------|--------|---------|
| Row Height | 40px | 36px |
| Header Height | 48px | 44px |
| Dropdown Width | 42px | 36px |
| Column Spacing | 6px | 4px |

## 📦 Technische Details

**Neue Dateien:**
- `test/features/noten/tendenz_calculation_test.dart` - 9 Tests

**Geänderte Dateien:**
- `lib/providers/app_providers.dart` - `currentUserKuerzelProvider`
- `lib/features/noten/noten_matrix_logic.dart` - `getNoteWithTendenz`
- `lib/features/noten/noten_layout_constants.dart` - Kompaktere Werte
- `lib/features/noten/widgets/note_input_widgets.dart` - Vertikale Tendenzen
- `lib/features/noten/screens/noten_eingabe_screen.dart` - Nutzt neuen Provider
- `lib/features/noten/screens/noten_uebersicht_screen.dart` - Nutzt neuen Provider

## ✅ Qualität

- **Tests:** 370 Unit-Tests (9 neu für Tendenz-Berechnung)
- **Coverage:** ≥50%
- **Linting:** 0 Warnungen
- **CI:** Alle Workflows grün

## 📋 Upgrade-Anleitung

1. `flutter pub get`
2. Keine Datenbank-Migration erforderlich
3. Bestehende Tendenzen bleiben erhalten (nur Anzeige-Änderung)
