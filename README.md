# Notentool Web

Eine Flutter Web-Anwendung zur Verwaltung von Schülernoten (Notenverwaltung).

## Tech Stack

- **Framework**: Flutter 3.x (Web)
- **Language**: Dart 3.x
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Authentication)
- **Routing**: go_router
- **UI**: Material Design 3

## Projektstruktur

```
lib/
├── main.dart                 # App-Einstiegspunkt mit Firebase-Init
├── firebase_options.dart     # Firebase-Konfiguration
├── models/                   # Datenmodelle (Grade, Student, Subject)
├── providers/                # Riverpod State Provider
├── screens/                  # UI-Bildschirme
│   ├── home_screen.dart      # Hauptbildschirm
│   └── login_screen.dart     # Login/Authentifizierung
├── services/                 # Business-Logik (GradeService, AuthService)
└── widgets/                  # Wiederverwendbare Komponenten
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
