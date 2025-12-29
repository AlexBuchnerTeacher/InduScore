# Copilot Improvement Prompt (Copy-Paste Ready)

**Repository:** AlexBuchnerTeacher/InduScore  
**Ziel:** Schrittweise Umsetzung aller Findings aus dem Repository-Analyse-Report  
**Basis:** docs/REPOSITORY_ANALYSIS_REPORT.md  
**Version:** 1.0  
**Datum:** 2025-12-29

---

## Verwendung

Kopiere diesen Prompt 1:1 in GitHub Copilot (VS Code Agent Mode) oder als GitHub Issue/PR-Beschreibung. Der Prompt führt Copilot Schritt für Schritt durch die Umsetzung aller 20 Findings.

---

## Master Prompt (Start hier)

```markdown
Rolle: Du bist ein Expert Flutter Developer mit Fokus auf Clean Architecture, Riverpod State Management und Firebase Backend.

Kontext: Das InduScore-Projekt (Flutter Web, Riverpod, Firestore) wurde analysiert. 20 Findings wurden identifiziert (siehe docs/REPOSITORY_ANALYSIS_REPORT.md). Deine Aufgabe: Findings schrittweise abarbeiten gemäß 3-Phasen-Refactoring-Plan.

Regeln (STRICT):
1. KEINE Code-Änderungen ohne explizite Rückfrage
2. Pro Session: MAX 1 Finding (außer bei Abhängigkeiten)
3. IMMER ERST Tests schreiben, DANN refactorn
4. Nach jeder Änderung: `flutter analyze && flutter test` ausführen
5. Commit-Messages: Conventional Commits (feat/fix/refactor/test/docs)
6. PR-Größe: <300 LOC (außer Auto-Generated Code)

Arbeitsweise:
1. Finding auswählen (nach Priorität: Phase 1 → Phase 2 → Phase 3)
2. Akzeptanzkriterien aus Report kopieren
3. Test-Plan erstellen (ERST Tests!)
4. Implementierung vorschlagen (kleinstmöglich)
5. Review-Checkliste abarbeiten (CODING_GUIDELINES.md)
6. Commit & Push (mit Finding-ID in Commit-Message)

Output-Format (für jedes Finding):
---
### Finding F-XXX: [Titel]

**Status:** 🟡 In Progress  
**Priorität:** [High/Medium/Low]  
**Effort:** [S/M/L]  
**Phase:** [1/2/3]

#### Akzeptanzkriterien (aus Report)
- [ ] Kriterium 1
- [ ] Kriterium 2

#### Test-Plan
1. Unit Test: [Beschreibung]
2. Widget Test (falls UI): [Beschreibung]
3. Manual Test: [Schritte]

#### Implementierung (Vorschlag)
```dart
// Code hier (nur relevante Teile)
```

#### Risiken
- Risiko 1: [Mitigation]
- Risiko 2: [Mitigation]

#### Review-Checkliste
- [ ] `flutter analyze` ohne Fehler
- [ ] `flutter test` alle Tests grün
- [ ] CODING_GUIDELINES.md eingehalten
- [ ] Commit-Message korrekt (feat/fix/refactor + Finding-ID)

#### Commit-Message (Vorschlag)
```
refactor(F-XXX): [Titel]

- Änderung 1
- Änderung 2

Closes #XXX
Ref: docs/REPOSITORY_ANALYSIS_REPORT.md
```
---

Start: Finding F-001 (klassen_screen.dart refactorn)
```

---

## Phase 1: Stabilisieren (Findings F-001 bis F-015)

### Schritt 1: Finding F-001 (klassen_screen.dart refactorn)

