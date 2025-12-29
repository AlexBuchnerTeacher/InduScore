# Coding Guidelines (InduScore)

**Version:** 2.0 (Erweitert)  
**Letzte Aktualisierung:** 2025-12-29

Diese Guidelines definieren verbindliche Code-Standards für InduScore. Ziel ist es, eine konsistente, wartbare und skalierbare Codebasis zu gewährleisten.

---

## 1. Architektur-Prinzipien

### 1.1 Single Responsibility Principle (SRP)
- **Jede Datei hat exakt eine Verantwortlichkeit**
- **Keine God-Classes** (alles in einer Datei)
- Bei >300 Zeilen → Datei aufteilen

**✅ Gut:**
```dart
// lib/features/noten/noten_matrix_logic.dart (nur Berechnungen)
class NotenMatrixLogic {
  static double berechneDurchschnitt(List<Grade> grades) { ... }
}

// lib/features/noten/noten_matrix_screen.dart (nur UI)
class NotenMatrixScreen extends ConsumerWidget { ... }
```

**❌ Schlecht:**
```dart
// lib/screens/noten_screen.dart (UI + Logic + Dialogs)
class NotenScreen extends StatefulWidget {
  void _berechneDurchschnitt() { ... } // ❌ Logic im Screen
  Widget _buildDialog() { ... }         // ❌ Dialog im Screen
}
```

### 1.2 Feature-based Struktur
- **Ordner nach Features**, nicht nach Technik
- Neue Features → neuer Ordner in `lib/features/`

**Struktur:**
```
lib/features/noten/
├── noten_matrix_screen.dart     # Screen (UI)
├── noten_matrix_logic.dart      # Business Logic
├── noten_providers.dart         # Riverpod Provider
└── widgets/
    ├── editable_note_cell.dart  # Wiederverwendbar
    └── noten_table_widget.dart
```

### 1.3 Layer-Separation (Dependency Rule)
- **UI → Logic → Data** (einseitig)
- UI darf Logic & Data aufrufen
- Logic darf nur Data aufrufen
- Data kennt UI & Logic NICHT

**✅ Erlaubt:**
```dart
// UI (Screen)
class NotenScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesProvider); // ✅ UI → Data
    final avg = NotenMatrixLogic.berechneDurchschnitt(grades); // ✅ UI → Logic
    return Text('Durchschnitt: $avg');
  }
}

// Logic
class NotenMatrixLogic {
  static double berechneDurchschnitt(List<Grade> grades) { 
    // ✅ Logic nutzt nur Models (Data)
    return grades.fold(0.0, (sum, g) => sum + g.note) / grades.length;
  }
}
```

**❌ Verboten:**
```dart
// Data (Service)
class FirestoreService {
  void showSnackbar(String msg) { // ❌ Data → UI
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

## 2. Datei-Größen & Komplexität

### 2.1 Maximale Zeilenzahlen

| Datei-Typ | Max. LOC | Begründung |
|-----------|----------|------------|
| **Screens** | 300 | Mehr → auslagern in Widgets/Dialogs |
| **Widgets** | 150 | Klein & wiederverwendbar |
| **Logic** | 300 | Fokus auf eine Domäne |
| **Services** | 500 | Firestore CRUD kann umfangreich sein |
| **Models** | 200 | Nur Datenstrukturen, keine Logik |

**Verstöße werden im PR Review abgelehnt!**

### 2.2 Komplexitäts-Metriken

- **Cyclomatic Complexity:** Max. 10 pro Methode
- **Nesting Depth:** Max. 3 Ebenen
- **Method Lines:** Max. 50 Zeilen pro Methode

**Tools:**
```bash
# Linting mit analysis_options.yaml
flutter analyze

