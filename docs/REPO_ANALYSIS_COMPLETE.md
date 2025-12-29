# InduScore - Vollständige Repository-Analyse & Verbesserungsplan
**Datum:** 2025-12-29  
**Analyst:** GitHub Copilot Agent Mode  
**Version:** InduScore 0.16.0

---

## A) EXECUTIVE SUMMARY

### Top-10 Findings (Priorisiert nach Business Impact)

1. **🔴 KRITISCH: Code-Size-Regeln werden massiv verletzt**
   - **Fundstelle:** `lib/screens/klassen_screen.dart` (1268 LOC), `lib/features/noten/widgets/noten_matrix_view.dart` (1137 LOC), `lib/screens/csv_import_screen.dart` (1094 LOC)
   - **Eigene Regel:** CODING_GUIDELINES.md definiert 300 LOC für UI, 300 LOC für Logic, 150 LOC für Widgets
   - **Impact:** 6 Dateien übersch reiten 800 LOC (267-423% über Limit)
   - **Quick Win:** Widget-Extraktion in klassen_screen.dart → 3-4 eigene Dateien

2. **🟡 MEDIUM: CODING_GUIDELINES.md extrem unvollständig**
   - **Fundstelle:** CODING_GUIDELINES.md (33 Zeilen, keine konkreten Beispiele)
   - **Fehlt:** Naming Conventions, State Management Rules, Error Handling Policy, Testing Standards, Security Guidelines
   - **Impact:** Keine Enforcement-Mechanismen, inkonsistente Umsetzung
   - **Quick Win:** Template aus bestehendem Code ableiten + in CI integrieren

3. **🟡 MEDIUM: Fehlende Architektur-Dokumentation**
   - **Fundstelle:** Kein `/docs/ARCHITECTURE.md`, kein ADR-Folder
   - **Impact:** Neue Entwickler verstehen Datenfluss/Layering nicht
   - **Quick Win:** Architecture Map + Datenfluss-Diagramm erstellen

4. **🟡 MEDIUM: Test-Strategie undokumentiert**
   - **Fundstelle:** Keine `/docs/TESTING_STRATEGY.md`
   - **Aktuell:** 16 Test-Dateien (~3k LOC), 51.71% Coverage (laut README v0.13.4)
   - **Fehlt:** Testpyramide, Mocking-Policy, Golden Tests, Integration Tests
   - **Quick Win:** Bestehende Test-Patterns dokumentieren

5. **🟢 LOW: analysis_options.yaml nutzt nur Basis-Lints**
   - **Fundstelle:** analysis_options.yaml:10 (`include: package:flutter_lints/flutter.yaml`)
   - **Fehlt:** Custom Lints (prefer_const, avoid_dynamic_calls, etc.)
   - **Impact:** Code-Qualität könnte durch strikte Lints verbessert werden
   - **Quick Win:** Strict-Lints aktivieren + CI-Check

6. **🟢 LOW: 56x SnackBar-Pattern wiederholt**
   - **Fundstelle:** 56 Vorkommen von `ScaffoldMessenger.of(context).showSnackBar`
   - **Impact:** Boilerplate-Code, keine zentrale Fehlerbehandlung
   - **Quick Win:** Helper-Methode `showRBSSnackBar()` in rbs_components.dart