**Prompt:**
```markdown
Finding F-001: klassen_screen.dart (1268 LOC) verstößt gegen 300-LOC-Regel

Aufgabe:
1. Analysiere `lib/screens/klassen_screen.dart`
2. Identifiziere alle Dialogs (z.B. `_showAddKlasseDialog`, `_showEditKlasseDialog`, etc.)
3. Extrahiere jeden Dialog in eigene Widget-Datei (`lib/widgets/dialogs/klasse_*.dart`)
4. Reduziere `klassen_screen.dart` auf <300 LOC

Akzeptanzkriterien:
- [ ] `klassen_screen.dart` <300 LOC
- [ ] Mindestens 3 Dialog-Widgets extrahiert (klasse_add_dialog.dart, klasse_edit_dialog.dart, klasse_delete_dialog.dart)
- [ ] Alle Dialogs rückgabewertbasiert (`Navigator.pop(result)`)
- [ ] Keine funktionale Änderung (nur Refactoring)

Vorgehen:
1. ERST: Widget-Tests für bestehende Dialogs schreiben (Baseline)
2. DANN: Dialogs extrahieren (einzeln, je 1 Commit)
3. Tests erneut ausführen (müssen weiterhin grün sein)
4. `flutter analyze && flutter test` vor jedem Commit

Commit-Messages:
```
test(F-001): Add baseline tests for klassen_screen dialogs
refactor(F-001): Extract KlasseAddDialog to widgets/dialogs
refactor(F-001): Extract KlasseEditDialog to widgets/dialogs
refactor(F-001): Extract KlasseDeleteDialog to widgets/dialogs
refactor(F-001): Reduce klassen_screen to <300 LOC
```

Risiken:
- Dialog-State könnte verloren gehen → State im Dialog kapseln
- Navigator.pop(result) könnte Null-Safety Issues haben → Null-Check im Caller

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

### Schritt 2: Finding F-002 (noten_matrix_view.dart aufteilen)

**Prompt:**
```markdown
Finding F-002: noten_matrix_view.dart (1137 LOC) zu komplex (3 Modi: Klassen/Fächer/LN)

Aufgabe:
1. Analysiere `lib/features/noten/widgets/noten_matrix_view.dart`
2. Identifiziere 3 Modi: KlassenMatrix, FaecherMatrix, LNMatrix
3. Erstelle 3 separate Widgets:
   - `klassen_matrix_view.dart` (Schüler × Fächer)
   - `faecher_matrix_view.dart` (Fächer × Leistungsnachweise)
   - `ln_matrix_view.dart` (Schüler × Leistungsnachweise)
4. Gemeinsame Logic in `noten_matrix_logic.dart` (bereits vorhanden)

Akzeptanzkriterien:
- [ ] 3 separate Widget-Dateien (je <400 LOC)
- [ ] `noten_matrix_view.dart` gelöscht oder nur als Router (50 LOC)
- [ ] Alle 3 Widgets nutzen `noten_matrix_logic.dart`
- [ ] Keine Duplikation (gemeinsame Widgets in `_shared/`)

Vorgehen:
1. Unit-Tests für `noten_matrix_logic.dart` ergänzen (falls fehlend)
2. Widget-Tests für Matrix-View (Baseline: Screenshot/Golden Test)
3. Ersten Modus (Klassen) extrahieren → `klassen_matrix_view.dart`
4. Zweiten Modus (Fächer) extrahieren → `faecher_matrix_view.dart`
5. Dritten Modus (LN) extrahieren → `ln_matrix_view.dart`
6. Gemeinsame Widgets in `_shared/matrix_cell.dart`, `_shared/matrix_header.dart`
7. `noten_matrix_view.dart` als Router umbauen (switch über mode)

Commit-Messages:
```
test(F-002): Add unit tests for noten_matrix_logic
test(F-002): Add golden tests for noten_matrix_view
refactor(F-002): Extract KlassenMatrixView
refactor(F-002): Extract FaecherMatrixView
refactor(F-002): Extract LNMatrixView
refactor(F-002): Extract shared matrix widgets
refactor(F-002): Simplify noten_matrix_view to router
```

Risiken:
- Routing könnte brechen → Manuelle Tests aller 3 Modi
- Provider-Watches könnten inkonsistent werden → Select() nutzen

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

