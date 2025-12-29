# Phase 2: Strukturieren (v0.18.0) - Security & Architecture

**Parent Issue**: #54 (Phase 1 complete ✅)
**Estimated Duration**: 3-4 Wochen
**Target Version**: v0.18.0

## 🎯 Ziel
Architecture aufräumen, Security härten, Services testbar machen

---

## 📋 Scope (8 Findings)

### F-004: Firestore Rules rollenbasiert
- **Impact**: High | **Effort**: Small (<4h)
- **Problem**: `allow read, write: if request.auth != null;` - alle authentifizierten User dürfen alles
- **Lösung**: Rollenbasierte Access Control (Admin/Lehrer/Ausbilder/Schüler)
- **Deliverable**: `firestore.rules` mit Role-Based Access Control

### F-005: Field-Level Security in Firestore Rules
- **Impact**: Medium | **Effort**: Medium (4-16h)
- **Problem**: Keine Field-Validation in Rules
- **Lösung**: Field-Level Security (z.B. nur Lehrer dürfen Noten ändern)
- **Deliverable**: Erweiterte `firestore.rules` mit Field-Validation

### F-008: Service-Tests (PDF, NOI, CSV)
- **Impact**: Medium | **Effort**: Medium (4-16h)
- **Problem**: Keine Tests für kritische Services
- **Lösung**: Unit Tests für PDF Export, NOI Export, CSV Import
- **Deliverable**: 
  - `test/services/pdf_export_service_test.dart`
  - `test/services/noi_export_service_test.dart`
  - `test/services/csv_import_service_test.dart`
- **Ziel**: >60% Coverage pro Service

### F-013: Dependency Injection für Services
- **Impact**: Medium | **Effort**: Medium (4-16h)
- **Problem**: `FirebaseFirestore.instance` hardcoded - nicht testbar
- **Lösung**: Constructor Injection für alle Services
- **Deliverable**: Alle Services mit DI (`lib/services/*_service.dart`)
- **Breaking Change**: Ja, Migration Guide notwendig

### F-016: Migration `screens/` → `features/`
- **Impact**: Medium | **Effort**: Large (>16h)
- **Problem**: Unvollständige Migration - `screens/` und `features/` parallel
- **Lösung**: Alle Screens nach `features/` migrieren
- **Deliverable**:
  - `lib/features/dashboard/` (von home_screen.dart)
  - `lib/features/noten/` (von noten_*.dart)
  - `lib/screens/` leer oder deprecated

### F-009: Pagination für Firestore Queries
- **Impact**: Medium | **Effort**: Medium (4-16h)
- **Problem**: `loadAll()` - keine Pagination, Performance-Problem bei >500 Schülern
- **Lösung**: Firestore Pagination (max. 50 Items initial, "Load More" Button)
- **Deliverable**: Pagination in allen Listen (Schüler, Klassen, Fächer, LNs)

### F-014: Dartdoc für alle Services
- **Impact**: Low | **Effort**: Small (<4h)
- **Problem**: Services ohne Dartdoc-Kommentare
- **Lösung**: Dartdoc für alle Public APIs
- **Deliverable**: Alle Services dokumentiert

### F-018: Error-Handling standardisieren
- **Impact**: Low | **Effort**: Small (<4h)
- **Problem**: Inconsistent Error-Handling (Mix aus SnackBar, Dialog, Logger)
- **Lösung**: Standard-Error-Widget überall
- **Deliverable**: `lib/widgets/error_snack_bar.dart`, einheitlich genutzt

---

## 📦 Deliverables

### Security
- [ ] `firestore.rules` (rollenbasiert, Field-Validation)
- [ ] `test/firestore_rules_test.dart` (Emulator-Tests)

### Testing
- [ ] `test/services/pdf_export_service_test.dart`
- [ ] `test/services/noi_export_service_test.dart`
- [ ] `test/services/csv_import_service_test.dart`

### Architecture
- [ ] `lib/services/*_service.dart` (Constructor DI)
- [ ] `lib/features/dashboard/` (Migration von home_screen.dart)
- [ ] `lib/features/noten/` (Migration von noten_*.dart)
- [ ] `lib/widgets/error_snack_bar.dart`
- [ ] `docs/MIGRATION_0.18.0.md`

---

## 🎯 Abnahmekriterien

- [ ] **Firestore Rules**: 4 Rollen mit Field-Validation
- [ ] **Firestore Rules Tests**: Emulator-Tests für alle Rollen
- [ ] **Service Tests**: 3 Test-Dateien mit >60% Coverage
- [ ] **Architecture**: Nur noch `lib/features/`, `lib/screens/` leer
- [ ] **Pagination**: Max. 50 Items initial in allen Listen
- [ ] **Dartdoc**: Alle Services dokumentiert
- [ ] **Error-Handling**: Standard-Widget überall genutzt
- [ ] **Coverage**: >65% (Target)
- [ ] **Tests**: Alle passing
- [ ] **Breaking Changes**: Migration Guide vorhanden

---

## ⚠️ Risiken & Mitigation

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Firestore Rules brechen Production | Medium | High | Emulator-Tests vor Deploy, Staged Rollout |
| Migration bricht Routing | Medium | High | Manuelle Tests aller Routes, E2E-Tests |
| DI ist Breaking Change | High | Medium | Versionierung (v0.18.0), Migration Guide |
| Service-Tests komplex | Medium | Low | Mocking Framework (mockito), Incrementell |

---

## 📊 Reihenfolge (empfohlen)

1. **Dependency Injection** (F-013) - Services testbar machen
2. **Service-Tests** (F-008) - Tests schreiben
3. **Firestore Rules** (F-004, F-005) - Security härten + Emulator-Tests
4. **Migration screens → features** (F-016) - Architecture cleanup
5. **Pagination** (F-009) - Performance
6. **Error-Handling** (F-018) - UX consistency
7. **Dartdoc** (F-014) - Dokumentation

---

## 🔗 Referenzen

- **Phase 1 (Complete)**: #54
- **Phase 3 (Planned)**: Will be created after Phase 2
- **Architecture Docs**: docs/ARCHITECTURE.md
- **Testing Strategy**: docs/TESTING_STRATEGY.md

---

**Created**: 2025-12-29
**Status**: Planning
**Assignee**: TBD
