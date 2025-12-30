# InduScore - Copilot Verbesserungsplan

**Erstellt**: 2025-12-30  
**Repo**: AlexBuchnerTeacher/InduScore  
**Aktuelle Version**: v0.20.0  
**Ziel**: Repo-Score 8.1/10 → 9.0/10

---

## 📊 Executive Summary

### Repo-Status: SEHR GUT (8.1/10)

**Stärken** (NICHT ÄNDERN!):
- ✅ Exzellente Dokumentation (4000+ Zeilen: Architecture, Testing, Logging Policy, Coding Guidelines)
- ✅ Feature-based Architecture (12 Features in lib/features/)
- ✅ Firestore Security Rules (4 Rollen: admin, lehrer, ausbilder, schueler)
- ✅ PII-Logging Policy (DSGVO-konform)
- ✅ 38 Strikte Lint-Regeln (analysis_options.yaml)
- ✅ 269 Tests (Unit + Widget), 25 Test-Dateien
- ✅ CI/CD Pipeline (Analyze, Test, Deploy, Dependabot)

**Verbesserungsbedarf**:
- 🔴 Keine Flutter SDK-Installation (verhindert lokale Entwicklung)
- 🔴 Keine Integration-Tests (0 E2E-Tests)
- 🔴 3 Dateien >800 LOC (Wartbarkeitsgrenze überschritten)
- 🟡 CI Coverage-Threshold nur 35% (zu niedrig)
- 🟡 Kein Firebase Crashlytics (Production-Fehler werden nicht erfasst)
- 🟡 TODOs ohne Issue-Referenzen

---

## 🎯 Verbesserungsplan (3 Phasen)

### Phase 4: Qualitätssicherung (v0.21.0)

**Dauer**: 2-3 Wochen  
**Ziel**: Test-Coverage auf 50%+, Integration-Tests, Crashlytics

#### Tasks

| Task | Beschreibung | Priorität | Effort | Fundstelle |
|------|-------------|-----------|--------|------------|
| **F-100** | Flutter SDK Setup | P1 | S | `flutter --version` → not found |
| **F-101** | Integration-Tests | P1 | L | Kein `integration_test/` Verzeichnis |
| **F-103** | CI Coverage 50%+ | P1 | S | `.github/workflows/ci.yml:53` (MIN_COVERAGE=35) |
| **F-104** | Crashlytics | P2 | S | `main.dart` - kein Crashlytics Setup |
| **F-105** | TODOs Cleanup | P2 | S | `klassen_screen.dart:188,259` |

#### Implementierung (Schritt-für-Schritt)

**Schritt 1: Flutter SDK Setup**
```bash
# Datei erstellen: scripts/setup-flutter.sh
#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:~/flutter/bin"
flutter doctor

# Test: bash scripts/setup-flutter.sh && flutter --version
# Commit: chore(infra): Add Flutter SDK setup script
```

**Schritt 2: CI Coverage erhöhen**
```yaml
# Datei: .github/workflows/ci.yml (Zeile 53)
# Änderung:
- MIN_COVERAGE=35
+ MIN_COVERAGE=50

# Test: flutter test --coverage
# Commit: ci: Increase coverage threshold to 50%
```

**Schritt 3: TODOs aufräumen**
```bash
# Grep-Check:
grep -rn "TODO" lib/ | grep -v "TODO(#"

# Ändern in klassen_screen.dart:
- // TODO: Implement ImportPreviewDialog
+ // TODO(#123): Implement ImportPreviewDialog

# Commit: refactor: Add issue references to TODOs
```

**Schritt 4: Crashlytics Integration**
```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Crashlytics Setup
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const ProviderScope(child: MyApp()));
}

// Test: Exception werfen, in Firebase Console prüfen
// Commit: feat(monitoring): Add Firebase Crashlytics integration
```

**Schritt 5: Integration-Tests**
```dart
// Datei erstellen: integration_test/login_to_dashboard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:induscore/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login → Dashboard Flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Login Screen
    expect(find.text('Anmelden'), findsOneWidget);

    // 2. Credentials eingeben
    await tester.enterText(find.byType(TextField).first, 'BU');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Dashboard sichtbar
    expect(find.text('Dashboard'), findsOneWidget);
  });
}

// 2 weitere Tests erstellen:
// - integration_test/noten_eingabe_test.dart
// - integration_test/csv_import_test.dart

// CI erweitern (.github/workflows/ci.yml):
- name: Integration Tests
  run: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/login_to_dashboard_test.dart

// Commit: test: Add integration tests for critical user flows
```