# Metrics (optional)
dart pub global activate dart_code_metrics
metrics lib/
```

---

## 3. Naming Conventions

### 3.1 Dateien & Ordner

| Typ | Convention | Beispiel |
|-----|------------|----------|
| **Screens** | `<feature>_screen.dart` | `noten_eingabe_screen.dart` |
| **Widgets** | `<name>_widget.dart` | `editable_note_cell.dart` |
| **Logic** | `<feature>_logic.dart` | `noten_matrix_logic.dart` |
| **Providers** | `<feature>_providers.dart` | `noten_providers.dart` |
| **Services** | `<domain>_service.dart` | `firestore_service.dart` |
| **Models** | `<entity>.dart` | `student.dart`, `grade.dart` |

**Regel:** Snake_case für Dateien, PascalCase für Klassen

### 3.2 Klassen

| Typ | Convention | Beispiel |
|-----|------------|----------|
| **Screens** | `<Feature>Screen` | `NotenEingabeScreen` |
| **Widgets** | `<Name>Widget` | `EditableNoteCellWidget` |
| **Logic** | `<Feature>Logic` | `NotenMatrixLogic` |
| **Services** | `<Domain>Service` | `FirestoreService` |
| **Models** | `<Entity>` | `Student`, `Grade` |
| **Providers** | `<entity>Provider` | `studentsProvider` |

### 3.3 Variablen & Methoden

**Variablen:** camelCase
```dart
final String firstName = 'Max';
final List<Student> activeStudents = [];
```

**Methoden:** camelCase mit Verb
```dart
void addStudent(Student student) { ... }
Future<List<Grade>> fetchGrades() async { ... }
bool isAktiv() => status == StudentStatus.aktiv;
```

**Konstanten:** lowerCamelCase (nicht SCREAMING_SNAKE_CASE)
```dart
const double maxGrade = 6.0;
const int minPassingGrade = 4;
```

**Private:** Prefix `_`
```dart
String _privateField;
void _privateMethod() { ... }
```

### 3.4 Provider-Namen (Riverpod)

| Provider-Typ | Convention | Beispiel |
|--------------|------------|----------|
| **Stream** | `<entity>sProvider` | `studentsProvider` |
| **Future** | `<entity>Provider` | `studentProvider` |
| **State** | `selected<Entity>Provider` | `selectedKlasseIdProvider` |
| **Service** | `<service>Provider` | `firestoreServiceProvider` |

---

## 4. UI Guidelines

### 4.1 Screens

**Regeln:**
- Max. 300 Zeilen
- Nur Darstellung, keine Berechnungen
- Keine direkten Firestore-Calls (nutze Provider)
- Keine Dialogs inline (auslagern in `widgets/dialogs/`)

**Struktur:**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Provider-Watches
    final data = ref.watch(myProvider);
    
    // 2. AsyncValue Handling
    return data.when(
      data: (value) => _buildContent(value),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
  
  Widget _buildContent(MyData data) {
    // 3. Layout
    return Scaffold(
      appBar: AppBar(...),
      body: Column(...),
      floatingActionButton: FloatingActionButton(...),
    );
  }
}
```

### 4.2 Widgets

**Regeln:**
- Max. 150 Zeilen
- Keine Provider-Zugriffe (nur wenn unbedingt nötig)
- Alle Daten via Constructor injizieren
- `const` nutzen wo möglich (Performance)

**✅ Gut (Stateless, wiederverwendbar):**
```dart
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  
  const StudentCard({
    required this.student,
    required this.onTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(student.displayName),
        onTap: onTap,
      ),
    );
  }
}
```

**❌ Schlecht (Provider im Widget):**
```dart
class StudentCard extends ConsumerWidget {
  final String studentId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ❌ Provider-Zugriff im Widget macht es schwer wiederverwendbar
    final student = ref.watch(studentProvider(studentId)).value;
    return Card(...);
  }
}
```

### 4.3 Dialogs

**Regeln:**
- Dialogs in eigenen Dateien (`lib/widgets/dialogs/`)
- Rückgabe via `Navigator.pop(result)`
- Keine Business-Logic im Dialog

**Struktur:**
```dart
// lib/widgets/dialogs/student_edit_dialog.dart
class StudentEditDialog extends StatefulWidget {
  final Student? student; // null = neuer Student
  
  const StudentEditDialog({this.student, super.key});
  
  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  late final TextEditingController _firstNameController;
  
  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.student?.firstName);
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'Neuer Schüler' : 'Schüler bearbeiten'),
      content: TextField(controller: _firstNameController, ...),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Abbrechen
          child: Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            final student = Student(
              id: widget.student?.id ?? '',
              firstName: _firstNameController.text,
              // ...
            );
            Navigator.pop(context, student); // ✅ Rückgabe
          },
          child: Text('Speichern'),
        ),
      ],
    );
  }
}
```

---

## 5. Logic Guidelines

### 5.1 Logic-Dateien

**Regeln:**
- Max. 300 Zeilen
- **Kein `BuildContext`** (pure Dart, kein Flutter)
- Nur statische Methoden oder reine Funktionen
- Keine UI-Imports (`import 'package:flutter/material.dart'` verboten!)

