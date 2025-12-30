# Release Notes v0.18.0 - Phase 2: Testing & Security

**Release-Datum:** 30. Dezember 2025  
**Issue:** [#67 Phase 2: Testbare Services & Security](https://github.com/FelixSchwarz/notentool_web/issues/67)

## Übersicht

Phase 2 fokussiert auf **Testbarkeit** und **Sicherheit**. Die wichtigsten Änderungen:

- ✅ **50 neue Unit-Tests** für Export-Services
- ✅ **Dependency Injection** für Firebase-Services
- ✅ **Verbesserte Firestore Security Rules** mit rollenbasierter Zugriffskontrolle
- ✅ **Service-Dokumentation** (Dartdoc)

## Neue Features

### Service Test Suite (F-008)

Umfassende Unit-Tests für alle Export-Services:

| Service | Tests | Abdeckung |
|---------|-------|-----------|
| CsvImportService | 22 | Spaltenerkennung, Parsing, Encoding |
| NoiExportService | 17 | XML-Generierung, Sonderzeichen, Validierung |
| PdfExportService | 16 | PDF-Erzeugung, Formatierung |
| **Gesamt** | **253** | +50 neue Tests |

### Dependency Injection (F-013)

AuthService und FirestoreService unterstützen nun Constructor Injection:

```dart
// Produktion (Standard)
final authService = AuthService();

// Tests (mit Mock)
final authService = AuthService(firebaseAuth: mockAuth);
```

### Firestore Security Rules (F-004/F-005)

Neue Helper-Funktionen und rollenbasierte Zugriffskontrolle:

```javascript
// Helper-Funktionen
function isAdmin() { ... }
function isAktiv() { ... }
function hasAccessToKlasse(klasseId) { ... }

// Field-Level Security für app_users
// Geschützte Felder: rolle, status, email, kuerzel
```

**Zugriffsmatrix:**

| Collection | Lehrer | Admin |
|------------|--------|-------|
| app_users (eigene) | Lesen, Update* | Vollzugriff |
| subjects | Lesen | Vollzugriff |
| klassen | Lesen, Create, Update** | Vollzugriff |
| students | Lesen, Create, Update** | Vollzugriff |
| leistungsnachweise | Lesen, Create, Update*** | Vollzugriff |
| grades | CRUD | Vollzugriff |

*Ohne geschützte Felder  
**Nur eigene Klassen  
***Nur eigene LNs

## Verschoben auf Phase 3

Folgende Tasks wurden auf Phase 3 verschoben (größerer Aufwand):

- **F-016**: Migration screens → features (>16h)
- **F-009**: Pagination für Firestore-Queries
- **F-018**: Einheitliche Fehlerbehandlung

## Upgrade-Anleitung

1. **Code aktualisieren:**
   ```bash
   git pull origin main
   flutter pub get
   ```

2. **Firestore Rules deployen:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Tests ausführen:**
   ```bash
   flutter test
   ```

## Kompatibilität

- Keine Breaking Changes
- Alle 253 Tests bestanden
- Flutter 3.x kompatibel

## Nächste Schritte (Phase 3)

- Migration der verbleibenden Screens zu Features
- Pagination für große Datenmengen
- Zentrale Fehlerbehandlung mit App-weiten Error-Dialogen

---

**Vollständiges Changelog:** [CHANGELOG.md](CHANGELOG.md)  
**Issue #67:** [Phase 2: Testbare Services & Security](https://github.com/FelixSchwarz/notentool_web/issues/67)
