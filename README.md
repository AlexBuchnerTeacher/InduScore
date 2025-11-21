# InduScore

**Notenverwaltung für Berufsschulen** – Referat für Bildung und Sport München

Eine moderne Flutter-Webanwendung zur effizienten Verwaltung von Schülernoten, Leistungsnachweisen und Zeugnisnoten an Berufsschulen.

![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.2-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)


## Features (v0.3.0)
- **Fächerverwaltung**: CRUD, Beruf-Zuordnung, Farbcodierung, Wochenstunden, Credits
- **Klassenverwaltung**: Einfache Verwaltung von Klassen mit Format "EAT321"
- **RBS Styleguide 1.2**: Dynamic Red, Roboto Condensed
- **Firebase Integration**: Firestore & Authentication
- **Responsive Design**: Optimiert für Desktop & Mobile
- **IHK Bayern Notenschlüssel**: 92%+=1, 81%+=2, 67%+=3, 50%+=4, 30%+=5
- **Berufsschul-spezifisch**: IE, EAT, EBT, EGS, Zeitgruppen, Schuljahre


### Kommende Features (v1.0.0)
- Schülerverwaltung mit CSV-Import & Pseudonymisierung
- Leistungsnachweise & Noteneingabe
- Automatische Zeugnisnoten-Berechnung (gewichteter Schnitt)
- Nachschreiber-Management mit Zeitgruppen
- PDF-Export für Notenlisten & Zeugnisse
# Release v0.3.0

Die Version v0.3.0 ist als Web-App über GitHub Pages verfügbar:
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
│   │   └── grade.dart                 # Noten-Model
│   ├── providers/app_providers.dart   # Riverpod State Provider
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard
│   │   ├── login_screen.dart          # Login/Auth
│   │   ├── klassen_screen.dart        # Klassenverwaltung
│   │   └── faecher_screen.dart        # Fächerverwaltung
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