### Schritt 3: Finding F-003 (csv_import_screen.dart Logic auslagern)

**Prompt:** (analog zu F-001/F-002, gekürzt)

### Schritt 4-6: Findings F-004 bis F-006 (Security + Tests)

**Prompt:**
```markdown
Finding F-004, F-005: Firestore Rules härten (rollenbasiert + Field-Validation)

Aufgabe:
1. Erweitere `firestore.rules` um rollenbasierte Access Control
2. Field-Level Validation (createdBy, updatedBy nur vom Owner)
3. Erstelle Firestore Rules Unit Tests (Emulator)

Akzeptanzkriterien:
- [ ] Rules prüfen `users/<uid>/rolle`
- [ ] 4 Rollen: admin, lehrer, ausbilder, schueler
- [ ] Field-Validation: `createdBy == request.auth.uid` bei Create
- [ ] Rules Unit Tests (Emulator) für alle Rollen

Vorgehen:
1. Firestore Emulator Setup (.github/workflows/firestore-rules-test.yml)
2. Rules Unit Tests schreiben (ERST Tests!)
3. Rules Step-by-Step erweitern (1 Collection pro Commit)
4. Tests nach jeder Änderung ausführen

Firestore Rules (Beispiel):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rolle;
    }
    
    match /users/{userId} {
      allow read: if request.auth.uid == userId || getUserRole() == 'admin';
      allow write: if getUserRole() == 'admin';
    }
    
    match /students/{studentId} {
      allow read: if request.auth != null && getUserRole() in ['admin', 'lehrer', 'ausbilder'];
      allow write: if getUserRole() in ['admin', 'lehrer'];
    }
    
    match /grades/{gradeId} {
      allow read, write: if getUserRole() in ['admin', 'lehrer'];
      allow create: if request.resource.data.createdBy == request.auth.uid;
      allow update: if resource.data.createdBy == request.auth.uid;
    }
  }
}
```

Rules Unit Tests (Beispiel):
```javascript
// test/firestore.rules.test.js
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

describe('Firestore Rules', () => {
  it('should allow admin to read all users', async () => {
    const db = getFirestore({ uid: 'admin-user', role: 'admin' });
    await assertSucceeds(db.collection('users').get());
  });
  
  it('should deny lehrer to write users', async () => {
    const db = getFirestore({ uid: 'lehrer-user', role: 'lehrer' });
    await assertFails(db.collection('users').doc('other-user').set({...}));
  });
});
```

CI/CD Integration (.github/workflows/firestore-rules-test.yml):
```yaml
name: Firestore Rules Test
on: [push, pull_request]
jobs:
  test-rules:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g @firebase/rules-unit-testing
      - run: firebase emulators:exec --only firestore "npm test"
```

Commit-Messages:
```
test(F-004): Add Firestore Rules unit tests (Emulator)
feat(F-004): Add role-based access control for users collection
feat(F-004): Add role-based access control for students collection
feat(F-005): Add field-level validation for grades (createdBy)
ci(F-004): Add Firestore Rules test workflow
```

Risiken:
- Rules zu restriktiv → Production-User können nicht mehr arbeiten
- Migration: Bestehende Daten könnten gegen neue Rules verstoßen
→ Emulator-Tests BEFORE Production Deploy!

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

### Schritt 7: Finding F-006 (Unit Tests für Models)

