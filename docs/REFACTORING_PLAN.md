# InduScore - 3-Phasen Refactoring-Plan

**Version:** 0.16.0  
**Datum:** 2025-12-29  
**Basis:** Repository-Analyse (REPO_ANALYSIS_COMPLETE.md)

---

## PHASE 1: STABILISIEREN (Prio 1)

### Ziel
Technische Schulden eliminieren, eigene Coding Guidelines einhalten, CI härten.

### Scope
- Widget-Extraktion großer Dateien (6 Dateien >800 LOC)
- SnackBar-Helper (56x Duplikate)
- CI-Verbesserungen (Coverage, Lints, Dependency-Audit)
- .gitignore Cleanup

### Reihenfolge (nach Business Impact)
1. **klassen_screen.dart Widget-Extraktion** (F01, kritischste Datei 1268 LOC)
2. **noten_matrix_view.dart Widget-Extraktion** (F01, 1137 LOC)
3. **csv_import_screen.dart Refactoring** (F01, 1094 LOC)
4. **SnackBar-Helper** (F05, Quick Win)
5. **CI Coverage-Threshold** (F07)
6. **Strikte Lints** (F08)
7. **Dependabot** (F12)
8. **.gitignore Cleanup** (F19)

### Erfolgskriterien
- ✅ Alle Screens <500 LOC (aktuell: 6 Dateien >800 LOC)
- ✅ SnackBar-Duplikate <5 (aktuell: 56)
- ✅ CI fails bei <50% Coverage (aktuell: kein Threshold)
- ✅ dart analyze clean mit strikten Lints
- ✅ Dependabot PRs aktiv

### Risiken & Mitigation
| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Widget-Extraktion bricht Tests | Mittel | Hoch | Tests vorher + nachher laufen lassen |
| Strikte Lints erzeugen 100+ Warnings | Hoch | Mittel | Schrittweise aktivieren, pro Lint 1 PR |
| Coverage-Threshold zu streng (50%) | Mittel | Mittel | Mit 40% starten, dann schrittweise erhöhen |

### Abnahmekriterien
- [ ] Code-Review von 2 Entwicklern
- [ ] Alle Tests passing (local + CI)
- [ ] dart analyze clean
- [ ] Manual UI-Test (kritische Flows)

---

## PHASE 2: STRUKTURIEREN (Prio 2)

### Ziel
Dokumentation vervollständigen, Testabdeckung erhöhen, Wissen externalisieren.

### Scope
- CODING_GUIDELINES.md erweitern (33 → 300+ Zeilen)
- ARCHITECTURE.md erstellen (Datenfluss, Layering)
- TESTING_STRATEGY.md erstellen
- Tests für kritische Screens (klassen_screen, csv_import)
- Integration-Tests (Login → Noteneingabe)

### Reihenfolge
1. **CODING_GUIDELINES.md erweitern** (F02, Foundation für alles)
2. **ARCHITECTURE.md erstellen** (F03, Onboarding neuer Entwickler)
3. **TESTING_STRATEGY.md** (F04)
4. **klassen_screen_test.dart** (F06, 0% Coverage → 60%+)
5. **Integration-Test** (F14, kritischer User-Flow)

### Erfolgskriterien
- ✅ CODING_GUIDELINES.md >300 Zeilen mit Beispielen (aktuell: 33 Zeilen)
- ✅ ARCHITECTURE.md vorhanden mit Diagrammen
- ✅ TESTING_STRATEGY.md vorhanden
- ✅ klassen_screen.dart Coverage >60% (aktuell: 0%)
- ✅ Gesamt-Coverage >55% (aktuell: 51.71%)
- ✅ Mind. 1 Integration-Test vorhanden

### Risiken & Mitigation
| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Doku veraltet schnell | Mittel | Mittel | In PR-Template: "Doku aktualisiert?" Checkbox |
| Tests für große Screens schwer | Hoch | Mittel | Widget-Extraktion (Phase 1) macht Tests einfacher |
| Integration-Tests flaky | Mittel | Hoch | Nur kritische Flows, Retry-Logic |

### Abnahmekriterien
- [ ] Alle Docs peer-reviewt von 2+ Personen
- [ ] Stakeholder-Approval für ARCHITECTURE.md
- [ ] Neue Tests 100% passing (kein Flakiness)
- [ ] Coverage-Increase messbar (+4%+)

---

## PHASE 3: OPTIMIEREN & SKALIEREN (Prio 3)

### Ziel
Production-Readiness: Security, Performance, Developer Experience.

### Scope
- Security Audit (PII-Logging, Firestore Rules)
- LOGGING_POLICY.md erstellen
- Pre-Commit Hooks (Auto-Format, Lint)
- Firebase Crashlytics
- Firestore Index-Dokumentation
- Golden Tests (UI-Regression)
- Accessibility Audit (optional)

### Reihenfolge
1. **LOGGING_POLICY.md** (F09, Security-Foundation)
2. **PII-Logging entfernen** (F09, Code-Scan)
3. **Firestore Rules Audit** (F10, Kommentare hinzufügen)
4. **Pre-Commit Hooks** (F11, DX-Verbesserung)
5. **Firebase Crashlytics** (F10, Production-Monitoring)
6. **firestore.indexes.md** (F18, Performance-Doku)
7. **Golden Tests** (F15, UI-Regression-Prevention)
8. **Accessibility Audit** (F20, optional je nach Stakeholder)

