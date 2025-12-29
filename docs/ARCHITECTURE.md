# InduScore - Architektur-Dokumentation

## Übersicht

InduScore ist eine Flutter-Webanwendung für die Notenverwaltung an Berufsschulen. Die Anwendung folgt einer **Feature-based Architecture** mit klarer Layer-Trennung und nutzt **Riverpod** für State Management.

**Version:** 0.16.0  
**Framework:** Flutter 3.38.2 (Web)  
**Language:** Dart 3.10.0  
**Build Date:** 2025-12-29

---

## Architektur-Prinzipien

### 1. Feature-based Structure
Die Anwendung ist nach fachlichen Features organisiert, nicht nach technischen Schichten:

```
lib/
├── core/                    # Gemeinsame Basis-Komponenten
├── features/                # Feature-Module (Domain-orientiert)
│   ├── dashboard/
│   ├── noten/
│   ├── klassen/
│   ├── faecher/
│   ├── schueler/
│   └── leistungsnachweise/
├── models/                  # Datenmodelle (App-weit)
├── providers/               # Riverpod State Provider (App-weit)
├── screens/                 # Legacy Screens (schrittweise in features/ migrieren)
├── services/                # Backend-Services (Firestore, Auth, etc.)
└── widgets/                 # Wiederverwendbare UI-Komponenten
```

### 2. Layered Architecture (innerhalb Features)

Jedes Feature folgt einer 3-Schichten-Architektur:

```
Feature (z.B. noten/)
├── Presentation Layer (UI)
│   ├── *_screen.dart        # Screens (300 LOC max)
│   └── widgets/*_widget.dart# UI-Widgets (150 LOC max)
├── Business Logic Layer
│   ├── *_logic.dart         # Geschäftslogik (300 LOC max, kein BuildContext)
│   └── *_providers.dart     # Riverpod State Provider
└── Data Layer
    └── (via services/)      # Firestore, Auth (zentral in services/)
```

**Abhängigkeitsregeln (Dependency Rule):**
- **UI → Logic → Data** (einseitig)
- UI darf Logic & Data aufrufen
- Logic darf nur Data aufrufen
- Data kennt UI & Logic NICHT

### 3. Single Responsibility Principle (SRP)

Jede Datei hat **exakt eine Verantwortlichkeit**:
- **Screens:** Routing, Layout, User Input
- **Widgets:** Wiederverwendbare UI-Komponenten
- **Logic:** Berechnungen, Validierung, Aggregation
- **Services:** Firebase CRUD, Auth, Export/Import
- **Models:** Datenstrukturen, Serialisierung
- **Providers:** State Management, Dependency Injection

---

## Tech Stack

### Frontend
- **Flutter 3.38.2** (Web-optimiert)
- **Dart 3.10.0** (Sound Null Safety)
- **Material Design 3** + **RBS Styleguide 1.2** (München)

### State Management
- **Riverpod 3.0.3** (Consumer-based)
  - `Provider` für Singletons (Services)
  - `StateProvider` für einfache UI-States
  - `StreamProvider` für Firestore Realtime Streams
  - `FutureProvider` für asynchrone Daten
  - `FutureProvider.family` für parametrisierte Queries

### Backend
- **Firebase Core 4.2.1**
- **Firebase Auth 6.1.2** (Email/Password)
- **Cloud Firestore 6.1.0** (NoSQL Database)
- **Firebase Hosting** (CI/CD Deployment)

### Routing
- **go_router 17.0.0** (Declarative Routing)
- Rollenbasierte Navigation Guards
- Deep-Linking Support

### UI/UX
- **google_fonts 6.3.2** (RBS Typography)
- **RBS Styleguide 1.2** (München Corporate Design)
- Responsive Web-Layout (Desktop & Mobile)

### Export/Import
- **syncfusion_flutter_pdf 25.1.39** (PDF Export)
- **file_picker 8.1.3** (CSV/PDF Import)
- **intl 0.19.0** (Datum/Zahlen-Formatierung)

---

## Datenfluss

### 1. Realtime Daten (Firestore Streams)

