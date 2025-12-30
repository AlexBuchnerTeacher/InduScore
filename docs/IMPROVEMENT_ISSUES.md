# Improvement Issues - Backlog

Basierend auf der Repo Deep-Dive Analyse (siehe `docs/REPO_DEEP_DIVE_ANALYSIS.md`)

---

## Phase 1: Stabilisieren

### Issue: F-001 - API-Key aus Repository entfernen
**Priority:** 🔴 HIGH  
**Effort:** S (Small, <2h)  
**Category:** Security

#### Beschreibung
Firebase API-Key ist öffentlich im Repository sichtbar.

#### Fundstelle
`lib/firebase_options.dart:27`

#### Tasks
- [ ] Package `flutter_dotenv` hinzufügen
- [ ] `.env.example` Template erstellen
- [ ] `firebase_options.dart` auf Environment-Variables umstellen
- [ ] `.env` zu `.gitignore` hinzufügen
- [ ] CI/CD Workflow mit GitHub Secrets aktualisieren
- [ ] Dokumentation in README.md updaten

#### Akzeptanzkriterien
- API-Key nicht mehr hardcoded im Repository
- CI baut erfolgreich mit GitHub Secrets
- Local Development funktioniert mit `.env`

---

### Issue: F-006 - Widget-Tests für kritische Screens
**Priority:** 🟡 MEDIUM  
**Effort:** L (Large, >8h)  
**Category:** Testing

#### Beschreibung
Keine Widget-Tests für kritische Screens vorhanden.

#### Fundstellen
- `lib/features/import/screens/csv_import_screen.dart` (1034 LOC)
- `lib/features/noten/screens/noten_eingabe_screen.dart` (785 LOC)
- `lib/features/noten/screens/noten_uebersicht_screen.dart` (950 LOC)

#### Tasks
- [ ] `test/features/import/screens/csv_import_screen_test.dart` erstellen
- [ ] `test/features/noten/screens/noten_eingabe_screen_test.dart` erstellen
- [ ] `test/features/noten/screens/noten_uebersicht_screen_test.dart` erstellen
- [ ] Mindestens 10 Tests pro Screen

#### Akzeptanzkriterien
- 30+ neue Tests
- >60% Coverage pro Screen
- CI grün

---

### Issue: F-007 - Coverage-Threshold erhöhen
**Priority:** 🟡 MEDIUM  
**Effort:** S (Small, <2h)  
**Category:** CI/CD

#### Beschreibung
Coverage-Threshold ist nur 35%, sollte mindestens 50% sein.

#### Fundstelle
`.github/workflows/ci.yml:55`

#### Tasks
- [ ] MIN_COVERAGE von 35 auf 50 erhöhen
- [ ] Sicherstellen dass aktuelle Tests 50%+ erreichen
- [ ] CI-Run validieren

#### Akzeptanzkriterien
- CI prüft auf 50%+ Coverage
- CI bleibt grün

---

### Issue: F-010 - debugPrint Statements entfernen
**Priority:** 🟢 LOW  
**Effort:** S (Small, <2h)  
**Category:** Code Quality

#### Beschreibung
10 debugPrint Statements sind noch im Code vorhanden.

#### Fundstellen
- Diverse Dateien in `lib/`

#### Tasks
- [ ] `grep -rn "debugPrint" lib/` ausführen
- [ ] Alle debugPrint Statements analysieren
- [ ] Entfernen oder hinter `kDebugMode` Guard setzen
- [ ] CI-Run validieren

#### Akzeptanzkriterien
- 0 debugPrint Statements in Production Code
- Keine Regression in Tests

---

### Issue: F-012 - Pre-Commit Hooks Setup
**Priority:** 🟢 LOW  
**Effort:** M (Medium, 2-8h)  
**Category:** DX

#### Beschreibung
Keine Pre-Commit Hooks vorhanden.

#### Tasks
- [ ] `husky` und `lint-staged` über npm installieren
- [ ] Pre-Commit Hook für `flutter analyze` konfigurieren
- [ ] Pre-Commit Hook für `dart format --set-exit-if-changed` konfigurieren
- [ ] CONTRIBUTING.md mit Setup-Anleitung updaten

#### Akzeptanzkriterien
- Pre-Commit Hook blockt unformattierten Code
- Pre-Commit Hook blockt Code mit Lint-Fehlern
- Dokumentation vorhanden

