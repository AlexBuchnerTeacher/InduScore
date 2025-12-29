# COPILOT IMPROVEMENT PROMPT (Copy-Paste Fertig)

## Kontext
Du arbeitest am InduScore-Repository (Flutter Web App für Notenverwaltung).  
Basis: Repository-Analyse vom 29.12.2025  
Version: 0.16.0 (63 Dart-Dateien, ~21k LOC)

---

## PHASE 1: STABILISIEREN (Prio 1, ~3-5 Tage)

### Ziel
Technische Schulden reduzieren, Code-Qualität auf einheitliches Niveau bringen, CI härten.

### Scope & Reihenfolge

#### 1.1 Widget-Extraktion für große Dateien (F01)
**Warum zuerst:** Verstößt gegen eigene Coding Guidelines (300 LOC), blockiert Wartbarkeit

**Dateien:**
1. `lib/screens/klassen_screen.dart` (1268 LOC → Ziel: <500 LOC)
   - Extrahiere `_ImportPreviewDialog` (Zeile 603-895) → `lib/features/klassen/widgets/import_preview_dialog.dart`
   - Extrahiere `_MergeDialog` (Zeile 910-1258) → `lib/features/klassen/widgets/merge_dialog.dart`
   - Extrahiere `_MatchedStudent` class → eigenes File
   
2. `lib/features/noten/widgets/noten_matrix_view.dart` (1137 LOC → Ziel: <800 LOC)
   - Extrahiere Matrix-Rendering-Logik → `noten_matrix_renderer.dart`
   - Extrahiere Header-Widgets → `matrix_header_widgets.dart`

3. `lib/screens/csv_import_screen.dart` (1094 LOC → Ziel: <600 LOC)
   - Extrahiere CSV-Parse-Logik → `lib/services/csv_parser.dart`
   - Extrahiere Preview-Widgets → `widgets/csv_preview.dart`

**Pattern pro Datei:**
```bash
# 1. Neue Datei erstellen
# 2. Widget/Class kopieren + anpassen
# 3. In Original-Datei ersetzen mit Import
# 4. Tests anpassen (imports)
# 5. dart analyze
# 6. Commit: "refactor(klassen): Extract _ImportPreviewDialog to separate file"
```

**Akzeptanzkriterien:**
- Alle Screens <500 LOC
- Alle Widgets <200 LOC
- `dart analyze` clean
- Alle Tests passing

---

#### 1.2 SnackBar Helper erstellen (F05)
**Warum:** 56x dupliziert, Quick Win für DRY-Principle

**Schritte:**
1. Öffne `lib/core/widgets/rbs_components.dart`
2. Füge hinzu:
```dart
enum RBSSnackBarType { success, error, info, warning }

class RBSSnackBar {
  static void show(
    BuildContext context,
    String message, {
    RBSSnackBarType type = RBSSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = switch (type) {
      RBSSnackBarType.success => RBSColors.courtGreen,
      RBSSnackBarType.error => RBSColors.dynamicRed,
      RBSSnackBarType.warning => RBSColors.warning,
      RBSSnackBarType.info => RBSColors.textOnLight,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: type == RBSSnackBarType.error
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              )
            : null,
      ),
    );
  }
}
```

3. Suche **alle** `ScaffoldMessenger.of(context).showSnackBar` und ersetze:
```bash
# Alt:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gespeichert')),
);

# Neu:
RBSSnackBar.show(context, 'Gespeichert', type: RBSSnackBarType.success);
```

4. Commit: `refactor(ui): Replace all SnackBar calls with RBSSnackBar helper`

**Akzeptanzkriterien:**
- `grep -r "ScaffoldMessenger.of" lib` zeigt <5 Vorkommen (nur in RBSSnackBar selbst)
- Tests passing

---

#### 1.3 CI härten (F07, F08, F12)
**Warum:** Verhindert Regressionen

**Schritte:**

1. **Coverage-Threshold** (`.github/workflows/ci.yml`):
```yaml
# Nach Zeile 39 (flutter test --coverage):
- name: Check Coverage
  run: |
    # Install very_good_coverage
    dart pub global activate very_good_coverage
    # Check minimum 50% coverage
    very_good_coverage --min-coverage 50 --exclude '**/*.g.dart' --exclude '**/*.freezed.dart'
```