### Erfolgskriterien
- ✅ LOGGING_POLICY.md vorhanden
- ✅ 0 PII in Debug-Logs (grep-verified)
- ✅ Firestore Rules dokumentiert
- ✅ Pre-Commit Hooks bei allen Entwicklern aktiv
- ✅ Crashlytics in Production deployed
- ✅ Alle Firestore Indexes dokumentiert
- ✅ >5 Golden-Tests vorhanden
- ✅ Coverage >60%

### Risiken & Mitigation
| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Crashlytics-Overhead in Web | Niedrig | Niedrig | Performance-Test vor Rollout |
| Pre-Commit Hooks nerven Entwickler | Mittel | Niedrig | Opt-out dokumentieren, aber empfohlen |
| Golden-Tests bei UI-Änderungen aufwändig | Hoch | Niedrig | Nur für kritische Widgets (5-10 Tests max) |
| a11y Audit findet 50+ Issues | Mittel | Hoch | Scoping: Nur WCAG Level A, nicht AAA |

### Abnahmekriterien
- [ ] Security-Review von 2+ Personen
- [ ] Crashlytics zeigt Test-Crashes in Dashboard
- [ ] Golden-Tests in CI integriert
- [ ] a11y-Checklist abgearbeitet (falls Scope)

---

## TIMELINE & RESOURCEN

### Zeitplan (konservativ)
```
Phase 1: Woche 1-2   (10 Arbeitstage)
Phase 2: Woche 3-4   (10 Arbeitstage)
Phase 3: Woche 5-7   (15 Arbeitstage)
Buffer:  Woche 8     (5 Arbeitstage)
---
GESAMT: ~40 Arbeitstage (8 Wochen)
```

### Ressourcen-Bedarf
- **1 Senior Flutter-Entwickler** (Full-Time, alle 3 Phasen)
- **1 Tech Writer** (Part-Time, Phase 2: Doku-Review)
- **1 QA-Tester** (Part-Time, Phase 3: a11y-Audit)

### Parallelisierung (optional)
- Phase 1.1-1.3 (Widget-Extraktion) kann parallel laufen mit Phase 1.4-1.7 (CI/Tooling)
- Phase 2.1-2.3 (Doku) kann parallel laufen mit Phase 2.4-2.5 (Tests)
- **Zeitersparnis:** ~30% (8 Wochen → 6 Wochen)

---

## ROLLBACK-STRATEGIE

### Wenn Phase fehlschlägt
- **Phase 1 fehlschlägt:** Rollback via Git (Feature-Branches), CI blockiert Merge
- **Phase 2 fehlschlägt:** Docs sind additive (kein Rollback nötig), Tests können deaktiviert werden
- **Phase 3 fehlschlägt:** Crashlytics deaktivierbar, Pre-Commit Hooks optional

### Breaking-Change-Management
- Widget-Extraktion ändert Imports → **Breaking für Forks** (dokumentieren in CHANGELOG)
- Strikte Lints → **Breaking für CI** (schrittweise aktivieren)
- Coverage-Threshold → **Breaking für CI** (mit 40% starten)

---

## SUCCESS METRICS

### Technische Metriken
| Metrik | Vorher (v0.16.0) | Nach Phase 1 | Nach Phase 2 | Nach Phase 3 |
|--------|------------------|--------------|--------------|--------------|
| Max. File LOC | 1268 | <500 | <500 | <500 |
| SnackBar-Duplikate | 56 | <5 | <5 | <5 |
| Test Coverage | 51.71% | 50%+ (CI) | 55%+ | 60%+ |
| Analyze Warnings | ? | 0 | 0 | 0 |
| Docs (Zeilen) | ~300 | ~400 | ~1500+ | ~2000+ |
| Integration-Tests | 0 | 0 | 1+ | 3+ |
| Golden-Tests | 0 | 0 | 0 | 5+ |

### Business Metriken
| Metrik | Vorher | Nachher (Ziel) |
|--------|--------|----------------|
| Onboarding-Zeit (neue Entwickler) | ~5 Tage | ~2 Tage |
| Bug-Discovery-Time | ? | -30% (via Crashlytics) |
| Code-Review-Zeit | ~2h/PR | ~1h/PR (klarere Guidelines) |
| Regression-Bugs (UI) | ? | -50% (via Golden-Tests) |

---

## KOMMUNIKATIONSPLAN

### Stakeholder-Updates
- **Wöchentlich:** Status-Mail (Was wurde gemacht, Blockaden, nächste Woche)
- **Bi-Weekly:** Demo-Call (zeigen statt erzählen)
- **Nach jeder Phase:** Executive Summary (1 Seite, Business-Value)

### Team-Kommunikation
- **Daily:** Async-Update in Slack/Teams
- **Blockers:** Sofort eskalieren (nicht bis Weekly warten)
- **Docs:** Über PR-Comments reviewen (GitHub-Review-Feature)

---

## NEXT STEPS

### Sofort (heute)
1. **Stakeholder-Approval einholen** für 3-Phasen-Plan
2. **Zeitbudget klären** (alle 3 Phasen oder nur 1+2?)
3. **Ressourcen committen** (1 Entwickler Full-Time?)

### Diese Woche
1. **Branch erstellen:** `refactor/phase-1-stabilize`
2. **Start Phase 1.1:** klassen_screen.dart Widget-Extraktion
3. **Setup Tracking:** GitHub Project Board mit allen 20 Findings als Issues

### Nächste Woche
1. **Phase 1.1-1.3 abschließen** (Widget-Extraktion)
2. **Phase 1.4-1.7 starten** (CI/Tooling)
3. **Weekly Stakeholder-Update**

---

**Bereit für den Start? Los geht's mit Phase 1.1! 🚀**