**✅ Gut:**
```dart
// lib/features/noten/noten_matrix_logic.dart
class NotenMatrixLogic {
  /// Berechnet den gewichteten Durchschnitt
  static double berechneGewichtetenDurchschnitt({
    required List<Grade> grades,
    required List<Leistungsnachweis> leistungsnachweise,
  }) {
    if (grades.isEmpty) return 0;
    
    double summe = 0;
    double gewichtungSumme = 0;
    
    for (final grade in grades) {
      final ln = leistungsnachweise.firstWhere((l) => l.id == grade.leistungsnachweisId);
      final noteWithTendenz = _applyTendenz(grade.note, grade.tendenz);
      summe += noteWithTendenz * ln.gewichtung;
      gewichtungSumme += ln.gewichtung;
    }
    
    return gewichtungSumme > 0 ? summe / gewichtungSumme : 0;
  }
  
  static double _applyTendenz(int note, Tendenz tendenz) {
    // ...
  }
}
```

**❌ Schlecht:**
```dart
// ❌ BuildContext in Logic
class NotenMatrixLogic {
  static void showError(BuildContext context, String msg) { // ❌
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### 5.2 Error Handling in Logic

**Regel:** Logic wirft Exceptions, UI fängt sie ab

```dart
// Logic
class NotenMatrixLogic {
  static double berechneDurchschnitt(List<Grade> grades) {
    if (grades.isEmpty) {
      throw ArgumentError('Grades list cannot be empty'); // ✅ Exception werfen
    }
    return grades.fold(0.0, (sum, g) => sum + g.note) / grades.length;
  }
}

// UI
try {
  final avg = NotenMatrixLogic.berechneDurchschnitt(grades);
} on ArgumentError catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Fehler: ${e.message}')),
  );
}
```

---

## 6. State Management (Riverpod)

### 6.1 Provider-Typen

| Use Case | Provider-Typ | Beispiel |
|----------|--------------|----------|
| **Singleton** | `Provider` | Services (Firestore, Auth) |
| **Realtime Data** | `StreamProvider` | Firestore Streams |
| **Async Data** | `FutureProvider` | Einzeldokument laden |
| **Simple State** | `StateProvider` | UI-Flags (selectedId, filter) |
| **Complex State** | `StateNotifierProvider` | Formulare, komplexe UI-States |

### 6.2 Provider in `app_providers.dart`

**Alle Provider zentral registrieren:**
```dart
// lib/providers/app_providers.dart

// Services
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Realtime Data
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents();
});

// Parametrisierte Queries
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>((
  ref,
  klasseId,
) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudentsByKlasse(klasseId);
});

// UI-State
final selectedKlasseIdProvider = StateProvider<String?>((ref) => null);
```

### 6.3 Side-Effects vermeiden

**❌ Verboten:**
```dart
final badProvider = Provider((ref) {
  ref.watch(anotherProvider);
  // ❌ Side-Effect (Firestore-Write)
  FirebaseFirestore.instance.collection('logs').add({
    'timestamp': DateTime.now(),
  });
});
```

**✅ Richtig:**
```dart
// Side-Effects nur in UI-Event-Handlern
ElevatedButton(
  onPressed: () async {
    await ref.read(firestoreServiceProvider).logEvent('button_pressed');
  },
  child: Text('Klick'),
)
```

### 6.4 ConsumerWidget vs. Consumer

**ConsumerWidget:** Gesamtes Widget rebuildet
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider); // ✅ Gesamtes Widget rebuildet
    return Text(data);
  }
}
```

**Consumer:** Nur Teil rebuildet (Performance)
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Static Header'), // ✅ Rebuildet NICHT
        Consumer(
          builder: (context, ref, child) {
            final data = ref.watch(myProvider); // ✅ Nur dieser Teil rebuildet
            return Text(data);
          },
        ),
      ],
    );
  }
}
```

---

## 7. Models

### 7.1 Model-Struktur

**Regeln:**
- Max. 200 Zeilen
- Immutable (final fields)
- `fromFirestore()` + `toFirestore()` Methoden
- `copyWith()` für Updates

**Template:**
```dart
class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String klasseId;
  final DateTime createdAt;
  
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.klasseId,
    required this.createdAt,
  });
  
  /// Firestore → Model
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      klasseId: data['klasseId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  /// Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'klasseId': klasseId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  /// Kopie mit geänderten Feldern
  Student copyWith({
    String? firstName,
    String? lastName,
    String? klasseId,
  }) {
    return Student(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      klasseId: klasseId ?? this.klasseId,
      createdAt: createdAt,
    );
  }
  
  /// Computed Properties (Getters)
  String get displayName => '$firstName $lastName';
  String get sortKey => '${lastName.toLowerCase()}, ${firstName.toLowerCase()}';
}
```

### 7.2 Enums

**Regel:** Enums statt Strings für Status/Typen

**✅ Gut:**
```dart
enum StudentStatus {
  aktiv('Aktiv'),
  ausgetreten('Ausgetreten');
  
