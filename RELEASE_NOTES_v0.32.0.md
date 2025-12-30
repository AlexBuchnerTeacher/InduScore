# Release Notes v0.32.0 - Feature-Guards Polish & SnackBar Refactoring

**Release-Datum:** 31.12.2025

## Übersicht

v0.32.0 erweitert das Feature-Flag-System um Guards für Filter und Noten-Zugriff und stellt alle SnackBar-Meldungen auf die zentrale `AppSnackBars`-Klasse um.

## Neue Features

### canUseFilter Guard
- Filter-Bereiche in Klassen-, Schüler- und Fächer-Screens werden bei `canUseFilter = false` ausgeblendet
- Betroffene Komponenten:
  - `KlassenFilterSection`
  - `SchuelerScreen` (Dropdown-Filter)
  - `FaecherScreen` (Dropdown-Filter)

### canAccessNoten Guard
- Alle Links zu Noten-Ansichten werden bei `canAccessNoten = false` deaktiviert
- Betroffene Komponenten:
  - Dashboard Klassen-Chips → `/noten/klasse/{id}`
  - Leistungsnachweise-Liste → `/noten/{id}`
  - Nachschreiber-Section → `/noten/klasse/{klasseId}`
  - Klassen-Detail-Screen → `onLNTap`

## Verbesserungen

### Einheitliche SnackBars
- Alle `ScaffoldMessenger.of(context).showSnackBar(...)` auf `AppSnackBars.showSuccess/showError/showInfo(...)` umgestellt
- Konsistente Farbgebung und Icon-Darstellung
- Betroffene Dateien:
  - `noten_eingabe_screen.dart`
  - `noten_uebersicht_screen.dart`
  - `feature_flags_screen.dart`
  - `klasse_edit_dialog.dart`
  - `klasse_delete_dialog.dart`

## Technische Details

### Geänderte Dateien
| Datei | Änderung |
|-------|----------|
| `lib/widgets/klassen/klassen_filter_section.dart` | canUseFilter Guard |
| `lib/features/schueler/screens/schueler_screen.dart` | canUseFilter Guard |
| `lib/features/faecher/screens/faecher_screen.dart` | canUseFilter Guard |
| `lib/features/dashboard/widgets/klassen_chips.dart` | canAccessNoten Guard |
| `lib/features/dashboard/widgets/leistungsnachweise_list.dart` | canAccessNoten Guard |
| `lib/features/dashboard/widgets/nachschreiber_section.dart` | canAccessNoten Guard |
| `lib/features/klassen/screens/klassen_detail_screen.dart` | canAccessNoten Guard |
| `lib/features/noten/screens/noten_eingabe_screen.dart` | AppSnackBars |
| `lib/features/noten/screens/noten_uebersicht_screen.dart` | AppSnackBars |
| `lib/features/admin/screens/feature_flags_screen.dart` | AppSnackBars |
| `lib/widgets/dialogs/klasse_edit_dialog.dart` | AppSnackBars |
| `lib/widgets/dialogs/klasse_delete_dialog.dart` | AppSnackBars |

## Tests

- 386 Tests bestanden
- Keine Breaking Changes
- Rückwärtskompatibel

## Upgrade-Hinweise

Keine besonderen Maßnahmen erforderlich. Update erfolgt automatisch.

## Bekannte Einschränkungen

- Weitere Dateien mit `ScaffoldMessenger` können in zukünftigen Releases umgestellt werden
- Die Guards deaktivieren nur die Navigation, zeigen aber keine "Gesperrt"-Hinweise

---

*InduScore - Notenverwaltung für RBS*