2. **Strikte Lints** (`analysis_options.yaml`):
```yaml
linter:
  rules:
    # Bisherige Rules beibehalten, PLUS:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_dynamic_calls: true
    avoid_print: true
    cancel_subscriptions: true
    close_sinks: true
    unnecessary_await_in_return: true
    use_key_in_widget_constructors: true
```

3. **Dependency Audit** (neue Datei `.github/workflows/dependencies.yml`):
```yaml
name: Dependency Audit
on:
  schedule:
    - cron: '0 0 * * 1'  # Jeden Montag
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub outdated
      - run: flutter pub outdated --mode=null-safety
```

4. **Dependabot aktivieren** (`.github/dependabot.yml`):
```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

**Commits:**
- `ci: Add coverage threshold check (min 50%)`
- `ci: Enable strict lints in analysis_options.yaml`
- `ci: Add dependency audit workflow`
- `ci: Enable Dependabot for Dart packages`

**Akzeptanzkriterien:**
- CI fails bei <50% Coverage
- `dart analyze` zeigt neue Warnings (dann fixen!)
- Dependabot PRs erscheinen wöchentlich

---

#### 1.4 .gitignore erweitern (F19)
**Warum:** issues.json/milestones.json sollten nicht committed sein

**Schritte:**
```bash
# 1. .gitignore erweitern:
echo "" >> .gitignore
echo "# Generated files (should be in project management tool)" >> .gitignore
echo "issues.json" >> .gitignore
echo "issues_export.json" >> .gitignore
echo "milestones.json" >> .gitignore
echo "*.wsuo" >> .gitignore
echo ".vs/" >> .gitignore

# 2. Aus Git entfernen:
git rm --cached issues.json issues_export.json milestones.json .vs/ -r

# 3. Commit:
git commit -m "chore: Move issues/milestones to .gitignore, remove from repo"
```

**Akzeptanzkriterien:**
- `git status` zeigt keine issues*.json mehr

---

### Definition of Done (Phase 1)
- [ ] Alle Screens <500 LOC
- [ ] Alle Widgets <200 LOC
- [ ] SnackBar-Helper überall genutzt (<5 alte Calls)
- [ ] CI-Coverage-Check aktiv (min 50%)
- [ ] Strikte Lints aktiviert + alle Warnings behoben
- [ ] Dependabot aktiviert
- [ ] issues.json nicht mehr in Git
- [ ] Alle Tests passing
- [ ] `dart analyze` clean

---

## PHASE 2: STRUKTURIEREN (Prio 2, ~5-7 Tage)

### Ziel
Dokumentation vervollständigen, Testabdeckung erhöhen, Architektur verstehbar machen.

### Scope & Reihenfolge

#### 2.1 CODING_GUIDELINES.md erweitern (F02)
**Warum:** Aktuell 33 Zeilen, braucht 300+ Zeilen mit Beispielen

**Vorlage:** Nutze `/docs/REPO_ANALYSIS_COMPLETE.md`, Abschnitt D) als Basis

**Schritte:**
1. Backup: `cp CODING_GUIDELINES.md CODING_GUIDELINES.md.backup`
2. Erweitere mit:
   - **1. Naming Conventions** (mit Code-Beispielen aus Repo)
   - **2. Architekturregeln** (Layering-Diagramm)
   - **3. State Management Rules** (Provider-Typen-Tabelle)
   - **4. Error Handling** (Exception vs Result Pattern)
   - **5. Async & Streams** (Lifecycle-Regeln)
   - **6. Testing Standards** (Testpyramide, Mocking)
   - **7. Code Style** (Kommentare, max. File Length)
   - **8. Security & Privacy** (PII-Logging-Verbot)
3. Jedes Kapitel braucht:
   - ✅ **Beispiele AUS dem Repo** (nicht generisch!)
   - ✅ **Fundstelle** (Datei + Zeile)
   - ✅ **DO/DON'T Code-Snippets**
4. Commit: `docs: Expand CODING_GUIDELINES.md with 300+ lines of repo-specific examples`

**Akzeptanzkriterien:**
- CODING_GUIDELINES.md >300 Zeilen
- Alle 8 Kapitel vorhanden
- Mind. 15 Code-Beispiele mit Fundstellen
- Peer-Review approved

---

#### 2.2 ARCHITECTURE.md erstellen (F03)
**Warum:** Neue Entwickler brauchen Architektur-Übersicht

**Struktur:**
```markdown
# InduScore - Architektur-Dokumentation