  final String label;
  const StudentStatus(this.label);
  
  static StudentStatus fromString(String? value) {
    return StudentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StudentStatus.aktiv,
    );
  }
}
```

**❌ Schlecht:**
```dart
// ❌ String-basiert (Typos möglich)
class Student {
  final String status; // 'aktiv', 'ausgetreten', 'aktiff' (Typo!)
}
```

---

## 8. Services

### 8.1 Firestore-Service

**Regeln:**
- Zentrale CRUD-Logik in `firestore_service.dart`
- Streams für Realtime-Updates
- Async/Await für Single Queries
- Error Handling mit try-catch

**Template:**
```dart
class FirestoreService {
  final FirebaseFirestore _firestore;
  
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Stream (Realtime)
  Stream<List<Student>> getStudents() {
    return _firestore.collection('students').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
    );
  }
  
  // Future (Single Query)
  Future<Student> getStudent(String id) async {
    final doc = await _firestore.collection('students').doc(id).get();
    if (!doc.exists) {
      throw Exception('Student not found');
    }
    return Student.fromFirestore(doc);
  }
  
  // Create
  Future<String> addStudent(Student student) async {
    final docRef = await _firestore.collection('students').add(student.toFirestore());
    return docRef.id;
  }
  
  // Update
  Future<void> updateStudent(Student student) async {
    await _firestore.collection('students').doc(student.id).update(student.toFirestore());
  }
  
  // Delete
  Future<void> deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }
}
```

### 8.2 Auth-Service

**Regeln:**
- Firebase Auth Wrapper
- Deutsche Fehlermeldungen
- Error Handling für alle Auth-Methoden

---

## 9. Error Handling

### 9.1 Exception vs. Error

**Exception:** Erwartbare Fehler (User-Input, Network)
```dart
if (email.isEmpty) {
  throw ArgumentError('Email darf nicht leer sein');
}
```

**Error:** Programmierfehler (Bugs)
```dart
assert(students.isNotEmpty, 'Students should never be empty here');
```

### 9.2 Try-Catch Pattern

**UI-Layer:**
```dart
try {
  await ref.read(firestoreServiceProvider).addStudent(student);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Schüler gespeichert')),
  );
} on FirebaseException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Fehler: ${e.message}')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unbekannter Fehler: $e')),
  );
}
```

---

## 10. Kommentare & Dokumentation

### 10.1 Wann kommentieren?

**✅ Kommentieren:**
- Public APIs (Methoden, Klassen)
- Komplexe Algorithmen
- Workarounds / Hacks
- TODOs (mit Ticket-Referenz)

**❌ NICHT kommentieren:**
- Offensichtlicher Code
- Variablen-Namen (sollten selbsterklärend sein)

**✅ Gut:**
```dart
/// Berechnet den gewichteten Durchschnitt aller Noten eines Schülers.
/// 
/// Tendenzen werden wie folgt umgerechnet:
/// - Plus (+): -0.3
/// - Neutral (·): 0
/// - Minus (-): +0.3
/// 
/// Returns 0 wenn [grades] leer ist.
double berechneGewichtetenDurchschnitt(List<Grade> grades) { ... }
```

**❌ Schlecht:**
```dart
// Addiert 1 zu i
i = i + 1; // ❌ Offensichtlich
```

### 10.2 TODOs

**Format:** `// TODO(Ticket): Beschreibung`

```dart
// TODO(#123): Pagination implementieren
// FIXME(#456): Bug bei leerer Liste
// HACK: Workaround für Flutter Web Issue #789
```

---

## 11. Testing

**Siehe ausführliche Dokumentation:** [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md)

**Quick Rules:**
- Jedes Model hat Unit Tests
- Kritische Logic hat Unit Tests
- Services werden gemockt (Mockito)
- Neue Features benötigen Tests (PR-Pflicht)

---

## 12. Commits & Versioning

### 12.1 Commit-Messages

**Format:** `<type>: <description>`

| Typ | Verwendung | Beispiel |
|-----|------------|----------|
| `feat` | Neues Feature | `feat: Favoriten-Klassen im Dashboard` |
| `fix` | Bugfix | `fix: Tendenz-Berechnung bei Note 1` |
| `refactor` | Code-Umstrukturierung | `refactor: Extract StudentEditDialog` |
| `docs` | Dokumentation | `docs: Update ARCHITECTURE.md` |
| `test` | Tests hinzufügen | `test: Add unit tests for NotenMatrixLogic` |
| `style` | Formatierung | `style: Run dart format` |
| `chore` | Build/Tooling | `chore: Update dependencies` |

