# Release Notes v0.21.0 - Phase 4: Quality & Observability

**Release Date:** 2025-12-30  
**Tag:** `v0.21.0`

## 🎯 Zusammenfassung

Diese Version verbessert die **Code-Qualität** und **Observability** der Anwendung durch Integration-Tests und Firebase Crashlytics für automatisches Crash-Reporting in Production.

## ✨ Neue Features

### Integration Tests
- Neues `integration_test/` Verzeichnis mit E2E-Test-Grundgerüst
- Test für App-Initialisierung und Login-Screen
- Dokumentation für lokale und CI-Ausführung

### Firebase Crashlytics
- Automatische Crash-Reports in Release-Builds
- Flutter Framework-Fehler werden erfasst
- Async-Fehler aus Futures/Streams werden geloggt
- Debug-Builds bleiben unbeeinträchtigt

## 🔧 Verbesserungen

### Code-Qualität
- Alle TODO-Kommentare mit Issue-Referenzen versehen
- `klassen_screen.dart`: TODOs verweisen jetzt auf Issue #21 (PDF Import Pipeline)

## 📦 Dependencies

**Neu:**
- `firebase_crashlytics: ^5.0.6`
- `integration_test` (Flutter SDK)

## ✅ Qualität

- **Tests:** 269 (alle bestanden)
- **Coverage:** ≥50%
- **Linting:** 0 Warnungen

## 📋 Upgrade-Anleitung

```bash
# Neuen Code holen
git pull origin main

# Dependencies aktualisieren
flutter pub get

# Tests ausführen
flutter test
```

## 🔗 Links

- [CHANGELOG.md](CHANGELOG.md)
- [Issue #68 - v1.0.0 Roadmap](https://github.com/AlexBuchnerTeacher/InduScore/issues/68)
- [Issue #21 - Premium PDF Import Pipeline](https://github.com/AlexBuchnerTeacher/InduScore/issues/21)