**Prompt:**
```markdown
Finding F-006: Fehlende Unit Tests für Student, Subject, Klasse, Leistungsnachweis

Aufgabe:
Erstelle Unit Tests für 4 Models (je 1 Test-Datei):
1. `test/models/student_test.dart`
2. `test/models/subject_test.dart`
3. `test/models/klasse_test.dart`
4. `test/models/leistungsnachweis_test.dart`

Test-Coverage pro Model:
- `fromFirestore()` → Parsing
- `toFirestore()` → Serialisierung
- `copyWith()` → Immutability
- Getters (z.B. `displayName`, `sortKey`)
- Enum-Handling (z.B. `StudentStatus.fromString()`)

Template (student_test.dart):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Student', () {
    group('fromFirestore', () {
      test('should parse valid Firestore document', () {
        // Arrange
        final doc = MockDocumentSnapshot();
        when(doc.id).thenReturn('123');
        when(doc.data()).thenReturn({
          'firstName': 'Max',
          'lastName': 'Mustermann',
          'klasseId': 'klasse-1',
          'createdAt': Timestamp.fromDate(DateTime(2020, 9, 1)),
          'eintrittsDatum': Timestamp.fromDate(DateTime(2020, 9, 1)),
          'status': 'aktiv',
        });
        
        // Act
        final student = Student.fromFirestore(doc);
        
        // Assert
        expect(student.id, '123');
        expect(student.firstName, 'Max');
        expect(student.lastName, 'Mustermann');
        expect(student.klasseId, 'klasse-1');
        expect(student.status, StudentStatus.aktiv);
      });
      
      test('should handle missing optional fields', () {
        final doc = MockDocumentSnapshot();
        when(doc.id).thenReturn('456');
        when(doc.data()).thenReturn({
          'firstName': 'Anna',
          'lastName': 'Schmidt',
          'klasseId': 'klasse-2',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'eintrittsDatum': Timestamp.fromDate(DateTime.now()),
          // austrittsDatum fehlt (optional)
        });
        
        final student = Student.fromFirestore(doc);
        
        expect(student.austrittsDatum, isNull);
        expect(student.status, StudentStatus.aktiv); // Default
      });
    });
    
    group('toFirestore', () {
      test('should convert to Firestore map', () {
        final student = Student(
          id: '123',
          firstName: 'Max',
          lastName: 'Mustermann',
          klasseId: 'klasse-1',
          eintrittsDatum: DateTime(2020, 9, 1),
          createdAt: DateTime(2020, 9, 1),
        );
        
        final map = student.toFirestore();
        
        expect(map['firstName'], 'Max');
        expect(map['lastName'], 'Mustermann');
        expect(map['klasseId'], 'klasse-1');
        expect(map['createdAt'], isA<Timestamp>());
      });
    });
    
    group('copyWith', () {
      test('should create copy with changed fields', () {
        final s1 = Student(
          id: '123',
          firstName: 'Max',
          lastName: 'Mustermann',
          klasseId: 'klasse-1',
          eintrittsDatum: DateTime(2020, 9, 1),
          createdAt: DateTime(2020, 9, 1),
        );
        
        final s2 = s1.copyWith(firstName: 'Anna');
        
        expect(s2.id, s1.id); // Unchanged
        expect(s2.firstName, 'Anna'); // Changed
        expect(s2.lastName, s1.lastName); // Unchanged
      });
    });
    
    group('displayName', () {
      test('should return "Vorname Nachname"', () {
        final student = Student(
          id: '123',
          firstName: 'Max',
          lastName: 'Mustermann',
          klasseId: 'klasse-1',
          eintrittsDatum: DateTime(2020, 9, 1),
          createdAt: DateTime(2020, 9, 1),
        );
        
        expect(student.displayName, 'Max Mustermann');
      });
    });
    
    group('sortKey', () {
      test('should return "nachname, vorname" (lowercase)', () {
        final student = Student(
          id: '123',
          firstName: 'Max',
          lastName: 'Mustermann',
          klasseId: 'klasse-1',
          eintrittsDatum: DateTime(2020, 9, 1),
          createdAt: DateTime(2020, 9, 1),
        );
        
        expect(student.sortKey, 'mustermann, max');
      });
    });
    
    group('StudentStatus', () {
      test('fromString should parse valid status', () {
        expect(StudentStatus.fromString('aktiv'), StudentStatus.aktiv);
        expect(StudentStatus.fromString('ausgetreten'), StudentStatus.ausgetreten);
      });
      
      test('fromString should default to aktiv for invalid input', () {
        expect(StudentStatus.fromString('invalid'), StudentStatus.aktiv);
        expect(StudentStatus.fromString(null), StudentStatus.aktiv);
      });
    });
  });
}
```

