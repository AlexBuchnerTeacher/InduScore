# InduScore - Testing-Strategie

## Übersicht

Dieses Dokument definiert die Testing-Standards für InduScore. Ziel ist es, eine hohe Code-Qualität zu gewährleisten und Regressions-Fehler zu minimieren, ohne die Entwicklungsgeschwindigkeit zu sehr einzuschränken.

**Aktuelle Test-Coverage:** 51.71% (Stand v0.16.0)  
**Ziel-Coverage:** 70% (v1.0.0)  
**Test-Dateien:** 16  
**Test-LOC:** ~3.000

---

## Test-Pyramide

```
        /\
       /E2E\         Integration Tests (geplant, 5%)
      /------\
     /Widget \       Widget Tests (vorhanden, 20%)
    /----------\
   /   Unit     \    Unit Tests (hauptsächlich, 75%)
  /--------------\
```

### Verteilung (Ziel)

| Test-Typ | Anteil | Anzahl (Ziel) | Status |
|----------|--------|---------------|--------|
| **Unit Tests** | 75% | ~100 | ✅ 16 Dateien |
| **Widget Tests** | 20% | ~20 | ⚠️ Teilweise |
| **Integration Tests** | 5% | ~5 | ❌ Noch nicht |

---

## 1. Unit Tests

### Scope

**Was wird getestet:**
- **Models** (Serialisierung, Validierung, Getters)
- **Logic** (Berechnungen, Aggregationen, Transformationen)
- **Services** (mit Mocks, ohne echte Firebase-Calls)
- **Utilities** (Helper-Funktionen, Parser)

**Was wird NICHT getestet:**
- UI-Code (Widgets, Screens)
- Firebase SDK (ist bereits getestet)
- Third-Party Packages

### Naming Convention

```dart
// Datei: lib/models/student.dart
// Test: test/models/student_test.dart

// Datei: lib/features/noten/noten_matrix_logic.dart
// Test: test/features/noten/noten_matrix_logic_test.dart
```

**Regel:** Test-Datei = Source-Datei + `_test.dart` Suffix

### Test-Struktur

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/student.dart';

void main() {
  group('Student', () {
    group('fromFirestore', () {
      test('should parse valid Firestore document', () {
        // Arrange
        final doc = MockDocumentSnapshot(...);
        
        // Act
        final student = Student.fromFirestore(doc);
        
        // Assert
        expect(student.firstName, 'Max');
        expect(student.lastName, 'Mustermann');
      });
      
      test('should handle missing optional fields', () {
        // ...
      });
      
      test('should throw on invalid data', () {
        // ...
      });
    });
    
    group('toFirestore', () {
      test('should convert to Firestore map', () {
        // ...
      });
    });
    
    group('displayName', () {
      test('should return "Vorname Nachname"', () {
        // ...
      });
    });
  });
}
```

**Best Practices:**
- `group()` für logische Gruppierung (Klasse → Methode)
- `test()` für einzelne Testfälle
- AAA-Pattern: **Arrange → Act → Assert**
- Aussagekräftige Testbeschreibungen (should...)

### Mocking (Services)

**Problem:** FirestoreService nutzt echte Firebase SDK → Tests wären langsam & benötigen Internet

**Lösung:** Mockito für Service-Mocks

**Setup:**
```dart
// test/services/firestore_service_test.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentSnapshot])
import 'firestore_service_test.mocks.dart';

