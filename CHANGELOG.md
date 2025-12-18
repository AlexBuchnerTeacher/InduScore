# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.13.7] - 2025-12-18

### Fixed
- **Benutzerverwaltung**: Zugriffsproblem für ersten Admin behoben
  - Automatische AppUser-Erstellung beim ersten Login
  - Erster User wird automatisch als Admin angelegt
  - Löst "Zugriff verweigert" beim initialen Setup
  - Weitere User werden als Lehrer angelegt (Admin kann Rolle dann ändern)

### Technical Notes
- Auto-AppUser-Erstellung in `currentAppUserProvider`
- Erster User erhält automatisch `UserRole.admin`
- Weitere User erhalten `UserRole.lehrer` (Standard)
- Verbesserte Fallback-Logik in `isCurrentUserAdminProvider` mit `hasValue`-Checks
- Kürzel wird automatisch aus E-Mail extrahiert (z.B. "MU" aus "mu@induscore.de")

## [0.13.5] - 2025-12-17

### Fixed
- **ASV NOI-Export**: Kritischer Fehler beim Import in ASV behoben
  - Root-Element von `<NotenImport_Berufsschule>` zu `<zeugnsnoten-import>` korrigiert
  - ASV-Fehlermeldung: "Root-Element <zeugnsnoten-import> erwartet" behoben
  - Klasse-Attribut vom Root-Element in Schüler-Stammdaten verschoben
  - Struktur an ASV-Anforderungen angepasst

### Added
- **NOI-Export-Validator**: PowerShell-Script zur Qualitätssicherung
  - Prüft XML-Struktur auf ASV-Konformität
  - Validiert Root-Element und Pflichtattribute
  - Überprüft Schüler-Stammdaten
  - Script: `validate-noi-export.ps1`
- **Dokumentation**: Umfassende NOI-Export-Dokumentation
  - `docs/ASV_NOI_EXPORT_FIX.md`: Fehlerbehebung und Workflow
  - Beispiel-XML für Berufsschulen: `docs/noi-schema/test-berufsschule.xml`
  - Qualitätssicherungs-Prozess vor Weitergabe an Kollegen

### Technical Notes
- Offizielle NOI-Schemas (v3.23.4) sind nur für Gymnasien (G8/G9) verfügbar
- Kein offizielles NOI-Schema für Berufsschulen vorhanden
- Export-Format basiert auf ASV-Fehlermeldung und Best Practices
- Weitere Tests mit ASV erforderlich zur vollständigen Validierung

## [0.13.4] - 2025-12-14

### Added
- **Sticky Headers**: Spaltenüberschriften bleiben beim Scrollen fixiert
  - NotenTableWidget: Header-Zeile fixiert bei vertikalem Scroll
  - FaecherMatrixWidget: Fächer-Header fixiert bei vertikalem Scroll
  - Horizontales Scrollen funktioniert weiterhin für breite Tabellen

### Changed
- **Massive Code-Reduktion**: noten_uebersicht_screen.dart von 2230 → 970 Zeilen (57% Reduktion)
- **Widget-Extraktion**: 7 neue Widget-Dateien erstellt (~1500+ Zeilen ausgelagert)
  - `NotenTableWidget` (434 Zeilen): Tabellen-Ansicht mit Statistiken
  - `FaecherMatrixWidget` (445 Zeilen): Matrix-Ansicht Schüler × Fächer
  - `NoteInputWidgets` (320 Zeilen): Wiederverwendbare Input-Komponenten
  - `StudentSubjectCard` (182 Zeilen): Schüler-Fach-Karte
  - `noten_eingabe.dart` (38 Zeilen): Model für Noten-Eingabe
  - `noten_statistik.dart` (14 Zeilen): Statistik-Model
  - `tendenz.dart` (15 Zeilen): Tendenz-Enum
- **Verbesserte Code-Struktur**: 
  - Bessere Testbarkeit durch Widget-Separation
  - Wiederverwendbare Komponenten
  - Klarere Verantwortlichkeiten

### Technical
- Entfernte Methoden (~1260 Zeilen):
  - `_buildNotenTable` → `NotenTableWidget`
  - `_buildFaecherMatrix` → `FaecherMatrixWidget`
  - `_buildNoteDropdown`, `_buildTendenzButtons` → `note_input_widgets.dart`
  - `_buildStudentSubjectCard`, `_buildStudentLNRow` → `StudentSubjectCard`
  - Alle `_buildCompact*` Methoden und Helper
