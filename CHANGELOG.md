# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
