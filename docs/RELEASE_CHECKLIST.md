# InduScore - Release & Deploy Checkliste

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-12-30  
**Gilt ab:** v0.19.0

> **Ziel:** Einheitlicher, nachvollziehbarer Release-Prozess für alle Entwickler

---

## Übersicht

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Vorbereitung  →  2. Release  →  3. Verifizierung  →  4. Doku │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1️⃣ Vor dem Release (Vorbereitung)

### Code-Qualität sicherstellen

- [ ] **Tests ausführen:** `flutter test` - Alle Tests grün
- [ ] **Analyse durchführen:** `flutter analyze` - Keine Issues
- [ ] **Coverage prüfen:** Mindestens 50% (CI-Threshold)

### Versionen synchronisieren

Alle folgenden Dateien müssen die gleiche Version haben:

| Datei | Zu aktualisieren |
|-------|------------------|
| `pubspec.yaml` | `version: X.Y.Z+BUILD` |
| `version.json` | `{"version": "X.Y.Z"}` |

**Versionierungsschema:** [Semantic Versioning](https://semver.org/lang/de/)
- **MAJOR (X):** Breaking Changes
- **MINOR (Y):** Neue Features, abwärtskompatibel
- **PATCH (Z):** Bugfixes, abwärtskompatibel
- **BUILD:** Inkrementelle Build-Nummer (immer +1 erhöhen)

### Dokumentation aktualisieren

- [ ] **CHANGELOG.md:** Neue Version mit allen Änderungen
- [ ] **README.md:** Version-Badge aktualisieren
- [ ] **RELEASE_NOTES_vX.Y.Z.md:** Erstellen (siehe Template unten)
- [ ] **docs/REFACTORING_ROADMAP.md:** Phase-Status aktualisieren
- [ ] **docs/TESTING_STRATEGY.md:** Test-Statistiken aktualisieren
- [ ] **docs/ARCHITECTURE.md:** Bei Architektur-Änderungen

---

## 2️⃣ Release durchführen

### Feature-Branch mergen (wenn vorhanden)

```bash
# Auf main wechseln
git checkout main
git pull origin main

# Feature-Branch mergen
git merge feature/branch-name --no-ff

# Push
git push origin main
```

### Tag erstellen und pushen

```bash
# Tag erstellen (löst Release-Workflow aus!)
git tag -a vX.Y.Z -m "Release vX.Y.Z - Kurzbeschreibung"

# Tag pushen
git push origin vX.Y.Z
```

### GitHub Release erstellen

1. Gehe zu: https://github.com/AlexBuchnerTeacher/InduScore/releases/new
2. **Tag:** `vX.Y.Z` (bereits erstellt)
3. **Title:** `vX.Y.Z - Feature-Titel`
4. **Description:** Inhalt aus `RELEASE_NOTES_vX.Y.Z.md` kopieren
5. **Generate release notes** für automatische PR/Commit-Liste
6. **Publish release** klicken

> ⚠️ **Wichtig:** Der Release-Workflow hängt automatisch `web-release.zip` an!

---

## 3️⃣ Nach dem Release (Verifizierung)

### GitHub Actions prüfen

**IMMER nach jedem Push/Tag prüfen!**

```bash
# Actions-Status anzeigen
gh run list --limit 5

# Oder im Browser:
# https://github.com/AlexBuchnerTeacher/InduScore/actions
```

Erwartete Workflows:
| Workflow | Trigger | Erwarteter Status |
|----------|---------|-------------------|
| **CI** | Push to main | ✅ Grün |
| **Deploy to GitHub Pages** | Push to main | ✅ Grün |
| **Release** | Tag push | ✅ Grün |

### Live-Deployment testen

- [ ] **URL öffnen:** https://alexbuchnerteacher.github.io/InduScore/
- [ ] **Version prüfen:** Stimmt mit Release überein
- [ ] **Login testen:** Email/Password funktioniert
- [ ] **Basis-Navigation:** Drawer, Screens, Routing
- [ ] **Firestore-Operationen:** Lesen/Schreiben funktioniert

---

## 4️⃣ Dokumentation nachpflegen

### Nach erfolgreichem Release

- [ ] **Issue schließen:** Zugehörige GitHub Issues schließen
- [ ] **Milestone schließen:** Wenn alle Issues der Version erledigt
- [ ] **docs/ Dateien:** Version/Datum aktualisieren

### Zu prüfende Dokumentationen

```bash
# Alle relevanten Dateien prüfen:
version.json                    # Muss aktuelle Version zeigen
docs/ARCHITECTURE.md            # Version & Datum
docs/TESTING_STRATEGY.md        # Test-Statistiken
docs/REFACTORING_ROADMAP.md     # Phase-Status
INSTALL.md                      # Aktuelle Version
```

---

## 📋 Release Notes Template

Neue Datei erstellen: `RELEASE_NOTES_vX.Y.Z.md`

```markdown
# Release Notes v{VERSION}

**Datum:** {DATUM}  
**Typ:** Feature Release | Bugfix Release | Breaking Change

---

## 🎯 Highlights

- Feature 1
- Feature 2

---

## ✨ Neue Features

### Feature-Name (Issue #{NR})
Beschreibung...

---

## 🐛 Bugfixes

- Fix 1 (#Issue)
- Fix 2 (#Issue)

---

## 🔧 Technische Änderungen

- Änderung 1
- Änderung 2

---

## 📊 Statistiken

| Metrik | Wert |
|--------|------|
| Tests | XXX |
| Coverage | XX% |
| Neue Dateien | X |

---

## 📥 Installation

Web-App: https://alexbuchnerteacher.github.io/InduScore/

---

## ⬆️ Upgrade-Hinweise

Keine Breaking Changes / Falls vorhanden: Migration beschreiben
```

---

## 🚨 Häufige Fehler vermeiden

### ❌ DON'T

- Tag pushen ohne vorher `flutter test` + `flutter analyze`
- Version nur in `pubspec.yaml` ändern (andere Dateien vergessen!)
- Release ohne Dokumentations-Update
- Actions nicht prüfen nach Push/Tag

### ✅ DO

- Immer komplette Checkliste durchgehen
- Actions nach JEDEM Push kontrollieren
- Bei fehlgeschlagenen Actions sofort fixen
- Dokumentation ist Teil des Releases

---

## 🔧 Nützliche Commands

```bash
# Version anzeigen
cat pubspec.yaml | Select-String "version:"

# Alle Tags anzeigen
git tag -l

# Letzten Tag anzeigen
git describe --tags --abbrev=0

# Actions-Status prüfen
gh run list --limit 5

# Bestimmten Workflow-Run anzeigen
gh run view {RUN_ID}

# Tests mit Coverage
flutter test --coverage

# Analyse
flutter analyze
```

---

## 📚 Referenzen

- [Semantic Versioning](https://semver.org/lang/de/)
- [GitHub Actions Doku](https://docs.github.com/en/actions)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

## Änderungshistorie

| Version | Datum | Änderung |
|---------|-------|----------|
| 1.0 | 2025-12-30 | Initiale Version (v0.19.0) |