```
Firestore DB
    ↓ Stream (onSnapshot)
FirestoreService.getXXX()
    ↓ Stream<List<Model>>
StreamProvider (Riverpod)
    ↓ AsyncValue<List<Model>>
ConsumerWidget
    ↓ when(data: ..., loading: ..., error: ...)
UI Widget
```

**Beispiel:**
```dart
// Provider (app_providers.dart)
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents();
});

// Screen (UI)
class StudentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    return studentsAsync.when(
      data: (students) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### 2. CRUD-Operationen (User-Interaktion)

```
User Input (Button, TextField)
    ↓
UI Event Handler (onPressed, onSubmitted)
    ↓ ref.read(firestoreServiceProvider)
FirestoreService.createXXX() / updateXXX()
    ↓ await firestore.collection(...).add(...)
Firestore DB (Write)
    ↓ onSnapshot Event
StreamProvider (Auto-Update)
    ↓
UI Widget (Reaktives Re-Render)
```

**Optimistic Updates:**
- Matrix-Screens nutzen lokale State-Updates für sofortige UI-Reaktion
- Firestore-Sync erfolgt im Hintergrund
- Bei Fehler: Rollback & Error-Snackbar

### 3. Authentifizierung

```
Login Screen (Email + Password)
    ↓
AuthService.signInWithEmailPassword()
    ↓
FirebaseAuth.signInWithEmailAndPassword()
    ↓
authStateProvider (StreamProvider)
    ↓
GoRouter Redirect (/ → /login wenn nicht eingeloggt)
    ↓
