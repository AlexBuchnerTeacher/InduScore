# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

<!-- Next release content goes here -->

## [0.17.0] - 2025-12-29 - Phase 1: Code Quality & Refactoring

### Added
- **Common Dialog Library** (Issue #54 F-011/F-012) - Dialog Consolidation ✅
  - Created `lib/widgets/dialogs/common_dialogs.dart` (253 LOC) with 6 reusable dialog builders:
    - `showConfirmationDialog()` - Standard confirmation with custom actions
    - `showDeleteConfirmationDialog()` - Delete confirmation with red warning styling
    - `showInfoDialog()` - Simple info message with OK button
    - `showErrorDialog()` - Error message with red icon and styling
    - `showSuccessDialog()` - Success message with green icon and styling
    - `showInputDialog()` - Text input dialog with form validation
  - Replaced 16 inline AlertDialog implementations across 5 screens:
    - schueler_screen.dart: Delete confirmation
    - settings_screen.dart: Subject delete confirmation
    - user_verwaltung_screen.dart: Password reset + user delete confirmations
    - faecher_screen.dart: Subject delete confirmation
  - Reduced duplicate dialog code by ~150-200 LOC
  - All dialogs follow RBS Styleguide 1.2 theming
  - Remaining 15 showDialog calls are context-specific (forms, specialized widgets)

### Changed
- **csv_import_screen.dart UI Widget Extraction** (Issue #54 F-003 Phase 1) - 11% LOC Reduction ✅
  - Created `lib/screens/widgets/csv_import_widgets.dart` (246 LOC) with 5 reusable UI components:
    - `buildStepCard()` - Step indicator with completion states (active/complete/inactive)
    - `buildColumnMappingChip()` - CSV column assignment chip with mapping indicator
    - `buildPreviewTable()` - 5-row data preview table with column mapping
    - `buildStatChip()` - Statistics display chip (students, classes, teachers, subjects)
    - `KlasseDropdownWidget` - Riverpod-integrated class selector with auto-selection
  - Reduced csv_import_screen.dart from 1068→954 LOC (11% reduction)
  - Business logic remains in screen (tightly coupled to widget state)
  - Future Phase 2: Migrate to Riverpod StateNotifier for further LOC reduction
  - All 203 tests passing, backward compatible

- **noten_matrix_view.dart Widget Extraction** (Issue #54 F-002) - 91% LOC Reduction ✅
  - Split monolithic noten_matrix_view.dart into 4 specialized widget files:
    - `lib/features/noten/widgets/klassen_matrix_widget.dart` (412 LOC) - Schüler × Fächer/LNs Matrix
    - `lib/features/noten/widgets/schueler_matrix_widget.dart` (301 LOC) - LNs × Note für einzelnen Schüler
    - `lib/features/noten/widgets/ln_matrix_widget.dart` (359 LOC) - Schüler × Note für einzelnen LN
    - `lib/features/noten/widgets/matrix_common_widgets.dart` (155 LOC) - Shared widgets and helpers
  - Reduced noten_matrix_view.dart from 1056→91 LOC (91% reduction)
  - Main file now simple router widget delegating to specialized widgets
  - All widgets <450 LOC (well under 800 LOC limit)
  - Preserved all features: inline editing, optimistic updates, callbacks
  - RBS Styleguide 1.2 compliance maintained
  - Backward compatible (same public API)

- **klassen_screen.dart Widget Extraction** (Issue #54 F-001) - 50% LOC Reduction ✅
  - Extracted 4 reusable widgets from klassen_screen.dart:
    - `lib/widgets/klassen/klassen_filter_section.dart` (115 LOC) - Zeitgruppen/Beruf/Schuljahr filters
    - `lib/widgets/klassen/klasse_card.dart` (87 LOC) - Color-coded class cards
    - `lib/widgets/dialogs/klasse_edit_dialog.dart` (233 LOC) - Create/edit with Klassenname validation
    - `lib/widgets/dialogs/klasse_delete_dialog.dart` (67 LOC) - Cascade deletion confirmation
  - Reduced klassen_screen.dart from 608→304 LOC (99% of <300 target)
  - Removed duplicate _getBerufColor method (appeared 3 times)
  - All widgets maintain RBS Styleguide 1.2 compliance
  - Callback pattern preserves Riverpod integration

- **Lint Rules Enhancement** (Issue #54 F-015) - Strict Lint Rules ✅
  - Added 25 strict lint rules to analysis_options.yaml (13→38 rules total)
  - Code quality: `avoid_empty_else`, `avoid_type_to_string`, `only_throw_errors`
  - Async patterns: `unawaited_futures`, `cancel_subscriptions`
  - Best practices: `always_declare_return_types`, `always_put_required_named_parameters_first`, `prefer_final_fields/locals`
  - Style: `unnecessary_lambdas`, `unnecessary_this`, `unnecessary_parenthesis`
  - Applied 78 automatic lint fixes across 35 files
  - Result: 164 lint infos → 0 (100% clean codebase) ✅

### Added
- **Model Unit Tests** (Issue #54 F-006) - 63 new tests ✅
  - `test/models/student_test.dart` (24 tests) - fromFirestore, toFirestore, copyWith, equality
  - `test/models/subject_test.dart` (15 tests) - Model conversion, edge cases
  - `test/models/klasse_test.dart` (15 tests) - Class model validation
  - `test/models/leistungsnachweis_test.dart` (9 tests) - Assessment model
  - Coverage: >80% per model
  - Total tests: 140→203 (+63), all passing ✅

### Fixed
- **Dependency Updates** - Cloud Firestore 6.1.1, go_router 17.0.1, file_picker 10.3.8, syncfusion_flutter_pdf 32.1.20, google_fonts 6.3.3
  - Fixed sealed `DocumentSnapshot` compile errors (85 errors) - refactored test mocks to use `Fake` pattern
  - Resolved all 25 `avoid_dynamic_calls` warnings with proper type imports and casts
  - Fixed Zeitgruppe enum comparison (.index)
  - Applied 52 lint auto-fixes (prefer_const_constructors)
  - Removed incompatible dialog files (import_preview_dialog, merge_students_dialog)
  - All 203 tests passing ✅

### Changed
- **klassen_screen.dart Widget Extraction** (Issue #54 F-001) - 50% LOC Reduction ✅
  - Extracted 4 reusable widgets from klassen_screen.dart:
    - `lib/widgets/klassen/klassen_filter_section.dart` (115 LOC) - Zeitgruppen/Beruf/Schuljahr filters
    - `lib/widgets/klassen/klasse_card.dart` (87 LOC) - Color-coded class cards
    - `lib/widgets/dialogs/klasse_edit_dialog.dart` (233 LOC) - Create/edit with Klassenname validation
    - `lib/widgets/dialogs/klasse_delete_dialog.dart` (67 LOC) - Cascade deletion confirmation
  - Reduced klassen_screen.dart from 608→304 LOC (99% of <300 target)
  - Removed duplicate _getBerufColor method (appeared 3 times)
  - All widgets maintain RBS Styleguide 1.2 compliance
  - Callback pattern preserves Riverpod integration

- **Lint Rules Enhancement** (Issue #54 F-015) - Cherry-picked from PR #59 ✅
  - Added 25 strict lint rules to analysis_options.yaml (13→38 rules total)
  - Code quality: `avoid_empty_else`, `avoid_type_to_string`, `only_throw_errors`
  - Async patterns: `unawaited_futures`, `cancel_subscriptions`
  - Best practices: `always_declare_return_types`, `always_put_required_named_parameters_first`, `prefer_final_fields/locals`
  - Style: `unnecessary_lambdas`, `unnecessary_this`, `unnecessary_parenthesis`
  - Applied 78 automatic lint fixes across 35 files:
    - Required parameters before optional (54 fixes)
    - Lambda tearoffs (30 fixes) - reduced code by 124 lines
    - Final local variables (3 fixes)
  - Fixed 5 `only_throw_errors` in auth_service.dart - wrapped error messages in Exception class
  - Result: 164 lint infos → 0 (100% clean codebase) ✅

## [0.16.0] - 2025-12-29 - User-Profilscreen

### Added
- **User-Profilscreen** (Issue #49) ✅
  - Getrennt von Admin Einstellungen (für alle User-Rollen)
  - 3 Tabs: Profil (readonly), Sicherheit, Favoriten
  - Passwort ändern mit Re-Authentifizierung
  - Favoriten-Klassen Verwaltung
  - Navigationseintrag "Mein Profil" im Drawer
  - RBS-konformes Design
  - Route: /profil
  - 51 neue Tests (140 Tests gesamt, alle passing)

## [0.15.0] - 2025-12-29 - v0.15.0 MVP Vorbereitung

### Added
- **Unit-Tests für Zeugnisnoten-Berechnung** (Issue #11) - ABGESCHLOSSEN ✅
  - 24 Tests für `Zeugnisnote.berechneSchnitt()`
  - Tests für `Zeugnisnote.rundeNote()` (Rundungsregel < 0.6 abrunden, ≥ 0.6 aufrunden)
  - Tests für `Zeugnisnote.berechneZeugnisnote()` (End-to-End)
  - Tests für `formatSchnitt()` und `getTendenz()`
  - Alle 89 Tests bestehen
- **Settings-Screen** (Issue #14) - ABGESCHLOSSEN ✅
  - Tab-basierte UI für Berufe (readonly) und Fächer (CRUD)
  - Fächer-Verwaltung: Erstellen, Bearbeiten, Löschen
  - Zuordnung von Fächern zu Berufen
  - Fachtyp, Wochenstunden, Credits konfigurierbar
  - RBS-konformes Design (Cards, Dialoge, Farben)
  - Route `/einstellungen` im Navigation-Drawer (nur für Admins!)
  - Firestore-Persistenz für alle Operationen
- **Flexibler Login mit Kürzel und Email** - NEU ✅
  - Login unterstützt jetzt BEIDE Eingabearten: Kürzel (z.B. "BU") UND vollständige Email-Adresse
  - Groß-/Kleinschreibung bei Kürzeln irrelevant (automatische Konvertierung)
  - Automatische Kürzel-zu-Email-Auflösung über Firestore `app_users` Collection
  - Neue Methode `FirestoreService.getAppUserByKuerzel()` für Kürzel-Lookup
  - Fallback auf alte `@induscore.de` Konvention wenn Kürzel nicht in Firestore gefunden
  - Script `create_both_users.js` zum Erstellen von appUser-Dokumenten für existierende Auth-User
  - Script `check_kuerzel.js` zum Testen der Kürzel-Firestore-Abfragen
- **Firestore Security Rules** - NEU ✅
  - Pre-Login Lesezugriff auf `app_users` Collection für Kürzel-Lookup
  - Schreibschutz für `app_users` und `subjects` (nur Admins)
  - Granulare Rules für alle Collections (klassen, grades, leistungsnachweise)
  - Deployed über Firebase CLI (`firestore.rules` + `firebase.json`)

### Changed
- Version auf 0.15.0 für v0.15.0 MVP Vorbereitung
- Versionsnummern-Notation durchgehend auf v0.15.0 vereinheitlicht (statt v1.0.0)
- **Admin Einstellungen nur für Admins** (Issue #49) - ABGESCHLOSSEN ✅
  - Settings Screen in Navigation nur für Admins sichtbar
  - Screen-Titel von "Einstellungen" zu "Admin Einstellungen" geändert
  - Benutzerverwaltung und Admin Einstellungen zusammengefasst im Admin-Bereich

### Fixed
- **Settings Screen Bugs** (Issue #49) - ABGESCHLOSSEN ✅
  - Farbparsing-Fehler behoben: Hex-Farben mit `#` werden jetzt korrekt geparst
  - Screen-Titel korrigiert: "Admin Einstellungen" statt "Einstellungen"
- **Login-Problem behoben**: Eingabe von Kürzeln funktioniert jetzt mit echten Email-Domains (@bs-ie.muenchen.musin.de, @gmx.de), nicht nur mit gehardcodeten @induscore.de
- **Firestore Permission Denied beim Kürzel-Login behoben**: Security Rules erlauben jetzt Pre-Login Lesezugriff
- **DEBUG-Code entfernt**: Admin-User-Erstellungs-Button wurde aus Login-Screen entfernt
- **DEBUG print-Statements entfernt**: Alle print()-Aufrufe aus login_screen.dart entfernt (Lint-Warnungen behoben)

---

## [0.14.0] - 2025-12-18

### Added
- **Berechtigungssystem erweitert (Issue #39)** ✅
  - 4 Benutzerrollen: Admin, Lehrer, Ausbilder*, Schüler* 
    (*Ausbilder/Schüler: Reserviert für separate App, aktuell nicht aktiv genutzt)
  - Permission Provider für alle Operationen (`permissions_providers.dart`)
  - Permission Guards in allen relevanten Screens (Buttons, Menü-Einträge)
  - Favoriten-Klassen System für Lehrer/Ausbilder
  - Dashboard Favoriten-Toggle (⭐) mit Auto-Filter
  - Ownership-Tracking für Leistungsnachweise (`createdBy` Feld)

### Changed
- **Benutzerverwaltung komplett überarbeitet**
  - Email-Adresse jetzt bearbeitbar (mit Warnung)
  - Alle 4 Rollen auswählbar
  - Favoriten-Klassen Multiselect (für Lehrer/Ausbilder)
  - `canManageUsersProvider` statt `isCurrentUserAdminProvider`
- **AppUser Model erweitert**
  - `klassenIds` → `favoriteKlassenIds` (mit Migration-Fallback)
  - Kürzel jetzt immer uppercase gespeichert
  - 2 neue Rollen: Ausbilder, Schüler
- **Kürzel Case-Insensitivity**
  - Login funktioniert mit "mu", "MU", "Mu"
  - Anzeige immer uppercase
  - `TextCapitalization.characters` auf allen Kürzel-Inputs
- **Screen-Zugriff eingeschränkt**
  - CSV Import: Nur Admin
  - Klassen/Fächer/Schüler anlegen/bearbeiten/löschen: Nur Admin
  - Leistungsnachweise anlegen: Admin + Lehrer + Ausbilder
  - Leistungsnachweise bearbeiten/löschen: Nur eigene (Admin kann alle)
  - Benutzerverwaltung: Nur Admin
- **Dashboard optimiert**
  - Favoriten-Filter für Lehrer/Ausbilder (Default: aktiv)
  - Admin sieht standardmäßig alle Klassen
  - Kombination mit Zeitgruppen-Filter möglich
- **Drawer-Menü rollenbasiert**
  - CSV Import nur für Admin sichtbar
  - Benutzerverwaltung nur für Admin sichtbar
  - Alle anderen Menüs: Admin + Lehrer + Ausbilder

### Fixed
- Alle Linter-Warnungen behoben (TODOs, relative imports, avoid_print)
- Permission Guards in allen Create/Edit/Delete Buttons

### Technical Notes
- Neue Permission Providers (lib/providers/permissions_providers.dart):
  - `canManageUsersProvider` - Nur Admin (Benutzerverwaltung)
  - `canImportCSVProvider` - Nur Admin (CSV Import)
  - `canManageDataProvider` - Admin + Lehrer + Ausbilder (Lesen von Daten)
  - `canCreateDataProvider` - Nur Admin (Anlegen von Klassen, Fächern, Schülern)
  - `canCreateLeistungsnachweisProvider` - Admin + Lehrer + Ausbilder
  - `canEditLeistungsnachweisProvider(LN)` - Admin (alle) + Lehrer/Ausbilder (nur eigene)
- Migration-Fallbacks in Code (keine Datenbank-Migration erforderlich)
- Script: `scripts/create_admin.dart` zum Anlegen von Admin-Usern
  - `canEditLeistungsnachweisProvider(ln)` - Admin=alle, Lehrer/Ausbilder=eigene
- `FavoritenFilterNotifier` für Dashboard-Filter
- Automatische Migration durch Fallbacks (keine manuelle Migration nötig)
- Migrationsdokumentation: `docs/MIGRATION_0.14.0.md`

### Security
- Berechtigungen werden serverseitig validiert (Permission Provider)
- Screens zeigen "Zugriff verweigert" bei fehlenden Berechtigungen
- Lehrer/Ausbilder können nur eigene Leistungsnachweise bearbeiten

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
