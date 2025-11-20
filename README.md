# Notentool Web

**Notenverwaltung für Berufsschulen** - Referat für Bildung und Sport München

Eine moderne Flutter Web-Anwendung zur effizienten Verwaltung von Schülernoten, Leistungsnachweisen und Zeugnisnoten an Berufsschulen.

[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](CHANGELOG.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.2-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)

## ✨ Features (v0.2.0)

- ✅ **Klassenverwaltung**: Einfache Verwaltung von Klassen mit Format "EAT321"
- ✅ **RBS Styleguide 1.2**: München RBS Design System (Dynamic Red, Roboto Condensed)
- ✅ **Firebase Integration**: Firestore für Datenpersistenz, Authentication
- ✅ **Responsive Design**: Optimiert für Desktop & Mobile
- ✅ **IHK Bayern Notenschlüssel**: 92%+=1, 81%+=2, 67%+=3, 50%+=4, 30%+=5
- ✅ **Berufsschul-spezifisch**: IE, EAT, EBT, EGS, Zeitgruppen, Schuljahre

### 🚀 Kommende Features (v1.0.0)

- 📋 Schülerverwaltung mit CSV-Import & Pseudonymisierung
- 📚 Fächerverwaltung mit Beruf-Zuordnung
- 📝 Leistungsnachweise & Noteneingabe
- 🧮 Automatische Zeugnisnoten-Berechnung (gewichteter Schnitt)
- 🔄 Nachschreiber-Management mit Zeitgruppen
- 📄 PDF-Export für Notenlisten & Zeugnisse

## 🛠 Tech Stack

- **Framework**: Flutter 3.38.2 (Web)
- **Language**: Dart 3.10.0
- **State Management**: Riverpod 3.0.3
- **Backend**: Firebase (Firestore, Auth)
- **Routing**: go_router 17.0.0
- **Design**: RBS Styleguide 1.2 (München)
- **Fonts**: google_fonts 6.3.2 (Roboto Condensed, Open Sans)

## 📁 Projektstruktur

```
lib/
├── main.dart                      # App-Einstiegspunkt
├── firebase_options.dart          # Firebase-Konfiguration
├── core/
│   ├── theme/
│   │   └── rbs_theme.dart         # RBS Design System
│   └── widgets/
│       └── rbs_components.dart    # RBS UI Components
├── models/
│   ├── beruf.dart                 # Beruf, Schuljahr, Zeitgruppe
│   ├── klasse.dart                # Klassen-Model
│   ├── leistungsnachweis.dart     # Leistungsnachweise & IHK-Notenschlüssel
│   ├── zeugnisnote.dart           # Zeugnisnoten-Berechnung
│   ├── student.dart               # Schüler-Model (v1.0.0)
│   ├── subject.dart               # Fächer-Model (v1.0.0)
│   └── grade.dart                 # Noten-Model (v1.0.0)
├── providers/
│   └── app_providers.dart         # Riverpod State Provider
├── screens/
│   ├── home_screen.dart           # Dashboard
│   ├── login_screen.dart          # Login/Auth
│   └── klassen_screen.dart        # Klassenverwaltung
├── services/
│   ├── auth_service.dart          # Authentifizierung
│   └── firestore_service.dart     # Firestore CRUD
└── widgets/
    └── rbs_drawer.dart            # Navigation Drawer
```

## Setup

### 1. Dependencies installieren

```bash
flutter pub get
```

### 2. Firebase konfigurieren

**Wichtig**: Bevor Sie die App ausführen können, müssen Sie Firebase konfigurieren:

1. Installieren Sie die FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Konfigurieren Sie Firebase für Ihr Projekt:
   ```bash
   flutterfire configure
   ```
   
   Dies erstellt automatisch die korrekten Firebase-Konfigurationen in `lib/firebase_options.dart`.

3. In der Firebase Console:
   - Aktivieren Sie **Authentication** (Email/Password)
   - Aktivieren Sie **Cloud Firestore**
   - Konfigurieren Sie Firestore Security Rules

### 3. Firestore Security Rules (Beispiel)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Nur authentifizierte Benutzer
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Development

### App ausführen (Chrome)

```bash
flutter run -d chrome
```

### Tests ausführen

```bash
flutter test
```

### Code analysieren

```bash
flutter analyze
```

### Production Build

```bash
flutter build web
```

Die fertige App befindet sich dann in `build/web/`.

## Features (Geplant)

- ✅ Benutzer-Authentifizierung (Firebase Auth)
- ✅ Material Design 3 UI
- ✅ Responsive Web-Layout
- ✅ Dark Mode Support
- ⏸️ Schülerverwaltung
- ⏸️ Fächerverwaltung
- ⏸️ Noteneintragung
- ⏸️ Statistiken & Analytics
- ⏸️ Export/Import (CSV, Excel)

## Development Guidelines

- Verwenden Sie **Riverpod** für State Management
- Business-Logik gehört in **Services**, nicht in UI-Widgets
- Firestore für alle Datenpersistenz nutzen
- Responsive Design für Desktop- und Mobile-Browser
- Fehlerbehandlung für Web-Kontext implementieren

## Nützliche Befehle

```bash
# Dependencies aktualisieren
flutter pub upgrade

# Veraltete Pakete prüfen
flutter pub outdated

# Code formatieren
dart format .

# FlutterFire neu konfigurieren
flutterfire configure
```

## Troubleshooting

### Firebase-Fehler beim Start

Falls Sie beim App-Start Firebase-Fehler sehen:
1. Führen Sie `flutterfire configure` aus
2. Stellen Sie sicher, dass `lib/firebase_options.dart` korrekte Werte enthält
3. Überprüfen Sie, dass Firebase Auth und Firestore aktiviert sind

### CORS-Fehler in Chrome

Falls CORS-Probleme auftreten:
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

## Links

- [Flutter Dokumentation](https://docs.flutter.dev/)
- [FlutterFire Dokumentation](https://firebase.flutter.dev/)
- [Riverpod Dokumentation](https://riverpod.dev/)
- [go_router Dokumentation](https://pub.dev/packages/go_router)