## 1. Übersicht
- Tech-Stack (Flutter 3.38.2, Riverpod 3.0.3, Firebase)
- Deployment (Firebase Hosting)

## 2. Layering (mit Diagramm)
[UI Layer] → [State Layer (Riverpod)] → [Service Layer] → [Firestore]

## 3. Feature-Struktur
lib/features/<feature>/ Organisation

## 4. Datenfluss (mit Beispiel)
User-Input → Provider → Service → Firestore → Stream → Provider → UI

## 5. State Management (Riverpod)
- Provider-Typen Entscheidungsbaum
- Global vs Feature-Scoped Providers

## 6. Dependency Graph
services/ nutzt models/
providers/ nutzt services/
screens/ nutzt providers/ + widgets/

## 7. Firestore Schema
Collection-Übersicht mit Feldern

## 8. Routing (go_router)
Route-Definitionen + Auth-Guard

## 9. Security-Architektur
- Firestore Rules Strategie
- Permission Guards (permissions_providers.dart)

## 10. Entscheidungen (ADRs)
- Warum Riverpod? (vs. Bloc/GetX)
- Warum keine Code-Generation? (vs. freezed)
```

**Schritte:**
1. Erstelle `docs/ARCHITECTURE.md`
2. Nutze Mermaid für Diagramme (GitHub rendert diese)
3. Commit: `docs: Add comprehensive ARCHITECTURE.md with diagrams`

**Akzeptanzkriterien:**
- ARCHITECTURE.md >500 Zeilen
- Mind. 2 Mermaid-Diagramme (Layering, Datenfluss)
- Stakeholder-Review approved

---

#### 2.3 TESTING_STRATEGY.md erstellen (F04)
**Warum:** 51% Coverage ist gut, aber Strategie fehlt

**Struktur:**
```markdown
# InduScore - Testing-Strategie

## 1. Testpyramide (Soll-Verteilung)
- 70% Unit-Tests (models/, services/, logic/)
- 20% Widget-Tests (screens/, widgets/)
- 10% Integration-Tests (User-Flows)

## 2. IST-Zustand
- 16 Test-Dateien, ~3k LOC
- Coverage: 51.71% (v0.13.4)

## 3. Coverage-Ziele
- Models: 90%
- Services: 80%
- Providers: 70%
- Screens: 50%
- Gesamt: 65% (aktuell 51%)

## 4. Mocking-Strategie
- Mockito für Services
- Fake Firestore für Integration
- ProviderContainer für Widget-Tests

## 5. Test-Patterns (mit Beispielen)
- Unit-Test Pattern (grade_test.dart)
- Widget-Test Pattern (profile_screen_test.dart)
- Golden-Test Pattern (noch nicht vorhanden)

## 6. CI-Integration
- flutter test --coverage
- Threshold: min 50% (Phase 1), später 65%

