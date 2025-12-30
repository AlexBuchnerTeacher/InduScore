# Release Notes v0.20.0

**Datum:** 2025-12-30  
**Typ:** Major Architecture Release  
**Branch:** `feature/phase-3-v0.20.0`

---

## 🎯 Highlights

- **Feature-based Architecture**: Komplette Migration von `screens/` nach `features/`
- **Accessibility**: Semantics-Labels für bessere Barrierefreiheit
- **Clean Code**: Entfernung von Test-Screens und veralteten Dateien

---

## ✨ Neue Features

### F-016: Feature-based Architecture (Breaking Change)

**Vorher:**
```
lib/
├── screens/           # Alle Screens in einem Ordner
│   ├── home_screen.dart
│   ├── klassen_screen.dart
│   └── ...
```

**Nachher:**
```
lib/
├── features/
│   ├── auth/screens/          # Login
│   ├── dashboard/screens/     # Home
│   ├── klassen/screens/       # Klassen + Detail
│   ├── faecher/screens/       # Fächer + Detail
│   ├── schueler/screens/      # Schüler + Detail
│   ├── leistungsnachweise/screens/  # LN + Editor
│   ├── noten/screens/         # Eingabe + Übersicht
│   ├── export/screens/        # NOI Export
│   ├── import/screens/        # CSV Import
│   ├── users/screens/         # Benutzerverwaltung
│   ├── settings/screens/      # Einstellungen
│   └── profile/screens/       # Profil
```

**Vorteile:**
- Bessere Modularität und Wartbarkeit
- Klare Feature-Grenzen
- Einfacheres Onboarding für neue Entwickler
- Vorbereitung für zukünftige Code-Splitting

### F-017: Accessibility Verbesserungen

Neue Semantics-Labels für Screen Reader:

- **RBSButton**: `semanticLabel` Parameter für beschreibende Labels
- **RBSCard**: `semanticLabel` Parameter für Karten-Beschreibung
- **Drawer Items**: Automatische Semantics mit Status-Informationen

```dart
// Beispiel
RBSButton(
  label: 'Speichern',
  semanticLabel: 'Änderungen speichern',
  onPressed: _save,
)
```

---

## 🔧 Technische Änderungen

### Import-Migration

Alle relativen Imports wurden auf Package-Imports umgestellt:

```dart
// Vorher (relativ)
import '../core/theme/rbs_theme.dart';

// Nachher (package)
import 'package:induscore/core/theme/rbs_theme.dart';
```

### Entfernte Dateien

- `lib/screens/` - Vollständig nach `features/` migriert
- `lib/screens/test_matrix_screen.dart` - Entwicklungs-Screen entfernt
- `/test-matrix` Route - Entfernt

### Geänderte Imports in main.dart

Alle Screen-Imports verwenden jetzt den neuen Feature-Pfad:

```dart
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_screen.dart';
import 'features/klassen/screens/klassen_screen.dart';
// ... etc.
```

---

## 📊 Statistiken

| Metrik | Wert |
|--------|------|
| Tests | 269 (alle bestanden) |
| Migrierte Screens | 14 |
| Neue Feature-Ordner | 12 |
| LOC entfernt | ~100 (test screen + alte struktur) |
| Analyse-Fehler | 0 |

---

## 📁 Feature-Struktur (Neu)

```
lib/features/
├── auth/
│   └── screens/login_screen.dart
├── dashboard/
│   ├── screens/home_screen.dart
│   └── widgets/
├── klassen/
│   ├── screens/klassen_screen.dart
│   ├── screens/klassen_detail_screen.dart
│   └── widgets/
├── faecher/
│   ├── screens/faecher_screen.dart
│   ├── screens/faecher_detail_screen.dart
│   └── widgets/
├── schueler/
│   ├── screens/schueler_screen.dart
│   └── screens/schueler_detail_screen.dart
├── leistungsnachweise/
│   ├── screens/leistungsnachweise_screen.dart
│   └── screens/ln_editor_screen.dart
├── noten/
│   ├── screens/noten_eingabe_screen.dart
│   ├── screens/noten_uebersicht_screen.dart
│   └── widgets/
├── export/
│   └── screens/noi_export_screen.dart
├── import/
│   ├── screens/csv_import_screen.dart
│   └── widgets/csv_import_widgets.dart
├── users/
│   └── screens/user_verwaltung_screen.dart
├── settings/
│   └── screens/settings_screen.dart
└── profile/
    └── screens/profile_screen.dart
```

---

## ⬆️ Upgrade-Hinweise

### Breaking Changes

**Imports**: Wenn Sie eigene Dateien haben, die Screens importieren, müssen die Pfade angepasst werden:

```dart
// Alt
import 'package:induscore/screens/home_screen.dart';

// Neu
import 'package:induscore/features/dashboard/screens/home_screen.dart';
```

### Migration

1. Suchen Sie nach `import 'package:induscore/screens/`
2. Ersetzen Sie durch den neuen Feature-Pfad
3. Führen Sie `flutter analyze` aus um fehlende Imports zu finden

---

## 📥 Installation

Web-App: https://alexbuchnerteacher.github.io/InduScore/

---

## 🔜 Ausblick (v1.0.0)

- E2E-Tests für kritische Workflows
- Web-Performance-Optimierungen
- Lighthouse Score > 90