Akzeptanzkriterien:
- [ ] 4 neue Test-Dateien (student, subject, klasse, leistungsnachweis)
- [ ] Jede Datei >80% Coverage
- [ ] Alle Tests grün (`flutter test`)
- [ ] Mocking mit Mockito (DocumentSnapshot)

Vorgehen:
1. Mockito Mocks generieren (`flutter pub run build_runner build`)
2. Tests für Student schreiben (Template nutzen)
3. Tests für Subject, Klasse, Leistungsnachweis (analog)
4. Coverage messen (`flutter test --coverage`)

Commit-Messages:
```
test(F-006): Add unit tests for Student model
test(F-006): Add unit tests for Subject model
test(F-006): Add unit tests for Klasse model
test(F-006): Add unit tests for Leistungsnachweis model
```

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

---

## Phase 2: Strukturieren (Findings F-007 bis F-016)

### Schritt 8-10: Findings F-007 bis F-009 (Integration Tests, Service Tests, Pagination)

**Hinweis:** Analog zu Phase 1, aber komplexer (E2E-Setup, Mocking).

**Beispiel-Prompt (Finding F-007 - Integration Tests):**
```markdown
Finding F-007: Keine Integration Tests

Aufgabe:
1. Flutter Driver Setup
2. Erstelle 3 E2E-Tests:
   - Login → Dashboard → Logout
   - Create Student → Verify in List
   - Add Grade → Verify in Matrix

Setup (test_driver/):
```dart
// test_driver/app.dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:induscore/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
```

```dart
// test_driver/app_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('InduScore E2E', () {
    late FlutterDriver driver;
    
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });
    
    tearDownAll(() async {
      await driver.close();
    });
    
    test('login → dashboard → logout', () async {
      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('test@example.com');
      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('password123');
      await driver.tap(find.byValueKey('login_button'));
      
      await driver.waitFor(find.text('Dashboard'));
      
      await driver.tap(find.byValueKey('logout_button'));
      await driver.waitFor(find.text('Login'));
    });
  });
}
```

Run:
```bash
flutter drive --target=test_driver/app.dart
```

Commit-Messages:
```
test(F-007): Add Flutter Driver setup
test(F-007): Add E2E test for login flow
test(F-007): Add E2E test for student creation
test(F-007): Add E2E test for grade entry
```

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

---

## Phase 3: Optimieren (Findings F-017 bis F-020)

### Schritt 11-15: Performance, Accessibility, Web-Optimierung

**Beispiel-Prompt (Finding F-010 - Provider .select()):**
```markdown
Finding F-010: Keine gezielten Provider-Watches (oft gesamtes Objekt statt .select())

Aufgabe:
Optimiere Provider-Watches in allen Screens:
- Identifiziere Stellen mit `ref.watch(provider).value`
- Ersetze durch `ref.watch(provider.select((s) => s.value?.field))`

Beispiel (Vorher):
```dart
final student = ref.watch(studentProvider(id)).value;
return Text(student.firstName); // ❌ Rebuildet bei JEDEM Feld
```

Beispiel (Nachher):
```dart
final firstName = ref.watch(studentProvider(id).select((s) => s.value?.firstName));
return Text(firstName ?? ''); // ✅ Nur bei firstName-Änderung
```

Vorgehen:
1. Alle Screens durchsuchen (`grep -r "ref.watch" lib/screens/`)
2. Pro Screen: Identifiziere unnötige Watches
3. Refactor mit `.select()` (1 Screen pro Commit)
4. Performance-Test (Flutter DevTools: Rebuild-Count vorher/nachher)

Akzeptanzkriterien:
- [ ] Mindestens 10 Stellen optimiert
- [ ] Rebuild-Count reduziert (DevTools Messung)
- [ ] Keine funktionale Änderung