## 7. Fehlende Tests (Priorität)
1. klassen_screen_test.dart (PDF-Import, CRUD)
2. csv_import_screen_test.dart
3. Integration: Login → Dashboard → Noteneingabe
```

**Commit:** `docs: Add TESTING_STRATEGY.md with coverage goals`

**Akzeptanzkriterien:**
- TESTING_STRATEGY.md >200 Zeilen
- CI-Referenz vorhanden

---

#### 2.4 Tests für kritische Screens (F06, F14)
**Warum:** klassen_screen.dart (1268 LOC) hat 0% Coverage

**Schritte:**

1. **Widget-Tests für KlassenScreen** (`test/screens/klassen_screen_test.dart`):
```dart
void main() {
  group('KlassenScreen', () {
    testWidgets('renders permission denied for non-admin', (tester) async {
      // Setup: Mock currentAppUserProvider mit Lehrer-Rolle
      // Assert: "Zugriff verweigert" Text vorhanden
    });

    testWidgets('shows create dialog when FAB pressed', (tester) async {
      // Setup: Admin-User
      // Act: Tap FAB
      // Assert: Dialog appears
    });

    testWidgets('PDF import button visible for admin', (tester) async {
      // Setup: Admin-User
      // Assert: Import-Button vorhanden
    });
  });
}
```

2. **Integration-Test** (`integration_test/login_to_noten_test.dart`):
```dart
void main() {
  integrationTest.testWidgets('Login → Dashboard → Noteneingabe Flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Login
    await tester.enterText(find.byType(TextField).first, 'BU');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();

    // 2. Dashboard visible
    expect(find.text('Dashboard'), findsOneWidget);

    // 3. Navigate to Noteneingabe
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // 4. Noteneingabe Screen visible
    expect(find.text('Noteneingabe'), findsOneWidget);
  });
}
```

**Commits:**
- `test: Add widget tests for KlassenScreen (PDF import, CRUD)`
- `test: Add integration test for login-to-noten flow`

**Akzeptanzkriterien:**
- klassen_screen.dart Coverage >60%
- Mind. 1 Integration-Test vorhanden
- CI passing

---

### Definition of Done (Phase 2)
- [ ] CODING_GUIDELINES.md >300 Zeilen mit Beispielen
- [ ] ARCHITECTURE.md vorhanden mit Diagrammen
- [ ] TESTING_STRATEGY.md vorhanden
- [ ] klassen_screen_test.dart mit >10 Tests
- [ ] 1+ Integration-Test
- [ ] Coverage >55%
- [ ] Alle Docs peer-reviewt

---

## PHASE 3: OPTIMIEREN & SKALIEREN (Prio 3, ~7-10 Tage)

### Ziel
Performance, Security, DX auf Production-Level bringen.

### Scope & Reihenfolge

#### 3.1 Security Audit (F09, F10)
**Warum:** Pre-Login Read-Access auf app_users ist Risiko

**Schritte:**

1. **LOGGING_POLICY.md erstellen**:
```markdown
# Logging & Privacy Policy

## Regel 1: Kein PII-Logging
NIEMALS loggen:
- Schüler-Namen (firstName, lastName)
- Schüler-Emails
- Lehrer-Emails (außer für Auth-Errors)

Erlaubt:
- IDs (studentId, klasseId, userId)
- Enums (UserRole, StudentStatus)
- Zahlen (Noten, Counts)

## Beispiele:
```dart
// ❌ FALSCH:
debugPrint('Student ${student.displayName} gespeichert');

// ✅ KORREKT:
debugPrint('Student ${student.id} gespeichert');
```

2. **Firestore Rules Audit**:
```javascript
// firestore.rules - Kommentar hinzufügen:
match /app_users/{userId} {
  // Pre-Login Read für Kürzel-Lookup
  // SECURITY NOTE: Ermöglicht Enumeration aller Kürzel
  // Akzeptiert weil: Kürzel sind nicht sensitiv (z.B. "BU", "MU")
  // Alternative: Cloud Function für Kürzel-zu-Email (performt schlechter)
  allow read: if request.auth == null;
}
```

3. **Code-Scan für PII-Logging**:
```bash
# Suche nach potenziellem PII-Logging:
grep -r "print.*displayName\|print.*email\|print.*firstName\|print.*lastName" lib/

# Wenn Treffer: Refactoren zu ID-only Logging
```

**Commits:**
- `docs: Add LOGGING_POLICY.md with PII-Verbot`
- `security: Add comment in firestore.rules explaining app_users read access`
- `security: Remove PII from all debug logs`

**Akzeptanzkriterien:**
- LOGGING_POLICY.md vorhanden
- Grep findet 0 PII-Logs
- Firestore Rules kommentiert

---