- Screen-Datei enthält nur noch:
  - State Management (Map<String, NotenEingabe>)
  - Filter-Logik (~130 Zeilen)
  - View-Modi-Orchestrierung
  - Core Business Logic (_updateNote, _saveGrade)
  - Helper-Methoden

### Fixed
- Unused import in noten_uebersicht_screen.dart entfernt


## [0.13.0] - 2025-12-12

### Added
- **Matrix-Refactoring komplett**: Alle 5 Detail-Screens mit Inline-Editing
  - KlassenDetailScreen: Schüler × Fächer Matrix (byKlasse-Modus)
  - SchuelerDetailScreen: Alle LNs eines Schülers gruppiert nach Fach (bySchueler-Modus)
  - FaecherDetailScreen: Alle Schüler eines Fachs cross-class (byFach-Modus)
  - LNEditorScreen: Noteneingabe für einzelnen LN (byLN-Modus)
  - NotenMatrixView: 1125 Zeilen, 3 Modi, vollständig funktional
- **Optimistic Updates**: Kürzel "geändert von" zeigt sofort an (vor Firebase-Bestätigung)
- **Dashboard-Refactoring**: 773 → 145 Zeilen (-81%)
  - 5 Widget-Komponenten extrahiert: statistics_cards, klassen_chips, nachschreiber_section, leistungsnachweise_list, dashboard_widgets
  - Nachschreiber-Section mit Eskalationsstufen (Kritisch/Dringend/Neu)
  - 4 Statistik-Kacheln responsive (Klassen, Schüler, Fächer, Noten)
- **Zeitgruppen-Filter global**: Alle Detail-Screens filtern nach ZG1/ZG2/ZG3
- **Navigation verbessert**: Hamburger-Menü in allen Übersichts-Screens (Web-Support)

### Changed
- **getUserKuerzel()**: Unterstützt jetzt vorname.nachname@domain UND kurze Emails (bu@domain)
- **EditableNoteCell**: Kompakter (45px) und voller Modus (60px + Tendenz-Buttons)
- **Type-Safety für Web**: Spread-Operator Pattern `<String>[...source]` statt `.cast<T>()`

### Fixed
- **Layout-Overflow behoben**: fachColWidth 80→90→110→120→150→160px, finaler Fix
- **FirebaseAuth direkt**: currentUserProvider null-Problem gelöst mit FirebaseAuth.instance.currentUser
- **Tendenz-Buttons**: compact: false wiederhergestellt nach Layout-Fix
- **Import-Fehler**: Nachschreiber aus providers statt models, unused imports entfernt

### Technical Debt
- NotenMatrixView: 1125 Zeilen (>300 Guideline), Splitting vorbereitet mit noten_matrix_base.dart
- noten_matrix_base.dart: Mixin erstellt aber noch nicht integriert (breaking change)

## [0.12.0] - 2025-12-11

### Added
- **Feature-based Architektur**: Neue Ordnerstruktur `lib/features/` für bessere Wartbarkeit
- **NotenMatrixView**: Universelle Matrix-Komponente für alle Noten-Ansichten
  - 3 Modi: byKlasse, bySchueler, byLN (aktuell byKlasse vollständig)
  - Horizontal scrollbare Fächer (nebeneinander)
  - Sticky left column (Schüler-Namen)
  - Inline-Editing mit direktem Firebase-Update
  - EditableNoteCell mit Tendenz-Buttons
- **Klassen-Detail Screen**: Neue Matrix-Ansicht für Klassen
  - Filter nach Fach und LN-Typ
  - Durchschnitte (Fach + Gesamt + Klasse)
  - Cross-Linking vorbereitet

### Changed
- **Coding Guidelines umgesetzt**: Single Responsibility, max 300 Zeilen pro File
- **Logik ausgelagert**: `noten_matrix_logic.dart` für Business Logic
- **Controller getrennt**: `noten_matrix_controller.dart` für UI-State
- **Befreiungs-Badge**: Zeigt jetzt Fach-Kürzel (D, PuG) statt generisches "B"

### Fixed
- Type-Cast Fehler bei Filter-Listen (`List<dynamic>` → `List<String>`)
- updatedBy wird korrekt gespeichert (Stream-Provider aktualisiert automatisch)


## [0.11.3] - 2025-12-10

