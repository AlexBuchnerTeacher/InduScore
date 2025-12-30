# Integration Tests

Diese Tests prüfen das Zusammenspiel der App-Komponenten und kritische User-Workflows.

## Voraussetzungen

- Flutter SDK ≥ 3.10.0
- Chrome Browser (für Web-Tests)
- Optional: Firebase Emulator (für Auth-Tests)

## Tests ausführen

### Einfacher Test-Run (ohne Firebase)

```bash
# Alle Integration-Tests
flutter test integration_test/

# Spezifischer Test
flutter test integration_test/app_test.dart
```

### Mit Chrome Driver (Web)

```bash
# Chrome Driver starten (separates Terminal)
chromedriver --port=4444

# Tests ausführen
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome
```

### Mit Firebase Emulator (vollständige Tests)

```bash
# Firebase Emulators starten
firebase emulators:start

# In anderem Terminal: Tests mit Emulator
flutter test integration_test/ --dart-define=USE_FIREBASE_EMULATOR=true
```

## Test-Struktur

| Datei | Beschreibung |
|-------|--------------|
| `app_test.dart` | App-Start, Login-Screen, Navigation |

## CI Integration

Integration-Tests werden in GitHub Actions ausgeführt:
- `.github/workflows/ci.yml` führt `flutter test` aus
- Für vollständige E2E-Tests wird Firebase Emulator benötigt

## Hinweise

- Tests ohne Firebase Auth zeigen nur den Login-Screen
- Für authentifizierte Flows: Firebase Emulator nutzen oder Test-Mocks
- Web-Tests erfordern `--platform chrome` Flag
