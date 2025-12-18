# Admin Scripts

## Setup

1. **Firebase Service Account Key holen:**
   - Gehe zu: https://console.firebase.google.com
   - Projekt auswählen (induscore)
   - ⚙️ **Project Settings** → **Service Accounts** Tab
   - Klicke **"Generate new private key"**
   - Datei speichern als: `scripts/firebase-admin-key.json`

2. **Dependencies installieren:**
   ```bash
   cd scripts
   npm install
   ```

3. **Admin erstellen:**
   ```bash
   npm run create-admin
   ```

## Security

⚠️ **WICHTIG:** Die Datei `firebase-admin-key.json` enthält sensitive Daten!
- Niemals in Git committen!
- Ist bereits in `.gitignore`