---

## Phase 2: Strukturieren

### Issue: F-002 - csv_import_screen.dart refactoren
**Priority:** 🟡 MEDIUM  
**Effort:** L (Large, >8h)  
**Category:** Tech Debt

#### Beschreibung
Screen hat 1034 LOC, deutlich über dem 500 LOC Limit.

#### Fundstelle
`lib/features/import/screens/csv_import_screen.dart:1-1034`

#### Tasks
- [ ] Widget-Extraktion: Preview-Table Widget
- [ ] Widget-Extraktion: Column-Mapping Widget
- [ ] Widget-Extraktion: Import-Button Widget
- [ ] Logic-Extraktion: CSV-Parsing Logic in separaten Controller
- [ ] Tests anpassen

#### Akzeptanzkriterien
- Haupt-Screen <500 LOC
- 3-4 neue Widget-Dateien
- Alle bestehenden Tests grün
- Neue Tests für extrahierte Widgets

---

### Issue: F-003 - noten_uebersicht_screen.dart optimieren
**Priority:** 🟡 MEDIUM  
**Effort:** M (Medium, 2-8h)  
**Category:** Tech Debt

#### Beschreibung
Screen hat 950 LOC, Matrix-Widgets bereits extrahiert, Filter/Header noch im Screen.

#### Fundstelle
`lib/features/noten/screens/noten_uebersicht_screen.dart:1-950`

#### Tasks
- [ ] Filter-Section als Widget extrahieren
- [ ] Header/Title als Widget extrahieren
- [ ] Statistiken-Bereich als Widget extrahieren

#### Akzeptanzkriterien
- Screen <500 LOC
- Alle Tests grün

---

### Issue: F-004 - noten_eingabe_screen.dart refactoren
**Priority:** 🟡 MEDIUM  
**Effort:** M (Medium, 2-8h)  
**Category:** Tech Debt

#### Beschreibung
Screen hat 785 LOC, über dem 500 LOC Limit.

#### Fundstelle
`lib/features/noten/screens/noten_eingabe_screen.dart:1-785`

#### Tasks
- [ ] InputRow Widget extrahieren
- [ ] SaveButton Widget extrahieren
- [ ] Tendenz-Buttons Widget extrahieren

#### Akzeptanzkriterien
- Screen <500 LOC
- Alle Tests grün

---

### Issue: F-005 - FirestoreService aufsplitten
**Priority:** 🟡 MEDIUM  
**Effort:** L (Large, >8h)  
**Category:** Tech Debt

#### Beschreibung
Service hat 849 LOC, über dem 800 LOC Limit.

#### Fundstelle
`lib/services/firestore_service.dart:1-849`

#### Tasks
- [ ] StudentService extrahieren
- [ ] KlasseService extrahieren
- [ ] GradeService extrahieren
- [ ] LeistungsnachweisService extrahieren
- [ ] Provider-Referenzen aktualisieren
- [ ] Tests anpassen

#### Akzeptanzkriterien
- Jeder Service <300 LOC
- Alle Provider-Referenzen aktualisiert
- Alle Tests grün

---

### Issue: F-009 - Cloud Function für Kürzel-Lookup
**Priority:** 🟡 MEDIUM  
**Effort:** M (Medium, 2-8h)  
**Category:** Security

#### Beschreibung
Pre-Login Read auf app_users Collection ermöglicht Enumeration.

#### Fundstelle
`firestore.rules:53`

#### Tasks
- [ ] Cloud Function erstellen für Kürzel-zu-Email-Lookup
- [ ] Rate-Limiting implementieren
- [ ] Firestore Rules anpassen (kein Pre-Login Read mehr)
- [ ] Login-Screen auf Cloud Function umstellen
- [ ] Tests

#### Akzeptanzkriterien
- Cloud Function deployed
- Rate-Limiting aktiv (max 10 Requests/Minute)
- Firestore Rules ohne Pre-Login Read

---

### Issue: F-013 - ADRs in separate Dateien
**Priority:** 🟢 LOW  
**Effort:** S (Small, <2h)  
**Category:** Documentation

#### Beschreibung
ADRs sind inline in ARCHITECTURE.md statt in separaten Dateien.

#### Fundstelle
`docs/ARCHITECTURE.md:470-530`

