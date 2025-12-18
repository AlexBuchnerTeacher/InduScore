# Issue: Benutzerverwaltung & Berechtigungssystem erweitern

## 📋 Zusammenfassung

Erweiterung der Benutzerverwaltung um 4 Benutzerrollen (Admin, Lehrer, Ausbilder, Schüler) mit entsprechenden Berechtigungen, Favoriten-System für Klassen und erweiterten Admin-Features.

## 🎯 Ziele

1. **4 Benutzerrollen** implementieren (Ausbilder/Schüler für spätere Apps vorbereiten)
2. **Favoriten-System** für Klassen statt fester Zuweisungen
3. **Berechtigungen** auf allen Screens durchsetzen (Admin vs Lehrer)
4. **Benutzerverwaltung** vervollständigen (Bugs fixen, Features hinzufügen)
5. **Audit-Trail** für Leistungsnachweise (`createdBy` Feld)

## 🐛 Bekannte Bugs (zu fixen)

- [ ] **Benutzer anlegen funktioniert nicht** (`user_verwaltung_screen.dart`)
- [ ] **Email ändern nicht möglich** in Benutzer-Bearbeitung

## 🆕 Neue Features

### 1. Erweiterte Benutzerrollen

**Models:**
- [ ] `app_user.dart`: UserRole um `ausbilder` und `schueler` erweitern
- [ ] `app_user.dart`: `klassenIds` → `favoriteKlassenIds` umbenennen
- [ ] `leistungsnachweis.dart`: Feld `createdBy` (String, User-ID) hinzufügen

```dart
enum UserRole {
  admin('Admin'),
  lehrer('Lehrer'),
  ausbilder('Ausbilder'),  // Für spätere App
  schueler('Schüler');     // Für spätere App
}
```

### 2. Benutzerverwaltung (Admin-only)

**UI-Verbesserungen:**
- [ ] Rollen-Dropdown: Alle 4 Rollen anzeigen
- [ ] **Favoriten-Klassen:** Multiselect-Dropdown für Klassen-Auswahl
- [ ] **Erweiterte Infos anzeigen:**
  - [ ] Favoriten-Klassen: "3 Klassen: E1IT, E2IT, E3IT" oder "Keine Favoriten"
  - [ ] LN-Anzahl: "12 Leistungsnachweise erstellt"
  - [ ] Erstellungsdatum: "Erstellt: 10.12.2025"
  - [ ] Letzter Login prominenter: "Letzter Login: 18.12.2025 10:30"

**Fixes:**
- [ ] Email-Änderung ermöglichen (aktuell disabled)
- [ ] Benutzer-Anlage testen und fixen falls kaputt

### 3. Favoriten-System für Klassen

**Dashboard:**
- [ ] Toggle "Nur Favoriten anzeigen" hinzufügen
- [ ] Favoriten-Klassen hervorgehoben anzeigen

**Klassen-Screen:**
- [ ] Stern-Icon ⭐ neben Klassenname zum Favorisieren
- [ ] Click: Favorit hinzufügen/entfernen
- [ ] Visuelles Feedback (gefüllter/ungefüllter Stern)

### 4. Berechtigungen pro Screen

#### Benutzerverwaltung (`user_verwaltung_screen.dart`)
- [ ] Navigation nur für Admin sichtbar (RBSDrawer)
- [ ] Screen: Access Guard (`isCurrentUserAdminProvider`)

#### Klassen (`klassen_screen.dart`)
- [x] Alle: Klassen lesen
- [ ] Admin: "Neue Klasse" Button
- [ ] Lehrer: Kein "Neue Klasse" Button
- [ ] Admin: Bearbeiten/Löschen möglich
- [ ] Lehrer: Nur Ansicht
- [ ] Alle: Favoriten-Stern anzeigen

#### Schüler (`schueler_verwaltung_screen.dart`)
- [x] Alle: Schüler lesen
- [ ] Admin: "Neuer Schüler" Button
- [ ] Lehrer: Kein "Neuer Schüler" Button
- [ ] Admin: Bearbeiten/Löschen möglich
- [ ] Lehrer: Nur Ansicht

#### Fächer (`faecher_screen.dart`)
- [x] Alle: Fächer lesen
- [ ] Admin: "Neues Fach" Button
- [ ] Lehrer: Kein "Neues Fach" Button
- [ ] Admin: Bearbeiten/Löschen möglich
- [ ] Lehrer: Nur Ansicht

#### Leistungsnachweise (`leistungsnachweise_screen.dart`)
- [ ] Admin + Lehrer: "Neuer LN" Button
- [ ] Admin + Lehrer: **Alle** LN bearbeiten/löschen (keine Einschränkung nach Ersteller)
- [ ] `createdBy` beim Erstellen speichern (für Audit/Statistik)

#### CSV/ASV Import (`csv_import_screen.dart`)
- [ ] Navigation nur für Admin
- [ ] Access Guard

#### NOI Export (`noi_export_screen.dart`)
- [x] Admin + Lehrer: Vollen Zugriff

## 🔧 Technische Umsetzung

### Provider erweitern

```dart
// app_providers.dart

/// Prüft ob aktueller User Admin ist
final isCurrentUserAdminProvider = Provider<bool>((ref) { ... });

/// Prüft ob aktueller User Lehrer ist  
final isCurrentUserLehrerProvider = Provider<bool>((ref) { ... });

/// Kann User andere User verwalten?
final canManageUsersProvider = Provider<bool>((ref) => 
  ref.watch(isCurrentUserAdminProvider)
);

/// Kann User Klassen/Schüler/Fächer verwalten?
final canManageDataProvider = Provider<bool>((ref) => 
  ref.watch(isCurrentUserAdminProvider)
);

/// Kann User Leistungsnachweise bearbeiten?
final canEditLeistungsnachweiseProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider).value;
  if (user == null) return false;
  return user.isAdmin || user.rolle == UserRole.lehrer;
});
```

