# Coding Guidelines (InduScore)

**Version:** 2.0 (erweitert gemäß Issue #51 Finding F02)  
**Letzte Aktualisierung:** 2025-12-29  
**Basis:** Tatsächliche Code-Patterns aus InduScore Repository

> **Hinweis:** Diese Guidelines basieren auf der bestehenden Codebase und definieren verbindliche Standards für alle Entwickler.

---

## Inhaltsverzeichnis
1. [Naming Conventions](#1-naming-conventions)
2. [Architekturregeln](#2-architekturregeln)
3. [State Management (Riverpod)](#3-state-management-riverpod)
4. [Error Handling](#4-error-handling)
5. [Async & Streams](#5-async--streams)
6. [Testing Standards](#6-testing-standards)
7. [Code Style](#7-code-style)
8. [Security & Privacy](#8-security--privacy)
9. [Dependency Policy](#9-dependency-policy)

---

## 1. Naming Conventions

### 1.1 Dateien & Ordner
**Regel:** `snake_case` für alle Dateien und Ordner

✅ **KORREKT:**
```
lib/screens/noten_eingabe_screen.dart
lib/services/firestore_service.dart
lib/features/noten/widgets/editable_note_cell.dart
```

❌ **FALSCH:**
```
lib/screens/NotenEingabeScreen.dart  # PascalCase
lib/services/FirestoreService.dart   # PascalCase
lib/models/students.dart             # Plural für Model
```

**Konventionen:**
- Screens: `*_screen.dart` (z.B. `klassen_screen.dart`)
- Services: `*_service.dart` (z.B. `auth_service.dart`)
- Models: Singular (z.B. `student.dart`, nicht `students.dart`)
- Widgets: beschreibender Name (z.B. `editable_note_cell.dart`)

### 1.2 Classes & Widgets
**Regel:** `PascalCase` für alle Classes und Widgets

✅ **KORREKT:**
```dart
class KlassenScreen extends ConsumerStatefulWidget { }
class FirestoreService { }
class RBSButton extends StatelessWidget { }
enum UserRole { admin, lehrer, ausbilder, schueler }
```

❌ **FALSCH:**
```dart
class klassenScreen { }  # camelCase
class firestore_service { }  # snake_case
```

**Private Classes:**
```dart
class _KlassenScreenState extends ConsumerState<KlassenScreen> { }
class _ImportPreviewDialog extends StatelessWidget { }
```

### 1.3 Variables & Methods
**Regel:** `camelCase` für alle Variablen und Methoden

✅ **KORREKT:**
```dart
// Variables
String klasseId;
AppUser? currentUser;
bool isLoggedIn;

// Private fields
final FirebaseFirestore _db = FirebaseFirestore.instance;
StreamSubscription<User?>? _authSubscription;

// Methods
Future<Student> getStudent(String id) async { }
void showKlasseDialog() { }
```

**Konstanten:**
```dart
// lowerCamelCase für lokale Konstanten
const headlineFont = 'Roboto Condensed';
const dynamicRed = Color(0xFFFF5E35);

// SCREAMING_SNAKE_CASE für globale Konstanten
const int MAX_FILE_SIZE_MB = 10;
```

### 1.4 Provider Naming (Riverpod-spezifisch)
**Regel:** Immer `*Provider` Suffix

✅ **KORREKT:**
```dart
final studentsProvider = StreamProvider<List<Student>>(...);
final currentUserProvider = StreamProvider<AppUser?>(...);
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>(...);
final zeitgruppenFilterProvider = StateProvider<ZeitGruppenFilter>(...);
```

❌ **FALSCH:**
```dart
final students = StreamProvider<List<Student>>(...);  # Fehlendes Provider-Suffix
final currentUserStream = StreamProvider<AppUser?>(...);  # Stream-Suffix nicht nötig
```

---

## 2. Architekturregeln

### 2.1 Layering (STRIKT!)

**Regel:** Strikte Trennung zwischen UI, State, Service und Data Layer

```
┌─────────────────────────────────────┐
│  UI Layer (Screens/Widgets)        │  ← Nur Darstellung
│  lib/screens/, lib/features/       │  ← ref.watch(provider)
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  State Layer (Riverpod Providers)  │  ← Zustandsverwaltung
│  lib/providers/                    │  ← Stream-Transformation
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  Service Layer                     │  ← Business Logic
│  lib/services/                     │  ← KEINE UI-Imports!
└────────────┬────────────────────────┘
             │ (nutzt)
┌────────────▼────────────────────────┐
│  Data Layer (Firestore)            │  ← Nur via Services
│  Firebase Cloud Firestore          │
└─────────────────────────────────────┘
```

**Regeln:**
1. **UI → Provider → Service → Firestore** (niemals Layer überspringen!)
2. **Services dürfen KEIN `BuildContext` importieren**
3. **Widgets dürfen KEINE direkten Firestore-Queries ausführen**
4. **Provider sind readonly** (Schreibzugriff nur via Service-Methoden)

✅ **KORREKT:**
```dart
// UI nutzt Provider (lib/screens/home_screen.dart)
@override
Widget build(BuildContext context) {
  final klassenAsync = ref.watch(klassenProvider);
  final currentUser = ref.watch(currentAppUserProvider);
  // ...
}

// Service hat KEINE UI-Imports (lib/services/firestore_service.dart)
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
// KEIN import 'package:flutter/material.dart'!
```

❌ **FALSCH:**
```dart
// Direkter Firestore-Zugriff in Widget
FirebaseFirestore.instance.collection('students').get();

// BuildContext in Service
class FirestoreService {
  void showError(BuildContext context, String message) { }  // ❌ VERBOTEN!
}
```

### 2.2 Feature-Struktur
**Regel:** Große Features in `lib/features/<feature_name>/` strukturieren

```
lib/features/<feature_name>/
├── <feature_name>_screen.dart     # Haupt-Screen
├── widgets/                       # Feature-spezifische Widgets
│   └── <widget_name>.dart
├── logic/                         # Business Logic (optional)
│   └── <logic_name>.dart
└── models/                        # Feature-spezifische Models (optional)
```

**Beispiel:**
```
lib/features/noten/
├── noten_matrix_logic.dart
├── noten_matrix_controller.dart
└── widgets/
    ├── noten_matrix_view.dart
    ├── editable_note_cell.dart
    └── statistics_cards.dart
```

### 2.3 File Size Limits
**Regel:** Keine großen Dateien, die schwer zu warten sind

| Datei-Typ | Max. Zeilen | Begründung |
|-----------|-------------|------------|
| Screens | 500 LOC | Leichtere Wartung, bessere Testbarkeit |
| Widgets | 200 LOC | Wiederverwendbarkeit |
| Services | 800 LOC | Business Logic kapseln |
| Models | 300 LOC | Datenstrukturen kompakt halten |

❌ **Verstöße beheben durch:**
- Widget-Extraktion (große Screens → kleinere Widgets)
- Service-Aufspaltung (große Services → mehrere fokussierte Services)
- Logic-Extraktion (Komplexe Berechnungen → eigene Dateien)

---

## 3. State Management (Riverpod)

### 3.1 Provider-Typen Wahl

| Provider-Typ | Wann nutzen? | Beispiel |
|--------------|-------------|----------|
| `Provider<T>` | Singleton-Services, Computed Values | `firestoreServiceProvider` |
| `StreamProvider<T>` | Firestore Realtime-Daten | `studentsProvider` |
| `FutureProvider<T>` | One-Time Async Load | `appVersionProvider` |
| `StateProvider<T>` | UI-State (Filter, Selection) | `zeitgruppenFilterProvider` |
| `*.family<T, Arg>` | Provider mit Parameter | `studentsByKlasseProvider` |

✅ **KORREKT:**
```dart
// Singleton-Service
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// Realtime-Daten
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents();
});

// Family-Provider mit Parameter
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>(
  (ref, klasseId) {
    final service = ref.watch(firestoreServiceProvider);
    return service.getStudentsByKlasse(klasseId);
  },
);
```

### 3.2 ref.watch vs ref.read vs ref.listen

**Regel:**
- `ref.watch()`: In `build()` für reaktive Updates
- `ref.read()`: In Event-Handlern (onPressed, onTap)
- `ref.listen()`: Für Side-Effects (Navigation, SnackBar)

✅ **KORREKT:**
```dart
@override
Widget build(BuildContext context) {
  final klassenAsync = ref.watch(klassenProvider);  // ← Reaktiv!
  
  return ElevatedButton(
    onPressed: () {
      final service = ref.read(firestoreServiceProvider);  // ← One-Time!
      service.createKlasse(...);
    },
  );
}
```

❌ **FALSCH:**
```dart
ElevatedButton(
  onPressed: () {
    final service = ref.watch(firestoreServiceProvider);  // ❌ Rebuild bei jedem Klick!
  },
);
```

### 3.3 AsyncValue Pattern

**Regel:** Nutze `.when()` oder `.maybeWhen()` für AsyncValue

✅ **KORREKT:**
```dart
return currentUser.maybeWhen(
  data: (user) => user?.rolle == UserRole.admin,
  orElse: () => false,
);

return klassenAsync.when(
  data: (klassen) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Fehler: $err'),
);
```

❌ **FALSCH:**
```dart
return currentUser.value?.rolle == UserRole.admin;  // ❌ .value kann Exception werfen!
```

---

## 4. Error Handling

### 4.1 Exception vs Result Pattern

**Regel:** Nutze Exceptions für echte Fehler, nicht für Flow-Control

✅ **KORREKT:**
```dart
// Exception für Fehler
Future<Student> getStudent(String id) async {
  final doc = await _students.doc(id).get();
  if (!doc.exists) {
    throw Exception('Student mit ID $id nicht gefunden');
  }
  return Student.fromFirestore(doc);
}

// Exception-Handling mit deutschen Messages
String _handleAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'Kein Benutzer mit dieser E-Mail gefunden.';
    case 'wrong-password':
      return 'Falsches Passwort.';
    default:
      return 'Anmeldefehler: ${e.message}';
  }
}
```

### 4.2 User-Feedback Pattern

**Regel:** Nutze `RBSSnackBar` Helper (Issue #51 F05)

✅ **KORREKT:**
```dart
// Erfolg
RBSSnackBar.show(
  context,
  'Erfolgreich gespeichert',
  type: RBSSnackBarType.success,
);

// Fehler
RBSSnackBar.show(
  context,
  'Fehler beim Speichern: ${e.message}',
  type: RBSSnackBarType.error,
);
```

❌ **FALSCH (veraltet):**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gespeichert')),  // ❌ Nicht mehr nutzen!
);
```

---

## 5. Async & Streams

### 5.1 Stream Lifecycle

**Regel:** Alle StreamControllers/Subscriptions in `dispose()` canceln

✅ **KORREKT:**
```dart
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

### 5.2 Firestore Streams

**Regel:** Nutze StreamProvider statt manuelle Subscriptions

✅ **KORREKT:**
```dart
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents();  // ← Riverpod managed Lifecycle!
});
```

❌ **FALSCH:**
```dart
StreamSubscription? _sub;
void initState() {
  _sub = FirebaseFirestore.instance
    .collection('students')
    .snapshots()
    .listen(...);  // ❌ Fehleranfällig, Riverpod ist besser!
}
```

---

## 6. Testing Standards

### 6.1 Testpyramide (Soll-Verteilung)

```
        ▲
       /│\      10% Integration Tests
      / │ \     
     /  │  \    20% Widget Tests
    /   │   \   
   /    │    \  70% Unit Tests
  /_____|_____\
```

**Coverage-Ziele:**
- **Models:** 90%+ (einfach zu testen)
- **Services:** 80%+ (Business Logic)
- **Providers:** 70%+ (Glue Code)
- **Screens:** 50%+ (UI-Tests aufwändiger)
- **Gesamt:** 60%+ (aktuell 51.71%)

### 6.2 Mocking-Strategie

**Regel:** Mockito für Services, Fake Firestore für Integration

✅ **KORREKT:**
```dart
// Unit-Test mit Mock
class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  test('getStudent returns student', () async {
    final mock = MockFirestoreService();
    when(mock.getStudent('123')).thenAnswer((_) async => testStudent);
    // ...
  });
}
```

### 6.3 Widget-Test Pattern

✅ **KORREKT:**
```dart
testWidgets('ProfileScreen shows user data', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppUserProvider.overrideWith((ref) => testUser),
      ],
      child: MaterialApp(home: ProfileScreen()),
    ),
  );
  
  expect(find.text(testUser.displayName), findsOneWidget);
});
```

---

## 7. Code Style

### 7.1 Const Usage

**Regel:** Verwende `const` wo immer möglich (Performance!)

✅ **KORREKT:**
```dart
const SizedBox(height: RBSSpacing.md)
const Text('Anmelden')
const Icon(Icons.add)
```

### 7.2 Kommentare

**Regel:** 
- Docstrings für public API (///)
- Inline-Kommentare nur für komplexe Logik
- KEIN auskommentierter Code

✅ **KORREKT:**
```dart
/// Berechnet die Durchschnittsnote eines Schülers
/// 
/// Berücksichtigt nur Noten mit [isBerücksichtigt] = true
/// und gewichtet nach Leistungsnachweis-Typ.
double calculateAverage(List<Grade> grades) { }
```

### 7.3 TODO-Policy

**Regel:** TODOs nur mit Issue-Nummer

✅ **KORREKT:**
```dart
// TODO(#123): Implement pagination for large classes
```

❌ **FALSCH:**
```dart
// TODO: fix this later  // ❌ Keine Verantwortlichkeit!
```

---

## 8. Security & Privacy

### 8.1 PII-Logging Verbot

**Regel:** NIEMALS persönliche Daten loggen

✅ **KORREKT:**
```dart
debugPrint('Student ${student.id} gespeichert');
debugPrint('Note für LN ${leistungsnachweisId}: ${grade.value}');
```

❌ **FALSCH:**
```dart
debugPrint('Student ${student.displayName} gespeichert');  // ❌ PII!
debugPrint('Email: ${user.email}');  // ❌ PII!
```

**Erlaubt zu loggen:**
- IDs (studentId, klasseId, userId)
- Enums (UserRole, StudentStatus)
- Zahlen (Noten, Counts)

**VERBOTEN zu loggen:**
- Namen (firstName, lastName, displayName)
- Emails
- Adressen

### 8.2 Firestore Rules

**Regel:** Granulare Berechtigungen, kein globaler Zugriff

✅ **KORREKT:**
```javascript
match /students/{studentId} {
  allow read: if isLoggedIn();
  allow write: if isAdmin() || isLehrer();
}
```

---

## 9. Dependency Policy

### 9.1 Neue Dependencies

**Regel:** Neue Packages nur nach Approval, mit Begründung

**Checklist:**
- [ ] Package ist aktiv maintained (letztes Update <6 Monate)
- [ ] Package hat >500 Likes auf pub.dev
- [ ] Keine Breaking Changes in letzter Version
- [ ] License kompatibel (MIT, BSD, Apache)
- [ ] Keine Sicherheitswarnungen

### 9.2 Version Pinning

**Regel:** Exakte Versionen für kritische Packages

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^3.0.3  # ← Caret-Range OK für stable packages
  firebase_core: 3.14.0     # ← Exakt für kritische Firebase-Packages
```

---

## 10. Commit Messages

**Regel:** Conventional Commits Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: Neue Features
- `fix`: Bugfixes
- `refactor`: Code-Umstrukturierung ohne Funktionsänderung
- `docs`: Dokumentation
- `test`: Tests hinzufügen/ändern
- `chore`: Build-Tasks, Dependencies
- `ci`: CI/CD-Änderungen

✅ **KORREKT:**
```
feat(klassen): Add PDF import for class rosters

Implements PDF parsing with pdfjs_flutter package.
Supports both RBS and generic CSV exports.

Closes #42
```

❌ **FALSCH:**
```
updated stuff  # ❌ Zu vage
Fix  # ❌ Kein Scope
```

---

## Enforcement

Diese Guidelines werden durch folgende Mechanismen enforced:

1. **CI-Checks:**
   - `flutter analyze` mit strikten Lints
   - `flutter test --coverage` mit min. 50% Threshold
   - `dart format --set-exit-if-changed`

2. **Pre-Commit Hooks:**
   - Auto-Format bei Commit
   - Lint-Check

3. **Code Reviews:**
   - Mindestens 1 Approval erforderlich
   - Guidelines-Checklist in PR-Template

4. **Dependabot:**
   - Wöchentliche Dependency-Updates
   - Automatische Security-Patches

---

**Bei Fragen zu diesen Guidelines:** Issue öffnen mit Label `documentation`