Commit-Messages:
```
perf(F-010): Optimize provider watches in home_screen
perf(F-010): Optimize provider watches in noten_eingabe_screen
perf(F-010): Optimize provider watches in klassen_screen
```

Frage: Soll ich starten? (Ja/Nein/Anpassen)
```

---

## Review-Prozess (nach jedem Finding)

**Prompt (nach Implementierung):**
```markdown
Review-Checkliste für Finding F-XXX:

1. **Code Review**
   - [ ] `flutter analyze` ohne Fehler
   - [ ] `flutter test` alle Tests grün
   - [ ] CODING_GUIDELINES.md eingehalten (Dateigrößen, Naming, etc.)
   - [ ] Keine Duplikation eingeführt
   - [ ] Error Handling vorhanden

2. **Tests**
   - [ ] Unit Tests für neue Logic
   - [ ] Widget Tests für neue UI
   - [ ] Coverage nicht gesunken

3. **Documentation**
   - [ ] Dartdoc-Kommentare für Public APIs
   - [ ] README.md aktualisiert (falls nötig)
   - [ ] CHANGELOG.md aktualisiert

4. **Git**
   - [ ] Commit-Message korrekt (Conventional Commits)
   - [ ] Finding-ID in Commit referenziert
   - [ ] Branch von main aktualisiert
   - [ ] PR erstellt (falls Feature-Branch)

5. **Manual Testing**
   - [ ] App läuft (`flutter run -d chrome`)
   - [ ] Kritische Workflows getestet (Login, Dashboard, etc.)
   - [ ] Keine Regressions-Fehler

Frage: Review bestanden? (Ja/Nein/Anpassen)
```

---

## Tracking (Fortschritt)

**Prompt (Status-Update):**
```markdown
Status-Update: Repository Improvement

**Phase 1: Stabilisieren**
- [x] F-001: klassen_screen.dart refactorn
- [x] F-002: noten_matrix_view.dart aufteilen
- [x] F-003: csv_import_screen.dart Logic auslagern
- [x] F-004: Firestore Rules rollenbasiert
- [x] F-005: Field-Level Security
- [x] F-006: Unit Tests für Models
- [ ] F-011: Dialog-Widgets extrahieren
- [ ] F-012: Dialogs in eigene Widgets
- [ ] F-015: analysis_options.yaml erweitern

**Phase 2: Strukturieren**
- [ ] F-007: Integration Tests
- [ ] F-008: Service-Tests
- [ ] F-009: Pagination
- [ ] F-013: Dependency Injection
- [ ] F-016: Migration screens → features

**Phase 3: Optimieren**
- [ ] F-010: Provider .select()
- [ ] F-017: Accessibility
- [ ] F-020: Web-Optimierungen

**Nächster Schritt:** F-011 (Dialog-Widgets)

Frage: Weiter mit F-011? (Ja/Nein/Pause)
```

---

## Hilfestellung

### Wenn Copilot feststeckt:
```markdown
Hilfe! Ich komme nicht weiter bei Finding F-XXX.

Problem:
[Beschreibung]

Bereits versucht:
1. [Versuch 1]
2. [Versuch 2]

Error-Message:
```
[Fehler hier einfügen]
```

Frage:
- Soll ich einen anderen Ansatz versuchen?
- Soll ich das Finding überspringen?
- Soll ich um menschliche Review bitten?
```

### Wenn Tests fehlschlagen:
```markdown
Tests fehlgeschlagen bei Finding F-XXX.

Failing Test:
```
[Test-Output hier einfügen]
```

Code (relevant):
```dart
[Code hier einfügen]
```

Hypothese:
[Vermutung was schiefläuft]

Frage:
- Soll ich den Test anpassen?
- Soll ich den Code fixen?
- Soll ich debuggen (mit print())?
```

---

## Finale Validierung

**Prompt (nach allen 20 Findings):**
```markdown
Finale Validierung: Alle 20 Findings abgeschlossen