#### Abnahmekriterien Phase 4
- ✅ `flutter --version` erfolgreich
- ✅ CI-Coverage-Threshold = 50%
- ✅ 0 TODOs ohne Issue-Ref
- ✅ Crashlytics in Firebase Console aktiv
- ✅ 3 Integration-Tests grün (Login, Noteneingabe, CSV-Import)
- ✅ Alle Tests grün (Unit + Widget + Integration)

---

### Phase 5: Performance-Optimierung (v0.22.0)

**Dauer**: 2-3 Wochen  
**Ziel**: Alle Dateien <800 LOC, Code-Splitting, Provider-Optimierung

#### Tasks

| Task | Beschreibung | Effort | Fundstelle |
|------|-------------|--------|------------|
| **F-102a** | csv_import_screen.dart reduzieren | M | 1034 LOC → <500 LOC |
| **F-102b** | noten_uebersicht_screen.dart reduzieren | M | 968 LOC → <500 LOC |
| **F-102c** | firestore_service.dart splitten | M | 849 LOC → <400 LOC |
| **F-106** | Code-Splitting (Lazy Loading) | M | `main.dart` - synchrone Imports |
| **F-110** | Provider `.select()` Optimierung | S | Grep-Check in Features |

#### Implementierung

**Schritt 1: Widget-Extraktion (csv_import_screen.dart)**
```dart
// Neue Widgets erstellen:
// lib/features/import/widgets/csv_upload_section.dart (~200 LOC)
// lib/features/import/widgets/csv_preview_table.dart (~300 LOC)
// lib/features/import/widgets/csv_mapping_dialog.dart (~250 LOC)

// csv_import_screen.dart: Von 1034 → <500 LOC

// Test: Funktionalität unverändert, alle Tests grün
// Commit: refactor(import): Extract widgets from csv_import_screen
```

**Schritt 2: Widget-Extraktion (noten_uebersicht_screen.dart)**
```dart
// Ähnlich wie Schritt 1, weitere Widget-Extraktion
// Ziel: <500 LOC

// Commit: refactor(noten): Extract widgets from noten_uebersicht_screen
```

**Schritt 3: Service-Splitting (firestore_service.dart)**
```dart
// Neue Services erstellen:
// lib/services/student_service.dart (Student CRUD)
// lib/services/grade_service.dart (Grade CRUD)
// lib/services/klasse_service.dart (Klasse CRUD)

// firestore_service.dart: Nur gemeinsame Helper, <400 LOC

// Test: Alle Service-Tests grün
// Commit: refactor(services): Split firestore_service into focused services
```

**Schritt 4: Code-Splitting**
```dart
// lib/main.dart - Lazy Loading für große Features
GoRoute(
  path: '/klassen',
  pageBuilder: (context, state) => MaterialPage(
    child: FutureBuilder(
      future: import('features/klassen/screens/klassen_screen.dart'),
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!.KlassenScreen();
        return const CircularProgressIndicator();
      },
    ),
  ),
)

// Test: Lighthouse Bundle Size <500KB
// Commit: perf: Add lazy loading for feature routes
```

**Schritt 5: Provider-Optimierung**
```bash
# Grep-Check:
grep -rn "ref.watch(" lib/features/ | grep -v ".select("

# Ändern:
- final klassen = ref.watch(klassenProvider);
+ final klassen = ref.watch(klassenProvider.select((klassen) => klassen.value));

# Test: DevTools Rebuild-Counter
# Commit: perf: Optimize provider watches with .select()
```

#### Abnahmekriterien Phase 5
- ✅ Alle Dateien <800 LOC
- ✅ Initial Bundle <500KB
- ✅ Lighthouse Performance >80
- ✅ Reduced Rebuilds (DevTools Profiler)

---

### Phase 6: Excellence (v1.0.0)

**Dauer**: 3-4 Wochen  
**Ziel**: Accessibility >90, Golden-Tests, ADRs, Verschlüsselung (optional)

#### Tasks

