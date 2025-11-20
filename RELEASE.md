# Deployment Checklist - Notentool v0.2.0

## 📋 Pre-Release Checklist

### Code Quality
- [x] Alle Compile-Fehler behoben
- [x] Keine Warnungen mehr im Code
- [x] Unused Imports entfernt
- [x] Code formatiert (`flutter format .`)
- [x] Alle TODOs abgearbeitet oder dokumentiert

### Testing
- [ ] Login/Logout funktioniert
- [ ] Klassenverwaltung: Erstellen, Bearbeiten, Löschen
- [ ] Klassenname-Parsing ("EAT321") funktioniert
- [ ] Filter (Schuljahr, Beruf) funktionieren
- [ ] Navigation über Drawer funktioniert
- [ ] Responsive auf verschiedenen Bildschirmgrößen
- [ ] Firestore-Operationen erfolgreich

### Firebase
- [ ] Firebase Projekt "notentool" aktiv
- [ ] Authentication: Email/Password aktiviert
- [ ] Firestore: Sicherheitsregeln konfiguriert
- [ ] Firestore: Collections (klassen, leistungsnachweise) erstellt
- [ ] Firebase Hosting konfiguriert (optional)

### Documentation
- [x] README.md aktualisiert
- [x] CHANGELOG.md aktualisiert
- [x] LICENSE erstellt
- [x] Version in pubspec.yaml auf 0.2.0+2 gesetzt

### Build & Deploy
- [ ] Production Build erstellen: `flutter build web --release`
- [ ] Build-Artefakte in `build/web/` überprüfen
- [ ] Firebase Hosting Deploy (optional): `firebase deploy --only hosting`
- [ ] Git Tag erstellen: `git tag v0.2.0`
- [ ] Git Push mit Tags: `git push origin main --tags`
- [ ] GitHub Release erstellen mit Changelog

## 🚀 Build Commands

```bash
# Development
flutter run -d chrome

# Production Build
flutter build web --release --web-renderer html

# Firebase Deploy (optional)
firebase deploy --only hosting

# Git Tag
git tag -a v0.2.0 -m "Release v0.2.0 - Klassenverwaltung & Navigation"
git push origin v0.2.0
```

## 🔧 Firestore Security Rules (Beispiel)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Nur authentifizierte Benutzer
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Klassen: Nur eigene Lehrer-Daten
    match /klassen/{klasseId} {
      allow read, write: if request.auth != null;
    }
    
    // Leistungsnachweise: Nur eigene Lehrer-Daten
    match /leistungsnachweise/{lnId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📝 Release Notes Template (GitHub)

```markdown
# Release v0.2.0 - Klassenverwaltung & Navigation

## 🎉 Neue Features

### Klassenverwaltung
- Vollständige CRUD-Funktionalität für Klassen
- Vereinfachte Eingabe: "EAT321" wird automatisch geparst
- Filter nach Schuljahr und Beruf
- Farbcodierte Beruf-Anzeige (IE, EAT, EBT, EGS)

### Domain-Modelle
- Beruf Enum: IE, EAT, EBT, EGS
- Schuljahr mit Auto-Erkennung
- Klassen-Format: "EAT321" (Beruf + Stufe + Zeitgruppe + Nummer)
- IHK Bayern Notenschlüssel implementiert
- Zeugnisnoten-Berechnung mit Rundungsregeln

### Navigation
- RBS Drawer-Menü mit Dynamic Red Header
- Übersichtliche Navigation zwischen Bereichen
- Aktive Seite visuell hervorgehoben

## 🐛 Bug Fixes
- Layout-Overflow in HomeScreen behoben
- Deprecated Parameters aktualisiert
- Enter-Taste triggert Login

## 🔧 Technisch
- Firebase Firestore Integration erweitert
- Riverpod Providers für neue Collections
- RBS Styleguide 1.2 durchgängig umgesetzt

## 📦 Download
[Build Artifacts](link-to-build)

## 🚀 Nächste Schritte (v1.0.0)
- Schülerverwaltung
- Fächerverwaltung
- Noteneingabe & Berechnung
- PDF-Export
```

## ✅ Post-Release
- [ ] GitHub Release erstellt
- [ ] Build Artifacts hochgeladen
- [ ] Team informiert
- [ ] Produktiv-URL getestet
- [ ] Backup erstellt
