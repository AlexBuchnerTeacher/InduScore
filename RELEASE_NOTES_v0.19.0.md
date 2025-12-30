# Release Notes v0.19.0 - Phase 2.5: UX & Performance

**Release-Datum:** 30. Dezember 2025  
**Issue:** [#69 Phase 2.5: Architecture Cleanup](https://github.com/AlexBuchnerTeacher/InduScore/issues/69)

## Übersicht

Phase 2.5 fokussiert auf **UX-Konsistenz** und **Performance-Grundlagen**:

- ✅ **Einheitliches Error-Handling** mit AppSnackBars
- ✅ **Pagination-Widget** für große Listen
- ✅ **16 neue Tests** (269 gesamt)

## Neue Features

### AppSnackBars - Einheitliches Feedback (F-018)

Neues Utility für konsistente Benutzer-Benachrichtigungen:

```dart
// Erfolg (grün)
AppSnackBars.showSuccess(context, 'Gespeichert!');

// Fehler (rot)
AppSnackBars.showError(context, 'Speichern fehlgeschlagen', error: e);

// Warnung (orange)
AppSnackBars.showWarning(context, 'Ungespeicherte Änderungen');

// Info (blau)
AppSnackBars.showInfo(context, 'Neue Version verfügbar');
```

**Features:**
- Einheitliches Design nach RBS-Styleguide
- Icons für visuelle Unterscheidung
- Floating SnackBars mit abgerundeten Ecken
- Undo-Action Support

### PaginatedFirestoreList - Lazy Loading (F-009)

Generisches Widget für paginierte Firestore-Listen:

```dart
PaginatedFirestoreList<Student>(
  query: firestore.collection('students').orderBy('lastName'),
  fromFirestore: Student.fromFirestore,
  itemBuilder: (student) => StudentTile(student),
  pageSize: 25,
  autoLoadOnScroll: true,
)
```

**Features:**
- Initiales Laden mit Limit (Default: 25)
- "Mehr laden" Button oder Infinite Scroll
- Error-States mit Retry
- Pull-to-Refresh
- Leerer-State Widget

## Migrierte Screens

| Screen | SnackBars migriert |
|--------|-------------------|
| faecher_screen.dart | 4 |
| schueler_screen.dart | 4 |
| settings_screen.dart | 4 |

## Statistik

- **269 Tests** gesamt (+16 seit v0.18.0)
- **2 neue Widgets** in lib/shared/widgets/
- **-42 Zeilen** durch SnackBar-Konsolidierung

## Verschoben auf Phase 3 (v1.0.0)

- **F-016**: Migration screens → features (>16h Aufwand)

## Upgrade-Anleitung

1. **Code aktualisieren:**
   ```bash
   git pull origin main
   flutter pub get
   ```

2. **Tests ausführen:**
   ```bash
   flutter test
   ```

## Kompatibilität

- Keine Breaking Changes
- Alle 269 Tests bestanden
- Flutter 3.x kompatibel

---

**Vollständiges Changelog:** [CHANGELOG.md](CHANGELOG.md)  
**Issue #69:** [Phase 2.5: Architecture Cleanup](https://github.com/AlexBuchnerTeacher/InduScore/issues/69)
