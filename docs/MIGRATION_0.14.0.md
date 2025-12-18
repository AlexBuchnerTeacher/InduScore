# Migration Guide: Version 0.13.7 → 0.14.0

## Übersicht
Version 0.14.0 führt ein umfassendes Berechtigungssystem ein (Issue #39).

## Datenbank-Änderungen

### AppUser Collection
**Neue Felder:**
- `favoriteKlassenIds: string[]` - Favoriten-Klassen für Dashboard (ersetzt `klassenIds`)
- `rolle: string` - Jetzt 4 Werte: 'admin', 'lehrer', 'ausbilder', 'schueler'

**Migration:**
✅ **Automatisch** - Fallback im Code eingebaut:
```dart
favoriteKlassenIds: data['favoriteKlassenIds'] ?? data['klassenIds'] ?? []
```
- Alte Dokumente mit `klassenIds` funktionieren weiterhin
- Beim nächsten Update wird `favoriteKlassenIds` gespeichert

**Neue Rollen:**
- Bestehende User behalten ihre Rolle ('admin' oder 'lehrer')
- Neue Rollen 'ausbilder' und 'schueler' können manuell vergeben werden

### Leistungsnachweis Collection
**Neue Felder:**
- `createdBy: string?` - Kürzel des Erstellers (optional, nullable)

**Migration:**
✅ **Nicht erforderlich** - Feld ist optional:
- Alte Leistungsnachweise haben `createdBy = null`
- Admin kann alle bearbeiten
- Lehrer/Ausbilder können alle ohne `createdBy` bearbeiten
- Neue Leistungsnachweise bekommen automatisch `createdBy` gesetzt

## Berechtigungen (Permissions)

### Übersicht
| Berechtigung | Admin | Lehrer | Ausbilder | Schüler |
|--------------|-------|--------|-----------|---------|
| Benutzerverwaltung | ✅ | ❌ | ❌ | ❌ |
| CSV Import | ✅ | ❌ | ❌ | ❌ |
| Klassen/Fächer/Schüler | ✅ | ✅ | ✅ | ❌ |
| Leistungsnachweise erstellen | ✅ | ✅ | ✅ | ❌ |
| Eigene LN bearbeiten | ✅ | ✅ | ✅ | ❌ |
| Fremde LN bearbeiten | ✅ | ❌ | ❌ | ❌ |

### Permission Providers
Neue Provider in `lib/providers/permissions_providers.dart`:
- `canManageUsersProvider` - Nur Admin
- `canImportCSVProvider` - Nur Admin
- `canManageDataProvider` - Admin + Lehrer + Ausbilder
- `canCreateLeistungsnachweisProvider` - Admin + Lehrer + Ausbilder
- `canEditLeistungsnachweisProvider(ln)` - Admin=alle, Lehrer/Ausbilder=eigene

## UI-Änderungen

### Dashboard
- Neuer Favoriten-Toggle (⭐) neben Zeitgruppen-Filter
- Default: Lehrer/Ausbilder sehen nur Favoriten, Admin sieht alle
- Nur sichtbar wenn User Favoriten hat

### Benutzerverwaltung
- Email jetzt bearbeitbar (mit Warnung)
- 4 Rollen auswählbar (statt 2)
- Favoriten-Klassen Multiselect (für Lehrer/Ausbilder)

### Screen-Zugriff
- CSV Import: Nur Admin (mit "Zugriff verweigert" Screen)
- Klassen/Fächer/Schüler: Admin + Lehrer + Ausbilder
- Leistungsnachweise: Bearbeiten-Buttons nur wenn berechtigt
- Benutzerverwaltung: Nur Admin

## Kürzel Case-Insensitivity
**Neue Funktion:** Kürzel sind jetzt case-insensitive beim Login/Registrierung
- Eingabe: "mu" → Gespeichert: "MU"
- Login funktioniert mit "mu", "MU", "Mu"
- Anzeige: Immer uppercase

**Betroffene Screens:**
- Login
- Registrierung
- Passwort-Reset
- Benutzerverwaltung

## Testing
✅ **Admin-Szenario:**
- Kann alle Screens öffnen
- Kann alle Leistungsnachweise bearbeiten
- Kann Benutzer verwalten
- Kann CSV importieren

✅ **Lehrer-Szenario:**
- Kann Klassen/Fächer/Schüler verwalten
- Kann eigene Leistungsnachweise bearbeiten
- Sieht Favoriten-Toggle im Dashboard
- Kann CSV Import nicht öffnen

✅ **Ausbilder-Szenario:**
- Gleiche Berechtigungen wie Lehrer
- Sieht Favoriten-Toggle

✅ **Schüler-Szenario:**
- Nur Lese-Zugriff (noch nicht vollständig implementiert)

## Rollback
Falls Probleme auftreten:
```bash
git checkout v0.13.7
flutter clean
flutter pub get
flutter run -d chrome
```

## Support
Bei Fragen oder Problemen bitte Issue auf GitHub erstellen.