| Task | Beschreibung | Effort | Fundstelle |
|------|-------------|--------|------------|
| **F-108** | ADR-Dateien erstellen | S | `docs/adr/` nicht vorhanden |
| **F-107** | Accessibility-Tests | M | Keine WAVE-Scans |
| **F-112** | Golden-Tests | M | Kein `test/goldens/` |
| **F-111** | Verschlüsselung (OPTIONAL) | L | Schülernamen in Klartext |

#### Implementierung

**Schritt 1: ADRs erstellen**
```markdown
# Verzeichnis: docs/adr/
# Dateien:
# - 0001-riverpod-state-management.md
# - 0002-firebase-backend.md
# - 0003-feature-based-architecture.md

# Template:
# ADR-001: Riverpod for State Management
## Status: Accepted
## Context: Need scalable state management
## Decision: Riverpod 3.0+
## Consequences:
✅ Compile-safe
✅ Auto-disposal
❌ Learning curve

# Commit: docs: Add ADRs for key architecture decisions
```

**Schritt 2: Accessibility**
```dart
// Manual WAVE-Scan aller 14 Screens
// Fixes:
// - Semantics-Labels für alle Buttons
// - ARIA-Labels für Formularfelder
// - Keyboard-Navigation

// Test:
testWidgets('RBSButton has semantics label', (tester) async {
  await tester.pumpWidget(RBSButton(label: 'Speichern'));
  expect(
    tester.getSemantics(find.byType(RBSButton)),
    matchesSemantics(label: 'Speichern'),
  );
});

// Commit: a11y: Add semantics labels and ARIA attributes
```

**Schritt 3: Golden-Tests**
```bash
# Verzeichnis: test/goldens/
# Tests für: RBSDrawer, NotenMatrixView, DashboardWidgets, KlasseCard, RBSButton

flutter test --update-goldens

# CI erweitern:
- name: Golden Tests
  run: flutter test --no-update-goldens

# Commit: test: Add golden tests for critical UI components
```

**Schritt 4: Verschlüsselung (OPTIONAL)**
```dart
// Nur bei Bedarf: AES-256 für Schülernamen
// Package: encrypt: ^5.0.0
// POC zuerst (1 Woche Evaluation)

// Commit: feat(security): Add AES-256 encryption for student names
```

#### Abnahmekriterien Phase 6
- ✅ WAVE-Tool: 0 Critical Errors
- ✅ Lighthouse Accessibility >90
- ✅ Min. 5 Golden-Tests
- ✅ Min. 3 ADRs dokumentiert
- ✅ (Optional) Verschlüsselung aktiv

---

## 📋 Findings Backlog (Komplett)

### P1 - Kritisch (4 Findings)

| ID | Kategorie | Impact | Effort | Beschreibung | Fundstelle |
|----|-----------|--------|--------|-------------|------------|
| F-100 | Build/Infra | H | S | Flutter SDK nicht installiert | `flutter --version` → not found |
| F-101 | Testing | H | L | Keine Integration-Tests | Kein `integration_test/` |
| F-102 | Code Quality | M | M | 3 Dateien >800 LOC | csv_import: 1034, noten_uebersicht: 968, firestore_service: 849 |
| F-103 | Testing | M | S | CI Coverage 35% (zu niedrig) | `.github/workflows/ci.yml:53` |

### P2 - Wichtig (4 Findings)

| ID | Kategorie | Impact | Effort | Beschreibung | Fundstelle |
|----|-----------|--------|--------|-------------|------------|
| F-104 | Monitoring | M | S | Kein Crashlytics | `main.dart` |
| F-105 | Code Quality | L | S | TODOs ohne Issue-Ref | `klassen_screen.dart:188,259` |
| F-106 | Performance | M | M | Kein Code-Splitting | `main.dart` |
| F-107 | Accessibility | M | M | Keine A11y-Tests | Keine WAVE-Scans |

### P3 - Nice-to-Have (5 Findings)

| ID | Kategorie | Impact | Effort | Beschreibung | Fundstelle |
|----|-----------|--------|--------|-------------|------------|
| F-108 | Documentation | L | S | Keine ADR-Dateien | `docs/adr/` fehlt |
| F-109 | Code Gen | L | M | Keine Code-Generation | Models manuell |
| F-110 | Performance | L | S | Provider ohne `.select()` | Features-Screens |
| F-111 | Security | M | L | Keine Verschlüsselung | Klartext-Namen |
| F-112 | Testing | L | M | Keine Golden-Tests | `test/goldens/` fehlt |