void main() {
  late FirestoreService service;
  late MockFirebaseFirestore mockFirestore;
  
  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    service = FirestoreService(firestore: mockFirestore);
  });
  
  test('getStudent should return student from Firestore', () async {
    // Arrange
    final mockDoc = MockDocumentSnapshot();
    when(mockDoc.data()).thenReturn({
      'firstName': 'Max',
      'lastName': 'Mustermann',
      // ...
    });
    when(mockFirestore.collection('students').doc('123').get())
        .thenAnswer((_) async => mockDoc);
    
    // Act
    final student = await service.getStudent('123');
    
    // Assert
    expect(student.firstName, 'Max');
    verify(mockFirestore.collection('students').doc('123').get()).called(1);
  });
}
```

**Mocks generieren:**
```bash
flutter pub run build_runner build
```

### Existing Unit Tests (v0.16.0)

| Test-Datei | LOC | Coverage | Status |
|------------|-----|----------|--------|
| `test/models/grade_test.dart` | ~150 | 100% | ✅ |
| `test/models/student_test.dart` | 0 | 0% | ❌ Fehlt |
| `test/models/zeugnisnote_test.dart` | ~200 | 100% | ✅ |
| `test/models/noten_eingabe_test.dart` | ~180 | 100% | ✅ |
| `test/models/noten_statistik_test.dart` | ~160 | 100% | ✅ |
| `test/models/tendenz_test.dart` | ~100 | 100% | ✅ |
| `test/models/beruf_test.dart` | ~80 | 100% | ✅ |
| `test/services/auth_service_test.dart` | ~250 | 80% | ⚠️ Teilweise |
| `test/services/firestore_service_test.dart` | ~400 | 60% | ⚠️ Teilweise |
| `test/klasse_parser_test.dart` | ~150 | 100% | ✅ |

**Fehlende Tests:**
- `lib/models/student.dart` (!!!)
- `lib/models/subject.dart`
- `lib/models/klasse.dart`
- `lib/models/leistungsnachweis.dart`
- `lib/models/ln_exemption.dart`
- `lib/features/noten/noten_matrix_logic.dart`
- `lib/services/pdf_export_service.dart`
- `lib/services/noi_export_service.dart`
- `lib/services/csv_import_service.dart`

---

## 2. Widget Tests

### Scope

**Was wird getestet:**
- **Kritische UI-Komponenten** (Buttons, Forms, Dialogs)
- **Reusable Widgets** (`lib/core/widgets/`, `lib/widgets/`)
- **Render-Logik** (bedingte Anzeige, Layouts)

**Was wird NICHT getestet:**
- Jedes kleine Widget (zu aufwändig)
- Komplexe Screens (besser Integration Tests)
- Stateless Presenter-Widgets (nur Darstellung, keine Logik)

### Test-Struktur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/core/widgets/rbs_components.dart';

void main() {
  group('RBSButton', () {
    testWidgets('should render label', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RBSButton(
              label: 'Speichern',
              onPressed: () {},
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Speichern'), findsOneWidget);
    });
    
    testWidgets('should call onPressed when tapped', (tester) async {
      // Arrange
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RBSButton(
              label: 'Klick',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(RBSButton));
      await tester.pump();
      
      // Assert
      expect(pressed, isTrue);
    });
    
    testWidgets('should be disabled when onPressed is null', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RBSButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );
      
      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```

### Testing mit Riverpod

**Problem:** Widgets nutzen `ConsumerWidget` und `ref.watch()` → benötigen `ProviderScope`

**Lösung:** Test-Setup mit `ProviderScope` + Override

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

