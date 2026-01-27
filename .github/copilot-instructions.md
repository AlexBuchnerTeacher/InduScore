# InduScore - KI-Coding-Agent Anleitung

## Projektübersicht
**InduScore** ist eine Flutter-Webanwendung zur Notenverwaltung an Berufsschulen in München. Deployment ausschließlich als Web-App via Firebase Hosting.

## Tech Stack
- **Framework**: Flutter 3.38.2 (nur Web, kein Mobile)
- **Sprache**: Dart 3.10.0
- **State Management**: Riverpod 3.1.0 (StreamProvider, StateProvider)
- **Backend**: Firebase (Firestore für Daten, Auth mit Email/Passwort)
- **Routing**: go_router 17.0.1 mit eigenem `GoRouterRefreshStream` (siehe `lib/main.dart`)
- **UI**: Material Design 3 + RBS Styleguide (München Branding)
- **PDF**: syncfusion_flutter_pdf 32.1.20
- **Testing**: mockito 5.4.4, 386+ Tests mit >50% Coverage

## Architektur: Strikte 4-Schichten-Trennung

**KRITISCH**: Niemals Schichten überspringen! Fluss muss sein: `UI → Provider → Service → Firestore`

```
┌─────────────────────────────────┐
│ UI-Schicht                      │  ← NUR UI-Logik, ref.watch(provider)
│ lib/features/*/screens/         │  ← KEINE direkten Firestore-Aufrufe
│ lib/features/*/widgets/         │  ← KEINE Business-Logik
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ State-Schicht                   │  ← Stream-Provider, State Management
│ lib/providers/                  │  ← Stream-Transformation, Permission Guards
│   app_providers.dart            │  ← KEINE Business-Logik (an Services delegieren)
│   permissions_providers.dart    │  ← 23 Feature-Flags für granulare Zugriffskontrolle
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ Service-Schicht                 │  ← Business-Logik, Firestore CRUD
│ lib/services/                   │  ← KEIN BuildContext importieren! (testbares Dart)
│   firestore_service.dart        │  ← Constructor DI: FirestoreService({FirebaseFirestore? firestore})
│   pdf_export_service.dart       │  ← Notenberechnungen, CSV/PDF/NOI Export
│   noi_export_service.dart       │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ Daten-Schicht                   │  ← Firebase Firestore (NoSQL)
│ Firebase Cloud Firestore        │  ← Realtime Listener via .snapshots()
│ firestore.rules                 │  ← Rollenbasierte Sicherheit (admin, lehrer, ausbilder, schueler)
└─────────────────────────────────┘
```

**Beispiele für Verstöße die zu VERMEIDEN sind:**
```dart
// ❌ FALSCH: Direkter Firestore-Zugriff im Widget
FirebaseFirestore.instance.collection('students').get();

// ❌ FALSCH: BuildContext im Service
class FirestoreService {
  void showError(BuildContext context, String msg) {} // VERBOTEN!
}

// ✅ RICHTIG: Widget → Provider → Service
final students = ref.watch(studentsProvider); // Widget
// Provider delegiert an Service
final service = ref.watch(firestoreServiceProvider);
return service.getStudents(); // Service verarbeitet Firestore
```

## Feature-basierte Struktur

**Aktuelle Migration**: Von `lib/screens/` → `lib/features/*/` (siehe [REFACTORING_ROADMAP.md](../docs/REFACTORING_ROADMAP.md))

```
lib/features/<domain>/
├── screens/           # Haupt-Screens (z.B. klassen_screen.dart)
├── widgets/           # Feature-spezifische Widgets
└── (logic/)           # Optionale Business-Logik falls komplex
```

**Wichtige Features:**
- **noten**: `NotenMatrixView` (universelles Matrix-Widget, 3 Modi: byKlasse/bySchueler/byLN)
- **klassen/schueler/faecher**: CRUD-Screens mit Inline-Editing
- **export**: NOI XML/CSV Export für Zeugnisnoten (Bayerisches Schulsystem)
- **import**: CSV-Import mit Duplikat-Erkennung + PDF-Merge mit Schüler-Matching
- **admin**: Feature-Flags Verwaltung (23 Flags für granulare Berechtigungen)

## Kritische Patterns & Konventionen

### 1. Namenskonventionen (siehe `CODING_GUIDELINES.md`)
- **Dateien/Ordner**: `snake_case` (z.B. `noten_eingabe_screen.dart`)
- **Klassen/Widgets**: `PascalCase` (z.B. `NotenMatrixView`)
- **Variablen/Methoden**: `camelCase` (z.B. `getStudent(String id)`)
- **Provider**: IMMER `*Provider` Suffix (z.B. `studentsProvider`, `zeitgruppenFilterProvider`)

### 2. Riverpod-Patterns
```dart
// Service Singleton
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Firestore Stream
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents(); // Gibt Stream<List<Student>> zurück
});

// Family Provider (parametrisiert)
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>((ref, klasseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudentsByKlasse(klasseId);
});

// UI State
final zeitgruppenFilterProvider = StateProvider<ZeitGruppenFilter>((ref) => ZeitGruppenFilter.alle);
```