7. **🟢 LOW: Nur 9 copyWith Implementierungen (bei 13 Models)**
   - **Fundstelle:** lib/models/* (8 Models mit toFirestore/fromFirestore, aber nur 9 copyWith)
   - **Fehlt:** freezed oder json_serializable Code-Generation
   - **Impact:** Manuelle Boilerplate-Code, Fehlerrisiko
   - **Quick Win:** freezed evaluieren (Breaking Change) ODER copyWith vervollständigen

8. **🟡 MEDIUM: Fehlende Dependency Audit**
   - **Fundstelle:** pubspec.yaml (15 Produktions-Dependencies)
   - **Risiko:** Veraltete Packages, Security-Lücken
   - **Fehlt:** Regelmäßiges `flutter pub outdated`, Dependabot, Security Audit
   - **Quick Win:** CI-Job für `dart pub outdated`

9. **🟢 LOW: Keine Pre-Commit Hooks**
   - **Fundstelle:** Kein `.git/hooks/pre-commit`, kein `husky`-equivalent
   - **Fehlt:** Auto-Format, Lint-Check vor Commit
   - **Quick Win:** `melos` oder `lefthook` Setup

10. **🟢 LOW: Fehlende Error Boundary / Global Error Handler**
    - **Fundstelle:** main.dart hat kein `FlutterError.onError` override
    - **Impact:** Crashes werden nicht zentral geloggt
    - **Quick Win:** Firebase Crashlytics Integration

---

## B) REPO SCORECARD (0-10 Skala)

### 1. **Architektur: 7/10**

**Begründung:**
- ✅ **Stärken:**
  - Feature-based Struktur vorhanden (`lib/features/`, `lib/screens/`, `lib/services/`, `lib/models/`)
  - Klare Layering: UI → Provider (Riverpod) → Service → Firestore
  - Keine direkten Firestore-Aufrufe außerhalb von `firestore_service.dart` (0 Treffer)
  - Permission Guards sauber in `permissions_providers.dart` zentralisiert
- ❌ **Schwächen:**
  - Fehlende Dokumentation (`ARCHITECTURE.md`)
  - Screens mischen UI + Business Logic (klassen_screen.dart: 3 nested StatefulWidgets mit State)
  - Dependency Graph nicht visualisiert

**Fundstellen:**
- Positiv: `lib/services/firestore_service.dart` (829 LOC, aber kapselt alle Firestore-Zugriffe)
- Negativ: `lib/screens/klassen_screen.dart:603-1268` (_ImportPreviewDialog, _MergeDialog inline statt eigene Files)

---

### 2. **Codequalität: 6/10**

**Begründung:**
- ✅ **Stärken:**
  - Hohe const/final Usage (2513 Vorkommen)
  - Kein Dead Code (0 TODO/FIXME/HACK/BUG markers)
  - Nur 10 print/debugPrint Statements (gut controlled)
  - Nur 4 Dateien mit `// ignore:` Lint-Suppressions
  - 125 StatefulWidget/setState Vorkommen (nicht exzessiv für 63 Dateien)
- ❌ **Schwächen:**
  - **6 Dateien mit 800+ LOC** verletzen eigene 300-LOC-Regel massiv
  - Fehlende Code-Generation (freezed/json_serializable), alles manuell
  - 56x duplizierter SnackBar-Code
  - Keine Linter-Regel gegen große Dateien

**Fundstellen:**
- Negativ: `lib/screens/klassen_screen.dart` (1268 LOC = 423% über 300-LOC-Limit)
- Positiv: `lib/models/app_user.dart` (137 LOC, gut strukturiert mit Enums + copyWith)

---

### 3. **Sicherheit: 7/10**

**Begründung:**
- ✅ **Stärken:**
  - Firestore Rules granular definiert (`firestore.rules:1-49`)
  - Admin-only Operations korrekt abgesichert (canManageUsersProvider, canCreateDataProvider)
  - Kein hardcoded Firebase-Config (firebase_options.dart generiert)
  - .gitignore schließt `firebase-admin-key.json` aus
  - Passwort-Änderung mit Re-Auth (`auth_service.dart:76-103`)
- ❌ **Schwächen:**
  - Kein Error-Logging-Policy dokumentiert (potenzielle PII in Logs?)
  - Fehlende Input-Validation-Patterns dokumentiert
  - Keine Secrets-Scanning im CI (z.B. `truffleHog`, `detect-secrets`)
  - Pre-Login Read-Access auf app_users Collection (Kürzel-Lookup) könnte missbraucht werden

**Fundstellen:**
- Positiv: `firestore.rules:8-16` (app_users lesbar für Kürzel-Login, schreibgeschützt für Admins)
- Risiko: `firestore.rules:9` (`allow read: if request.auth == null`) ermöglicht Enumeration aller Kürzel

---

### 4. **Performance: 8/10**

**Begründung:**
- ✅ **Stärken:**
  - Riverpod Provider-Caching nutzt StreamProvider/FutureProvider optimal
  - Firestore Queries haben `.orderBy()` (keine Full-Collection-Scans)
  - Pagination-Ready (perPage-Parameter in Firestore-Queries nicht gesehen, aber Struktur unterstützt es)
  - Keine build()-Methoden-Callbacks in Loops (statische Builder)
- ⚠️ **Unbekannt (ohne Flutter-Lauf):**
  - Rebuild-Hotspots in großen Screens (1268-LOC-File)
  - Firestore Listener Lifecycle (werden Streams in dispose() cancelled?)
  - Image/Asset Optimization
- ❌ **Schwächen:**
  - Keine Firestore Index-Dokumentation (firestore.indexes.json vorhanden, aber nicht kommentiert)

**Fundstellen:**
- Positiv: `lib/providers/app_providers.dart:79-83` (subjectsProvider nutzt `.orderBy('name')`)
- Unbekannt: `lib/features/noten/widgets/noten_matrix_view.dart:78-79` (2 ScrollController, dispose() nicht geprüft)

---

### 5. **Tests: 7/10**

**Begründung:**
- ✅ **Stärken:**
  - 16 Test-Dateien, ~3k LOC Tests (14% Test-zu-Code-Ratio)
  - Coverage 51.71% laut README (v0.13.4)
  - Unit-Tests für Models (grade_test.dart, zeugnisnote_test.dart, beruf_test.dart)
  - Widget-Tests für Profile-Screen (`test/widgets/profile/`)
  - Mockito + build_runner Setup vorhanden
- ❌ **Schwächen:**
  - Keine Integration-Tests (kein `integration_test/` Ordner)
  - Keine Golden-Tests (keine `*.png` in test/)
  - Test-Coverage für große Screens fehlt (klassen_screen.dart, csv_import_screen.dart nicht in test/)
  - Keine CI-Coverage-Threshold (ci.yml:39 `--coverage` läuft, aber kein Fail bei <50%)

**Fundstellen:**
- Positiv: `test/models/zeugnisnote_test.dart` (24 Tests für Rundungslogik)
- Negativ: Keine `test/screens/klassen_screen_test.dart` (kritischster Screen)

---

### 6. **Developer Experience (DX): 6/10**

**Begründung:**
- ✅ **Stärken:**
  - README.md sehr gut (195 Zeilen, Features, Tech-Stack, Setup-Guide)
  - CONTRIBUTING.md vorhanden (Workflow, PR-Template)
  - CI/CD Workflows funktionieren (.github/workflows/ci.yml, release.yml)
  - .github/copilot-instructions.md für AI-Assistenz
  - Versionierung über package_info_plus (Single Source of Truth)
- ❌ **Schwächen:**
  - CODING_GUIDELINES.md minimal (33 Zeilen, keine Beispiele)
  - Fehlende ARCHITECTURE.md, TESTING_STRATEGY.md
  - Keine Pre-Commit Hooks
  - Keine lokale Entwicklungs-Doku (Firebase Emulator Setup?)
  - Issue-Templates vorhanden, aber Issues.json/milestones.json im Repo (sollten in .gitignore)

**Fundstellen:**
- Positiv: `README.md:124-173` (Detaillierte Setup-Anleitung mit Firestore Rules)
- Negativ: `CODING_GUIDELINES.md:1-33` (Nur 6 Regeln, keine Enforcement)

---

### 7. **Dokumentation: 6/10**

**Begründung:**
- ✅ **Stärken:**
  - README.md ausführlich mit Roadmap + Features
  - CHANGELOG.md gepflegt (Keep a Changelog Format)
  - Inline-Dokumentation in Models gut (z.B. `app_user.dart:1-8` Docstring)
  - RBS Styleguide dokumentiert (`lib/core/theme/rbs_theme.dart:4-8` Header-Comment)
- ❌ **Schwächen:**
  - Fehlende High-Level Docs (ARCHITECTURE.md, TESTING_STRATEGY.md)
  - Keine API-Dokumentation (dart doc nicht in CI)
  - Docstrings in Screens/Services inkonsistent
  - Keine Deployment-Doku (Firebase Hosting Setup?)

**Fundstellen:**
- Positiv: `README.md:87-122` (Projektstruktur-Diagramm)
- Negativ: Keine `docs/DEPLOYMENT.md`

---

## **GESAMT-SCORE: 6.7/10** (Durchschnitt)

**Kategorisierung:** 🟡 **GOOD** (6-7), aber Potential für **EXCELLENT** (8+) mit fokussierten Verbesserungen.

---

## C) FINDINGS BACKLOG (Priorisierte Tabelle)

| ID | Kategorie | Impact | Effort | Beschreibung | Fundstelle | Empfehlung | Akzeptanzkriterien | Test/Verification |
|----|-----------|--------|--------|--------------|------------|------------|-------------------|-------------------|
| F01 | Code-Qualität | **H** | **M** | 6 Dateien übersteigen 800 LOC (eigene 300-LOC-Regel) | `klassen_screen.dart:1-1268`, `noten_matrix_view.dart:1-1137` | Widget-Extraktion: `_ImportPreviewDialog` → eigene Datei, `_MergeDialog` → eigene Datei | Alle Screens <500 LOC, Widgets <150 LOC | dart analyze, Manual Review |
| F02 | Dokumentation | **H** | **S** | CODING_GUIDELINES.md unvollständig (33 Zeilen) | `CODING_GUIDELINES.md:1-33` | Erweitern auf 300+ Zeilen mit Beispielen aus Codebase | Guidelines Kapitel 2.2 (siehe unten) vollständig | Peer Review |
| F03 | Dokumentation | **M** | **S** | Fehlende ARCHITECTURE.md | Keine Datei | Erstellen mit: Datenfluss-Diagramm, Dependency Graph, Layering-Regeln | Dokument vorhanden, reviewt | Stakeholder Approval |
| F04 | Dokumentation | **M** | **S** | Fehlende TESTING_STRATEGY.md | Keine Datei | Dokumentieren: Testpyramide, Mocking-Strategie, Coverage-Ziele | Dokument vorhanden, CI-Referenz | CI Integration |
| F05 | Code-Qualität | **M** | **S** | 56x duplizierter SnackBar-Code | Grep: 56 Treffer | Helper `RBSSnackBar.show(context, message, type)` in rbs_components.dart | SnackBar-Aufrufe <10 in Codebase | Grep-Check |
| F06 | Tests | **H** | **L** | Keine Tests für kritische Screens (klassen_screen.dart) | Keine `klassen_screen_test.dart` | Widget-Tests für KlassenScreen hinzufügen (PDF-Import, Create/Edit/Delete) | >80% Coverage für klassen_screen.dart | `flutter test --coverage` |
| F07 | CI/CD | **M** | **S** | Kein Coverage-Threshold im CI | `.github/workflows/ci.yml:39` | Coverage-Check mit `very_good_coverage` (min. 50%) | CI fails bei <50% Coverage | CI Run |
| F08 | Linting | **L** | **S** | Nur flutter_lints Basis, keine Custom Lints | `analysis_options.yaml:10` | Aktivieren: `prefer_const_constructors`, `avoid_dynamic_calls`, `avoid_print` | dart analyze warnings <10 | dart analyze |
| F09 | Security | **M** | **M** | Kein centrales Error-Logging (potenzielle PII in Logs) | `main.dart` (kein FlutterError.onError) | Policy: Kein Logging von Namen/Emails, nur IDs. Firebase Crashlytics | LOGGING_POLICY.md erstellt | Code Review |
| F10 | Security | **M** | **S** | Pre-Login Read-Access auf app_users (Kürzel-Enumeration) | `firestore.rules:9` | Rate-Limiting oder Security-Audit dokumentieren | Security Review abgeschlossen | Firestore Monitoring |
| F11 | DX | **L** | **S** | Keine Pre-Commit Hooks | Kein `.git/hooks/` | `lefthook` Setup: Auto-Format, Lint-Check | Pre-Commit Hook aktiv | Local Test |
| F12 | Dependencies | **M** | **S** | Kein automatisches Dependency-Audit | Keine Dependabot-Config | GitHub Dependabot aktivieren + CI-Job `flutter pub outdated` | Dependabot PRs aktiv | GitHub Settings |
| F13 | Code-Qualität | **L** | **M** | Keine Code-Generation (freezed/json_serializable) | Manuelle copyWith/toFirestore | Evaluieren: freezed für Models (Breaking Change) ODER manuelle copyWith vervollständigen | Entscheidung dokumentiert | ADR |
| F14 | Tests | **M** | **M** | Keine Integration-Tests | Kein `integration_test/` | Integration-Tests für kritische Flows (Login → Dashboard → Noteneingabe) | integration_test/ Ordner mit 3+ Tests | flutter drive |
| F15 | Tests | **L** | **L** | Keine Golden-Tests für UI-Regression | Keine `*.png` in test/ | Golden-Tests für kritische Widgets (NotenMatrixView, RBSDrawer) | >5 Golden-Tests | flutter test --update-goldens |
| F16 | Dokumentation | **L** | **S** | Fehlende DEPLOYMENT.md | Keine Datei | Deployment-Guide: Firebase Hosting, Firestore Rules Deploy | Dokument vorhanden | Stakeholder Review |
| F17 | CI/CD | **L** | **S** | Keine dart doc Generation im CI | `.github/workflows/ci.yml` | CI-Step: `dart doc` + GitHub Pages Deploy | Docs auf GitHub Pages | Browser Check |
| F18 | Performance | **M** | **M** | Firestore Indexes nicht dokumentiert | `firestore.indexes.json` | Kommentare in firestore.indexes.json: Warum jeder Index existiert | Alle Indexes kommentiert | Code Review |
| F19 | DX | **L** | **S** | issues.json/milestones.json im Repo committed | Root-Verzeichnis | In .gitignore eintragen | Files nicht in Git | git status |
| F20 | Accessibility | **M** | **L** | Kein a11y Audit durchgeführt | Unbekannt (kein Flutter-Lauf) | Semantics-Audit: Screen-Reader-Tests, Keyboard-Navigation | a11y-Checklist abgearbeitet | Manual Testing |

**Legende:**
- **Impact:** H (High) = Business-kritisch, M (Medium) = Wichtig, L (Low) = Nice-to-have
- **Effort:** S (Small) = <1 Tag, M (Medium) = 1-3 Tage, L (Large) = >3 Tage

---

## D) CODING GUIDELINES (Erweitert & Repo-Spezifisch)

### Vorbemerkung
Die bestehende `CODING_GUIDELINES.md` enthält wichtige Grundprinzipien, ist aber mit 33 Zeilen zu knapp für ein Projekt dieser Größe (21k LOC). Diese erweiterten Guidelines basieren auf **tatsächlichen Code-Patterns aus dem InduScore-Repository** und dienen als verbindlicher Standard.

---

### 1. **Naming Conventions**

#### 1.1 Dateien & Ordner
**Abgeleitet aus Codebase:**
- Dateinamen: `snake_case` (z.B. `noten_eingabe_screen.dart`, `firestore_service.dart`)
- Ordner: `snake_case` (z.B. `lib/features/noten/`, `lib/widgets/profile/`)
- Screen-Dateien: `*_screen.dart` (z.B. `klassen_screen.dart`)
- Service-Dateien: `*_service.dart` (z.B. `auth_service.dart`)
- Model-Dateien: Singular (z.B. `student.dart`, `klasse.dart`, nicht `students.dart`)

**Beispiele aus Repo:**
✅ KORREKT: `lib/screens/noten_eingabe_screen.dart`  
✅ KORREKT: `lib/services/firestore_service.dart`  
✅ KORREKT: `lib/features/noten/widgets/editable_note_cell.dart`  
❌ FALSCH: `NotenEingabeScreen.dart` (PascalCase)  
❌ FALSCH: `students.dart` (Plural für Model)

#### 1.2 Classes & Widgets
**Abgeleitet aus Codebase:**
- Classes: `PascalCase` (z.B. `KlassenScreen`, `FirestoreService`)
- Widgets: `PascalCase` + Widget-Suffix (z.B. `NotenMatrixView`, `RBSDrawer`)
- Private Classes: `_PascalCase` (z.B. `_KlassenScreenState`, `_ImportPreviewDialog`)
- Enums: `PascalCase` (z.B. `UserRole`, `StudentStatus`, `MatrixViewMode`)

**Beispiele aus Repo:**
```dart
// ✅ KORREKT (aus lib/models/app_user.dart:7-14)
enum UserRole {
  admin('Admin'),
  lehrer('Lehrer'),
  ausbilder('Ausbilder'),
  schueler('Schüler');
}

// ✅ KORREKT (aus lib/screens/klassen_screen.dart:17-22)
class KlassenScreen extends ConsumerStatefulWidget {
  const KlassenScreen({super.key});
}

// ✅ KORREKT (aus lib/features/noten/widgets/noten_matrix_view.dart:15-25)
enum MatrixViewMode {
  byKlasse,
  bySchueler,
  byLN,
}
```

#### 1.3 Variables & Methods
**Abgeleitet aus Codebase:**
- Variables: `camelCase` (z.B. `klasseId`, `currentUser`, `isLoggedIn`)
- Private Fields: `_camelCase` (z.B. `_students`, `_db`, `_auth`)
- Constants: `lowerCamelCase` (z.B. `headlineFont`, `dynamicRed`) ODER `SCREAMING_SNAKE_CASE` für globale Konstanten
- Methods: `camelCase` (z.B. `getStudent()`, `showKlasseDialog()`, `handlePdfImport()`)

**Beispiele aus Repo:**
```dart
// ✅ KORREKT (aus lib/services/firestore_service.dart:29-37)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _subjects => _db.collection('subjects');
}

// ✅ KORREKT (aus lib/models/student.dart:64-68)
class Student {
  String get displayName => '$firstName $lastName';
  String get sortKey => '${lastName.toLowerCase()}, ${firstName.toLowerCase()}';
  bool get isAktiv => status == StudentStatus.aktiv;
}
```

#### 1.4 Provider-Naming (Riverpod-spezifisch)
**Abgeleitet aus Codebase:**
- Provider: `*Provider` Suffix (z.B. `studentsProvider`, `currentUserProvider`)
- StreamProvider: `*Provider` (z.B. `authStateProvider`, `gradesProvider`)
- FutureProvider: `*Provider` (z.B. `appVersionProvider`, `studentProvider`)
- StateProvider: `*Provider` (z.B. `zeitgruppenFilterProvider`)
- Family-Provider: `*Provider` (z.B. `studentsByKlasseProvider`, `gradesByLeistungsnachweisProvider`)

**Beispiele aus Repo:**
```dart
// ✅ KORREKT (aus lib/providers/app_providers.dart:56-59)
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudents();
});

// ✅ KORREKT (aus lib/providers/app_providers.dart:68-74)
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>((
  ref,
  klasseId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudentsByKlasse(klasseId);
});
```

---

### 2. **Architekturregeln**

#### 2.1 Layering (Strikt!)
**Fundstelle:** Konsistent umgesetzt in gesamter Codebase

```
┌─────────────────────────────────────┐
│  UI Layer (Screens/Widgets)        │  ← Nur Darstellung, kein Business Logic
│  lib/screens/, lib/features/       │  ← ref.watch(provider), onTap → Service-Call
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  State Layer (Riverpod Providers)  │  ← Zustandsverwaltung, Stream-Transformation
│  lib/providers/                    │  ← ref.watch(firestoreServiceProvider)
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  Service Layer                     │  ← Business Logic, Aggregation, Firestore-Zugriffe
│  lib/services/                     │  ← KEINE UI-Imports (kein BuildContext)
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  Data Layer (Firestore)            │  ← Nur via Service-Layer zugänglich
│  Firebase Cloud Firestore          │  ← KEINE direkten Zugriffe aus UI
└─────────────────────────────────────┘
```

**Regeln:**
1. **UI → Provider → Service → Firestore** (niemals Layer überspringen)
2. **Services dürfen KEIN `BuildContext` importieren** (reine Dart-Logik)
3. **Widgets dürfen KEINE Firestore-Queries direkt ausführen** (nur via Provider)
4. **Provider sind readonly** (UI schreibt via Service-Methoden)

**Positive Beispiele aus Repo:**
```dart
// ✅ KORREKT: UI nutzt Provider (aus lib/screens/home_screen.dart)
final klassenAsync = ref.watch(klassenProvider);
final filtered = ref.watch(filteredKlassenProvider);

// ✅ KORREKT: Service hat KEINE UI-Imports (aus lib/services/firestore_service.dart:1-9)
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/student.dart';
// KEIN import 'package:flutter/material.dart' !

// ✅ KORREKT: Kein direkter Firestore-Zugriff außerhalb firestore_service.dart
// Grep-Check: 0 Treffer für "FirebaseFirestore.instance" außerhalb firestore_service.dart
```

#### 2.2 Feature-Struktur
**Fundstelle:** `lib/features/` teilweise umgesetzt, aber inkonsistent

**Standard (SOLL):**
```
lib/features/<feature_name>/
├── <feature_name>_screen.dart     # Haupt-Screen
├── widgets/                       # Feature-spezifische Widgets
│   └── <widget_name>.dart
├── logic/                         # Feature-spezifische Business Logic (optional)
│   └── <logic_name>.dart
└── models/                        # Feature-spezifische Models (optional)
    └── <model_name>.dart
```

**IST-Zustand (Beispiele):**
```
lib/features/noten/
├── noten_matrix_logic.dart        ✅ Logik separiert
├── noten_matrix_controller.dart   ✅ Controller separiert
└── widgets/
    ├── noten_matrix_view.dart     ✅ View separiert
    ├── editable_note_cell.dart    ✅ Widget separiert
    └── ...

lib/features/dashboard/
└── widgets/
    ├── nachschreiber_section.dart ✅ Widgets separiert
    └── ...

lib/screens/
├── klassen_screen.dart            ❌ 1268 LOC, sollte in features/klassen/ sein
└── ...
```

**Empfehlung:** Große Screens (>500 LOC) nach `features/` migrieren

---

### 3. **State Management Rules (Riverpod)**

#### 3.1 Provider-Typen (Wann was nutzen?)
**Abgeleitet aus lib/providers/app_providers.dart:**

| Provider-Typ | Wann nutzen? | Beispiel aus Repo |
|--------------|-------------|-------------------|
| `Provider<T>` | Singleton-Services, Computed Values | `firestoreServiceProvider`, `isLoggedInProvider` |
| `StreamProvider<T>` | Firestore Realtime-Daten | `studentsProvider`, `gradesProvider` |
| `FutureProvider<T>` | One-Time Async Load | `appVersionProvider`, `studentProvider` |
| `StateProvider<T>` | UI-State (Filter, Selection) | `zeitgruppenFilterProvider` |
| `*.family<T, Arg>` | Provider mit Parameter | `studentsByKlasseProvider`, `gradesByLeistungsnachweisProvider` |

**Beispiele aus Repo:**
```dart
// ✅ Provider für Singleton-Service (lib/providers/app_providers.dart:49-51)
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// ✅ StreamProvider für Realtime-Daten (lib/providers/app_providers.dart:56-59)
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudents();
});

// ✅ FutureProvider mit family für parametrisierte Abfrage (lib/providers/app_providers.dart:62-65)
final studentProvider = FutureProvider.family<Student, String>((ref, id) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getStudent(id);
});
```

#### 3.2 ref.watch vs ref.read vs ref.listen
**Regel:**
- `ref.watch()`: In `build()` für reaktive Updates
- `ref.read()`: In Event-Handlern (onPressed, onTap) für One-Time Read
- `ref.listen()`: Für Side-Effects (Navigation, SnackBar)

**Beispiele aus Repo:**
```dart
// ✅ ref.watch in build() (aus lib/screens/home_screen.dart)
@override
Widget build(BuildContext context) {
  final klassenAsync = ref.watch(klassenProvider);  // ← Reaktiv!
  final currentUser = ref.watch(currentAppUserProvider);
}

// ✅ ref.read in Event-Handler (aus lib/providers/app_providers.dart:65)
final studentProvider = FutureProvider.family<Student, String>((ref, id) async {
  final firestoreService = ref.read(firestoreServiceProvider);  // ← One-Time!
  return firestoreService.getStudent(id);
});
```

#### 3.3 AsyncValue Pattern
**Regel:** Nutze `.when()` oder `.maybeWhen()` für AsyncValue (niemals `.value` direkt)

**Beispiele aus Repo:**
```dart
// ✅ KORREKT: .maybeWhen() mit Error-Handling (aus lib/providers/permissions_providers.dart:12-15)
return currentUser.maybeWhen(
  data: (user) => user?.rolle == UserRole.admin,
  orElse: () => false,
);

// ❌ FALSCH (potenzielle Exception):
return currentUser.value?.rolle == UserRole.admin;  // .value kann null sein!
```

---

### 4. **Error Handling**

#### 4.1 Exception vs Result Pattern
**IST-Zustand:** Repo nutzt **Exceptions** (72 Vorkommen von "throw\|catch\|Exception")

**Beispiele aus Repo:**
```dart
// ✅ Current Pattern: Exceptions (aus lib/services/firestore_service.dart:52-55)
Future<Student> getStudent(String id) async {
  final doc = await _students.doc(id).get();
  if (!doc.exists) throw Exception('Student nicht gefunden');
  return Student.fromFirestore(doc);
}

// ✅ Exception-Handling mit deutschen Messages (aus lib/services/auth_service.dart:106-127)
String _handleAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'Kein Benutzer mit dieser E-Mail gefunden.';
    case 'wrong-password':
      return 'Falsches Passwort.';
    // ...
  }
}
```

**Regel:**
- **Exceptions für Fehler** (nicht für Flow-Control)
- **Deutsche User-facing Messages** in UI-Layer
- **Technische Messages in Logs** (falls Crashlytics kommt)

#### 4.2 User-Feedback Pattern
**IST-Zustand:** 56x SnackBar-Duplikate

**Current Pattern (dupliziert):**
```dart
// ❌ DUPLIZIERT (56x im Repo):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Erfolgreich gespeichert')),
);
```

**SOLL (Helper-Methode):**
```dart
// ✅ Vorschlag: lib/core/widgets/rbs_components.dart
class RBSSnackBar {
  static void show(BuildContext context, String message, {SnackBarType type = SnackBarType.info}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == SnackBarType.error ? RBSColors.error : RBSColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum SnackBarType { success, error, info, warning }
```

---

### 5. **Async & Streams**

#### 5.1 Stream Lifecycle
**Regel:** Alle StreamControllers/Subscriptions in `dispose()` canceln

**Beispiele aus Repo:**
```dart
// ✅ KORREKT: Stream-Subscription mit dispose() (aus lib/main.dart:42-54)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();  // ← Wichtig!
    super.dispose();
  }
}
```

**TODO:** Verifizieren dass alle ScrollController in dispose() disposed werden (z.B. `noten_matrix_view.dart:78-79`)

#### 5.2 Firestore Streams
**Regel:** Nutze StreamProvider statt manuelle Subscriptions

**Beispiele aus Repo:**
```dart
// ✅ KORREKT: StreamProvider (aus lib/providers/app_providers.dart:56-59)
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudents();  // ← Riverpod managed Lifecycle!
});

// ❌ FALSCH (manuelle Subscription):
StreamSubscription? _sub;
void initState() {
  _sub = FirebaseFirestore.instance.collection('students').snapshots().listen(...);
}
// → Fehleranfällig, Riverpod ist besser!
```

---