testWidgets('should display students from provider', (tester) async {
  // Arrange
  final mockStudents = [
    Student(id: '1', firstName: 'Max', lastName: 'Mustermann', ...),
    Student(id: '2', firstName: 'Anna', lastName: 'Schmidt', ...),
  ];
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentsProvider.overrideWith((ref) => Stream.value(mockStudents)),
      ],
      child: MaterialApp(
        home: StudentListWidget(),
      ),
    ),
  );
  await tester.pump(); // Stream emit
  
  // Assert
  expect(find.text('Max Mustermann'), findsOneWidget);
  expect(find.text('Anna Schmidt'), findsOneWidget);
});
```

### Existing Widget Tests (v0.16.0)

| Test-Datei | Status |
|------------|--------|
| `test/widget_test.dart` | ✅ (Default Flutter Test) |

**Fehlende Tests:**
- `lib/core/widgets/rbs_components.dart` (!!!)
- `lib/widgets/rbs_drawer.dart`
- `lib/features/noten/widgets/editable_note_cell.dart`
- `lib/features/dashboard/widgets/nachschreiber_section.dart`

---

## 3. Integration Tests

### Scope (Geplant v1.0.0)

**Was wird getestet:**
- **End-to-End Workflows** (Login → Dashboard → Noteneingabe → Logout)
- **Multi-Screen Navigation** (GoRouter)
- **Firebase Integration** (echte Firestore-Calls gegen Test-DB)

**Was wird NICHT getestet:**
- Einzelne Widgets (besser Widget Tests)
- Performance (separate Load Tests)

### Test-Struktur (Beispiel)

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
    
    test('complete workflow: login → create student → add grade', () async {
      // 1. Login
      await driver.tap(find.byValueKey('email_field'));
      await driver.enterText('test@example.com');
      await driver.tap(find.byValueKey('password_field'));
      await driver.enterText('password123');
      await driver.tap(find.byValueKey('login_button'));
      await driver.waitFor(find.text('Dashboard'));
      
      // 2. Create Student
      await driver.tap(find.byValueKey('nav_students'));
      await driver.tap(find.byValueKey('add_student_button'));
      await driver.enterText('Max');
      await driver.tap(find.byValueKey('save_button'));
      await driver.waitFor(find.text('Max Mustermann'));
      
      // 3. Add Grade
      // ...
    });
  });
}
```

**Setup:**
```bash
flutter drive --target=test_driver/app.dart
```

**Status:** ❌ Noch nicht implementiert

---

## 4. Golden Tests (Optional)

### Scope

**Was wird getestet:**
- **Visual Regression** (Screenshots von Widgets)
- **Responsive Layouts** (verschiedene Bildschirmgrößen)

**Beispiel:**
```dart
testWidgets('RBSButton golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RBSButton(label: 'Speichern', onPressed: () {}),
      ),
    ),
  );
  
  await expectLater(
    find.byType(RBSButton),
    matchesGoldenFile('goldens/rbs_button.png'),
  );
});
```

**Generierung:**
```bash
flutter test --update-goldens
```

**Status:** ❌ Noch nicht genutzt (optional für v1.0.0)

---

## Coverage-Ziele

### Aktuell (v0.16.0)

| Kategorie | Coverage | Ziel |
|-----------|----------|------|
| **Models** | 80% | 90% |
| **Logic** | 60% | 80% |
| **Services** | 40% | 70% |
| **Widgets** | 10% | 50% |
| **Screens** | 0% | 20% |
| **Gesamt** | 51.71% | 70% |

### Coverage messen

```bash
# Mit Coverage
flutter test --coverage

# Coverage-Report anzeigen (benötigt lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### CI/CD Integration

**GitHub Actions (.github/workflows/ci.yml):**
```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

**Status:** ⚠️ Coverage wird gemessen, aber nicht in CI/CD enforced

---

## Best Practices

### 1. Testbare Code-Architektur

**✅ Gut (Testbar):**
```dart
// Logic ohne BuildContext
class NotenMatrixLogic {
  static double berechneDurchschnitt(List<Grade> grades) {
    if (grades.isEmpty) return 0;
    final sum = grades.fold<double>(0, (sum, g) => sum + g.note);
    return sum / grades.length;
  }
}

// Test
test('berechneDurchschnitt should return average', () {
  final grades = [
    Grade(note: 2.0, ...),
    Grade(note: 3.0, ...),
  ];
  expect(NotenMatrixLogic.berechneDurchschnitt(grades), 2.5);
});
```

**❌ Schlecht (Schwer testbar):**
```dart
// Logic im Widget-Build
class NotenScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesProvider).value ?? [];
    
    // ❌ Berechnung im Widget (nicht testbar)
    final average = grades.fold<double>(0, (sum, g) => sum + g.note) / grades.length;
    
    return Text('Durchschnitt: $average');
  }
}
```

