# InduScore

**Notenverwaltung für Berufsschulen** – Referat für Bildung und Sport München

Eine moderne Flutter-Webanwendung zur effizienten Verwaltung von Schülernoten, Leistungsnachweisen und Zeugnisnoten an Berufsschulen.

![Version](https://img.shields.io/badge/version-0.19.0-blue.svg)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.2-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)
[![CI](https://github.com/AlexBuchnerTeacher/InduScore/actions/workflows/ci.yml/badge.svg)](https://github.com/AlexBuchnerTeacher/InduScore/actions/workflows/ci.yml)

## Features (v0.19.0)

### Neu in v0.19.0 - Phase 2.5: UX & Performance
- **AppSnackBars** - Einheitliches Error-Handling mit 4 Typen
- **PaginatedFirestoreList** - Widget für Lazy Loading großer Listen
- **269 Tests gesamt** (alle bestanden)

### Neu in v0.18.0 - Phase 2: Testing & Security
- **50 neue Unit-Tests** für Export-Services (CSV, NOI, PDF)
- **Dependency Injection** für AuthService und FirestoreService
- **Firestore Security Rules** mit rollenbasierter Zugriffskontrolle

### Neu in v0.16.0
- **User-Profilscreen** mit Passwort-Änderung
- **Verbesserte Benutzerverwaltung**

## Features (v0.13.4)

### Neu in v0.13.4
- **Sticky Headers**: Spaltenüberschriften bleiben beim Scrollen fixiert
- **Code-Optimierung**: 57% Reduktion in noten_uebersicht_screen.dart (2230 → 970 Zeilen)
- **Widget-Extraktion**: 7 neue wiederverwendbare Komponenten
- **Test-Suite**: 65 Tests mit 51.71% Coverage
- **Bessere Wartbarkeit**: Verbesserte Code-Struktur und Testbarkeit

### Neu in v0.13.0
- **Matrix-Refactoring**: Alle 5 Detail-Screens mit Inline-Editing
- **Optimistic Updates**: Sofortige Anzeige von Änderungen
- **Dashboard-Refactoring**: 81% Code-Reduktion (773 → 145 Zeilen)

### Weitere Features
- **Zeitgruppen-Filter**: Globaler Filter im Drawer für ZG1/ZG2/ZG3
- **Nachschreiber-Dashboard**: Übersicht mit 3 Eskalationsstufen
- **LN-Befreiungen**: Schüler als "nicht relevant" markieren
- **Rollenbasierte Berechtigungen**: Admin, Lehrer, Ausbilder, Schüler
- **Permission Guards**: Zugriffskontrolle auf Screen- und Feature-Ebene
- **Feature-based Architektur**: Saubere Code-Struktur nach Coding Guidelines
- **NotenMatrixView**: Universelle Matrix-Komponente mit 3 Modi
- **Inline-Editing**: Direkte Noten-Änderung in der Tabelle

### Kernfunktionen
- **Matrix-Ansicht**: Schüler-Fächer-Matrix mit Durchschnitten
- **Auto-Save Noteneingabe**: Excel-Style mit Tendenzen (+/·/-)
- **CSV Import**: Schülerlisten mit automatischer Spaltenerkennung
- **PDF Export**: Notenblätter und Klassenlisten
- **NOI Export**: XML/CSV für Zeugnisnoten (Bayern)
- **PDF-Import mit Merge**: Duplikate erkennen, Schüler matchen
- **Änderungs-Tracking**: Kürzel des letzten Bearbeiters
- **Responsive Design**: Desktop & Mobile optimiert
- **RBS Styleguide 1.2**: München Design System


## Roadmap

### v0.8.0 - Zeugnisnoten & Export
## Roadmap

### v0.11.0 - Zeugnisnoten
- [ ] Zeugnisnoten-Screen mit gewichtetem Durchschnitt
- [ ] Automatische Berechnung aus Leistungsnachweisen

### v1.0.0 - Datenschutz & Sicherheit
- [ ] Ende-zu-Ende Verschlüsselung für Schülernamen
- [ ] Verschlüsselung mit Lehrer-Passwort (AES-256)
- [ ] Recovery-Key System

## Live-Version

Die aktuelle Version ist als Web-App über Firebase Hosting verfügbar:
https://induscore-notentool.web.app/

## Tech Stack
- **Framework**: Flutter 3.38.2 (Web)
- **Language**: Dart 3.10.0
- **State Management**: Riverpod 3.0.3
- **Backend**: Firebase (Firestore, Auth, Hosting)
- **Routing**: go_router 17.0.0
- **Design**: RBS Styleguide 1.2 (München)
- **Fonts**: google_fonts 6.3.2

## Projektstruktur
```
├── lib/
│   ├── main.dart                      # App-Einstiegspunkt
│   ├── firebase_options.dart          # Firebase-Konfiguration
│   ├── core/
│   │   ├── theme/rbs_theme.dart       # RBS Design System
│   │   └── widgets/rbs_components.dart# RBS UI Components
│   ├── models/
│   │   ├── app_user.dart              # Benutzer-Model (4 Rollen, Favoriten)
│   │   ├── beruf.dart                 # Beruf, Schuljahr, Zeitgruppe
│   │   ├── grade.dart                 # Noten-Model
│   │   ├── klasse.dart                # Klassen-Model
│   │   ├── leistungsnachweis.dart     # Leistungsnachweise (mit createdBy)
│   │   ├── ln_exemption.dart          # LN-Befreiungen
│   │   ├── student.dart               # Schüler-Model
│   │   ├── subject.dart               # Fächer-Model
│   │   └── zeugnisnote.dart           # Zeugnisnoten-Berechnung
│   ├── providers/
│   │   ├── app_providers.dart         # Riverpod State Provider
│   │   └── permissions_providers.dart # Permission Guards (6 Provider)
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard mit Nachschreiber
│   │   ├── login_screen.dart          # Login/Auth
│   │   ├── klassen_screen.dart        # Klassenverwaltung
│   │   ├── faecher_screen.dart        # Fächerverwaltung
│   │   ├── schueler_screen.dart       # Schülerverwaltung
│   │   ├── user_verwaltung_screen.dart# Benutzerverwaltung (Admin)
│   │   ├── leistungsnachweise_screen.dart  # Leistungsnachweise
│   │   ├── noten_eingabe_screen.dart  # Excel-Style Noteneingabe
│   │   └── noten_uebersicht_screen.dart # Zentrale Notenübersicht
│   ├── services/
│   │   ├── auth_service.dart          # Authentifizierung
│   │   └── firestore_service.dart     # Firestore CRUD
│   └── widgets/rbs_drawer.dart        # Navigation Drawer
```

## Setup
1) Dependencies installieren
```bash
flutter pub get
```

2) Firebase konfigurieren
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
- In Firebase Console: Auth (Email/Password) und Cloud Firestore aktivieren
- Rules konfigurieren (Beispiel siehe unten)

3) Admin-User anlegen
```bash
# 1. Firestore-User anlegen
dart run scripts/create_admin.dart

# 2. Firebase Auth User erstellen (Firebase Console)
# Email: alex.buchner@gmx.de
# Passwort: [selbst wählen]
```

4) Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Alle Dokumente: Nur authentifizierte User
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

## Development
- App auf Chrome: `flutter run -d chrome`
- Tests: `flutter test`
- Analyze: `flutter analyze`
- Production Build: `flutter build web` (Output in `build/web/`)

### Versionierung & Releases
- **Release-Checkliste:** [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) - Vollständiger Prozess
- Version-Quelle: `pubspec.yaml` und `version.json` (müssen synchron sein)
- Releases: Tags `v*` triggern `.github/workflows/release.yml` (Web-Build + Asset)
- CI: `.github/workflows/ci.yml` (analyze, test, Coverage-Check)

## Features (Geplant)
- Benutzer-Authentifizierung (Firebase Auth)
- Material Design 3 UI
- Responsive Web-Layout
- Dark Mode Support
- Schülerverwaltung
- Fächerverwaltung
- Noteneintragung
- Statistiken & Analytics
- Export/Import (CSV, Excel)

## Development Guidelines
- Riverpod für State Management
- Business-Logik in Services, nicht in UI-Widgets
- Responsive Design, Fehlerbehandlung für Web-Kontext
- Siehe auch `CODING_GUIDELINES.md` und `CONTRIBUTING.md`