---

## 🎯 Success Metrics

| Metrik | v0.20.0 (IST) | v0.21.0 (Phase 4) | v0.22.0 (Phase 5) | v1.0.0 (Phase 6) |
|--------|--------------|-------------------|-------------------|------------------|
| **Repo-Score** | 8.1/10 | 8.5/10 | 8.8/10 | **9.0/10** 🎯 |
| **Test-Coverage** | ~35% (CI) | 50% | 55% | 60%+ |
| **Integration-Tests** | 0 | 3-4 | 3-4 | 5+ |
| **Dateien >800 LOC** | 3 | 3 | 0 | 0 |
| **Lighthouse Perf** | ? | ? | >80 | >85 |
| **Lighthouse A11y** | ? | ? | >80 | >90 |
| **Crashlytics** | ❌ | ✅ | ✅ | ✅ |

---

## 📝 Commit-Strategie

### Conventional Commits Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`, `a11y`

**Beispiele**:
- ✅ `feat(monitoring): Add Firebase Crashlytics integration`
- ✅ `refactor(import): Extract widgets from csv_import_screen`
- ✅ `test: Add integration tests for critical user flows`
- ✅ `ci: Increase coverage threshold to 50%`
- ❌ `updated stuff` (zu vage)
- ❌ `Fix` (kein Scope)

### PR-Struktur
- Pro Phase ein Feature-Branch (`feature/phase-4-quality-assurance`)
- Pro Task ein Commit
- Kleine, reviewbare PRs
- Alle Checks grün vor Merge

---

## ✅ Definition of Done

### Für jeden Task:
- [ ] Code implementiert
- [ ] Tests hinzugefügt/aktualisiert
- [ ] Tests grün (lokal + CI)
- [ ] `flutter analyze` erfolgreich
- [ ] Dokumentation aktualisiert (falls nötig)
- [ ] Review von 1 Person
- [ ] PR gemerged

### Für jede Phase:
- [ ] Alle Tasks complete
- [ ] Abnahmekriterien erfüllt
- [ ] CHANGELOG.md aktualisiert
- [ ] Git-Tag erstellt (z.B. `v0.21.0`)
- [ ] Release publiziert
- [ ] Repo-Score gemessen

---

## ⚠️ Wichtige Hinweise

### NIEMALS ÄNDERN:
- Bestehende Firestore Security Rules (nur erweitern)
- PII-Logging Policy (bereits DSGVO-konform)
- Feature-based Architecture (bereits migriert)
- Bestehende Tests (nur erweitern)
- Coding Guidelines (bereits exzellent)

### IMMER:
- Kleine, reviewbare Commits
- Tests ZUERST schreiben (TDD)
- Dokumentation aktualisieren
- Alle Checks grün vor Merge
- Conventional Commits nutzen

### BEI FRAGEN:
- Issue öffnen mit Label `question`
- `CODING_GUIDELINES.md` konsultieren (655 Zeilen)
- `docs/ARCHITECTURE.md` lesen (555 Zeilen)
- `docs/TESTING_STRATEGY.md` lesen (566 Zeilen)

---

## 📚 Ressourcen

### Dokumentation (bereits exzellent!)
- `CODING_GUIDELINES.md` (655 Zeilen) ✅
- `docs/ARCHITECTURE.md` (555 Zeilen) ✅
- `docs/TESTING_STRATEGY.md` (566 Zeilen) ✅
- `docs/LOGGING_POLICY.md` (419 Zeilen) ✅
- `docs/REFACTORING_ROADMAP.md` (Phase 1-3 complete) ✅
- `CONTRIBUTING.md` ✅
- `README.md` ✅

### CI/CD
- `.github/workflows/ci.yml` (Analyze, Test, Coverage)
- `.github/workflows/deploy-gh-pages.yml`
- `.github/workflows/release.yml`
- `.github/dependabot.yml`

### Konfiguration
- `pubspec.yaml` (Dependencies)
- `analysis_options.yaml` (38 Lint-Regeln)
- `firebase.json`
- `firestore.rules` (4 Rollen)
- `firestore.indexes.json`

---

**Erstellt**: 2025-12-30  
**Maintained by**: Development Team  
**Vollständige Analyse**: `REPO_COMPREHENSIVE_ANALYSIS.md`  
**Nächste Schritte**: Phase 4 starten (Qualitätssicherung)