Checkliste:
- [ ] Alle 20 Findings umgesetzt (siehe Status-Tracking)
- [ ] `flutter analyze` 0 Errors, 0 Warnings
- [ ] `flutter test` alle Tests grün
- [ ] Coverage >70% (Ziel erreicht)
- [ ] 0 Dateien >800 LOC
- [ ] Firestore Rules getestet (Emulator)
- [ ] E2E-Tests laufen
- [ ] Manual Tests: Login, Dashboard, Noteneingabe, Export
- [ ] README.md aktualisiert (neue Features, Setup-Änderungen)
- [ ] CHANGELOG.md aktualisiert (v0.17.0, v0.18.0, v1.0.0)

Performance-Vergleich (vorher/nachher):
- Initial Load: [vorher] → [nachher]
- Lighthouse Performance: [vorher] → [nachher]
- Lighthouse Accessibility: [vorher] → [nachher]
- Coverage: 51.71% → [nachher]

Repo Scorecard (vorher/nachher):
- Architektur: 8/10 → [nachher]
- Code-Qualität: 7/10 → [nachher]
- Sicherheit: 5/10 → [nachher]
- Performance: 7/10 → [nachher]
- Tests: 7/10 → [nachher]
- DX: 8/10 → [nachher]
- Dokumentation: 9/10 → [nachher]
- Wartbarkeit: 7/10 → [nachher]

**Gesamt:** 7.25/10 → [nachher]

Frage: Release vorbereiten (v1.0.0)? (Ja/Nein/Anpassen)
```

---

## Release-Prozess (v1.0.0)

**Prompt:**
```markdown
Release v1.0.0 vorbereiten

Schritte:
1. **Version Bump**
   - [ ] pubspec.yaml: `version: 1.0.0+100`
   - [ ] VERSION: `1.0.0`
   - [ ] lib/version.dart: `const version = '1.0.0';`

2. **CHANGELOG.md**
   ```markdown
   ## [1.0.0] - 2026-XX-XX
   
   ### Added
   - Integration Tests (E2E)
   - Firestore Rules (rollenbasiert)
   - Pagination für alle Listen
   - Accessibility (Screen Reader Support)
   - Web-Optimierungen (Code Splitting)
   
   ### Fixed
   - 5 Dateien >800 LOC refactored
   - Security: Firestore Rules gehärtet
   - Performance: Provider .select() optimiert
   
   ### Tests
   - Coverage 51.71% → 75%
   - Unit Tests für alle Models
   - Integration Tests (3 kritische Workflows)
   ```

3. **Git**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b release/v1.0.0
   git add pubspec.yaml VERSION lib/version.dart CHANGELOG.md
   git commit -m "chore: Release v1.0.0"
   git push origin release/v1.0.0
   ```

4. **GitHub Release**
   - [ ] PR erstellen (release/v1.0.0 → main)
   - [ ] CI/CD Tests abwarten (müssen grün sein!)
   - [ ] PR mergen
   - [ ] Tag erstellen: `git tag v1.0.0 && git push origin v1.0.0`
   - [ ] GitHub Release erstellen (Auto-Generated Notes)

5. **Deployment**
   - [ ] Firebase Hosting Deploy (Auto via GitHub Actions)
   - [ ] Firestore Rules Deploy (`firebase deploy --only firestore:rules`)
   - [ ] Smoke Tests auf Production (https://induscore-notentool.web.app/)

6. **Announcement**
   - [ ] README.md Badge aktualisieren (v1.0.0)
   - [ ] Twitter/LinkedIn Post (optional)
   - [ ] Team informieren

Frage: Release starten? (Ja/Nein/Anpassen)
```

---

## Ende

**Dieser Prompt ist Copy-Paste Ready!** Starte mit dem "Master Prompt" oben und arbeite dich Schritt für Schritt durch alle Findings. Copilot wird dich durch jedes Finding führen.

**Viel Erfolg! 🚀**

---

**Autor:** GitHub Copilot Agent  
**Datum:** 2025-12-29  
**Version:** 1.0