Permission Guards (check Rolle)
```

---

## Module & Features

### Core Module (`lib/core/`)

**Zweck:** Gemeinsame Basis-Komponenten für alle Features

- **`theme/rbs_theme.dart`**  
  RBS Styleguide 1.2 (München) – Corporate Design mit Farbpaletten, Typography, Spacing

- **`widgets/rbs_components.dart`**  
  Wiederverwendbare RBS-konforme UI-Komponenten (Buttons, Cards, etc.)

### Feature: Dashboard (`lib/features/dashboard/`)

**Zweck:** Übersicht für Lehrer – Klassen, Nachschreiber, Statistiken

- **Widgets:**
  - `klassen_chips.dart` – Favoriten-Klassen als Chips
  - `nachschreiber_section.dart` – 3-Stufen-Eskalation (Gelb/Orange/Rot)
  - `statistics_cards.dart` – KPIs (Schüler-Anzahl, LN-Anzahl, etc.)

- **State:**
  - Global: Zeitgruppen-Filter (ZG1/ZG2/ZG3)
  - Favoriten-Klassen (aus AppUser-Model)

### Feature: Noten (`lib/features/noten/`)

**Zweck:** Zentrale Notenerfassung & -übersicht

- **Screens:**
  - `noten_eingabe_screen.dart` (Legacy, in screens/)
  - `noten_uebersicht_screen.dart` (Legacy, in screens/)

- **Widgets:**
  - `noten_matrix_view.dart` (1137 LOC ⚠️) – Universelle Matrix (3 Modi)
  - `noten_table_widget.dart` – Tabellen-Rendering
  - `faecher_matrix_widget.dart` – Fächer-Pivot
  - `student_subject_card.dart` – Mobile-Ansicht
  - `editable_note_cell.dart` – Inline-Editing

- **Logic:**
  - `noten_matrix_logic.dart` – Notenberechnung (Tendenz-Handling, Durchschnitte)

- **Features:**
  - Excel-Style Noteneingabe (Tendenzen: +, ·, -)
  - Optimistic Updates (Sofortige UI-Reaktion)
  - Sticky Headers (beim Scrollen)
  - LN-Befreiungen (Schüler als "nicht relevant" markieren)

### Feature: Klassen (`lib/features/klassen/`)

**Zweck:** Klassenverwaltung (Beruf, Schuljahr, Zeitgruppe)

- **Screen:** `klassen_detail_screen.dart`
- **Legacy:** `klassen_screen.dart` (1268 LOC ⚠️ – größte Datei!)

- **Model:** `Klasse` (klasseId, name, berufId, schuljahr, zeitgruppe)
- **Favoriten:** Lehrer können Klassen markieren → Dashboard-Filter

### Feature: Fächer (`lib/features/faecher/`)

**Zweck:** Fächerverwaltung (Lernfelder für Berufsschulen)

- **Screen:** `faecher_detail_screen.dart`
- **Legacy:** `faecher_screen.dart` (786 LOC)

- **Model:** `Subject` (name, shortName, color, credits, category)
- **Kategorien:** Lernfeld, Allgemein, Sport

### Feature: Schüler (`lib/features/schueler/`)

**Zweck:** Schülerverwaltung mit ASV-Import

- **Screen:** `schueler_detail_screen.dart`
- **Legacy:** `schueler_screen.dart` (732 LOC)

- **Model:** `Student` (firstName, lastName, klasseId, asvId, status, Befreiungen)
- **Status:** Aktiv / Ausgetreten
- **Import:** CSV-Import mit Spalten-Mapping (ASV-kompatibel)

### Feature: Leistungsnachweise (`lib/features/leistungsnachweise/`)

**Zweck:** Leistungsnachweise (Schulaufgaben, Kurzarbeiten, etc.)

- **Legacy:** `leistungsnachweise_screen.dart` (747 LOC)

- **Model:** `Leistungsnachweis` (typ, gewichtung, datum, createdBy)
- **Typen:** Schulaufgabe, Kurzarbeit, Mündlich, Projekt, Sonstige
- **Ownership:** Tracking wer welchen LN erstellt hat (createdBy)

---

## Services (`lib/services/`)

### FirestoreService (`firestore_service.dart`, 829 LOC)

**Zweck:** Zentrale CRUD-Logik für alle Firestore-Collections

**Collections:**
- `users` – AppUser (rolle, kuerzel, favoriteKlasseIds)
- `students` – Schüler (ASV-Felder)
- `classes` – Klassen
- `subjects` – Fächer
- `grades` – Noten (note, tendenz, schuelerKuerzel)
- `leistungsnachweise` – Leistungsnachweise (gewichtung, datum)
- `berufe` – Berufe (name, abbreviation)
- `ln_exemptions` – LN-Befreiungen (schuelerId, leistungsnachweisId)

**Patterns:**
- Streams für Realtime-Updates (`getStudents()`, `getGrades()`, etc.)
- Async-Queries für Einzeldokumente (`getStudent(id)`)
- Batch-Writes für Transaktionen

### AuthService (`auth_service.dart`, 527 LOC)

**Zweck:** Firebase Auth Wrapper + Fehlerbehandlung

**Methoden:**
- `signInWithEmailPassword()` – Login
- `registerWithEmailPassword()` – Registrierung (nicht aktiv genutzt)
- `signOut()` – Logout
- `sendPasswordResetEmail()` – Passwort-Reset
- `changePassword()` – Passwort ändern (Re-Auth erforderlich)

**Error Handling:**
- `_handleAuthException()` – Firebase Error Codes → Deutsche Fehlermeldungen

### PDFExportService (`pdf_export_service.dart`, 427 LOC)

**Zweck:** PDF-Export (Notenblätter, Klassenlisten)

**Features:**
- Syncfusion PDF-Generierung
- RBS-Design (Fonts, Farben)
- Tabellen-Layout mit Durchschnitten

### NOIExportService (`noi_export_service.dart`, 711 LOC)

**Zweck:** Export für ASV (Amtliche Schulverwaltung Bayern)

**Formate:**
- XML (NotenImportOnline-Format)
- CSV (Backup)

**Features:**
- Mapping Schüler → ASV-ID
- Fächer → Lernfeld-Codes
- Zeugnisnoten-Berechnung

### CSVImportService (`csv_import_service.dart`, 1094 LOC)

**Zweck:** CSV-Import für Schüler & Fächer

**Features:**
- Auto-Erkennung Spalten (Vorname, Nachname, etc.)
- Duplikat-Prüfung
- ASV-Felder Mapping

### PDFImportService (`pdf_import_service.dart`, 581 LOC)

**Zweck:** PDF-Import (Klassenleiter-Listen)

**Features:**
- Text-Extraktion mit syncfusion_flutter_pdf
- Pattern-Matching (RegEx)
- Merge-Logik (Duplikate erkennen)

---

## State Management (Riverpod)

### Provider-Strategie

**1. Service-Provider (Singleton)**
```dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
```

**2. Stream-Provider (Realtime Data)**
```dart
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudents();
});
```

**3. Family-Provider (Parametrisiert)**
```dart
final studentsByKlasseProvider = 
    StreamProvider.family<List<Student>, String>((ref, klasseId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getStudentsByKlasse(klasseId);
});
```

**4. FutureProvider (Asynchrone Daten)**
```dart
final studentProvider = 
    FutureProvider.family<Student, String>((ref, id) async {
  final service = ref.read(firestoreServiceProvider);
  return service.getStudent(id);
});
```

**5. StateProvider (UI-State)**
```dart
final selectedKlasseIdProvider = StateProvider<String?>((ref) => null);
```

### Side-Effects

**Problem:** Riverpod Provider sind **deklarativ** und sollten keine Side-Effects haben.

**Lösung:**
- UI-Events (onPressed, onSubmitted) → `ref.read(serviceProvider).updateXXX()`
- NICHT in `build()` oder Provider-Body

**Anti-Pattern:**
```dart
// ❌ NICHT so
final badProvider = Provider((ref) {
  ref.watch(anotherProvider);
  // Side-Effect hier ist verboten!
  firestoreService.update(...); 
});
```

**Best Practice:**
```dart
// ✅ So ist es richtig
ElevatedButton(
  onPressed: () {
    ref.read(firestoreServiceProvider).updateStudent(...);
  },
  child: Text('Speichern'),
)
```

---

## Routing (go_router)

### Route-Struktur

```dart
GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Auth Guard: Redirect zu /login wenn nicht eingeloggt
    final user = ref.read(currentUserProvider);
    if (user == null && state.location != '/login') {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/klassen', builder: (context, state) => KlassenScreen()),
    GoRoute(path: '/faecher', builder: (context, state) => FaecherScreen()),
    GoRoute(path: '/schueler', builder: (context, state) => SchuelerScreen()),
    // ...
  ],
);
```

### Permission Guards (Planned)

**Rollen:** Admin, Lehrer, Ausbilder, Schüler

**Guards:**
```dart
// Beispiel (nicht implementiert)
final canEditNotenProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  return user?.rolle == 'admin' || user?.rolle == 'lehrer';
});
```

---

## Sicherheit

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Basis-Regel: Nur authentifizierte User
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Optional: User-Verwaltung nur für Admins
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rolle == 'admin';
    }
  }
}
```