### Added
- **ASV-Import mit Beziehungen** (Issue #36)
  - Direkter Import von ASV-CSV-Exporten (Amtliche Schulverwaltung Bayern)
  - Automatische Erkennung des ASV-Formats
  - Automatisches Anlegen von Klassen (aus Klassennamen geparst)
  - Automatisches Anlegen von Fächern (mit Kürzel und Name)
  - Automatisches Anlegen von Lehrern (aus Kürzel)
  - Speicherung der Schüler-Fach-Lehrer Beziehungen

- **Erweiterte Schüler-Daten**
  - Neues Feld: ASV-ID (lokales Differenzierungsmerkmal)
  - Neues Feld: Geschlecht (M/W)
  - Neues Feld: Religion
  - Neues Feld: E-Mail
  - Neues Feld: Ausbildungsbetrieb (für Ausbilder-Feature)
  - Neues Feld: Befreiung Deutsch
  - Neues Feld: Befreiung Politik und Gesellschaft (PuG)

- **SchuelerUnterricht Model**
  - Neue Entität für Schüler-Fach-Lehrer Zuordnungen
  - Speichert: Schüler, Fach, Lehrer, Gruppe, Klasse
  - Ermöglicht spätere Auswertungen nach Lehrer/Fach

- **Befreiungen in der Notenübersicht**
  - Befreiungs-Indikator "B" in der Schülerliste
  - Tooltip zeigt welche Befreiungen aktiv sind
  - Detail-Dialog mit allen Schüler-Informationen
  - Info-Chips für Geschlecht, Religion, Betrieb

### Changed
- CSV Import Screen: Automatische ASV-Format-Erkennung
- FirestoreService: Neue "Once"-Methoden für einmaliges Laden


## [0.10.0] - 2025-12-06

### Added
- **Globaler Zeitgruppen-Filter (ZG-Filter)**
  - SegmentedButton im Drawer: Alle / ZG1 / ZG2 / ZG3
  - Filter wirkt auf Dashboard, Klassen, Schüler, Leistungsnachweise
  - Zeitgruppe wird aus Klassennamen extrahiert (vorletzte Ziffer)

- **Nachschreiber-Dashboard**
  - Neue Sektion auf dem Dashboard mit Eskalationsstufen
  - Stufe 1 (gelb): ≤2 Tage überfällig
  - Stufe 2 (orange): ≤2 Wochen überfällig  
  - Stufe 3 (rot): >2 Wochen überfällig
  - Badge mit Anzahl der Nachschreiber
  - Schnellzugriff zum Befreien (Button + Swipe)

- **LN-Befreiungen ("Nicht relevant")**
  - Neues Model `LnExemption` für Schüler-LN-Befreiungen
  - Schüler können als "nicht relevant" für LN markiert werden
  - Befreite Schüler erscheinen nicht in Nachschreiber-Liste
  - Swipe-Geste in Noteneingabe: Links = Befreien, Rechts = Aufheben
  - Visuelle Markierung: Halbtransparent, durchgestrichen, "n.r." Badge
  - Rückgängig-Funktion via SnackBar

- **Benutzerverwaltung (Admin)**
  - Neues Model `AppUser` mit Rollen (Admin/Lehrer)
  - Vollständiger CRUD für Benutzer
  - Felder: Name, E-Mail, Kürzel, Rolle, Status
  - Suche und Filterung nach Rolle/Status
  - Benutzer aktivieren/deaktivieren
  - Neuer Menüpunkt unter Einstellungen (nur Admin)

### Fixed
- **Kürzel-Sofortaktualisierung**: Kürzel wird sofort nach Notenspeicherung angezeigt
- **Swipe-Crash behoben**: Race-Condition bei gleichzeitigem Swipe + Click verhindert
- **Null-Safety**: Robustere Fehlerbehandlung in Noteneingabe

### Changed
- Noteneingabe: Schüler bleiben nach Befreiung sichtbar (nur visuell markiert)
- Drawer: Neuer ZG-Filter und Benutzerverwaltung-Link


## [0.9.1] - 2025-12-05

### Added
- **Matrix-Ansicht für Klassen-Noten** (Notenübersicht)
  - Schüler in Zeilen, Fächer in Spalten
  - Durchschnitt pro Schüler pro Fach auf einen Blick
  - Gesamt-Durchschnitt pro Schüler und Klasse
  - Klick auf Fach öffnet Detail-Dialog mit allen LNs
  - Farbcodierte Noten-Anzeige
  - Horizontales Scrollen bei vielen Fächern

### Fixed
- **Fächer-Filterung nach Beruf** (kritischer Bug)
  - Fächer werden jetzt korrekt nach Beruf der Klasse gefiltert
  - Leistungsnachweis-Dialog zeigt nur passende Fächer
  - Export-Screen filtert Fächer nach Klassenzugehörigkeit
  - EAT-Schüler sehen keine EBT-Fächer mehr (und umgekehrt)


## [0.9.0] - 2025-12-05

### Added
- **CSV Import** für Schülerlisten
  - Automatische Spaltenerkennung (Vorname, Nachname, Klasse)
  - Unterstützung für Semikolon-, Komma- und Tab-getrennte Dateien
  - 3-Schritt-Wizard: Datei → Spalten → Import
  - Vorschau vor dem Import

- **PDF Export** für Notenberichte
  - Schüler-Notenblatt: Alle Fächer mit Einzelnoten und Durchschnitt
  - Fach-Notenliste: Alle Schüler einer Klasse mit Noten
  - Professionelles Layout im RBS-Design

- **Erweiterter Export-Screen** (`/export`)
  - NOI-Export (XML/CSV) für Zeugnisnoten
  - PDF-Export für Schüler und Fächer
  - Übersichtliche Kartenauswahl für Export-Typ

### Changed
- Neuer Menüpunkt "CSV Import" im Drawer
- Drawer: "NOI Export" → "Daten Export"


## [0.8.0] - 2025-12-05

### Added
- **NOI Export Service** für Zeugnisnoten
  - XML-Format für offizielle Notenverwaltungssysteme
  - CSV-Format für Excel-Kompatibilität
  - Bayerisches Berufsschul-Format

- **Dashboard Statistiken**
  - Übersichtskarten mit Anzahl Klassen, Schüler, Fächer, Noten
  - Farbige Icons und Schnellzugriff

- **Fächer-Farbauswahl**
  - 10 vordefinierte RBS-Farben
  - Hex-Eingabe für benutzerdefinierte Farben
  - Farbige Tags in Leistungsnachweisen


## [0.7.0] - 2025-12-04

### Changed
- **Student Model überarbeitet** (Breaking Change)
  - `pseudonym` entfernt - echte Namen
  - `firstName` und `lastName` als Pflichtfelder
  - `eintrittsDatum` und `austrittsDatum`
  - `StudentStatus`: aktiv/ausgetreten

- **PDF-Import mit Merge-Strategie**
  - Duplikate werden erkannt
  - Automatisches Matching per Vorname+Nachname
  - Austritte automatisch markieren

- **Modernisiertes Chip-Design**
  - RBSTag: Rund, gefüllt
  - RBSFilterChip: Pill-Form

### Fixed
- PDF-Parser robuster für OCR-Formate
- Sortierung nach Nachname


## [0.6.0] - 2025-12-03

### Added
- **Vereinfachte Noteneingabe**
  - Tendenz: +/·/- statt Punkte
  - Auto-Save bei Eingabe
  - Änderungs-Tracking (Kürzel)

- **Zentrale Notenübersicht**
  - Klick auf Klasse/Fach/Schüler → Noten
  - Filter-Chips und Statistiken
  - Durchschnittsberechnung

- **Neue LN-Typen**
  - Wochentest, Praktisch, Mündlich, Mitarbeit
  - Individuelle Gewichtung (1.0, 1.5, 2.0)

### Changed
- Grade Model: `tendenz`, `updatedBy` statt `punkte`
- Dashboard mit Schuljahr-Badge und Schnellzugriff


## [0.5.0] - 2025-12-02

### Added
- **Leistungsnachweise + Noteneingabe**
  - LeistungsnachweiseScreen mit CRUD
  - NotenEingabeScreen: Excel-Style Liste
  - IHK Bayern Notenschlüssel
  - Automatische Notenberechnung


## [0.4.0] - 2025-12-02

### Added
- **Schülerverwaltung**
  - SchuelerScreen mit CRUD
  - Filter nach Klasse
  - `studentsByKlasseProvider`


## [0.3.0] - 2025-12-01

### Added
- **Fächerverwaltung**
  - FaecherScreen mit CRUD
  - Berufszuordnung (EAT, EBT, EGS, IE)
  - Fachtypen: Allgemein, Beruflich, Lernfeld


## [0.2.0] - 2025-11-30

### Added
- **Klassenverwaltung**
  - KlassenScreen mit CRUD
  - Beruf, Jahrgangsstufe, Zeitgruppe
  - Schuljahr-Berechnung


## [0.1.0] - 2025-11-29

### Added
- **Projekt-Setup**
  - Flutter Web mit Firebase
  - Authentication (Email/Password)
  - Firestore Datenbank
  - RBS Styleguide Theme
  - go_router Navigation
  - Riverpod State Management
