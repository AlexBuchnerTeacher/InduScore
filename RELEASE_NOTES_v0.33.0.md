# Release Notes v0.33.0 – UI Improvements

**Release-Datum:** 2025-07-04  
**Version:** 0.33.0+35

---

## 🎯 Übersicht

Version 0.33.0 bringt eine Reihe von **UX-Verbesserungen**, die die Navigation vereinfachen, visuelle Rückmeldungen verbessern und die Schüleransicht benutzerfreundlicher gestalten.

---

## ✨ Neue Features

### 1. Home-Button in allen Screens
Alle Detailansichten haben jetzt einen **konsistenten Home-Button** (🏠) in der AppBar rechts, der direkt zum Dashboard führt.

**Betroffene Screens:**
- ProfileScreen
- SettingsScreen  
- FeatureFlagsScreen

### 2. Kürzel nur durch Admin
Lehrerkürzel werden **ausschließlich vom Admin** vergeben. Die automatische Generierung aus E-Mail-Adressen wurde entfernt.

**Änderungen:**
- Neue User werden ohne Kürzel angelegt
- Kürzel-Feld zeigt "—" wenn leer
- Nur Admins können Kürzel im User-Profil setzen

### 3. Tendenzen aus UI entfernt
Die Tendenz-Buttons (+/·/-) wurden aus der Benutzeroberfläche **entfernt**.

**Details:**
- Das Datenbank-Feld bleibt erhalten für spätere Nutzung
- UI ist schlanker und übersichtlicher
- Betroffene Widgets: EditableNoteCell, StudentSubjectCard, NotenTableWidget

### 4. Schüleransicht mit Teilen-Funktion
Der SchuelerDetailScreen hat jetzt einen **Share-Button** (📤) zum Teilen von Schülernoten.

**Features:**
- Formatierte Textausgabe mit Emoji-Icons
- Kopieren in Zwischenablage
- Enthält: Schülername, Klasse, Notenliste nach Fach gruppiert

### 5. Navigation vereinheitlicht
Die doppelte Route für Schüler-Noten wurde vereinheitlicht.

**Änderungen:**
- `/noten/schueler/{id}` → Redirect zu `/schueler/{id}`
- SchuelerDetailScreen ist jetzt die zentrale Schüler-Ansicht

### 6. Animationen bei Notenänderung
Wenn eine Note geändert wird, zeigt die Zelle jetzt eine **kurze Highlight-Animation**.

**Details:**
- Grüner Highlight für gute Noten (1-3)
- Roter Highlight für kritische Noten (5-6)
- Blauer Highlight für mittlere Noten (4)
- 600ms Fade-Out-Animation

### 7. Breadcrumb-Navigation
Detailansichten zeigen jetzt eine **Breadcrumb-Leiste** für bessere Orientierung.

**Format:** Home > Klassen > 12IT1 > Max Mustermann

**Betroffene Screens:**
- KlassenDetailScreen
- SchuelerDetailScreen

### 8. Farbcodierung für Fächer
Fächer werden konsistent mit ihrer zugewiesenen Farbe (`Subject.color`) dargestellt.

> *Hinweis: Diese Funktion war bereits implementiert, wurde aber offiziell dokumentiert.*

---

## 🔧 Technische Änderungen

### Neue Dateien
- `lib/shared/widgets/breadcrumb_navigation.dart` – Wiederverwendbares Breadcrumb-Widget
- `lib/features/schueler/widgets/share_student_grades.dart` – Service für Noten-Teilen

### Geänderte Dateien
| Datei | Änderung |
|-------|----------|
| `pubspec.yaml` | Version 0.33.0+35 |
| `lib/main.dart` | Route redirect für `/noten/schueler/:id` |
| `lib/providers/app_providers.dart` | Kürzel-Fallback entfernt |
| `lib/features/noten/widgets/editable_note_cell.dart` | Animation + Tendenz versteckt |
| `lib/features/noten/widgets/student_subject_card.dart` | Tendenz versteckt |
| `lib/features/noten/widgets/noten_table_widget.dart` | Tendenz versteckt |
| `lib/features/schueler/screens/schueler_detail_screen.dart` | Share-Button + Breadcrumb |
| `lib/features/klassen/screens/klassen_detail_screen.dart` | Breadcrumb |
| `lib/features/profile/screens/profile_screen.dart` | Home-Button |
| `lib/features/settings/screens/settings_screen.dart` | Home-Button |
| `lib/features/admin/screens/feature_flags_screen.dart` | Home-Button |

---

## ⬆️ Upgrade-Anleitung

```bash
git pull origin main
flutter pub get
flutter run -d chrome
```

Keine Datenbank-Migration erforderlich.

---

## 🐛 Bekannte Einschränkungen

- Breadcrumbs werden nur in KlassenDetailScreen und SchuelerDetailScreen angezeigt
- Share-Funktion nutzt nur Zwischenablage (kein natives Teilen auf Web)

---

## 📊 Metriken

- **Neue Widgets:** 2 (BreadcrumbNavigation, ShareStudentGrades)
- **Geänderte Dateien:** 12
- **Entfernte Funktionen:** 2 (Kürzel-Fallback, Tendenz-UI)
- **Breaking Changes:** 0

---

**Vollständiger Changelog:** [CHANGELOG.md](./CHANGELOG.md)
