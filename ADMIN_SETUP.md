# Admin-User erstellen für InduScore

## Problem
Nach dem initialen Setup existiert noch kein Benutzer in Firebase Auth.

## Lösung: Admin-User über Firebase Console erstellen

### 1. Firebase Console öffnen
https://console.firebase.google.com/

### 2. Projekt "InduScore" auswählen

### 3. Authentication → Users → "Add user"

### 4. Admin-User anlegen:
```
Email: alexander.buchner@bs-ie.muenchen.musin.de
Password: [Sicheres Passwort vergeben]
```

**WICHTIG:** User ID muss `bu-admin` sein!

### 5. Firestore-Dokument prüfen
In Firestore → `appUsers` → Dokument `bu-admin` sollte existieren mit:
```json
{
  "email": "alexander.buchner@bs-ie.muenchen.musin.de",
  "name": "Alexander Buchner",
  "kuerzel": "BU",
  "rolle": "admin",
  "status": "aktiv"
}
```

### 6. Login testen
- Kürzel: `BU`
- Passwort: [Das vergebene Passwort]

## Alternative: Weitere User erstellen

Für andere Lehrer:
1. Firebase Console → Authentication → Add user
2. Email: `XX@induscore.de` (XX = Kürzel)
3. Firestore → `appUsers` → Dokument mit ID = Kürzel erstellen

Beispiel für Lehrer "MU":
```json
{
  "id": "mu",
  "email": "MU@induscore.de",
  "name": "Max Mustermann",
  "kuerzel": "MU",
  "rolle": "lehrer",
  "status": "aktiv",
  "favoriteKlassenIds": [],
  "createdAt": "2025-12-29T...",
  "lastLoginAt": null
}
```

## Schnell-Setup via Script

Wenn Node.js installiert ist:

```bash
cd scripts
npm install
node create_admin.js
```

Das Skript erstellt automatisch:
- Firebase Auth User
- Firestore appUsers Dokument

**Voraussetzung:** `firebase-admin-key.json` muss vorhanden sein.
