# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.3.1] - 2025-12-02

### Fixed
- **Mobile Favicon** (#24)
  - Relative Pfade für Favicons (kompatibel mit `<base href>`)
  - Eigenes `apple-touch-icon.png` für iOS-Geräte
  - UTF-8 Encoding-Fix in index.html
- **go_router 17+ Kompatibilität**
  - Custom `GoRouterRefreshStream` Klasse implementiert
  - Ersetzt entfernte built-in Klasse für Auth-Refresh

---

## [0.3.0] - 2025-11-21

### Added
- **Fächerverwaltung** (#8)
  - `FachTyp` Enum: Allgemeinbildend, Beruflich, Lernfeld
  - Subject Model erweitert: typ, berufe, wochenstunden, credits
  - FaecherScreen mit CRUD-Funktionalität
  - Filter nach Beruf und Fachtyp
  - Farbcodierung nach Beruf (IE=Red, EAT=Green, EBT=Elder, EGS=Blue)
  - Detailanzeige: Wochenstunden, Credits, zugeordnete Berufe
  - RBS Styleguide 1.2 Design durchgängig

### Fixed
- Umlaut- und Encoding-Probleme in Enum und UI
- Farbränder für Beruf-Chips
- Save-Dialog: Fehlerhandling, Dialog-Schließung, Firestore-Integration

### Changed
- Google Fonts (Roboto) für bessere Umlaut-Darstellung
- Firestore-Regeln für Auth-User angepasst

### Geplant für v1.0.0
- Schülerverwaltung mit CSV-Import (#9)
- Leistungsnachweise & Noteneingabe (#10)
- Automatische Zeugnisnoten-Berechnung (#11)
- Nachschreiber-Management (#12)
- PDF-Export (#13)

----

## [0.2.0] - 2025-11-20

### Added
- **Domain-Modelle für Berufsschule** (#6)
  - `Beruf` Enum: IE, EAT, EBT, EGS mit vollständigen Namen
  - `Schuljahr` Klasse: Auto-Erkennung aktuelles Jahr (Aug-Dez)
  - `Zeitgruppe` Enum: 1, 2, 3 für Nachschreiber-Management
  - `Klasse` Model: Format "EAT321" (Beruf + Jahrgangsstufe + Zeitgruppe + Lfd.Nr.)
  - `Leistungsnachweis` Model: Typen mit Gewichtung (Schulaufgabe 2.0x, etc.)
  - `IHKNotenschluessel`: 92%+=1, 81%+=2, 67%+=3, 50%+=4, 30%+=5, <30%=6
  - `Zeugnisnote` Berechnung: Gewichteter Durchschnitt + Rundung (2.5→2, 2.6→3)

- **Klassenverwaltung** (#7)
  - Full CRUD UI mit RBS-Design
  - Listenansicht mit Beruf-farbcodierten Karten
  - Filter nach Schuljahr und Beruf
  - Vereinfachte Eingabe: "EAT321" wird automatisch geparst
  - RegEx-Validierung für Klassenname-Format
  - Löschen mit Bestätigung (inkl. Warnung vor Cascade-Delete)
  - Empty-State mit "Erste Klasse erstellen" Button

- **Navigation System** (#5 teilweise)
  - RBS Drawer-Menü mit Dynamic Red Header
  - Anzeige User-Email im Drawer
  - Navigation: Dashboard, Klassen (aktiv), Schüler/Fächer/Noten (disabled)
  - Logout-Funktion im Drawer
  - Aktive Seite visuell hervorgehoben

- **Firestore Services erweitert**
  - Klassen CRUD: getKlassen(), createKlasse(), updateKlasse(), deleteKlasse()
  - Leistungsnachweise CRUD: Full CRUD Operations
  - Cascade Delete: Löschen einer Klasse entfernt alle Leistungsnachweise
  - Filtered Queries: getKlassenBySchuljahrAndBeruf()

- **Riverpod Providers erweitert**
  - `klassenProvider`: Stream aller Klassen
  - `currentSchuljahrProvider`: Auto-Erkennung aktuelles Schuljahr
  - `leistungsnachweiseProvider`: Stream aller Leistungsnachweise
  - Family Providers für filtered Data

### Changed
- HomeScreen: Logout in Drawer verschoben (vorher AppBar)
- Login: Enter-Taste triggert Login-Funktion
- Klassenname-Format: Von "EAT-11-1-2024/25" zu "EAT321"
- Jahrgangsstufe: Von 10-13 zu 1-4 für bessere Lesbarkeit

### Fixed
- RenderFlex Overflow in HomeScreen (Card-Größe: 180→200px)
- Deprecated `value` Parameter in DropdownButtonFormField → `initialValue`
- Unused Imports bereinigt

---

## [0.1.0] - 2025-11-20

### Added
- **RBS Styleguide 1.2 Design System** (#18)
  - Theme mit Dynamic Red (RGB 255/94/53), Roboto Condensed, Open Sans
  - ColorScheme: Primary (Dynamic Red), Secondary (Growing Elder, Court Green)
  - Google Fonts Integration für Webfonts
  - Grid-basiertes Spacing (8dp-Basis)
  
- **RBS UI Components Library** (#18)
  - `RBSButton` - Dynamic Red, Roboto Condensed Bold
  - `RBSTag` - Outline-Style, doppelte Versalhöhe
  - `RBSCard` - Weiche Schatten, großer Weißraum
  - `RBSHeadline` - Roboto Condensed Bold, linksbündig
  - `RBSInput` - Klar, weiß, Outline bei Fokus
  - `RBSFilterChip` - Funktional für Filter
  - `RBSDialog` - Viel Luft, klare Typografie
  - `RBSSection` - Strukturblock für Content-Ebene
  
- **Login Screen (Cover-Ebene)** (#18)
  - Dynamic Red Hintergrund (verpflichtend gemäß Styleguide)
  - Keyvisual: 45° Pattern
  - Tag "#induscore" rechts oben
  - Headline + Subheadline (Roboto Condensed Bold, weiß)
  - Weißer Login-Card mit RBS-konformen Inputs
  - Responsive für Desktop & Mobile
  - Validation & Error-Handling
  
- **Initial Data Models** (#4)
  - `Student` - Firestore-Integration mit Pseudonymisierung
  - `Subject` - Fächerverwaltung mit Farb-Codes
  - `Grade` - Notenverwaltung mit Typen (Test, Oral, Homework, etc.)
  - `GradeType` Enum - Klassifizierung von Leistungsnachweisen
  
- **Firebase Services** (#4)
  - `AuthService` - Login, Register, Logout, Password-Reset
  - `FirestoreService` - CRUD für Students, Subjects, Grades
  - Deutsche Fehlermeldungen
  - Cascade Delete (Student → Grades)
  - Gewichtete Notenberechnung
  
- **Riverpod State Management** (#4)
  - Provider für Auth, Firestore, Students, Subjects, Grades
  - Stream-basierte Echtzeit-Updates
  - Statistik-Provider (Durchschnitte)
  
- **Projekt-Setup** (#3)
  - Flutter Web-Projekt mit Material Design 3
  - go_router für Navigation
  - Firebase Integration (Auth, Firestore)
  - Git Repository initialisiert

### Technical
- Clean Architecture Struktur begonnen
- Feature-first Ordnerstruktur (models, services, providers, screens, widgets)
- Vollständige Styleguide-Konformität (keine Versalien, linksbündig, Laufweite 0)

### Dependencies
- `flutter_riverpod: ^3.0.3`
- `firebase_core: ^4.2.1`
- `firebase_auth: ^6.1.2`
- `cloud_firestore: ^6.1.0`
- `go_router: ^17.0.0`
- `google_fonts: ^6.3.2`

---

## Release Notes Template

### v0.2.0 - Domain Layer (Geplant: 30.11.2025)
- Berufsschul-spezifische Domain-Modelle
- Repositories mit Clean Architecture
- Firestore Collections & Indizes
- Feature-Module-Struktur

### v1.0.0 - MVP (Geplant: 20.12.2025)
- Vollständige Notenverwaltung
- Klassen- und Schülerverwaltung
- PDF-Export
- Nachschreiber-Management
- Settings-Bereich