#### 3.2 Pre-Commit Hooks (F11)
**Warum:** Auto-Format + Lint vor Commit

**Schritte:**

1. **lefthook installieren** (`lefthook.yml`):
```yaml
pre-commit:
  parallel: true
  commands:
    format:
      glob: "*.dart"
      run: dart format {staged_files}
    analyze:
      glob: "*.dart"
      run: dart analyze --fatal-infos {staged_files}
```

2. **Setup-Script** (`scripts/setup-hooks.sh`):
```bash
#!/bin/bash
# Install lefthook
brew install lefthook  # oder: npm install -g @arkweid/lefthook

# Install hooks
lefthook install

echo "✅ Pre-commit hooks installed"
```

3. **README erweitern**:
```markdown
## Setup (Entwickler)
1. `flutter pub get`
2. `./scripts/setup-hooks.sh`  # ← NEU
3. `flutterfire configure`
```

**Commit:** `chore: Add pre-commit hooks with lefthook`

**Akzeptanzkriterien:**
- Commit schlägt fehl bei unformatiertem Code
- Commit schlägt fehl bei analyze-Fehlern

---

#### 3.3 Firebase Crashlytics (F10)
**Warum:** Production-Crashes tracken

**Schritte:**

1. **pubspec.yaml**:
```yaml
dependencies:
  firebase_crashlytics: ^4.5.0
```

2. **main.dart**:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(...);

  // Crashlytics Setup
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(...);
}
```

3. **Firebase Console**: Crashlytics aktivieren

**Commit:** `feat: Add Firebase Crashlytics for error tracking`

**Akzeptanzkriterien:**
- Crashlytics in Firebase Console aktiv
- Test-Crash erscheint in Dashboard

---

#### 3.4 Performance: Firestore Index-Doku (F18)
**Warum:** firestore.indexes.json hat 0 Kommentare

**Schritte:**
1. Öffne `firestore.indexes.json`
2. Füge Kommentare hinzu (JSON erlaubt keine Comments, daher Companion-File):

**Neue Datei:** `firestore.indexes.md`:
```markdown
# Firestore Index-Dokumentation

## Index 1: students (klasseId, lastName)
**Query:** `getStudentsByKlasse()` in firestore_service.dart:80  
**Grund:** Sortierung nach Namen innerhalb einer Klasse  
**Performance:** ~50ms für 30 Schüler

## Index 2: grades (leistungsnachweisId, studentId)
**Query:** `getGradesByLeistungsnachweis()` in firestore_service.dart:145  
**Grund:** Matrix-Ansicht braucht alle Noten eines LN  
**Performance:** ~30ms für 30 Noten
```

**Commit:** `docs: Add firestore.indexes.md explaining all indexes`

---

#### 3.5 Golden Tests (F15)
**Warum:** UI-Regression-Prevention

**Schritte:**

1. **Test hinzufügen** (`test/widgets/rbs_drawer_test.dart`):
```dart
void main() {
  testWidgets('RBSDrawer golden test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: Scaffold(drawer: RBSDrawer())),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(RBSDrawer),
      matchesGoldenFile('goldens/rbs_drawer.png'),
    );
  });
}
```

2. **Generate Goldens**:
```bash
flutter test --update-goldens
```

**Commits:**
- `test: Add golden tests for RBSDrawer, NotenMatrixView`

**Akzeptanzkriterien:**
- Mind. 5 Golden-Tests
- CI checkt Golden-Diffs

---

### Definition of Done (Phase 3)
- [ ] LOGGING_POLICY.md vorhanden
- [ ] PII-Logging entfernt
- [ ] Pre-Commit Hooks aktiv
- [ ] Firebase Crashlytics deployed
- [ ] firestore.indexes.md dokumentiert
- [ ] 5+ Golden-Tests
- [ ] Coverage >60%

---

## ENFORCEMENT: CI als Gatekeeper

**Finale .github/workflows/ci.yml:**
```yaml
name: CI
on: [push, pull_request]

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      # 1. Dependencies
      - run: flutter pub get
      
      # 2. Format Check
      - name: Check Format
        run: dart format --set-exit-if-changed .
      
      # 3. Analyze (mit strict lints)
      - name: Analyze
        run: dart analyze --fatal-infos
      
      # 4. Tests mit Coverage
      - name: Test
        run: flutter test --coverage
      
      # 5. Coverage Threshold
      - name: Coverage Check
        run: |
          dart pub global activate very_good_coverage
          very_good_coverage --min-coverage 60
      
      # 6. Build Check
      - name: Build Web
        run: flutter build web --release