### 2. Dependency Injection

**✅ Gut (Injizierbar):**
```dart
class FirestoreService {
  final FirebaseFirestore firestore;
  
  FirestoreService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  
  Stream<List<Student>> getStudents() {
    return firestore.collection('students').snapshots().map(...);
  }
}

// Test
test('getStudents should return students', () {
  final mockFirestore = MockFirebaseFirestore();
  final service = FirestoreService(firestore: mockFirestore);
  // ...
});
```

**❌ Schlecht (Hardcoded):**
```dart
class FirestoreService {
  Stream<List<Student>> getStudents() {
    // ❌ FirebaseFirestore.instance ist nicht mockbar
    return FirebaseFirestore.instance.collection('students').snapshots().map(...);
  }
}
```

### 3. Testdaten-Builder

**Problem:** Wiederholte Testdaten-Erstellung → DRY-Violation

**Lösung:** Builder-Pattern

```dart
// test/helpers/student_builder.dart
class StudentBuilder {
  String id = 'test-id';
  String firstName = 'Max';
  String lastName = 'Mustermann';
  String klasseId = 'klasse-1';
  DateTime eintrittsDatum = DateTime(2020, 9, 1);
  
  StudentBuilder withId(String id) {
    this.id = id;
    return this;
  }
  
  StudentBuilder withName(String firstName, String lastName) {
    this.firstName = firstName;
    this.lastName = lastName;
    return this;
  }
  
  Student build() {
    return Student(
      id: id,
      firstName: firstName,
      lastName: lastName,
      klasseId: klasseId,
      eintrittsDatum: eintrittsDatum,
      createdAt: DateTime.now(),
    );
  }
}

// Test
test('should sort students by last name', () {
  final students = [
    StudentBuilder().withName('Anna', 'Zorn').build(),
    StudentBuilder().withName('Max', 'Auer').build(),
  ];
  
  final sorted = students..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  
  expect(sorted.first.lastName, 'Auer');
});
```

### 4. Test-Organisation

**Ordnerstruktur:**
```
test/
├── helpers/
│   ├── student_builder.dart
│   └── mock_firestore.dart
├── models/
│   ├── student_test.dart
│   ├── grade_test.dart
│   └── ...
├── services/
│   ├── firestore_service_test.dart
│   └── auth_service_test.dart
├── features/
│   └── noten/
│       ├── noten_matrix_logic_test.dart
│       └── widgets/
│           └── editable_note_cell_test.dart
└── widget_test.dart
```

**Regel:** Test-Ordner = Source-Ordner (1:1 Mapping)

---

## Testing-Checkliste (Pull Requests)

**Vor jedem PR:**
- [ ] `flutter analyze` ohne Fehler
- [ ] `flutter test` alle Tests grün
- [ ] Neue Funktionen haben Unit Tests (mindestens)
- [ ] Coverage nicht gesunken (vs. main Branch)
- [ ] Kritische UI-Komponenten haben Widget Tests

**Für neue Features:**
- [ ] Model hat `fromFirestore()` und `toFirestore()` Tests
- [ ] Logic hat Unit Tests (für alle Public Methods)
- [ ] Service-Methoden haben Tests (mit Mocks)
- [ ] Kritische Widgets haben Widget Tests

---

## Roadmap

### v0.17.0 (Q1 2026)
- [ ] Unit Tests für fehlende Models (Student, Subject, Klasse, etc.)
- [ ] Widget Tests für `rbs_components.dart`
- [ ] Coverage auf 60% erhöhen

### v0.18.0 (Q2 2026)
- [ ] Unit Tests für Services (PDF Export, NOI Export, CSV Import)
- [ ] Widget Tests für Noten-Matrix-Widgets
- [ ] Coverage auf 70% erhöhen

### v1.0.0 (Q3 2026)
- [ ] Integration Tests (Login → Dashboard → Noteneingabe)
- [ ] Golden Tests für kritische UI-Komponenten
- [ ] Coverage auf 75% erhöhen
- [ ] CI/CD: Coverage-Gate (min. 70%)