**✅ Gut:**
```
feat: Add Zeitgruppen-Filter im Drawer

- StateProvider für ausgewählte ZG
- Filter-Chips in RBS-Drawer
- Dashboard zeigt nur Klassen der gewählten ZG

Closes #42
```

**❌ Schlecht:**
```
update stuff
fixed bug
WIP
```

### 12.2 Versionierung

**Semantic Versioning:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking Changes
- **MINOR:** Neue Features (abwärtskompatibel)
- **PATCH:** Bugfixes

**Sync:** `pubspec.yaml` + `VERSION` + `lib/version.dart` müssen identisch sein!

---

## 13. Code-Review Checkliste

**Vor PR-Erstellung:**
- [ ] `flutter analyze` ohne Fehler
- [ ] `flutter test` alle Tests grün
- [ ] Keine Dateien >300 LOC (Screens/Logic) bzw. >150 LOC (Widgets)
- [ ] Neue Features haben Tests
- [ ] Kommentare für komplexe Logik
- [ ] Commit-Messages folgen Convention

**Reviewer prüft:**
- [ ] SRP eingehalten
- [ ] Layer-Separation eingehalten
- [ ] Keine Firestore-Calls im UI
- [ ] Naming Conventions
- [ ] Error Handling vorhanden
- [ ] Tests vorhanden & sinnvoll

---

## 14. Tooling

### 14.1 Linting

**Konfiguration:** `analysis_options.yaml`
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    deprecated_member_use: info
    unnecessary_underscores: info

linter:
  rules:
    # Empfohlene zusätzliche Rules (optional):
    # - prefer_single_quotes
    # - prefer_const_constructors
    # - avoid_print
```

**Run:**
```bash
flutter analyze
```

### 14.2 Formatting

**Run:**
```bash
dart format lib/ test/
```

**IDE:** Auto-Format on Save aktivieren (VS Code / IntelliJ)

### 14.3 Dependencies

**Update:**
```bash
flutter pub upgrade --major-versions
```

**Audit:**
```bash
flutter pub outdated
```

---

## 15. Performance Best Practices

### 15.1 Const Constructors

**✅ Nutzen wo möglich:**
```dart
const Text('Hello'); // ✅ Wird nur 1x erstellt
```

**❌ Vermeiden:**
```dart
Text('Hello'); // ❌ Wird bei jedem Build neu erstellt
```

### 15.2 Provider-Watches minimieren

**✅ Select für granulare Watches:**
```dart
final firstName = ref.watch(studentProvider.select((s) => s.firstName));
```

**❌ Gesamtes Objekt watchen:**
```dart
final student = ref.watch(studentProvider); // ❌ Rebuildet bei jedem Feld
```

### 15.3 ListView.builder

**✅ Lazy Loading:**
```dart
ListView.builder(
  itemCount: students.length,
  itemBuilder: (context, index) => StudentCard(student: students[index]),
)
```

**❌ Eager Loading:**
```dart
ListView(
  children: students.map((s) => StudentCard(student: s)).toList(), // ❌ Alle auf einmal
)
```

---

## 16. Security Best Practices

### 16.1 Keine Secrets im Code

**❌ Verboten:**
```dart
const apiKey = 'abc123...'; // ❌ Secret im Code
```

**✅ Environment Variables:**
```dart
final apiKey = const String.fromEnvironment('API_KEY');
```

### 16.2 Firestore Rules

**Regel:** Niemals `allow read, write: if true;`

**Minimum:**
```javascript
allow read, write: if request.auth != null; // ✅ Nur eingeloggte User
```

**Besser:**
```javascript
// Nur eigene Daten lesen/schreiben
allow read, write: if request.auth.uid == userId;
```

### 16.3 Input Validation

**Immer validieren:**
```dart
if (email.isEmpty || !email.contains('@')) {
  throw ArgumentError('Ungültige Email');
}
```

---

## Zusammenfassung (Quick Reference)

| Regel | Max LOC | Verboten |
|-------|---------|----------|
| **Screens** | 300 | Firestore-Calls, Berechnungen |
| **Widgets** | 150 | Provider-Zugriffe (meist) |
| **Logic** | 300 | BuildContext, UI-Imports |
| **Services** | 500 | UI-Code |
| **Models** | 200 | Business-Logic |

**Golden Rules:**
1. Single Responsibility
2. UI → Logic → Data (einseitig)
3. Keine Firestore-Logik im UI
4. Keine UI-Code in Logic
5. Tests für neue Features

---

**Letzte Aktualisierung:** 2025-12-29  
**Autor:** GitHub Copilot Agent  
**Version:** 2.0
