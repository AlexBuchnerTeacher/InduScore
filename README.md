# InduScore

**Notenverwaltung für Berufsschulen** – Referat für Bildung und Sport München

Eine moderne Flutter-Webanwendung zur effizienten Verwaltung von Schülernoten, Leistungsnachweisen und Zeugnisnoten an Berufsschulen.

![Version](https://img.shields.io/badge/version-0.7.0-blue.svg)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.2-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)


## Features (v0.7.0)
- **NEU: Schüler-Model überarbeitet**: Echte Namen (Vor-/Nachname), Status (aktiv/ausgetreten), Ein-/Austrittsdatum
- **NEU: PDF-Import mit Merge**: Duplikate erkennen, Schüler matchen, Austritte markieren
- **NEU: Responsive Leistungsnachweise**: PopupMenu auf Mobilgeräten, ganze Card klickbar
- **NEU: Sortierung nach Nachname**: Alphabetisch in allen Listen
- **NEU: Modernes Icon-Design**: App-Icon mit Schatten-Effekt
- **Notenübersicht aus allen Kontexten**: Klick auf Klasse/Fach/Schüler zeigt alle Noten
- **Auto-Save**: Noten werden sofort gespeichert (kein Save-Button nötig)
- **Tendenzen statt Punkte**: Vereinfachte Noteneingabe mit +/·/- Tendenz
- **Gewichtung**: Wochentest (1.0), Praktisch (1.5), Mündlich (1.0), Mitarbeit (1.0)
- **Änderungs-Tracking**: Kürzel des letzten Bearbeiters in jeder Note
- **Leistungsnachweise**: Wochentest, Praktisch, Mündlich, Mitarbeit
- **Excel-Style Noteneingabe**: Schnelle Eingabe für ganze Klasse mit Statistiken
- **Schülerverwaltung**: Filter nach Klasse, Aktiv/Ausgetreten Toggle
- **Fächerverwaltung**: CRUD, Beruf-Zuordnung, Farbcodierung, Wochenstunden, Credits
- **Klassenverwaltung**: Einfache Verwaltung von Klassen mit Format "EAT321"
- **PDF-Import**: Klassenlisten aus PDF importieren (auch OCR)
- **RBS Styleguide 1.2**: Dynamic Red, Roboto Condensed
- **Firebase Integration**: Firestore & Authentication
- **Responsive Design**: Optimiert für Desktop & Mobile
- **Berufsschul-spezifisch**: IE, EAT, EBT, EGS, Zeitgruppen, Schuljahre


## Roadmap

### v0.8.0 - Zeugnisnoten & Export
- [ ] Zeugnisnoten-Screen mit gewichtetem Durchschnitt
- [ ] PDF-Export für Notenlisten
- [ ] Nachschreiber-Management mit Zeitgruppen

### v1.0.0 - Datenschutz & Sicherheit
- [ ] Ende-zu-Ende Verschlüsselung für Schülernamen
- [ ] Verschlüsselung mit Lehrer-Passwort (AES-256)
- [ ] Recovery-Key System

## Live-Version

Die aktuelle Version ist als Web-App über GitHub Pages verfügbar:
https://alexbuchnerteacher.github.io/InduScore/

## Tech Stack
- **Framework**: Flutter 3.38.2 (Web)
- **Language**: Dart 3.10.0
- **State Management**: Riverpod 3.0.3
- **Backend**: Firebase (Firestore, Auth)
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
│   │   ├── beruf.dart                 # Beruf, Schuljahr, Zeitgruppe
│   │   ├── klasse.dart                # Klassen-Model
│   │   ├── leistungsnachweis.dart     # Leistungsnachweise & IHK-Notenschlüssel
│   │   ├── zeugnisnote.dart           # Zeugnisnoten-Berechnung
│   │   ├── student.dart               # Schüler-Model
│   │   ├── subject.dart               # Fächer-Model
│   │   └── grade.dart                 # Noten-Model (Note, Punkte, Kommentar)
│   ├── providers/app_providers.dart   # Riverpod State Provider
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard
│   │   ├── login_screen.dart          # Login/Auth
│   │   ├── klassen_screen.dart        # Klassenverwaltung
│   │   ├── faecher_screen.dart        # Fächerverwaltung
│   │   ├── schueler_screen.dart       # Schülerverwaltung
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

3) Firestore Security Rules (Beispiel)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
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
- Version-Quelle: `pubspec.yaml` (`version`), `VERSION`, `lib/version.dart` (müssen gleich sein)
- Releases: Tags `v*` triggern `.github/workflows/release.yml` (Web-Build + Asset)
- CI: `.github/workflows/ci.yml` (analyze, test, Versions-Check)

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