### Migration bestehender Daten

```dart
// Script zum Migrieren: scripts/migrate_users_to_favorites.js

// Für alle bestehenden AppUsers:
// 1. Feld umbenennen: klassenIds → favoriteKlassenIds
// 2. Falls rolle fehlt: Standard = lehrer
// 3. Falls favoriteKlassenIds fehlt: []
```

### Firestore Structure

**Collection: `app_users`**
```json
{
  "id": "Xg0Tm6fXDaWWZPQ8IB3zP5QDunL2",
  "email": "alexander.buchner@bs-ie.muenchen.musin.de",
  "name": "Alexander Buchner",
  "kuerzel": "BU",
  "rolle": "admin",
  "status": "aktiv",
  "favoriteKlassenIds": ["klasse123", "klasse456"],
  "createdAt": "2025-12-18T10:00:00Z",
  "lastLoginAt": "2025-12-18T14:30:00Z"
}
```

**Collection: `leistungsnachweise`**
```json
{
  "id": "ln123",
  "klasseId": "klasse123",
  "subjectId": "fach456",
  "createdBy": "Xg0Tm6fXDaWWZPQ8IB3zP5QDunL2",
  "createdAt": "2025-12-15T10:00:00Z",
  // ... weitere Felder
}
```

## 📊 Berechtigungsmatrix (Referenz)

| Feature | Admin | Lehrer | Ausbilder | Schüler |
|---------|-------|--------|-----------|---------|
| Benutzerverwaltung | ✅ | ❌ | ❌ | ❌ |
| Klassen/Schüler/Fächer verwalten | ✅ | ❌ | ❌ | ❌ |
| CSV/ASV Import | ✅ | ❌ | ❌ | ❌ |
| Alle Klassen sehen | ✅ | ✅ | ❌ | ❌ |
| Favoriten-Klassen markieren | ✅ | ✅ | ❌ | ❌ |
| LN erstellen/bearbeiten/löschen | ✅ | ✅ | ❌ | ❌ |
| Noten eingeben | ✅ | ✅ | ❌ | ❌ |
| NOI Export | ✅ | ✅ | ❌ | ❌ |

## 🧪 Testing

### Manuelle Tests

**Admin-Account:**
- [ ] Benutzerverwaltung öffnen
- [ ] Neuen Lehrer anlegen
- [ ] Favoriten-Klassen zuweisen
- [ ] Lehrer-Rolle ändern → Admin
- [ ] Admin-Rolle ändern → Lehrer
- [ ] User deaktivieren/aktivieren
- [ ] User löschen

**Lehrer-Account:**
- [ ] Benutzerverwaltung NICHT sichtbar im Drawer
- [ ] Dashboard: Alle Klassen sichtbar
- [ ] Klassen: Favoriten-Stern anklicken
- [ ] Dashboard: Toggle "Nur Favoriten"
- [ ] Klassen: KEIN "Neue Klasse" Button
- [ ] Schüler: KEIN "Neuer Schüler" Button
- [ ] Fächer: KEIN "Neues Fach" Button
- [ ] LN: "Neuer LN" Button VORHANDEN
- [ ] LN: Alle LN bearbeitbar/löschbar
- [ ] CSV Import: NICHT zugreifbar

**Edge Cases:**
- [ ] Lehrer ohne Favoriten: Dashboard leer bei Toggle
- [ ] User-Anlage mit doppeltem Kürzel: Error
- [ ] User-Anlage mit ungültiger Email: Error
- [ ] User löschen: Auth + Firestore gelöscht?

## 📝 Dokumentation

- [ ] `CHANGELOG.md` aktualisieren (Version 0.14.0?)
- [ ] Code-Kommentare für neue Provider
- [ ] README: Berechtigungsmatrix dokumentieren
- [ ] Inline-Docs für neue Felder (`favoriteKlassenIds`, `createdBy`)

## 🚀 Deployment

1. Branch: `feature/user-management-improvements`
2. Commits: Logisch aufteilen (Models → Providers → UI)
3. Testing: Lokal komplett durchspielen
4. Merge: Nach Review in `main`
5. Tag: `v0.14.0` nach Merge
6. Migration-Script: Nach Deploy ausführen

## ⚠️ Breaking Changes

- **Datenmodell:** `klassenIds` → `favoriteKlassenIds` (Migration nötig)
- **Provider:** Bestehende `isCurrentUserAdminProvider` erweitert (sollte kompatibel sein)

## 🔮 Zukunft (nicht in diesem Issue)

- Ausbilder-App: Eigene Flutter-App mit Lesezugriff
- Schüler-App: Mobile App für Notenansicht
- Firestore Rules: Rollenbezogene Zugriffskontrolle
- Email-Einladungen: Statt manuellem Passwort
- Bulk-Import: User per CSV anlegen

## 📎 Related Issues

- #XXX: ASV Import Klassen/Schüler
- #XXX: NOI Export für Lehrer

---

**Priorität:** High  
**Labels:** `enhancement`, `user-management`, `permissions`, `breaking-change`  
**Milestone:** v0.14.0  
**Assignee:** @<username>
