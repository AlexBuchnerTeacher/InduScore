# InduScore Refactoring Roadmap

**Erstellt**: 2025-12-29
**Letzte Aktualisierung**: 2025-12-29
**Status**: Phase 1 Complete ✅

---

## 📊 Überblick

Basierend auf umfassenden Code-Analysen (PR #51, #52) wurden **20 priorisierte Findings** identifiert und in einen **3-Phasen-Plan** überführt:

- **Phase 1 (v0.17.0)**: Stabilisieren - Code-Qualität, Tests ✅ **COMPLETE**
- **Phase 2 (v0.18.0)**: Strukturieren - Security, Architecture ⏳ **PLANNED**
- **Phase 3 (v1.0.0)**: Optimieren - Performance, Accessibility ⏳ **PLANNED**

**Ziel**: Repo-Score von 7.25/10 → 9/10

---

## ✅ Phase 1: Stabilisieren (v0.17.0) - COMPLETE

**Issue**: #54 (geschlossen am 2025-12-29)
**Dauer**: 2-3 Wochen (aktive Entwicklung)
**Status**: 6/6 Tasks complete (100%)

### Achievements

| Task | Finding | LOC Impact | Status |
|------|---------|-----------|--------|
| klassen_screen.dart | F-001 | 608→304 (-50%) | ✅ Merged |
| noten_matrix_view.dart | F-002 | 1056→91 (-91%) | ✅ Merged |
| csv_import_screen.dart | F-003 | 1068→954 (-11%) | ✅ Merged |
| Model Unit Tests | F-006 | 63 tests, >80% coverage | ✅ Merged |
| Strict Lint Rules | F-015 | 38 rules, 0 errors | ✅ Merged |
| Dialog Consolidation | F-011/F-012 | ~150-200 LOC saved | ✅ Merged |

### Metrics

- **Total LOC Reduced**: -1647 lines (net: -1148 after new reusable code)
- **Widgets Created**: 24 focused, reusable components
- **Tests**: 203/203 passing (100%)
- **Code Quality**: 0 errors, 3 info warnings (safe)
- **PRs Merged**: #64, #65, #66

### Deliverables

**Widget Libraries:**
- `lib/screens/widgets/klassen_list_section.dart` (159 LOC)
- `lib/screens/widgets/klassen_grid_section.dart` (145 LOC)
- `lib/features/noten/widgets/klassen_matrix_widget.dart` (412 LOC)
- `lib/features/noten/widgets/schueler_matrix_widget.dart` (301 LOC)
- `lib/features/noten/widgets/ln_matrix_widget.dart` (359 LOC)
- `lib/features/noten/widgets/matrix_common_widgets.dart` (155 LOC)
- `lib/screens/widgets/csv_import_widgets.dart` (246 LOC)
- `lib/widgets/dialogs/common_dialogs.dart` (253 LOC)

**Test Files:**
- `test/models/student_test.dart` (24 tests)
- `test/models/subject_test.dart` (15 tests)
- `test/models/klasse_test.dart` (15 tests)
- `test/models/leistungsnachweis_test.dart` (9 tests)

**Configuration:**
- `analysis_options.yaml` - Erweitert mit 38 Strict Lint Rules

### Key Learnings

1. **Widget Extraction**: Erfolgreich für UI-Widgets, schwierig für state-coupled Logic
2. **Test-First Approach**: Erst Tests, dann Refactoring - 0 Regressions
3. **Incremental PRs**: Kleinere PRs (1-2 Tasks) schneller merged als große
4. **Dialog Pattern**: 16 von 31 Dialogs konsolidiert - Rest sind spezialisierte Widgets

---

## ⏳ Phase 2: Strukturieren (v0.18.0) - PLANNED

**Issue**: #67
**Geschätzte Dauer**: 3-4 Wochen
**Status**: Planning
**Scope**: 8 Findings

### Ziele

- **Security**: Firestore Rules härten (rollenbasiert, Field-Level)
- **Testability**: Dependency Injection für alle Services
- **Architecture**: Migration `screens/` → `features/` abschließen
- **Performance**: Pagination für alle Listen
- **Quality**: Service-Tests, Dartdoc, Standard-Error-Handling

### Tasks

| Finding | Beschreibung | Impact | Effort | Deliverable |
|---------|-------------|--------|--------|-------------|
| F-004 | Firestore Rules rollenbasiert | High | Small | `firestore.rules` (4 Rollen) |
| F-005 | Field-Level Security | Medium | Medium | Erweiterte Rules + Field-Validation |
| F-008 | Service-Tests (PDF, NOI, CSV) | Medium | Medium | 3 Test-Dateien, >60% Coverage |
| F-013 | Dependency Injection | Medium | Medium | Constructor DI für alle Services |
| F-016 | Migration screens → features | Medium | Large | `lib/features/` komplett |
| F-009 | Pagination | Medium | Medium | Max. 50 Items initial |
| F-014 | Dartdoc | Low | Small | Alle Services dokumentiert |
| F-018 | Error-Handling | Low | Small | `error_snack_bar.dart` |

### Abnahmekriterien

- [ ] Firestore Rules: 4 Rollen mit Field-Validation
- [ ] Firestore Rules Tests (Emulator)
- [ ] Service Tests: >60% Coverage
- [ ] Architecture: Nur noch `lib/features/`
- [ ] Pagination überall
- [ ] Dartdoc für alle Services
- [ ] Coverage >65%

### Risiken

- ⚠️ **Firestore Rules**: Könnte Production brechen → Emulator-Tests vor Deploy
- ⚠️ **DI**: Breaking Change → Migration Guide, Versionierung v0.18.0
- ⚠️ **Migration**: Könnte Routing brechen → Manuelle Tests aller Routes

---

## ⏳ Phase 3: Optimieren (v1.0.0) - PLANNED

**Issue**: #68
**Geschätzte Dauer**: 4-6 Wochen
**Status**: Planning
**Scope**: 6 Findings

### Ziele

- **Quality**: E2E-Tests für kritische Workflows
- **Performance**: Code Splitting, Lazy Loading, Provider-Optimierungen
- **Accessibility**: Semantics, Screen Reader, WAVE-Tool Compliance
- **Security (Optional)**: Ende-zu-Ende Verschlüsselung

### Tasks

| Finding | Beschreibung | Impact | Effort | Deliverable |
|---------|-------------|--------|--------|-------------|
| F-007 | Integration Tests | Medium | Large | 3-4 E2E-Tests |
| F-010 | Provider `.select()` | Low | Small | Optimierte Watches |
| F-017 | Accessibility | Medium | Medium | Semantics, Lighthouse >90 |
| F-020 | Web-Optimierungen | Low | Medium | Lazy Loading, <3s Load |
| BONUS | Verschlüsselung (Optional) | High | Large | AES-256, Recovery-Key |

### Abnahmekriterien

- [ ] E2E-Tests: 3-4 kritische Workflows
- [ ] Lighthouse Accessibility: >90
- [ ] Lighthouse Performance: >80
- [ ] Initial Load: <3s
- [ ] Coverage: >70%
- [ ] WAVE-Tool: 0 Critical Errors
- [ ] Verschlüsselung: Aktiv (OPTIONAL)

### Risiken

- ⚠️ **E2E-Tests**: Flaky → Retry-Logik, stable selectors
- ⚠️ **Verschlüsselung**: Komplex → Proof of Concept zuerst
- ⚠️ **Performance**: Könnte neue Bugs bringen → A/B Testing

---

## 📈 Success Metrics

### Vorher (v0.16.0)

- Code-Qualität: 7/10
- Sicherheit: 5/10
- Tests: 7/10
- Coverage: 51.71%
- Dateien >800 LOC: 5

### Nach Phase 1 (v0.17.0) - AKTUELL

- Code-Qualität: 8/10 ⬆️
- Sicherheit: 5/10 (unverändert)
- Tests: 8/10 ⬆️
- Coverage: ~55% ⬆️
- Dateien >800 LOC: 2 ⬇️

### Nach Phase 2 (v0.18.0) - ZIEL

- Code-Qualität: 8.5/10
- Sicherheit: 9/10 ⬆️⬆️
- Tests: 8.5/10 ⬆️
- Coverage: >65%
- Dateien >800 LOC: 0 ⬇️

### Nach Phase 3 (v1.0.0) - ENDZIEL

- Code-Qualität: 9/10
- Sicherheit: 9/10
- Tests: 9/10 ⬆️
- Coverage: >70%
- Dateien >800 LOC: 0
- **Repo-Score: 9/10** 🎯

---

## 🔗 Referenzen

### Issues
- **Phase 1**: #54 (geschlossen)
- **Phase 2**: #67 (offen)
- **Phase 3**: #68 (offen)

### Pull Requests (Phase 1)
- PR #64: noten_matrix_view widget extraction
- PR #65: csv_import_screen widget extraction
- PR #66: Common dialog library

### Dokumentation
- [Code-Analyse PR #51](https://github.com/AlexBuchnerTeacher/InduScore/pull/51): REPO_ANALYSIS_COMPLETE.md
- [Detaillierter Report PR #52](https://github.com/AlexBuchnerTeacher/InduScore/pull/52): REPOSITORY_ANALYSIS_REPORT.md
- [Architecture](./ARCHITECTURE.md): Feature-based Architecture
- [Testing Strategy](./TESTING_STRATEGY.md): Test-Pyramide, Coverage-Ziele
- [Coding Guidelines](../CODING_GUIDELINES.md): v2.0, 1000+ Zeilen

---

## 📋 Nächste Schritte

### Sofort (v0.17.0 Release)

1. **Release v0.17.0** erstellen mit Phase 1 Changes:
   - CHANGELOG.md aktualisieren ([Unreleased] → [0.17.0])
   - Git Tag erstellen
   - GitHub Release publizieren
   - Build deployen (optional)

2. **Issue #54 Cleanup**:
   - ✅ Issue geschlossen
   - ✅ Follow-up Issues erstellt (#67, #68)
   - Phase 1 Erfolg kommunizieren

### Nächster Sprint (Phase 2 Start)

1. **Dependency Injection** (F-013) - Services testbar machen
2. **Service-Tests** (F-008) - PDF, NOI, CSV
3. **Firestore Rules** (F-004, F-005) - Security härten

---

**Last Updated**: 2025-12-29
**Maintained by**: Development Team
**Review Frequency**: Nach jeder Phase