### 3. NotenMatrixView: Universelles Matrix-Widget
**Komplexeste UI-Komponente** - 3 Anzeigemodi (siehe [noten_matrix_view.dart](../lib/features/noten/widgets/noten_matrix_view.dart)):
- `byKlasse`: Schüler (Zeilen) × Leistungsnachweise gruppiert nach Fach (Spalten)
- `bySchueler`: LNs nach Fach (Zeilen) × Note/Datum (Spalten) - einzelner Schüler
- `byLN`: Schüler (Zeilen) × Note/Tendenz (Spalten) - einzelner LN

Verwendet spezialisierte Widgets: `KlassenMatrixWidget`, `SchuelerMatrixWidget`, `LNMatrixWidget`

### 4. Lehrerkürzel
**WICHTIG**: Kürzel werden NUR vom Admin vergeben und sind fest. Keine automatische Generierung aus Email oder Name!

### 5. Permission Guards (23 Feature-Flags)
Provider in [permissions_providers.dart](../lib/providers/permissions_providers.dart) und [feature_flags_provider.dart](../lib/providers/feature_flags_provider.dart):
```dart
// Rollenbasiert
final canManageUsersProvider = Provider<bool>((ref) => ref.watch(isAdminProvider));

// Feature-basiert (granulare Kontrolle)
final canCreateSchuelerProvider = Provider<bool>((ref) {
  return ref.watch(effectiveFeatureFlagsProvider).canCreateSchueler;
});

// Verwendung in der UI
final canCreate = ref.watch(canCreateKlassenProvider);
if (!canCreate) return SizedBox.shrink(); // Button verstecken
```

## Entwicklungs-Workflow

### Ausführen & Testen
```powershell
flutter run -d chrome                    # Dev Server (Hot Reload)
flutter build web                        # Production Build
flutter test                             # Unit + Widget Tests (386+ Tests)
flutter test --coverage                  # Coverage-Report generieren
```

### Häufige Aufgaben
- **Deployment**: `firebase deploy` (erfordert Firebase CLI, Ziel: `induscore-71af0.web.app`)
- **Dart formatieren**: `dart_format` Tool nutzen, NIE manuell formatieren
- **Alle Issues fixen**: `dart_fix` Tool für automatische Fixes
- **Admin-User erstellen**: `node scripts/create_admin.js` (erfordert Firebase Admin SDK)

### Test-Strategie (siehe [TESTING_STRATEGY.md](../docs/TESTING_STRATEGY.md))
- **70% Unit-Tests**: Models, Services, Business-Logik (z.B. `grade_test.dart`, `zeugnisnote_test.dart`)
- **20% Widget-Tests**: UI-Komponenten (z.B. `app_snack_bars_test.dart`)
- **10% Integration-Tests**: User-Flows (geplant, noch nicht implementiert)
- **Mocking**: `mockito` + `build_runner` für Service-Mocks verwenden

### Sicherheitsregeln
[firestore.rules](../firestore.rules) implementiert rollenbasierte Zugriffskontrolle:
- **admin**: Voller CRUD-Zugriff auf alle Collections
- **lehrer**: Lesen: alles, Schreiben: eigene Klassen/Schüler
- **ausbilder/schueler**: Nur Lesen (eingeschränkt durch favoriteKlassenIds)
- **Field-Level Security**: User können `rolle`, `status`, `email`, `kuerzel` nicht ändern

## Wichtige Dateien

| Datei | Zweck |
|-------|-------|
| [lib/main.dart](../lib/main.dart) | App-Entry, GoRouter mit `GoRouterRefreshStream` |
| [lib/providers/app_providers.dart](../lib/providers/app_providers.dart) | Alle globalen Riverpod-Provider (students, klassen, subjects, grades) |
| [lib/services/firestore_service.dart](../lib/services/firestore_service.dart) | Haupt-Firestore-CRUD (850 LOC, Constructor DI für Testbarkeit) |
| [lib/features/noten/widgets/noten_matrix_view.dart](../lib/features/noten/widgets/noten_matrix_view.dart) | Universelles Matrix-Widget (refactored von 1056 → 102 LOC) |
| [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) | Vollständige Architektur-Details, Datenfluss-Diagramme |
| [CODING_GUIDELINES.md](../CODING_GUIDELINES.md) | Namenskonventionen, Layering, Riverpod-Patterns (655 LOC) |
| [firestore.rules](../firestore.rules) | Sicherheitsregeln (rollenbasiert + field-level) |

## Häufige Stolperfallen

1. **Kein Mobile**: Nur Flutter Web-Projekt, keinen mobile-spezifischen Code hinzufügen
2. **GoRouter Refresh**: Eigenen `GoRouterRefreshStream` verwenden, nicht den veralteten aus go_router <10
3. **Services = Reines Dart**: Kein `import 'package:flutter/material.dart'` in Services (Testbarkeit!)
4. **Kürzel**: Werden NUR vom Admin gesetzt, nie automatisch aus Email generieren
5. **Provider-Naming**: Fehlender `Provider`-Suffix bricht Konventions-Suchen
6. **Layer-Verstöße**: Direkte Firestore-Aufrufe in Widgets brechen Testbarkeit und Architektur

## Datenschutz & Logging

Gemäß [LOGGING_POLICY.md](../docs/LOGGING_POLICY.md):
- **NIEMALS** Schülernamen, Lehrernamen oder E-Mails loggen
- Nur IDs für Debugging verwenden
- Firebase Crashlytics für Production Error-Logging
