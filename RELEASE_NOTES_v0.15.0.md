# InduScore v0.15.0 - Release Notes

**Release Date:** 29. Dezember 2024  
**Branch:** feature/v1.0.0-mvp  
**Milestone:** v1.0.0 - MVP

## 🎯 Überblick

Version 0.15.0 bringt wichtige Verbesserungen für den Login-Prozess, Admin-Berechtigungen und die Settings-Verwaltung. Dieser Release ist ein wichtiger Schritt in Richtung v1.0.0 MVP.

## ✨ Neue Features

### 🔐 Flexibler Login mit Kürzel
- **Kürzel-Login**: Anmeldung jetzt mit Lehrerkürzel (z.B. "BU") oder vollständiger Email-Adresse
- **Groß-/Kleinschreibung egal**: "bu", "BU", "Bu" funktionieren alle
- **Automatische Auflösung**: Kürzel werden über Firestore `app_users` Collection zur Email-Adresse aufgelöst
- **Fallback-Mechanismus**: Wenn Kürzel nicht in Firestore gefunden, Fallback auf `@induscore.de` Domain

**Technische Details:**
- Neue Methode `FirestoreService.getAppUserByKuerzel()`
- Firestore Pre-Login Lesezugriff für Kürzel-Lookup
- Scripts für User-Management: `create_both_users.js`, `check_kuerzel.js`

### 🔒 Firestore Security Rules
- **Pre-Login Zugriff**: `app_users` Collection lesbar vor dem Login (für Kürzel-Lookup)
- **Granulare Berechtigungen**: 
  - `app_users` & `subjects`: Nur Admins können schreiben
  - `klassen`, `grades`, `leistungsnachweise`: Alle eingeloggten User
- **Deployed**: Über `firebase.json` + `firestore.rules`

### ⚙️ Admin Einstellungen
- **Zugriffsbeschränkung**: Settings Screen nur noch für Admins sichtbar
- **Klare Benennung**: "Admin Einstellungen" statt generisches "Einstellungen"
- **Konsolidierter Admin-Bereich**: Settings + Benutzerverwaltung zusammen im Drawer

### ✅ Unit Tests für Zeugnisnoten (Issue #11)
- 24 neue Tests für Zeugnisnoten-Berechnung
- Tests für `berechneSchnitt()`, `rundeNote()`, `berechneZeugnisnote()`
- Tests für `formatSchnitt()` und `getTendenz()`
- **Alle 89 Tests bestehen** ✅

### ⚙️ Settings Screen (Issue #14)
- Tab-basierte UI für Berufe (readonly) und Fächer (CRUD)
- Vollständige Fächer-Verwaltung: Erstellen, Bearbeiten, Löschen
- Zuordnung von Fächern zu Berufen
- Konfiguration: Fachtyp, Wochenstunden, Credits
- RBS-konformes Design

## 🐛 Behobene Bugs

### Issue #49: Settings Screen Bugs
- ✅ **Farbparsing-Fehler**: Hex-Farben mit `#` werden jetzt korrekt verarbeitet
- ✅ **Titel korrigiert**: "Admin Einstellungen" statt "Einstellungen"
- ✅ **Navigation**: AppBar zeigt automatisch Zurück-Button

### Login-Probleme
- ✅ **Kürzel-Login funktioniert**: Firestore Permission Denied behoben
- ✅ **Echte Email-Domains**: Statt hartkodiertem `@induscore.de` jetzt echte Domains (@bs-ie.muenchen.musin.de, @gmx.de)
- ✅ **DEBUG-Code entfernt**: Admin-User-Erstellungs-Button aus Login-Screen entfernt

### Code Quality
- ✅ **Lint-Warnings behoben**: Alle `avoid_print` Warnungen beseitigt
- ✅ **Deprecation Warnings**: `withOpacity` → `withValues`, `value` → `initialValue`

## 🔄 Änderungen

- **Versionierung**: Durchgehend v0.15.0 Notation (statt v1.0.0)
- **Drawer**: Admin-Bereich nur für Admins sichtbar (Settings + Benutzerverwaltung)
- **Routes**: Kommentare für Admin-Only Routes aktualisiert

## 📦 Deployment-Hinweise

### Firestore Rules Deployment
```bash
firebase deploy --only firestore:rules --project notentool
```

### User Migration (für bestehende Installationen)
Führe `create_both_users.js` aus, um `app_users` Dokumente für existierende Auth-User zu erstellen:
```bash
cd scripts
node create_both_users.js
```

## 🧪 Testing

- ✅ Alle 89 Unit Tests bestehen
- ✅ Kürzel-Login manuell getestet (BU, BU-ADMIN)
- ✅ Email-Login manuell getestet
- ✅ Admin-Berechtigungen verifiziert
- ✅ Firestore Rules deployed und getestet

## 📝 Bekannte Einschränkungen

### Issue #50: ASV NOI Import - Falsches XML-Schema
- **Status**: Offen (Critical)
- **Problem**: ASV erwartet anderes XML-Schema für Berufsschule
- **Workaround**: Warte auf Beispiel-XML von Kollege mit ASV-Zugriff (in 2 Wochen)

### Issue #48: User-Profilscreen
- **Status**: Geplant für v1.1.0
- **Beschreibung**: Profilscreen für persönliche Einstellungen (getrennt von Admin Einstellungen)

## 🎯 Nächste Schritte (v1.0.0 MVP)

1. ✅ **Issue #11**: Unit Tests für Zeugnisnoten - ERLEDIGT
2. ✅ **Issue #14**: Settings Screen - ERLEDIGT
3. ✅ **Issue #49**: Settings Screen Bugs - ERLEDIGT
4. ⏳ **Issue #50**: ASV XML Schema - BLOCKIERT (warte auf Kollege)
5. 📋 **Weitere offene Issues für MVP prüfen**

## 👥 Mitwirkende

- Alexander Buchner (@AlexBuchnerTeacher)

## 📄 Vollständiges Changelog

Siehe [CHANGELOG.md](CHANGELOG.md) für alle Details.

---

**Download:** [Release v0.15.0](https://github.com/AlexBuchnerTeacher/InduScore/releases/tag/v0.15.0) _(nach Merge in main)_