#### Tasks
- [ ] `docs/adrs/` Ordner erstellen
- [ ] ADR-Template erstellen
- [ ] Existierende ADRs extrahieren:
  - [ ] ADR-001: Riverpod statt Bloc/GetX
  - [ ] ADR-002: Keine Code-Generation (freezed)
  - [ ] ADR-003: Firebase statt eigenes Backend
  - [ ] ADR-004: Material Design 3

#### Akzeptanzkriterien
- `docs/adrs/` mit 4+ ADR-Dateien
- ARCHITECTURE.md verlinkt zu ADRs

---

## Phase 3: Optimieren/Skalieren

### Issue: F-008 - Pagination für Schüler-Listen
**Priority:** 🟡 MEDIUM  
**Effort:** M (Medium, 2-8h)  
**Category:** Performance

#### Beschreibung
studentsProvider lädt alle Schüler ohne Pagination.

#### Fundstelle
`lib/providers/app_providers.dart:56-59`

#### Tasks
- [ ] PaginatedFirestoreList Widget in SchuelerScreen integrieren
- [ ] Infinite Scroll implementieren
- [ ] Loading-States
- [ ] Tests

#### Akzeptanzkriterien
- Lazy-Loading in SchuelerScreen
- Nur 25 Schüler initial geladen
- Performance-Verbesserung messbar

---

### Issue: F-011 - Integration-Tests erweitern
**Priority:** 🟢 LOW  
**Effort:** M (Medium, 2-8h)  
**Category:** Testing

#### Beschreibung
Integration-Tests nur Scaffold (1 Datei, 4 Tests).

#### Fundstelle
`integration_test/app_test.dart`

#### Tasks
- [ ] Login → Dashboard Flow testen
- [ ] Dashboard → Klassen → Detail Flow testen
- [ ] Noten-Eingabe Flow testen
- [ ] Export Flow testen
- [ ] Error-Handling Flow testen

#### Akzeptanzkriterien
- 5+ E2E-Flows getestet
- CI führt Integration-Tests aus

---

### Issue: F-014 - Firestore Offline-Caching
**Priority:** 🟢 LOW  
**Effort:** S (Small, <2h)  
**Category:** Performance

#### Beschreibung
Firestore Offline-Caching nicht aktiviert.

#### Fundstelle
`lib/main.dart`

#### Tasks
- [ ] `persistenceEnabled: true` in Firestore Settings
- [ ] Offline-Modus testen
- [ ] Sync-Indicator bei Reconnect

#### Akzeptanzkriterien
- App funktioniert offline
- Änderungen werden bei Reconnect synchronisiert

---

### Issue: F-015 - Golden-Tests für UI-Regression
**Priority:** 🟢 LOW  
**Effort:** M (Medium, 2-8h)  
**Category:** Testing

#### Beschreibung
Keine Golden-Tests für UI-Regression.

#### Tasks
- [ ] Golden-Test für RBSDrawer
- [ ] Golden-Test für RBSButton
- [ ] Golden-Test für RBSCard
- [ ] Golden-Test für NotenMatrixView
- [ ] Golden-Test für DashboardStatisticsGrid

#### Akzeptanzkriterien
- 5+ Golden-Tests
- CI prüft Golden-Tests

---

### Issue: F-017 - CSP Headers in Firebase Hosting
**Priority:** 🟢 LOW  
**Effort:** S (Small, <2h)  
**Category:** Security

#### Beschreibung
Keine Content-Security-Policy Headers.

#### Fundstelle
`firebase.json`

#### Tasks
- [ ] CSP Headers in firebase.json konfigurieren
- [ ] X-Content-Type-Options Header
- [ ] X-Frame-Options Header
- [ ] Deploy und testen

#### Akzeptanzkriterien
- Lighthouse Security Score verbessert
- CSP Headers aktiv

---

## Zusammenfassung

| Phase | Issues | Total Effort |
|-------|--------|--------------|
| Phase 1: Stabilisieren | 5 Issues | ~4 Tage |
| Phase 2: Strukturieren | 6 Issues | ~8 Tage |
| Phase 3: Optimieren | 5 Issues | ~6 Tage |
| **Gesamt** | **16 Issues** | **~18 Tage** |

---

**Erstellt:** 2025-12-30  
**Basierend auf:** Repo Deep-Dive Analyse v0.32.0