```

**Akzeptanzkriterien:**
- CI fails bei unformatiertem Code
- CI fails bei analyze-Warnings
- CI fails bei <60% Coverage
- CI fails bei Build-Errors

---

## PR & COMMIT-STRUKTUR

### Commit-Messages (Conventional Commits)
```
feat(klassen): Extract ImportPreviewDialog to separate file
fix(auth): Handle missing email in Kürzel-Login
refactor(ui): Replace SnackBar with RBSSnackBar helper
test(screens): Add widget tests for KlassenScreen
docs: Add ARCHITECTURE.md with layering diagram
ci: Add coverage threshold check
```

### PR-Strategie
**1 PR pro Thema:**
- PR #1: "Widget-Extraktion klassen_screen.dart" (F01)
- PR #2: "SnackBar Helper + Refactoring" (F05)
- PR #3: "CI Härtung (Coverage + Lints)" (F07, F08)
- ...

**Keine riesigen Sammel-PRs!** Max. 500 LOC changed pro PR.

---

## DEFINITION OF DONE (Gesamt)

### Phase 1 (Stabilisieren) ✅
- [ ] Alle Screens <500 LOC
- [ ] SnackBar-Helper überall
- [ ] CI-Coverage min 50%
- [ ] Strikte Lints aktiv
- [ ] Dependabot aktiv

### Phase 2 (Strukturieren) ✅
- [ ] CODING_GUIDELINES.md >300 Zeilen
- [ ] ARCHITECTURE.md vorhanden
- [ ] TESTING_STRATEGY.md vorhanden
- [ ] klassen_screen_test.dart vorhanden
- [ ] Coverage >55%

### Phase 3 (Optimieren) ✅
- [ ] LOGGING_POLICY.md vorhanden
- [ ] Pre-Commit Hooks aktiv
- [ ] Crashlytics deployed
- [ ] 5+ Golden-Tests
- [ ] Coverage >60%

### Finale Checks ✅
- [ ] Alle Tests passing (local + CI)
- [ ] `dart analyze` clean
- [ ] `dart format` clean
- [ ] Alle Docs peer-reviewt
- [ ] Stakeholder-Demo erfolgreich

---

## FRAGEN VOR START

Bevor du loslegst, kläre:

1. **Breaking Changes erlaubt?**
   - Widget-Extraktion ändert Imports
   - freezed würde Models komplett umschreiben
   
2. **Zeitbudget?**
   - Phase 1: ~3-5 Tage
   - Phase 2: ~5-7 Tage
   - Phase 3: ~7-10 Tage
   - **Gesamt: ~15-22 Tage**

3. **Prioritäten?**
   - Alle 3 Phasen? Oder nur Phase 1+2?
   
4. **Deployment?**
   - Firebase Hosting auto-deploy nach main-merge?
   - Staging-Environment?

---

## LOS GEHT'S!

**Start mit Phase 1.1:** Widget-Extraktion klassen_screen.dart

```bash
# 1. Branch erstellen
git checkout -b refactor/extract-klassen-widgets

# 2. Neue Dateien erstellen
touch lib/features/klassen/widgets/import_preview_dialog.dart
touch lib/features/klassen/widgets/merge_dialog.dart

# 3. Code extrahieren (siehe Anleitung oben)

# 4. Tests anpassen

# 5. Verify
dart analyze
flutter test

# 6. Commit
git add .
git commit -m "refactor(klassen): Extract _ImportPreviewDialog to separate file"

# 7. Repeat für _MergeDialog
```

**Nächster Schritt nach klassen_screen.dart:** noten_matrix_view.dart, dann csv_import_screen.dart

**Viel Erfolg! 🚀**