**⚠️ ACHTUNG:** Aktuell dürfen alle eingeloggten User alles lesen/schreiben!  
→ **TODO:** Rollenbasierte Rules implementieren

### Daten-Verschlüsselung (Geplant v1.0.0)

**Problem:** Schülernamen sind personenbezogene Daten (DSGVO)

**Lösung (Roadmap):**
- Ende-zu-Ende Verschlüsselung mit Lehrer-Passwort (AES-256)
- Recovery-Key System
- Schülernamen verschlüsselt in Firestore speichern
- Entschlüsselung im Client (Browser)

---

## Testing-Strategie

### Test-Pyramide

```
     /\
    /E2E\      Integration Tests (geplant)
   /------\
  / Widget \   Widget Tests (16 Dateien, ~3k LOC)
 /----------\
/   Unit     \ Unit Tests (Models, Logic, Services)
--------------
```

### Aktuelle Tests (v0.16.0)

**16 Test-Dateien:**
- `test/models/*_test.dart` – Model-Tests (Serialisierung, Validierung)
- `test/services/auth_service_test.dart` – Auth-Service (Mocking)
- `test/services/firestore_service_test.dart` – Firestore (Mocking)
- `test/klasse_parser_test.dart` – CSV-Parsing

**Coverage:** 51.71% (laut README)

