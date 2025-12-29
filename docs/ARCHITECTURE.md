# InduScore - Architektur-Dokumentation

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-12-29  
**Erstellt gemäß:** Issue #51 Finding F03

> **Ziel:** Neue Entwickler verstehen Datenfluss, Layering und Architekturentscheidungen in <2 Tagen (statt 5 Tagen ohne Doku)

---

## Inhaltsverzeichnis
1. [Tech-Stack & Deployment](#1-tech-stack--deployment)
2. [Layering-Architektur](#2-layering-architektur)
3. [Feature-Struktur](#3-feature-struktur)
4. [Datenfluss](#4-datenfluss)
5. [State Management (Riverpod)](#5-state-management-riverpod)
6. [Dependency Graph](#6-dependency-graph)
7. [Firestore Schema](#7-firestore-schema)
8. [Routing (go_router)](#8-routing-go_router)
9. [Security-Architektur](#9-security-architektur)
10. [Architekturentscheidungen (ADRs)](#10-architekturentscheidungen-adrs)

---

## 1. Tech-Stack & Deployment

### Tech-Stack
- **Framework:** Flutter 3.27+ (Web-only)
- **Language:** Dart 3.6+
- **State Management:** Riverpod 3.0+ (Streaming, Reactive)
- **Backend:** Firebase
  - **Firestore:** Database
  - **Auth:** Authentication (Email/Password)
  - **Hosting:** Web Hosting
  - **Storage:** Dateiablage (optional)
- **Routing:** go_router 14.6+
- **UI:** Material Design 3 mit RBS Styleguide

### Deployment
- **Hosting:** Firebase Hosting (`firebase deploy`)
- **URL:** `https://induscore-71af0.web.app`
- **CI/CD:** GitHub Actions (.github/workflows/ci.yml, release.yml)

---

## 2. Layering-Architektur

### 2.1 Übersicht

```
┌───────────────────────────────────────────────────────┐
│  UI LAYER                                            │
│  Screens, Widgets (lib/screens/, lib/features/)     │
│  - Nur Darstellung (Views)                           │
│  - ref.watch(provider) für reaktive Updates          │
│  - Keine Business Logic                              │
│  - Keine direkten Firestore-Zugriffe                 │
└────────────┬──────────────────────────────────────────┘
             │ (nutzt)
┌────────────▼──────────────────────────────────────────┐
│  STATE LAYER                                          │
│  Riverpod Providers (lib/providers/)                 │
│  - Zustandsverwaltung (StreamProvider, StateProvider)│
│  - Stream-Transformation (map, where, combineLatest) │
│  - Permission Guards (canManageUsers, canCreateData) │
│  - KEINE Business Logic                              │
└────────────┬──────────────────────────────────────────┘
             │ (nutzt)
┌────────────▼──────────────────────────────────────────┐
│  SERVICE LAYER                                        │
│  Services (lib/services/)                            │
│  - Business Logic (Berechnungen, Aggregationen)      │
│  - Firestore CRUD Operations                         │
│  - Data Transformation (Firestore ↔ Models)          │
│  - KEIN BuildContext (reiner Dart-Code)              │
└────────────┬──────────────────────────────────────────┘
             │ (nutzt)
┌────────────▼──────────────────────────────────────────┐
│  DATA LAYER                                           │
│  Firebase Cloud Firestore                            │
│  - NoSQL Database (Collections/Documents)            │
│  - Realtime Listeners (.snapshots())                 │
│  - Security Rules (firestore.rules)                  │
└───────────────────────────────────────────────────────┘
```

### 2.2 Layer-Regeln (VERBINDLICH!)

#### UI Layer
✅ **DARF:**
- `ref.watch(provider)` für Daten
- `ref.read(provider)` in Event-Handlern
- UI-Logik (Animationen, Navigation)

❌ **DARF NICHT:**
- `FirebaseFirestore.instance.collection(...).get()` (direkte Firestore-Zugriffe)
- Business Logic (Notenberechnung, Aggregation)
- `async/await` für Daten-Fetching (nutze Provider!)

#### State Layer
✅ **DARF:**
- Provider definieren (StreamProvider, StateProvider, FutureProvider)
- Streams kombinieren (`.map()`, `.where()`)
- Permission Guards (isAdmin, canManageUsers)

❌ **DARF NICHT:**
- Business Logic (Berechnungen → Service)
- Firestore Writes (Updates → Service)

#### Service Layer
✅ **DARF:**
- Firestore Reads/Writes
- Business Logic (Notenberechnung, PDF-Export)
- Data Transformation

❌ **DARF NICHT:**
- `import 'package:flutter/material.dart'` (kein BuildContext!)
- UI-Logik (Navigation, SnackBars)

---

## 3. Feature-Struktur

### 3.1 Aktueller Zustand

```
lib/
├── core/
│   ├── theme/                  # RBS Styleguide (Farben, Typografie)
│   └── widgets/                # Globale Widgets (RBSButton, RBSCard, RBSSnackBar)
├── features/                   # Feature-Modules
│   ├── dashboard/
│   │   └── widgets/            # Dashboard-spezifische Widgets
│   ├── noten/
│   │   ├── noten_matrix_logic.dart
│   │   ├── noten_matrix_controller.dart
│   │   └── widgets/            # Noten-spezifische Widgets
│   └── profile/
│       └── widgets/            # Profile-spezifische Widgets
├── models/                     # Datenmodelle (Student, Klasse, Grade, etc.)
├── providers/                  # Riverpod Providers (globale State)
├── screens/                    # Screens (sollten zu features/ migriert werden)
└── services/                   # Business Logic Services
    ├── auth_service.dart
    ├── firestore_service.dart
    ├── pdf_service.dart
    └── ...
```

### 3.2 Ziel-Struktur (Refactoring)

**Migration Plan:** Große Screens aus `lib/screens/` → `lib/features/*/`

```
lib/features/klassen/
├── klassen_screen.dart         # Haupt-Screen
├── widgets/
│   ├── import_preview_dialog.dart  # Issue #51 F01
│   ├── merge_dialog.dart           # Issue #51 F01
│   └── klasse_card.dart
└── logic/
    └── pdf_import_logic.dart
```

---

## 4. Datenfluss

### 4.1 Lese-Operationen (Firestore → UI)

```
1. USER INPUT (z.B. öffnet Screen)
   ↓
2. WIDGET (build-Methode)
   |
   | ref.watch(studentsProvider)
   ↓
3. PROVIDER (lib/providers/app_providers.dart)
   |
   | StreamProvider<List<Student>>
   | → service.getStudents()
   ↓
4. SERVICE (lib/services/firestore_service.dart)
   |
   | FirebaseFirestore.instance
   | .collection('students')
   | .orderBy('lastName')
   | .snapshots()
   ↓
5. FIRESTORE (Cloud Database)
   |
   | Stream<QuerySnapshot>
   ↓
6. SERVICE (Transform)
   |
   | .map((doc) => Student.fromFirestore(doc))
   ↓
7. PROVIDER (Emit Stream)
   |
   | Stream<List<Student>>
   ↓
8. WIDGET (Rebuild mit Daten)
   |
   | ListView.builder(students)
```

### 4.2 Schreib-Operationen (UI → Firestore)

```
1. USER INPUT (z.B. Klick auf "Speichern")
   ↓
2. WIDGET (Event-Handler)
   |
   | onPressed: () {
   |   final service = ref.read(firestoreServiceProvider);
   |   service.createStudent(newStudent);
   | }
   ↓
3. SERVICE (lib/services/firestore_service.dart)
   |
   | Future<void> createStudent(Student student)
   | → _students.add(student.toFirestore())
   ↓
4. FIRESTORE (Cloud Database)
   |
   | Document erstellt in /students/{id}
   ↓
5. FIRESTORE LISTENER (automatisch via StreamProvider)
   |
   | .snapshots() emittiert Update
   ↓
6. PROVIDER (Emit neuen Stream)
   ↓
7. WIDGET (Rebuild mit aktualisierten Daten)
```

---

## 5. State Management (Riverpod)

### 5.1 Provider-Typen in InduScore

| Provider-Typ | Use Case | Beispiel aus Codebase |
|--------------|----------|---------------------|
| `Provider<T>` | Singleton-Services, Computed Values | `firestoreServiceProvider`, `authServiceProvider` |
| `StreamProvider<T>` | Firestore Realtime-Daten | `studentsProvider`, `klassenProvider` |
| `FutureProvider<T>` | One-Time Async Load | `appVersionProvider`, `studentProvider` |
| `StateProvider<T>` | UI-State (Filter, Toggles) | `zeitgruppenFilterProvider` |
| `*.family<T, Arg>` | Provider mit Parameter | `studentsByKlasseProvider(klasseId)` |

### 5.2 Provider Scope

**Global Providers (lib/providers/app_providers.dart):**
- `studentsProvider` → Alle Schüler
- `klassenProvider` → Alle Klassen
- `subjectsProvider` → Alle Fächer
- `currentAppUserProvider` → Aktueller User

**Feature-Scoped Providers:**
- Noch nicht implementiert, aber geplant für große Features

### 5.3 Provider-Kombinationen

**Beispiel:** Gefilterte Schüler nach Klasse

```dart
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>(
  (ref, klasseId) {
    final service = ref.watch(firestoreServiceProvider);
    return service.getStudentsByKlasse(klasseId);
  },
);

// Widget nutzt:
final students = ref.watch(studentsByKlasseProvider(selectedKlasseId));
```

---

## 6. Dependency Graph

### 6.1 Abhängigkeiten (Wer nutzt wen?)

```
┌─────────────┐
│   Screens   │ nutzt ──→ Providers + Widgets + Models
└─────────────┘

┌─────────────┐
│  Providers  │ nutzt ──→ Services + Models
└─────────────┘

┌─────────────┐
│  Services   │ nutzt ──→ Models + Firestore
└─────────────┘

┌─────────────┐
│   Models    │ nutzt ──→ NICHTS (pure data classes)
└─────────────┘

┌─────────────┐
│   Widgets   │ nutzt ──→ Providers + Models + Theme
└─────────────┘
```

**Regel:** Abhängigkeiten nur nach unten, niemals zirkulär!

### 6.2 Verbotene Abhängigkeiten

❌ `Services` importieren `Widgets` → VERBOTEN  
❌ `Models` importieren `Providers` → VERBOTEN  
❌ `Services` importieren `BuildContext` → VERBOTEN

---

## 7. Firestore Schema

### 7.1 Collections Übersicht

```
Firestore
├── app_users/              # User-Accounts (Admin, Lehrer, Schüler)
│   └── {userId}
│       ├── email: String
│       ├── kuerzel: String
│       ├── rolle: String (admin|lehrer|ausbilder|schueler)
│       └── displayName: String
│
├── students/               # Schüler-Daten
│   └── {studentId}
│       ├── firstName: String
│       ├── lastName: String
│       ├── klasseId: String (→ klassen/{klasseId})
│       ├── berufId: String (→ berufe/{berufId})
│       ├── status: String (aktiv|archiviert)
│       └── zeitgruppe: String
│
├── klassen/               # Klassen
│   └── {klasseId}
│       ├── name: String (z.B. "GE1A-1")
│       ├── berufId: String (→ berufe/{berufId})
│       ├── schuljahr: String
│       └── lehrerId: String (→ app_users/{userId})
│
├── subjects/              # Fächer
│   └── {subjectId}
│       ├── name: String
│       ├── color: String (HEX)
│       └── abbreviation: String
│
├── leistungsnachweise/    # Leistungsnachweise (Tests, Schulaufgaben)
│   └── {leistungsnachweisId}
│       ├── name: String
│       ├── datum: Timestamp
│       ├── subjectId: String
│       ├── klasseId: String
│       ├── typ: String
│       └── maxPunkte: int
│
├── grades/                # Noten
│   └── {gradeId}
│       ├── studentId: String (→ students/{studentId})
│       ├── leistungsnachweisId: String
│       ├── value: double (1.0 - 6.0)
│       ├── punkte: int
│       └── isBerücksichtigt: bool
│
└── berufe/                # Berufe (IT-Systemkaufmann, etc.)
    └── {berufId}
        └── name: String
```

### 7.2 Firestore Indexes

**Definiert in:** `firestore.indexes.json`

**Wichtige Indexes:**
- `students`: (klasseId, lastName) → Für sortierte Schülerlisten pro Klasse
- `grades`: (leistungsnachweisId, studentId) → Für Matrix-Ansicht

---

## 8. Routing (go_router)

### 8.1 Route-Definition

**Datei:** `lib/main.dart` (GoRouter-Konfiguration)

**Hauptrouten:**
- `/` → `LoginScreen` (wenn nicht eingeloggt) oder `HomeScreen` (eingeloggt)
- `/home` → `HomeScreen` (Dashboard)
- `/klassen` → `KlassenScreen`
- `/schueler` → `SchuelerScreen`
- `/noten-eingabe` → `NotenEingabeScreen`
- `/noten-uebersicht` → `NotenUebersichtScreen`
- `/faecher` → `FaecherScreen`
- `/leistungsnachweise` → `LeistungsnachweiseScreen`
- `/settings` → `SettingsScreen`
- `/profile` → `ProfileScreen`

### 8.2 Auth-Guard

**Implementierung:** `GoRouterRefreshStream` (lib/main.dart)

```dart
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(authStateChanges),
  redirect: (context, state) {
    final isLoggedIn = /* check auth */;
    if (!isLoggedIn && state.location != '/') {
      return '/';  // Redirect zu Login
    }
    return null;  // Keine Umleitung
  },
);
```

**Regel:** Alle Routen außer `/` (Login) erfordern Authentifizierung

---

## 9. Security-Architektur

### 9.1 Firestore Rules Strategie

**Datei:** `firestore.rules`

**Prinzipien:**
1. **Default Deny:** Alles verboten, explizit erlauben
2. **Granulare Permissions:** Pro Collection/Document
3. **Rollen-basiert:** Admin, Lehrer, Ausbilder, Schüler

**Beispiel:**
```javascript
match /students/{studentId} {
  allow read: if request.auth != null;  // Alle eingeloggten User
  allow write: if isAdmin() || isLehrer();  // Nur Admin/Lehrer
}

match /app_users/{userId} {
  allow read: if request.auth == null;  // Pre-Login Kürzel-Lookup
  allow write: if isAdmin();  // Nur Admins
}
```

### 9.2 Permission Guards (Riverpod)

**Datei:** `lib/providers/permissions_providers.dart`

**Guards:**
- `canManageUsersProvider` → Admin-only
- `canCreateDataProvider` → Admin/Lehrer
- `canEditDataProvider` → Admin/Lehrer
- `canDeleteDataProvider` → Admin-only
- `canExportDataProvider` → Admin/Lehrer/Ausbilder
- `canViewReportsProvider` → Alle außer Schüler

**Verwendung in UI:**
```dart
final canManage = ref.watch(canManageUsersProvider);
if (canManage) {
  return FloatingActionButton(
    onPressed: () => showCreateDialog(),
  );
}
```

---

## 10. Architekturentscheidungen (ADRs)

### ADR-1: Warum Riverpod statt Bloc/GetX?

**Status:** Akzeptiert  
**Entscheidung:** Riverpod 3.0+ als State Management  
**Begründung:**
- ✅ Compile-safe (keine Strings für Provider-Lookup)
- ✅ Automatisches Dispose von Streams
- ✅ Family-Provider für parametrisierte Queries
- ✅ Einfache Testing (ProviderContainer)

**Alternativen:**
- ❌ Bloc: Zu viel Boilerplate für CRUD-App
- ❌ GetX: Nicht compile-safe, schlechtere DX

---

### ADR-2: Warum KEINE Code-Generation (freezed)?

**Status:** Evaluiert, noch nicht umgesetzt  
**Entscheidung:** Manuelle Models (aktuell)  
**Begründung:**
- ✅ Einfacher für Anfänger
- ✅ Kein Build-Runner-Overhead
- ❌ Mehr Boilerplate (copyWith, toFirestore)

**Nächste Schritte:** Evaluierung in Issue #51 F13

---

### ADR-3: Warum Firebase statt eigenes Backend?

**Status:** Akzeptiert  
**Entscheidung:** Firebase (Firestore + Auth + Hosting)  
**Begründung:**
- ✅ Realtime-Updates ohne WebSockets
- ✅ Managed Services (kein Server-Management)
- ✅ Granulare Security Rules
- ✅ Kostenlos für kleine Schulen (<50K Reads/Tag)

**Alternativen:**
- ❌ Supabase: Weniger Flutter-Integration
- ❌ Eigenes Backend: Zu hoher Wartungsaufwand

---

### ADR-4: Warum Material Design 3 statt Custom Design?

**Status:** Akzeptiert  
**Entscheidung:** Material Design 3 + RBS Styleguide Overlay  
**Begründung:**
- ✅ Accessibility out-of-the-box
- ✅ Responsive Komponenten
- ✅ RBS-Farben via ThemeData-Override

**Implementierung:** `lib/core/theme/rbs_theme.dart`

---

## 11. Bekannte Limitierungen

### 11.1 Technische Schulden (aus Issue #51)

1. **F01:** 6 Dateien >800 LOC (sollten <500 sein)
2. **F06:** Keine Tests für kritische Screens
3. **F14:** Keine Integration-Tests

### 11.2 Fehlende Features

- [ ] Offline-Support (Firestore Persistence)
- [ ] Push-Notifications (Firebase Cloud Messaging)
- [ ] Multi-Tenant Support (aktuell 1 Schule pro Firestore)

---

## 12. Weitere Ressourcen

- **README.md:** Setup-Anleitung, Features
- **CODING_GUIDELINES.md:** Code-Style, Naming Conventions
- **TESTING_STRATEGY.md:** (noch zu erstellen, Issue #51 F04)
- **Firestore Rules:** `firestore.rules`
- **CI/CD:** `.github/workflows/ci.yml`

---

**Bei Fragen:** Issue öffnen mit Label `architecture`