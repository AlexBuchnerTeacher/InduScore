# InduScore - Testing-Strategie

**Version:** 1.1  
**Letzte Aktualisierung:** 2025-12-30  
**Erstellt gemäß:** Issue #51 Finding F04

---

## Inhaltsverzeichnis
1. [Testpyramide](#1-testpyramide)
2. [IST-Zustand](#2-ist-zustand)
3. [Coverage-Ziele](#3-coverage-ziele)
4. [Mocking-Strategie](#4-mocking-strategie)
5. [Test-Patterns](#5-test-patterns)
6. [CI-Integration](#6-ci-integration)
7. [Fehlende Tests (Priorität)](#7-fehlende-tests-priorität)

---

## 1. Testpyramide

### 1.1 Soll-Verteilung

```
        ▲
       /│\      10% Integration Tests
      / │ \     (User-Flows, E2E)
     /  │  \    
    /   │   \   20% Widget Tests
   /    │    \  (UI-Komponenten)
  /     │     \ 
 /      │      \ 70% Unit Tests
/       │       \ (Models, Services, Logic)
```

**Begründung:**
- **Unit-Tests** sind schnell, isoliert und einfach zu schreiben
- **Widget-Tests** validieren UI-Komponenten und Interaktionen
- **Integration-Tests** testen kritische User-Flows End-to-End

### 1.2 Was testen?

| Test-Typ | Was testen? | Beispiel |
|----------|------------|----------|
| **Unit-Tests** | Models, Services, Business Logic, Berechnungen | `grade_test.dart`, `zeugnisnote_test.dart` |
| **Widget-Tests** | UI-Komponenten, User-Interaktionen, State-Changes | `profile_screen_test.dart` |
| **Integration-Tests** | User-Flows (Login → Dashboard → Aktion) | `login_to_noten_test.dart` (noch nicht vorhanden) |
| **Golden-Tests** | UI-Regression (Pixel-perfekte Screenshots) | Noch nicht vorhanden |

---

## 2. IST-Zustand

### 2.1 Statistiken (Stand v0.32.0)

- **Test-Dateien:** 35
- **Tests gesamt:** 386
- **Test-zu-Code-Ratio:** ~20%
- **Coverage:** >50%
- **CI Threshold:** 35% (sollte auf 50% erhöht werden - siehe F-007)

### 2.2 Vorhandene Tests

**Unit-Tests (14 Dateien):**
```
test/models/
├── app_user_test.dart            ✅ Vorhanden
├── beruf_test.dart               ✅ Vorhanden
├── feature_flags_test.dart       ✅ Vorhanden (11 Tests)
├── grade_test.dart               ✅ Vorhanden (wichtig: Rundungslogik)
├── klasse_test.dart              ✅ Vorhanden
├── leistungsnachweis_test.dart   ✅ Vorhanden
├── ln_exemption_test.dart        ✅ Vorhanden
├── noten_eingabe_test.dart       ✅ Vorhanden
├── noten_statistik_test.dart     ✅ Vorhanden
├── schueler_unterricht_test.dart ✅ Vorhanden
├── student_test.dart             ✅ Vorhanden
├── subject_test.dart             ✅ Vorhanden
├── tendenz_test.dart             ✅ Vorhanden
└── zeugnisnote_test.dart         ✅ Vorhanden (24 Tests für Rundungslogik)
```

**Widget-Tests:**
```
test/widgets/profile/
├── password_change_dialog_test.dart  ✅ Vorhanden
└── ...
test/shared/widgets/
├── app_snack_bars_test.dart          ✅ Vorhanden (11 Tests)
├── feature_guard_test.dart           ✅ Vorhanden (16 Tests)
└── paginated_firestore_list_test.dart ✅ Vorhanden (5 Tests)
```

**Service-Tests (6 Dateien):**
```
test/services/
├── asv_import_service_test.dart      ✅ Vorhanden
├── auth_service_test.dart            ✅ Vorhanden
├── csv_import_service_test.dart      ✅ Vorhanden (22 Tests)
├── firestore_service_test.dart       ✅ Vorhanden
├── noi_export_service_test.dart      ✅ Vorhanden (17 Tests)
└── pdf_export_service_test.dart      ✅ Vorhanden (16 Tests)
```

### 2.3 Fehlende Tests (Priorität - siehe docs/IMPROVEMENT_ISSUES.md)

⏳ **Noch zu erstellen:**
- `test/features/import/screens/csv_import_screen_test.dart` (F-006)
- `test/features/noten/screens/noten_eingabe_screen_test.dart` (F-006)
- `test/features/noten/screens/noten_uebersicht_screen_test.dart` (F-006)
- Integration-Tests erweitern (F-011)
- Golden-Tests (F-015)

---

## 3. Coverage-Ziele

### 3.1 Aktuelle Coverage

**Gesamt:** >50% (v0.32.0)

**Annahmen (basierend auf Codebase-Analyse):**
- Models: ~80% (gut getestet)
- Services: ~40% (nur CSV/Backup getestet)
- Providers: ~30% (wenig Tests)
- Screens: ~10% (nur Profile getestet)

### 3.2 Ziel-Coverage

| Kategorie | IST | Ziel | Priorität |
|-----------|-----|------|-----------|
| **Models** | ~80% | **90%+** | P3 (bereits gut) |
| **Services** | ~40% | **80%+** | **P1 (kritisch)** |
| **Providers** | ~30% | **70%+** | P2 (wichtig) |
| **Screens** | ~10% | **50%+** | **P1 (kritisch)** |
| **Widgets** | ~50% | **70%+** | P2 (wichtig) |
| **Gesamt** | 51.71% | **65%+** | **P1** |

**Erste Maßnahme:** Services und Screens auf 60%+ bringen

### 3.3 CI-Coverage-Threshold

**Aktuell:** Min. 50% (Issue #51 F07)  
**Nächster Schritt:** Auf 55% erhöhen nach Phase 2  
**Langfristig:** 60%+ nach Phase 3

---

## 4. Mocking-Strategie

### 4.1 Wann Mocking?

**Regel:** Mocke externe Abhängigkeiten, nicht interne Logik

**Mocken:**
- ✅ Firestore (via `FakeFirestoreInstance` oder Mockito)
- ✅ Firebase Auth (via Mockito)
- ✅ Services in Widget-Tests
- ✅ HTTP-Requests (falls vorhanden)

**NICHT Mocken:**
- ❌ Models (sind pure data classes)
- ❌ Berechnungen (teste echte Logik!)
- ❌ Simple Getter/Setter

### 4.2 Mocking-Tools

**Aktuell genutzt:**
- `mockito: ^5.4.4` (Code-Generation via build_runner)
- `build_runner: ^2.4.14` (für @GenerateMocks)

**Beispiel:**
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirestoreService])
void main() {
  test('getStudent returns student', () async {
    final mock = MockFirestoreService();
    when(mock.getStudent('123')).thenAnswer((_) async => testStudent);
    
    final result = await mock.getStudent('123');
    expect(result, testStudent);
  });
}
```

### 4.3 Fake Firestore (für Integration-Tests)

**Package:** `fake_cloud_firestore: ^2.5.0` (noch nicht im Projekt)

**Empfehlung:** Hinzufügen für Integration-Tests

```dart
final fakeFirestore = FakeFirebaseFirestore();
await fakeFirestore.collection('students').add({
  'firstName': 'Max',
  'lastName': 'Mustermann',
});

final docs = await fakeFirestore.collection('students').get();
expect(docs.size, 1);
```

---

## 5. Test-Patterns

### 5.1 Unit-Test Pattern (Models)

**Beispiel:** `test/models/grade_test.dart`

```dart
void main() {
  group('Grade Model', () {
    test('fromFirestore creates valid Grade', () {
      // Arrange
      final doc = MockDocumentSnapshot();
      when(doc.id).thenReturn('grade123');
      when(doc.data()).thenReturn({
        'studentId': 'student1',
        'leistungsnachweisId': 'ln1',
        'value': 2.5,
        'punkte': 45,
        'isBerücksichtigt': true,
      });

      // Act
      final grade = Grade.fromFirestore(doc);

      // Assert
      expect(grade.id, 'grade123');
      expect(grade.value, 2.5);
      expect(grade.isBerücksichtigt, isTrue);
    });

    test('copyWith creates new instance with changed values', () {
      final grade = Grade(id: '1', value: 3.0, /* ... */);
      final updated = grade.copyWith(value: 2.0);

      expect(updated.value, 2.0);
      expect(updated.id, '1'); // Andere Felder unverändert
    });
  });
}
```

### 5.2 Widget-Test Pattern (Screens)

**Beispiel:** `test/widgets/profile_screen_test.dart`

```dart
void main() {
  testWidgets('ProfileScreen shows user data', (tester) async {
    // Arrange: Mock User
    final testUser = AppUser(
      id: 'user1',
      kuerzel: 'BU',
      displayName: 'Max Mustermann',
      rolle: UserRole.lehrer,
    );

    // Act: Pump Widget mit ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAppUserProvider.overrideWith((ref) => AsyncValue.data(testUser)),
        ],
        child: MaterialApp(home: ProfileScreen()),
      ),
    );

    // Assert: Text vorhanden
    expect(find.text('Max Mustermann'), findsOneWidget);
    expect(find.text('Lehrer'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows password change dialog', (tester) async {
    await tester.pumpWidget(/* ... */);

    // Tap Button
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();

    // Dialog sichtbar
    expect(find.text('Passwort ändern'), findsOneWidget);
  });
}
```

### 5.3 Service-Test Pattern

**Noch zu implementieren:** `test/services/firestore_service_test.dart`

```dart
void main() {
  late MockFirebaseFirestore mockFirestore;
  late FirestoreService service;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    service = FirestoreService(firestore: mockFirestore);
  });

  test('getStudents returns list of students', () async {
    // Arrange: Fake Firestore mit Daten
    await mockFirestore.collection('students').add({
      'firstName': 'Max',
      'lastName': 'Mustermann',
      // ...
    });

    // Act
    final stream = service.getStudents();
    final students = await stream.first;

    // Assert
    expect(students, hasLength(1));
    expect(students.first.firstName, 'Max');
  });
}
```

### 5.4 Integration-Test Pattern

**Noch zu implementieren:** `integration_test/login_to_noten_test.dart`

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login → Dashboard → Noteneingabe Flow', (tester) async {
    // 1. App starten
    app.main();
    await tester.pumpAndSettle();

    // 2. Login (Kürzel-Login)
    await tester.enterText(find.byType(TextField).first, 'BU');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();

    // 3. Dashboard sichtbar
    expect(find.text('Dashboard'), findsOneWidget);

    // 4. Navigate zu Noteneingabe
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // 5. Noteneingabe Screen sichtbar
    expect(find.text('Noteneingabe'), findsOneWidget);
  });
}
```

### 5.5 Golden-Test Pattern

**Noch zu implementieren:** `test/widgets/rbs_drawer_test.dart`

```dart
void main() {
  testWidgets('RBSDrawer matches golden file', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            drawer: RBSDrawer(),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Screenshot vergleichen
    await expectLater(
      find.byType(RBSDrawer),
      matchesGoldenFile('goldens/rbs_drawer.png'),
    );
  });
}
```

**Golden-Tests erstellen:**
```bash
flutter test --update-goldens
```

---

## 6. CI-Integration

### 6.1 Aktueller CI-Workflow

**Datei:** `.github/workflows/ci.yml`

**Steps:**
1. ✅ Checkout
2. ✅ Setup Flutter
3. ✅ `flutter pub get`
4. ✅ `flutter analyze`
5. ✅ `flutter test --coverage`
6. ✅ Coverage-Threshold Check (min 50%) **NEU in Issue #51 F07**

### 6.2 Fehlende CI-Steps

**Noch zu implementieren:**
- [ ] Golden-Test Validation (`flutter test --update-goldens` in CI verboten)
- [ ] Integration-Test Execution (`flutter drive`)
- [ ] Coverage-Upload zu codecov.io (optional)
- [ ] Mutation-Testing (optional, fortgeschritten)

### 6.3 CI-Enforcement

**Regel:** PR kann NICHT gemerged werden bei:
- ❌ `flutter analyze` Warnings
- ❌ `flutter test` Failures
- ❌ Coverage <50% (aktuell), später <60%

---

## 7. Fehlende Tests (Priorität)

### 7.1 Kritische Tests (P1 - Diese Woche)

1. **klassen_screen_test.dart** (Issue #51 F06)
   - Test: PDF-Import Dialog
   - Test: Klasse erstellen Dialog
   - Test: Klasse bearbeiten
   - Test: Klasse löschen (mit Confirmation)
   - **Ziel:** >60% Coverage für klassen_screen.dart

2. **firestore_service_test.dart** (neu)
   - Test: CRUD für Students
   - Test: CRUD für Klassen
   - Test: CRUD für Grades
   - **Ziel:** >70% Coverage für firestore_service.dart

### 7.2 Wichtige Tests (P2 - Nächste Woche)

3. **csv_import_screen_test.dart**
   - Test: CSV-Upload
   - Test: Preview-Tabelle
   - Test: Mapping-Dialog

4. **Integration-Test: Login → Noteneingabe**
   - Test: Vollständiger User-Flow
   - **Datei:** `integration_test/login_to_noten_test.dart`

### 7.3 Nice-to-Have Tests (P3 - Später)

5. **Golden-Tests für kritische Widgets**
   - `RBSDrawer`
   - `NotenMatrixView`
   - `DashboardWidgets`

6. **Mutation-Testing** (fortgeschritten)
   - Package: `mutation`
   - Validiert Test-Qualität

---

## 8. Test-Daten & Fixtures

### 8.1 Test-Fixtures erstellen

**Empfehlung:** Erstelle `test/fixtures/` für wiederverwendbare Test-Daten

```dart
// test/fixtures/test_students.dart
final testStudent1 = Student(
  id: 'student1',
  firstName: 'Max',
  lastName: 'Mustermann',
  klasseId: 'klasse1',
  berufId: 'beruf1',
  status: StudentStatus.aktiv,
  zeitgruppe: 'A',
);

final testStudent2 = Student(/* ... */);

final List<Student> testStudents = [testStudent1, testStudent2];
```

**Verwendung:**
```dart
import '../fixtures/test_students.dart';

test('something', () {
  expect(someFunction(testStudent1), expectedResult);
});
```

---

## 9. Best Practices

### 9.1 Test-Naming

✅ **KORREKT:**
```dart
test('getStudent returns student when ID exists', () { });
test('getStudent throws exception when ID not found', () { });
testWidgets('ProfileScreen shows user data when logged in', (tester) async { });
```

❌ **FALSCH:**
```dart
test('test1', () { });  // ❌ Nicht aussagekräftig
test('it works', () { });  // ❌ Zu vage
```

### 9.2 Arrange-Act-Assert Pattern

**Immer nutzen:**
```dart
test('example', () {
  // Arrange (Setup)
  final student = testStudent1;
  final service = MockFirestoreService();
  when(service.getStudent(student.id)).thenAnswer((_) async => student);

  // Act (Execute)
  final result = await service.getStudent(student.id);

  // Assert (Verify)
  expect(result, student);
  expect(result.firstName, 'Max');
});
```

### 9.3 Eine Assertion pro Test (Ideal)

✅ **KORREKT:**
```dart
test('student has correct firstName', () {
  expect(testStudent1.firstName, 'Max');
});

test('student has correct lastName', () {
  expect(testStudent1.lastName, 'Mustermann');
});
```

⚠️ **OK (wenn zusammengehörig):**
```dart
test('student has correct name fields', () {
  expect(testStudent1.firstName, 'Max');
  expect(testStudent1.lastName, 'Mustermann');
});
```

---

## 10. Nächste Schritte

### Diese Woche
1. ✅ CI-Coverage-Threshold aktiviert (Issue #51 F07) → **ERLEDIGT**
2. [ ] `klassen_screen_test.dart` erstellen
3. [ ] `firestore_service_test.dart` erstellen
4. [ ] Coverage auf 55%+ bringen

### Nächste Woche
5. [ ] Integration-Test Setup (`integration_test/`)
6. [ ] `login_to_noten_test.dart` erstellen
7. [ ] Coverage auf 60%+ bringen

### Langfristig (Phase 3)
8. [ ] Golden-Tests für kritische Widgets
9. [ ] Coverage auf 65%+ bringen
10. [ ] Mutation-Testing evaluieren

---

**Bei Fragen zur Testing-Strategie:** Issue öffnen mit Label `testing`