**Mocking:**
- `mockito` + `build_runner` für Service-Mocks

### Test-Standards

**Unit Tests:**
- Jedes Model hat `fromFirestore()` und `toFirestore()` Tests
- Services werden mit Mockito gemockt
- Keine echten Firebase-Calls in Tests

**Widget Tests:**
- Kritische UI-Komponenten (Buttons, Forms)
- Nicht für jedes Widget (zu aufwändig)

**Integration Tests:**
- Noch nicht implementiert
- Geplant für kritische Workflows (Login → Dashboard → Noteneingabe)

---

## Performance-Optimierungen

### 1. Lazy Loading (StreamProvider)
- Firestore-Streams werden nur geladen wenn `ref.watch()` aktiv
- `ref.listen()` für Background-Updates ohne Rebuild

### 2. Pagination (Noch nicht implementiert)
- Firestore-Queries limitieren (`limit(50)`)
- Infinite Scroll für große Datensätze

### 3. Caching
- Firestore nutzt lokalen Cache (automatisch)
- Offline-Support out-of-the-box

### 4. Optimistic Updates
- Noten-Matrix: Sofortige UI-Aktualisierung
- Firestore-Sync im Hintergrund
- Rollback bei Fehler

### 5. Widget-Rebuilds minimieren
- `ConsumerWidget` statt `StatefulWidget` (Riverpod)
- `select()` für granulare Provider-Watches
- `const` Widgets wo möglich

---

## Deployment

### CI/CD Pipeline (GitHub Actions)

**Workflows:**
1. **ci.yml** (bei Push/PR)
   - `flutter analyze` (Linting)
   - `flutter test` (Tests)
   - Versions-Check (pubspec.yaml == VERSION == lib/version.dart)

2. **release.yml** (bei Tag `v*`)
   - `flutter build web`
   - Firebase Hosting Deploy
   - Release Asset (build.zip)

### Build-Prozess

```bash
# 1. Dependencies installieren
flutter pub get

# 2. Web-Build (Production)
flutter build web --release

# 3. Deploy (automatisch via CI)
firebase deploy --only hosting
```

**Output:** `build/web/` (statische Dateien)

### Hosting

**Plattform:** Firebase Hosting  
**URL:** https://induscore-notentool.web.app/

**Konfiguration:**
- `firebase.json` – Hosting-Rules
- `firestore.rules` – Firestore Security Rules
- `firestore.indexes.json` – Composite Indexes

---

## Technische Schulden & Refactoring-Bedarf

### Große Dateien (>800 LOC)

1. **`klassen_screen.dart`** (1268 LOC ⚠️)
   - **Problem:** Screen + Dialogs + Logic in einer Datei
   - **Lösung:** Dialogs in eigene Dateien auslagern

2. **`noten_matrix_view.dart`** (1137 LOC ⚠️)
   - **Problem:** Universelle Matrix-Komponente mit 3 Modi
   - **Lösung:** Aufteilung in 3 separate Widgets (Klassen/Fächer/LN)

3. **`csv_import_screen.dart`** (1094 LOC ⚠️)
   - **Problem:** Import-Logic + UI in einem Screen
   - **Lösung:** Logic in `csv_import_logic.dart` auslagern

4. **`noten_uebersicht_screen.dart`** (968 LOC)
   - **Status:** Bereits refactored (war 2230 LOC!)
   - **Progress:** 57% Code-Reduktion ✅

### Coding Guidelines Verstöße

**Regel:** Max 300 Zeilen pro Datei  
**Verstöße:** 5 Dateien >800 LOC (siehe oben)

### Fehlende Dokumentation

- ❌ `ARCHITECTURE.md` (wird gerade erstellt)
- ❌ `TESTING_STRATEGY.md` (geplant)
- ⚠️ `CODING_GUIDELINES.md` (zu knapp, 33 Zeilen)

### Migration: `screens/` → `features/`

**Status:** Teilweise migriert

