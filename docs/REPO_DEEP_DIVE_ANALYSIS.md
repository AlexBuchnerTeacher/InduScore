# InduScore - Repo Deep-Dive Analyse

**Version:** 1.0  
**Erstellt:** 2025-12-30  
**Basis:** v0.32.0 (386 Tests, 0 Analyse-Issues)  
**Branch:** `main`  

> **Hinweis:** Dieses Dokument ist reine Analyse- und Planungsdokumentation. 
> Es werden **keine Code-Änderungen** in diesem Ticket umgesetzt.

---

## Inhaltsverzeichnis

1. [Executive Summary](#a-executive-summary)
2. [Repo Scorecard](#b-repo-scorecard)
3. [Architecture Map](#c-architecture-map)
4. [Findings Backlog](#d-findings-backlog)
5. [Coding Guidelines - Repo-spezifisch](#e-coding-guidelines)
6. [Refactoring Plan (3 Phasen)](#f-refactoring-plan)
7. [Copilot Improvement Prompt](#g-copilot-improvement-prompt)
8. [Needs Input](#h-needs-input)

---

## A) Executive Summary

### Top-Risiken & Quick Wins (10 Bulletpoints)

| # | Typ | Beschreibung | Fundstelle | Impact |
|---|-----|--------------|------------|--------|
| 1 | 🔴 **Security** | Firebase API Key öffentlich in Repository | `lib/firebase_options.dart:27` | **HIGH** - Key sollte via Environment-Variable injiziert werden |
| 2 | 🟡 **Tech Debt** | 6 Screens >500 LOC (csv_import: 1034, noten_uebersicht: 950, noten_eingabe: 785) | `lib/features/import/screens/csv_import_screen.dart:1-1034` | **MED** - Erschwert Wartbarkeit |
| 3 | 🟢 **Quick Win** | Coverage-Threshold nur 35% (sollte 50%+) | `.github/workflows/ci.yml:55` | **MED** - Anheben auf 50% |
| 4 | 🟡 **Architecture** | `firestore_service.dart` mit 849 LOC - sollte aufgespalten werden | `lib/services/firestore_service.dart:1-849` | **MED** - Service zu groß |
| 5 | 🟢 **Quick Win** | 10 `debugPrint` Statements noch vorhanden (sollten entfernt werden) | diverse | **LOW** - Clean-up Task |
| 6 | 🟡 **Testing** | Keine Tests für kritische Screens (csv_import, noten_eingabe) | `test/features/` fehlt | **MED** - Coverage-Lücke |
| 7 | 🟢 **DX** | Integration-Tests nur Scaffold (1 Datei, 4 Tests) | `integration_test/app_test.dart` | **LOW** - Ausbaubar |
| 8 | 🟡 **Performance** | Keine Pagination in Haupt-Listen (studentsProvider lädt alle) | `lib/providers/app_providers.dart:56-59` | **MED** - Bei >500 Schülern langsam |
| 9 | 🟢 **Quick Win** | Fehlende Golden-Tests für UI-Regression | `test/` | **LOW** - Nice-to-have |
| 10 | 🟡 **Documentation** | ADRs nur inline in ARCHITECTURE.md (keine separaten Dateien) | `docs/ARCHITECTURE.md:470+` | **LOW** - Besser strukturieren |

---

## B) Repo Scorecard (0-10)

| Kategorie | Score | Begründung |
|-----------|-------|------------|
| **Architektur** | 8/10 | ✅ Klare Layer-Trennung (UI→Provider→Service→Firestore), Feature-based Structure, gute Modularität. -2 für zu große Files |
| **Codequalität** | 7/10 | ✅ Strikte Lint-Rules (38 aktive), 0 Analyse-Fehler, keine print()-Statements. -3 für 6 Files >500 LOC |
| **Sicherheit** | 6/10 | ✅ Granulare Firestore Rules, DSGVO-Logging-Policy. -4 für API-Key im Repo, Pre-Login Read auf app_users |
| **Performance** | 7/10 | ✅ Lazy Loading Routes, DashboardStatsProvider, Map-Lookups. -3 für fehlende Pagination, keine Offline-Caching |
| **Tests** | 7/10 | ✅ 386 Tests, 14 Model-Tests, 6 Service-Tests. -3 für nur 35% CI-Threshold, keine Screen-Widget-Tests |
| **DX (Developer Experience)** | 8/10 | ✅ Gute CI/CD, CONTRIBUTING.md, klare Guidelines. -2 für fehlende Pre-Commit-Hooks, keine Codegen (freezed) |
| **Dokumentation** | 9/10 | ✅ Umfangreiche Docs (ARCHITECTURE, TESTING, LOGGING, CODING_GUIDELINES, PERFORMANCE). -1 für fehlende API-Docs |

**Gesamt-Score: 7.4/10** - Sehr gut strukturiertes Projekt mit klaren Verbesserungsmöglichkeiten

---

## C) Architecture Map

### Hauptmodule und Datenfluss

```
┌───────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                   │
│  lib/features/*/screens/*.dart (18 Screens)                       │
│  lib/widgets/*.dart (6 Widget-Gruppen)                            │
│  lib/core/widgets/*.dart (RBS Components)                         │
│                                                                    │
│  Patterns: ConsumerStatefulWidget, ref.watch(), ref.read()        │
└───────────────────────────┬───────────────────────────────────────┘
                            │ (nutzt)
┌───────────────────────────▼───────────────────────────────────────┐
│                        STATE LAYER                                 │
│  lib/providers/app_providers.dart (598 LOC)                       │
│  lib/providers/permissions_providers.dart (139 LOC)               │
│  lib/providers/feature_flags_provider.dart (206 LOC)              │
│                                                                    │
│  Provider-Typen: StreamProvider, FutureProvider, StateProvider    │
│  Patterns: .family<T,Arg>, Notifier, Computed Providers           │
└───────────────────────────┬───────────────────────────────────────┘
                            │ (nutzt)
┌───────────────────────────▼───────────────────────────────────────┐
│                       SERVICE LAYER                                │
│  lib/services/firestore_service.dart (849 LOC)                    │
│  lib/services/auth_service.dart (148 LOC)                         │
│  lib/services/pdf_export_service.dart (427 LOC)                   │
│  lib/services/csv_import_service.dart (273 LOC)                   │
│  lib/services/noi_export_service.dart (236 LOC)                   │
│  lib/services/pdf_import_service.dart (230 LOC)                   │
│  lib/services/asv_import_service.dart (581 LOC)                   │
│                                                                    │
│  Patterns: Constructor DI, Pure Dart (kein BuildContext)          │
└───────────────────────────┬───────────────────────────────────────┘
                            │ (nutzt)
┌───────────────────────────▼───────────────────────────────────────┐
│                        DATA LAYER                                  │
│  Firebase Cloud Firestore                                         │
│  Collections: students, subjects, grades, klassen,                │
│               leistungsnachweise, app_users, settings             │
│                                                                    │
│  Security: firestore.rules (163 LOC)                              │
└───────────────────────────────────────────────────────────────────┘
```

### Feature-Struktur

```
lib/features/           (13 Features)
├── admin/              # Feature-Flags Screen
├── auth/               # Login Screen
├── dashboard/          # Home Screen + Widgets
├── export/             # NOI Export
├── faecher/            # Fächer CRUD
├── import/             # CSV Import
├── klassen/            # Klassen CRUD
├── leistungsnachweise/ # LN Management
├── noten/              # Noten Eingabe/Übersicht
├── profile/            # User Profile
├── schueler/           # Schüler CRUD
├── settings/           # Admin Settings
└── users/              # User Management
```

### Models (14 Dateien, 1582 LOC)

```
lib/models/
├── app_user.dart           (135 LOC) - User mit Rollen & Favoriten
├── beruf.dart              (84 LOC)  - Beruf & Schuljahr Enums
├── feature_flags.dart      (474 LOC) - 23 Feature-Flags
├── grade.dart              (86 LOC)  - Noten mit Tendenzen
├── klasse.dart             (131 LOC) - Klassen mit Zeitgruppen
├── leistungsnachweis.dart  (139 LOC) - Tests & Schulaufgaben
├── ln_exemption.dart       (44 LOC)  - LN-Befreiungen
├── student.dart            (159 LOC) - Schüler mit Status
├── subject.dart            (94 LOC)  - Fächer mit Farben
├── zeugnisnote.dart        (97 LOC)  - Zeugnisnoten-Berechnung
└── ... (4 weitere kleine Models)
```

### Provider-Hierarchie

```
firestoreServiceProvider (Singleton)
    ↓
studentsProvider ─────────┐
klassenProvider ──────────┤
subjectsProvider ─────────┼──→ dashboardStatsProvider (Computed)
gradesProvider ───────────┤
leistungsnachweiseProvider┘
    ↓
klassenMapProvider ───────┐
subjectsMapProvider ──────┼──→ O(1) Lookup Maps
studentsMapProvider ──────┘
    ↓
currentAppUserProvider ───→ currentUserKuerzelProvider
                          ↓
                    permissions_providers.dart
                    - canManageUsersProvider
                    - canCreateDataProvider
                    - canEditLeistungsnachweisProvider
```

### Routing (go_router)

```
Route Tree:
/login              → LoginScreen
/                   → HomeScreen (Dashboard)
├── /klassen        → KlassenScreen
│   └── /klassen/:id → KlassenDetailScreen
├── /faecher        → FaecherScreen
│   └── /faecher/:id → FaecherDetailScreen
├── /schueler       → SchuelerScreen
│   └── /schueler/:id → SchuelerDetailScreen
├── /leistungsnachweise → LeistungsnachweiseScreen
│   └── /leistungsnachweis/:id/edit → LNEditorScreen
├── /noten/:leistungsnachweisId → NotenEingabeScreen
├── /noten/klasse/:klasseId → NotenUebersichtScreen
├── /noten/fach/:fachId → NotenUebersichtScreen
├── /noten/schueler/:studentId → NotenUebersichtScreen
├── /export         → NoiExportScreen
├── /import         → CsvImportScreen
├── /einstellungen  → SettingsScreen (Admin)
├── /einstellungen/benutzer → UserVerwaltungScreen (Admin)
├── /einstellungen/feature-flags → FeatureFlagsScreen (Admin)
└── /profil         → ProfileScreen (alle User)
```

---

## D) Findings Backlog

### Legende
- **Impact:** H=High, M=Medium, L=Low
- **Effort:** S=Small (<2h), M=Medium (2-8h), L=Large (>8h)

| ID | Kategorie | Impact | Effort | Beschreibung | Fundstelle | Empfehlung | Akzeptanzkriterien |
|----|-----------|--------|--------|--------------|------------|------------|-------------------|
| **F-001** | Security | H | S | Firebase API-Key im Repository sichtbar | `lib/firebase_options.dart:27` | API-Keys via CI/CD Environment-Variables injizieren, `.env` Datei nutzen | API-Key nicht mehr in Git-History, CI baut erfolgreich |
| **F-002** | Tech Debt | M | L | csv_import_screen.dart hat 1034 LOC | `lib/features/import/screens/csv_import_screen.dart:1-1034` | Widget-Extraktion in 3-4 Dateien (Preview, Mapping, Import-Button) | Screen <500 LOC, Tests vorhanden |
| **F-003** | Tech Debt | M | L | noten_uebersicht_screen.dart hat 950 LOC | `lib/features/noten/screens/noten_uebersicht_screen.dart:1-950` | Matrix-Widgets bereits extrahiert, restliche Filter/Header extrahieren | Screen <500 LOC |
| **F-004** | Tech Debt | M | M | noten_eingabe_screen.dart hat 785 LOC | `lib/features/noten/screens/noten_eingabe_screen.dart:1-785` | InputRow und SaveButton als Widgets extrahieren | Screen <500 LOC |
| **F-005** | Tech Debt | M | L | firestore_service.dart hat 849 LOC | `lib/services/firestore_service.dart:1-849` | Aufsplitten in StudentService, KlasseService, GradeService | Jeder Service <300 LOC |
| **F-006** | Testing | M | L | Keine Widget-Tests für kritische Screens | `test/features/` (leer) | Tests für csv_import, noten_eingabe, klassen_screen | >60% Coverage pro Screen |
| **F-007** | CI/CD | M | S | Coverage-Threshold nur 35% statt 50% | `.github/workflows/ci.yml:55` | Threshold auf 50% erhöhen nach F-006 | CI prüft auf 50%+ |
| **F-008** | Performance | M | M | studentsProvider lädt alle Schüler ohne Pagination | `lib/providers/app_providers.dart:56-59` | Pagination mit PaginatedFirestoreList Widget nutzen | Lazy-Loading in Listen-Views |
| **F-009** | Security | M | S | Pre-Login Read auf app_users Collection | `firestore.rules:53` | Kürzel-Lookup via Cloud Function (Rate-Limiting) | Cloud Function deployed |
| **F-010** | DX | L | S | 10 debugPrint Statements verbleiben | diverse Dateien | Alle entfernen oder hinter kDebugMode | 0 debugPrint in Production |
| **F-011** | Testing | L | M | Integration-Tests nur Scaffold | `integration_test/app_test.dart` | Login→Dashboard→Noten Flow testen | 3+ E2E-Flows getestet |
| **F-012** | DX | L | M | Keine Pre-Commit Hooks | Keine Datei vorhanden | husky + lint-staged Setup | Pre-Commit führt analyze+format aus |
| **F-013** | Docs | L | S | ADRs inline statt separate Dateien | `docs/ARCHITECTURE.md:470-530` | Separate `docs/adrs/` Ordner | 4+ ADR-Dateien |
| **F-014** | Performance | L | S | Keine Firestore Offline-Caching aktiviert | `lib/main.dart` | `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)` | Offline-Modus funktioniert |
| **F-015** | Testing | L | M | Keine Golden-Tests für UI-Regression | `test/` | Golden-Tests für RBSDrawer, RBSButton, NotenMatrix | 5+ Golden-Tests |
| **F-016** | DX | L | L | Keine Code-Generation (freezed) für Models | `lib/models/` | Optional: freezed für immutable Models | Entscheidung dokumentieren (ADR) |
| **F-017** | Security | L | S | Keine CSP Headers in Firebase Hosting | `firebase.json` | Content-Security-Policy Headers hinzufügen | CSP Headers aktiv |

---

## E) Coding Guidelines - Repo-spezifisch

> Die vollständigen Guidelines sind in `CODING_GUIDELINES.md` dokumentiert.
> Hier sind die wichtigsten repo-spezifischen Regeln:

### Bestehende Standards (aus Repository extrahiert)

#### 1. Naming Conventions (✅ Umgesetzt)
```dart
// Dateien: snake_case
lib/features/noten/screens/noten_eingabe_screen.dart

// Classes: PascalCase
class NotenEingabeScreen extends ConsumerStatefulWidget

// Provider: *Provider Suffix
final studentsProvider = StreamProvider<List<Student>>((ref) {...});
```

#### 2. Layer-Regeln (✅ Umgesetzt)
- UI darf NICHT direkt auf Firestore zugreifen (über Provider)
- Services haben KEINEN BuildContext Import
- Models sind pure data classes

#### 3. File Size Limits (⚠️ 6 Verstöße)
| Max LOC | Aktuell | Dateien |
|---------|---------|---------|
| 500 (Screens) | 1034 | csv_import_screen.dart |
| 500 (Screens) | 950 | noten_uebersicht_screen.dart |
| 500 (Screens) | 785 | noten_eingabe_screen.dart |
| 500 (Screens) | 767 | schueler_screen.dart |
| 500 (Screens) | 764 | faecher_screen.dart |
| 800 (Services) | 849 | firestore_service.dart |

### Proposed Standards (noch nicht enforced)

#### 1. Error Handling Pattern
```dart
// PROPOSED: Result-Type statt Exceptions
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}
```
**Status:** Diskussion erforderlich (ADR erstellen)

#### 2. Widget-Test Pattern für Screens
```dart
// PROPOSED: Alle Screens mit eigenem Test-File
// test/features/<feature>/screens/<screen>_test.dart
testWidgets('NotenEingabeScreen shows student list', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [studentsByKlasseProvider.overrideWith(...)],
      child: MaterialApp(home: NotenEingabeScreen(leistungsnachweisId: 'test')),
    ),
  );
  expect(find.byType(ListView), findsOneWidget);
});
```
**Status:** Tests fehlen für kritische Screens

#### 3. Const Widgets Pattern
```dart
// PROPOSED: Alle stateless Widgets mit const constructor
const NotenCell({
  required this.grade,
  required this.onChanged,
  super.key,
});
```
**Status:** Bereits 70%+ umgesetzt, weitere Durchsetzung via Lint

### CI Enforcement

#### Aktuell implementiert:
- ✅ `flutter analyze` (0 Fehler)
- ✅ `flutter test --coverage`
- ✅ Coverage-Check (35% Minimum)

#### Noch zu implementieren:
- ⏳ `dart format --set-exit-if-changed` (Formatting-Check)
- ⏳ Pre-Commit Hooks (husky)
- ⏳ PR-Template Checklist-Enforcement

---

## F) Refactoring Plan (3 Phasen)

### Phase 1: Stabilisieren (2-3 Wochen)

**Ziel:** Kritische Risiken beheben, CI härten, Test-Coverage auf 50%+

| # | Task | Effort | Findings | Abnahmekriterien |
|---|------|--------|----------|------------------|
| 1.1 | API-Key aus Repository entfernen | S | F-001 | API-Key via CI-Secrets, `.env.example` Template |
| 1.2 | Coverage-Threshold auf 50% | S | F-007 | CI failt unter 50% |
| 1.3 | Widget-Tests für csv_import_screen | L | F-006 | 10+ Tests, 60%+ Coverage |
| 1.4 | Widget-Tests für noten_eingabe_screen | L | F-006 | 10+ Tests, 60%+ Coverage |
| 1.5 | debugPrint Statements entfernen | S | F-010 | 0 debugPrint in lib/ |
| 1.6 | Pre-Commit Hooks Setup | M | F-012 | husky + lint-staged aktiv |

**Risiken:**
- API-Key-Rotation kann bestehende Deployments brechen
- Coverage-Erhöhung erfordert Zeit für Test-Erstellung

**Abnahme:** CI grün, 50%+ Coverage, keine Secrets im Repo

---

### Phase 2: Strukturieren (3-4 Wochen)

**Ziel:** Tech Debt abbauen, große Dateien aufsplitten, Architektur verbessern

| # | Task | Effort | Findings | Abnahmekriterien |
|---|------|--------|----------|------------------|
| 2.1 | csv_import_screen.dart aufsplitten | L | F-002 | 3 Dateien, Haupt-Screen <500 LOC |
| 2.2 | noten_uebersicht_screen.dart optimieren | M | F-003 | <500 LOC |
| 2.3 | noten_eingabe_screen.dart refactoren | M | F-004 | <500 LOC |
| 2.4 | firestore_service.dart aufsplitten | L | F-005 | 4 Services (Student, Klasse, Grade, LN) |
| 2.5 | ADRs in separate Dateien | S | F-013 | docs/adrs/ mit 4+ Dateien |
| 2.6 | Cloud Function für Kürzel-Lookup | M | F-009 | Cloud Function deployed, Rate-Limiting aktiv |

**Risiken:**
- Service-Aufteilung erfordert Provider-Updates
- Screen-Refactoring kann UI-Bugs einführen

**Abnahme:** Alle Dateien <500/800 LOC, 386+ Tests weiterhin grün

---

### Phase 3: Optimieren/Skalieren (4-6 Wochen)

**Ziel:** Performance, DX, Skalierbarkeit verbessern

| # | Task | Effort | Findings | Abnahmekriterien |
|---|------|--------|----------|------------------|
| 3.1 | Pagination für Schüler-Listen | M | F-008 | Lazy-Loading in SchuelerScreen |
| 3.2 | Integration-Tests erweitern | L | F-011 | 5+ E2E-Flows |
| 3.3 | Golden-Tests für UI-Regression | M | F-015 | 5+ Golden-Tests |
| 3.4 | Firestore Offline-Caching | S | F-014 | Offline-Modus funktioniert |
| 3.5 | CSP Headers in Firebase Hosting | S | F-017 | Lighthouse Security Score verbessert |
| 3.6 | freezed Evaluation (optional) | M | F-016 | ADR-Entscheidung dokumentiert |
| 3.7 | Coverage auf 60%+ | L | - | CI prüft auf 60%+ |

**Risiken:**
- Pagination kann UX ändern (kein "Alle anzeigen" mehr)
- freezed erfordert build_runner, erhöht Komplexität

**Abnahme:** Lighthouse Performance >80, 60%+ Coverage, E2E-Tests grün

---

## G) Copilot Improvement Prompt

> Copy-paste-fertiger Prompt für die Umsetzung von Phase 1:

```
Du bist ein Flutter/Dart Experte und arbeitest am InduScore Repository.

## Kontext
- Version: v0.32.0
- 79 Dart-Dateien in lib/, 35 in test/
- 386 Tests, 0 Analyse-Fehler
- Tech Stack: Flutter 3.x, Riverpod 3.x, Firebase, go_router

## Aufgabe: Phase 1 - Stabilisieren

### Reihenfolge der Änderungen:

1. **API-Key Security (F-001)**
   - Datei: `lib/firebase_options.dart`
   - Erstelle: `.env.example` mit Platzhaltern
   - Nutze: `flutter_dotenv` Package
   - Update: CI Workflow mit GitHub Secrets
   - Teste: Local Build funktioniert mit `.env`

2. **Coverage-Threshold erhöhen (F-007)**
   - Datei: `.github/workflows/ci.yml:55`
   - Ändere: MIN_COVERAGE=35 → MIN_COVERAGE=50
   - Teste: CI läuft grün

3. **Widget-Tests für csv_import_screen (F-006)**
   - Erstelle: `test/features/import/screens/csv_import_screen_test.dart`
   - Tests:
     - CSV-Datei Upload simulieren
     - Spalten-Mapping UI
     - Import-Button mit Mock-Service
     - Error-States
   - Ziel: 10+ Tests, 60%+ Coverage

4. **Widget-Tests für noten_eingabe_screen (F-006)**
   - Erstelle: `test/features/noten/screens/noten_eingabe_screen_test.dart`
   - Tests:
     - Schüler-Liste Rendering
     - Noten-Eingabe Dropdown
     - Tendenz-Buttons
     - Speichern (Optimistic Update)
   - Ziel: 10+ Tests, 60%+ Coverage

5. **debugPrint entfernen (F-010)**
   - Suche: `grep -rn "debugPrint" lib/`
   - Ersetze: Mit `kDebugMode` Guard oder entfernen
   - Teste: Keine debugPrint in Production

6. **Pre-Commit Hooks (F-012)**
   - Installiere: `husky` und `lint-staged` (npm)
   - Konfiguriere: `flutter analyze` und `dart format`
   - Teste: Pre-Commit Hook blockt unformattierten Code

## Patterns & Conventions
- Nutze `ProviderScope(overrides: [...])` für Test-Mocks
- Folge `CODING_GUIDELINES.md` für Naming
- Nutze `RBSSnackBar.show()` für Feedback (nicht ScaffoldMessenger)
- Keine PII in debugPrint (siehe `docs/LOGGING_POLICY.md`)

## Tests ergänzen
- Folge Pattern aus `test/models/*_test.dart`
- Nutze Mockito für Services
- Arrange-Act-Assert Pattern

## CI/Checks enforc'n
- PR muss `flutter analyze` bestehen
- PR muss `flutter test` bestehen
- PR muss Coverage >= 50% haben

## PR/Commit-Struktur
- 1 Commit pro Task (1.1, 1.2, ...)
- Commit-Format: `<type>(<scope>): <description>`
- Beispiele:
  - `security(firebase): Move API key to environment variables`
  - `test(import): Add widget tests for csv_import_screen`
  - `ci: Increase coverage threshold to 50%`
  - `chore: Add pre-commit hooks with husky`

## Definition of Done
- [ ] Alle 6 Tasks abgeschlossen
- [ ] 386+ Tests (keine Regression)
- [ ] CI grün
- [ ] Coverage >= 50%
- [ ] Keine Secrets im Repository
- [ ] Pre-Commit Hooks aktiv
- [ ] CHANGELOG.md aktualisiert
```

---

## H) Needs Input

Die folgenden Punkte erfordern Entscheidungen oder zusätzliche Informationen:

| # | Thema | Frage | Wer |
|---|-------|-------|-----|
| 1 | Firebase Project | Ist das Firebase-Projekt `notentool` produktiv oder Development? | Admin |
| 2 | API-Key Rotation | Soll der aktuelle API-Key rotiert werden nach Migration zu Secrets? | Admin |
| 3 | freezed Adoption | Soll Code-Generation (freezed) für Models eingeführt werden? | Team |
| 4 | Offline-First | Wie wichtig ist Offline-Funktionalität für die Nutzer? | Product Owner |
| 5 | Cloud Functions | Gibt es ein Budget/Genehmigung für Cloud Functions (Blaze Plan)? | Admin |
| 6 | Golden-Tests | Welche UI-Komponenten sind am wichtigsten für Regression-Tests? | Team |

---

**Erstellt von:** Copilot Coding Agent  
**Review angefordert:** @AlexBuchnerTeacher  
**Nächste Schritte:** Review → Approval → Phase 1 starten
