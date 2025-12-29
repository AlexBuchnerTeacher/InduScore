# Git Release Commands für v0.2.0

## 📝 Änderungen committen

```bash
# Alle Dateien hinzufügen
git add .

# Commit erstellen
git commit -m "Release v0.2.0: Klassenverwaltung & Navigation

✨ Features:
- Klassenverwaltung mit CRUD-Funktionalität
- Domain-Modelle: Beruf, Klasse, Leistungsnachweis, Zeugnisnote
- RBS Drawer-Navigation
- IHK Bayern Notenschlüssel
- Automatische Klassenname-Parsing (EAT321)
- Filter nach Schuljahr und Beruf

🔧 Technical:
- Firestore Services erweitert
- Riverpod Providers für neue Collections
- RBS Styleguide 1.2 durchgängig

📚 Documentation:
- README.md komplett überarbeitet
- CHANGELOG.md aktualisiert
- LICENSE hinzugefügt
- INSTALL.md mit Deployment-Guide
- RELEASE.md mit Checkliste
- GitHub Issue-Templates

See CHANGELOG.md for full details."

# Push to main
git push origin main
```

## 🏷 Tag erstellen

```bash
# Annotated Tag mit Message
git tag -a v0.2.0 -m "Release v0.2.0 - Klassenverwaltung & Navigation

Hauptfeatures:
- Klassenverwaltung (CRUD)
- Domain-Modelle für Berufsschule
- RBS Navigation Drawer
- IHK Bayern Notenschlüssel
- Zeugnisnoten-Berechnung

Siehe CHANGELOG.md für Details."

# Tag zu Remote pushen
git push origin v0.2.0

# Alle Tags anzeigen
git tag -l
```

## 📦 GitHub Release erstellen

1. Gehe zu: https://github.com/AlexBuchnerTeacher/notentool_web/releases/new

2. **Tag**: `v0.2.0`

3. **Release Title**: `v0.2.0 - Klassenverwaltung & Navigation`

4. **Description**: (siehe unten)

5. **Assets hochladen**:
   - `build/web/` als ZIP komprimieren
   - `notentool-web-v0.2.0.zip` hochladen

### Release Description Template

```markdown
# 🎉 Release v0.2.0 - Klassenverwaltung & Navigation

## ✨ Neue Features

### 📚 Klassenverwaltung
- Vollständige CRUD-Funktionalität für Klassen
- Vereinfachte Eingabe: "EAT321" wird automatisch geparst
- Filter nach Schuljahr und Beruf (Chips)
- Farbcodierte Beruf-Anzeige:
  - 🔴 IE (Industrieelektroniker) - Dynamic Red
  - 🟢 EAT (Automatisierungstechnik) - Court Green
  - 🟣 EBT (Betriebstechnik) - Growing Elder
  - 🔵 EGS (Geräte und Systeme) - Blue
- Empty-State mit "Erste Klasse erstellen" Button
- Löschen mit Bestätigung (Warnung vor Cascade-Delete)

### 🏗 Domain-Modelle
- **Beruf Enum**: IE, EAT, EBT, EGS mit vollständigen Namen
- **Schuljahr**: Auto-Erkennung aktuelles Jahr (Aug-Dez = aktuell)
- **Zeitgruppe**: 1, 2, 3 für Nachschreiber-Management
- **Klasse**: Format "EAT321" (Beruf + Jahrgangsstufe + Zeitgruppe + Lfd.Nr.)
- **Leistungsnachweis**: Typen mit Gewichtung
  - Schulaufgabe: 2.0x
  - Stegreifaufgabe: 1.0x
  - Mündlich: 1.0x
  - Praktisch: 1.5x
  - Projekt: 2.0x
- **IHK Bayern Notenschlüssel**: 92%+=1, 81%+=2, 67%+=3, 50%+=4, 30%+=5, <30%=6
- **Zeugnisnote**: Gewichteter Durchschnitt + Rundung (2.5→2, 2.6→3)

### 🧭 Navigation System
- RBS Drawer-Menü mit Dynamic Red Header
- User-Email Anzeige im Drawer
- Navigation zu: Dashboard, Klassen (aktiv)
- Kommend: Schüler, Fächer, Noten, Statistiken, Einstellungen
- Logout-Funktion im Drawer
- Aktive Seite visuell hervorgehoben (rot + fett)

## 🐛 Bug Fixes
- Layout-Overflow in HomeScreen behoben (Card-Größe: 180→200px)
- Enter-Taste triggert Login-Funktion
- Deprecated `value` Parameter → `initialValue`
- Unused Imports bereinigt

## 🔧 Technische Verbesserungen
- Firebase Firestore Integration erweitert
  - Klassen CRUD mit Cascade-Delete
  - Leistungsnachweise CRUD
  - Filtered Queries (Schuljahr, Beruf)
- Riverpod Providers für neue Collections
  - `klassenProvider`, `currentSchuljahrProvider`
  - `leistungsnachweiseProvider`
  - Family Providers für filtered Data
- RBS Styleguide 1.2 durchgängig umgesetzt
- Code formatiert & analysiert (0 Issues)

## 📚 Dokumentation
- README.md komplett überarbeitet mit Badges & Features
- CHANGELOG.md mit vollständiger Historie
- LICENSE erstellt (Private)
- INSTALL.md mit Deployment-Guide
- RELEASE.md mit vollständiger Checkliste
- GitHub Issue-Templates (Bug Report, Feature Request)

## 📦 Installation

```bash
git clone https://github.com/AlexBuchnerTeacher/notentool_web.git
cd notentool_web
flutter pub get
flutterfire configure
flutter run -d chrome
```

Siehe [INSTALL.md](INSTALL.md) für detaillierte Anweisungen.

## 🚀 Nächste Schritte (v0.15.0)

- [ ] Schülerverwaltung mit CSV-Import & Pseudonymisierung (#9)
- [ ] Fächerverwaltung mit Beruf-Zuordnung (#8)
- [ ] Leistungsnachweise & Noteneingabe (#10)
- [ ] Automatische Zeugnisnoten-Berechnung (#11)
- [ ] Nachschreiber-Management mit Zeitgruppen (#12)
- [ ] PDF-Export für Notenlisten & Zeugnisse (#13)

## 📊 Statistiken

- **Lines of Code**: ~2500
- **Files Changed**: 25
- **New Files**: 13
- **Commits**: ~15

## 🙏 Credits

Entwickelt für das Referat für Bildung und Sport München
Berufsschule für Industrieelektronik

---

**Full Changelog**: https://github.com/AlexBuchnerTeacher/notentool_web/compare/v0.1.0...v0.2.0
```

## 🔄 Nach dem Release

```bash
# Branch für v0.15.0 vorbereiten
git checkout -b feature/schueler-verwaltung

# Oder direkt auf main weiterarbeiten
git checkout main
git pull origin main
```

## 📊 Release-Statistiken anzeigen

```bash
# Commits seit v0.1.0
git log v0.1.0..HEAD --oneline

# Geänderte Dateien
git diff v0.1.0..HEAD --stat

# Contributors
git shortlog -sn v0.1.0..HEAD
```

## 🔙 Rollback (falls nötig)

```bash
# Tag löschen (lokal)
git tag -d v0.2.0

# Tag löschen (remote)
git push origin :refs/tags/v0.2.0

# Zu vorherigem Tag zurück
git checkout v0.1.0
```