---

## Tools & Libraries

### Testing-Framework

- **flutter_test** (Standard Flutter Testing)
- **mockito** (Mocking für Services)
- **build_runner** (Mock-Generierung)

### Coverage

- **coverage** (Dart Package)
- **lcov** (Coverage-Reports)
- **codecov.io** (geplant, Badge im README)

### CI/CD

- **GitHub Actions** (.github/workflows/ci.yml)
- **Flutter Analyze** (Linting)
- **Flutter Test** (Unit + Widget Tests)

---

## Antipatterns

### ❌ Zu vermeiden

**1. Tests ohne Assertions**
```dart
test('should create student', () {
  final student = Student(...);
  // ❌ Kein expect()
});
```

**2. Fragile Tests (Abhängig von Firestore-State)**
```dart
test('should get student from Firestore', () async {
  // ❌ Nutzt echte Firestore-DB
  final student = await FirebaseFirestore.instance
      .collection('students').doc('123').get();
  expect(student.exists, isTrue);
});
```

**3. Test-Code-Duplikation**
```dart
test('test 1', () {
  final s1 = Student(id: '1', firstName: 'Max', ...); // ❌ Dupliziert
  // ...
});

test('test 2', () {
  final s2 = Student(id: '2', firstName: 'Anna', ...); // ❌ Dupliziert
  // ...
});

// ✅ Besser: StudentBuilder nutzen
```

**4. Tests mit Sleeps**
```dart
test('should update UI after delay', () async {
  // ...
  await Future.delayed(Duration(seconds: 2)); // ❌ Langsam, flaky
  expect(...);
});
```

---

## FAQ

### Warum keine 100% Coverage?

**Antwort:** 100% Coverage ist unrealistisch und nicht wirtschaftlich:
- UI-Code (Screens) ist schwer zu testen (Integration Tests besser)
- Boilerplate (Getters, Setters) ist trivial
- Aufwand vs. Nutzen steigt exponentiell

**Ziel:** 70% Coverage mit Fokus auf **kritischen Code** (Models, Logic, Services)

### Soll ich jeden Screen testen?

**Antwort:** Nein. Screens sind:
- Schwer zu testen (viele Dependencies)
- Ändern sich häufig (UI-Anpassungen)
- Besser mit Integration Tests abgedeckt

**Fokus:** Reusable Widgets & Kritische UI-Komponenten (z.B. Forms)

### Wie teste ich Riverpod StreamProvider?

**Antwort:** Mit `overrideWith()` im `ProviderScope`:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      studentsProvider.overrideWith((ref) => Stream.value([...])),
    ],
    child: MyApp(),
  ),
);
```

### Wann nutze ich Mocks vs. Fakes?

**Mocks:** Für komplexe Dependencies (FirebaseFirestore, HttpClient)  
**Fakes:** Für einfache Interfaces (z.B. In-Memory Repository)

**Beispiel Mock:**
```dart
final mockFirestore = MockFirebaseFirestore();
when(mockFirestore.collection('students')...).thenReturn(...);
```

**Beispiel Fake:**
```dart
class FakeStudentRepository implements StudentRepository {
  final List<Student> _students = [];
  
  @override
  Future<void> addStudent(Student s) async {
    _students.add(s);
  }
  
  @override
  Future<List<Student>> getStudents() async => _students;
}
```

---

## Referenzen

- [Flutter Testing Docs](https://docs.flutter.dev/testing)
- [Riverpod Testing](https://riverpod.dev/docs/cookbooks/testing)
- [Mockito Docs](https://pub.dev/packages/mockito)
- [Test-Driven Development (TDD)](https://en.wikipedia.org/wiki/Test-driven_development)

---

**Letzte Aktualisierung:** 2025-12-29  
**Autor:** GitHub Copilot Agent  
**Version:** 1.0