**Noch zu migrieren:**
- `home_screen.dart` → `features/dashboard/`
- `noten_eingabe_screen.dart` → `features/noten/`
- `noten_uebersicht_screen.dart` → `features/noten/`
- `csv_import_screen.dart` → `features/import/`

---

## Erweiterbarkeit

### Neue Features hinzufügen

**1. Feature-Ordner erstellen:**
```
lib/features/mein_feature/
├── mein_feature_screen.dart
├── mein_feature_logic.dart
├── mein_feature_providers.dart
└── widgets/
    └── mein_widget.dart
```

**2. Model erstellen (falls nötig):**
```dart
// lib/models/mein_model.dart
class MeinModel {
  final String id;
  final String name;
  
  factory MeinModel.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}
```

**3. Service-Methoden erweitern:**
```dart
// lib/services/firestore_service.dart
Stream<List<MeinModel>> getMeinModels() {
  return _firestore.collection('mein_collection').snapshots().map(...);
}
```

**4. Provider registrieren:**
```dart
// lib/providers/app_providers.dart
final meinModelsProvider = StreamProvider<List<MeinModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getMeinModels();
});
```

**5. Route hinzufügen:**
```dart
// lib/main.dart
GoRoute(
  path: '/mein-feature',
  builder: (context, state) => MeinFeatureScreen(),
)
```

---

## ADRs (Architecture Decision Records)

### ADR-001: Warum Riverpod statt Provider?

**Datum:** 2025-07-08  
**Status:** Accepted

**Kontext:**
- Provider 6.x hat Breaking Changes
- Riverpod ist Nachfolger von Provider (gleicher Autor)

**Entscheidung:**
- Riverpod 3.0 nutzen

**Begründung:**
- Compile-time Safety (keine Runtime-Errors bei Provider-Namen)
- Bessere DevTools
- Family-Provider für parametrisierte Queries
- Zukunftssicher

### ADR-002: Warum Feature-based statt Layer-based?

**Datum:** 2025-09-01  
**Status:** Accepted

**Kontext:**
- Alte Struktur: `lib/ui/`, `lib/logic/`, `lib/data/` (schwer navigierbar)

**Entscheidung:**
- Feature-based: `lib/features/noten/`, `lib/features/klassen/`

**Begründung:**
- Bessere Übersicht (alle Dateien eines Features zusammen)
- Leichtere Wartung
- Skalierbarkeit (neue Features isoliert hinzufügen)

### ADR-003: Warum RBS Styleguide 1.2?

**Datum:** 2025-07-15  
**Status:** Accepted

**Kontext:**
- App für Referat für Bildung und Sport München

**Entscheidung:**
- RBS Styleguide 1.2 umsetzen (Corporate Design)

**Begründung:**
- Einheitliches Design mit anderen RBS-Apps
- Barrierefreiheit (Kontraste, Schriftgrößen)
- Professionelles Erscheinungsbild

---

## Glossar

**ASV** – Amtliche Schulverwaltung (Bayern)  
**LN** – Leistungsnachweis (Schulaufgabe, Kurzarbeit, etc.)  
**NOI** – NotenImportOnline (XML-Format für Zeugnisnoten)  
**RBS** – Referat für Bildung und Sport (München)  
**ZG** – Zeitgruppe (ZG1, ZG2, ZG3 = Unterrichtszeiten)  
**Tendenz** – +/·/- bei Noten (z.B. 2+, 3·, 4-)  
**Nachschreiber** – Schüler mit fehlenden Noten (Eskalationsstufen: Gelb/Orange/Rot)  
**Kürzel** – Lehrer-Kürzel (2-4 Buchstaben, z.B. "AB", "MUST")  

---

## Weiterführende Dokumentation

- **CODING_GUIDELINES.md** – Code-Stil, Naming, Commits
- **CONTRIBUTING.md** – Entwicklungs-Workflow, PR-Template
- **TESTING_STRATEGY.md** – Test-Standards, Coverage-Ziele (geplant)
- **README.md** – Setup, Features, Roadmap

---

**Letzte Aktualisierung:** 2025-12-29  
**Autor:** GitHub Copilot Agent  
**Version:** 1.0
