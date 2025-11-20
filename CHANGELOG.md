# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Progress
- Domain-Modelle für Berufsschule (Issue #6)

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
  - Tag "#notentool" rechts oben
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
