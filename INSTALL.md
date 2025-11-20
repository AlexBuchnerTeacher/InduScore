# Installation & Deployment Guide

## 🚀 Lokale Installation

### Voraussetzungen
- Flutter SDK 3.38.2 oder höher
- Dart SDK 3.10.0 oder höher
- Chrome Browser (für Entwicklung)
- Firebase Account
- Git

### Installation

1. **Repository klonen**
```bash
git clone https://github.com/AlexBuchnerTeacher/notentool_web.git
cd notentool_web
```

2. **Dependencies installieren**
```bash
flutter pub get
```

3. **Firebase konfigurieren**

Installiere die FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Konfiguriere Firebase:
```bash
flutterfire configure
```

Wähle dein Firebase-Projekt "notentool" aus.

4. **Firebase Authentication aktivieren**
- Öffne [Firebase Console](https://console.firebase.google.com/)
- Gehe zu Authentication → Sign-in method
- Aktiviere "Email/Password"

5. **App starten**
```bash
flutter run -d chrome
```

## 🔐 Firestore Security Rules

Erstelle folgende Sicherheitsregeln in Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authentifizierung erforderlich
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Klassen
    match /klassen/{klasseId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }
    
    // Leistungsnachweise
    match /leistungsnachweise/{lnId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }
    
    // Schüler (v1.0.0)
    match /students/{studentId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }
    
    // Fächer (v1.0.0)
    match /subjects/{subjectId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }
    
    // Noten (v1.0.0)
    match /grades/{gradeId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }
  }
}
```

## 🌐 Deployment - Firebase Hosting

### Einmalige Einrichtung

1. **Firebase Tools installieren**
```bash
npm install -g firebase-tools
```

2. **Firebase Login**
```bash
firebase login
```

3. **Firebase initialisieren**
```bash
firebase init hosting
```

Konfiguration:
- Public directory: `build/web`
- Single-page app: Yes
- GitHub integration: Optional
- Überschreibe index.html: No

### Deployment

1. **Production Build**
```bash
flutter build web --release
```

2. **Deploy zu Firebase**
```bash
firebase deploy --only hosting
```

3. **URL prüfen**
```
https://notentool.web.app
oder
https://notentool.firebaseapp.com
```

## 🔧 Umgebungsvariablen

Firebase-Konfiguration ist in `lib/firebase_options.dart` gespeichert.

**Sicherheit**: Diese Datei enthält öffentliche API-Keys, die durch Firebase Security Rules geschützt sind.

## 📦 Build Artifacts

Nach `flutter build web --release`:
- Build-Verzeichnis: `build/web/`
- Hauptdatei: `build/web/index.html`
- Assets: `build/web/assets/`
- JavaScript: `build/web/main.dart.js`

## 🐳 Docker (Optional)

```dockerfile
# Dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Build & Run:
```bash
docker build -t notentool-web .
docker run -p 8080:80 notentool-web
```

## 🚦 Health Checks

Nach Deployment prüfen:
- [ ] Login funktioniert
- [ ] Klassenverwaltung lädt
- [ ] Firestore-Verbindung aktiv
- [ ] Keine Console-Errors
- [ ] Responsive Design funktioniert

## 🔄 Updates

1. **Code aktualisieren**
```bash
git pull origin main
flutter pub get
```

2. **Build & Deploy**
```bash
flutter build web --release
firebase deploy --only hosting
```

## 📊 Monitoring

- Firebase Console: [console.firebase.google.com](https://console.firebase.google.com/)
- Analytics: Firebase Analytics
- Errors: Firebase Crashlytics (für zukünftige mobile Apps)

## 🆘 Troubleshooting

### Build-Fehler
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Firebase-Verbindung fehlschlägt
- Prüfe `firebase_options.dart`
- Prüfe Firestore Security Rules
- Prüfe Firebase-Projekt Status

### Performance-Probleme
```bash
# Build mit Profiling
flutter build web --profile
# Oder mit Size-Analyse
flutter build web --release --analyze-size
```

## 📞 Support

Bei Problemen wende dich an:
- GitHub Issues: [github.com/AlexBuchnerTeacher/notentool_web/issues](https://github.com/AlexBuchnerTeacher/notentool_web/issues)
- Referat für Bildung und Sport München
