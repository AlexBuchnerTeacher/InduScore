# GitHub Issues Analyse & Release Planning v0.14.0

## 📊 Übersicht (28 Issues gesamt)

### Status-Verteilung
- **OPEN**: 11 Issues
- **CLOSED**: 17 Issues

---

## ✅ GESCHLOSSENE Issues (17) - Verifizieren ob wirklich umgesetzt

### Basis-Setup (alle geschlossen ✅)
- #3: Projekt-Reset und Initial Setup ✅
- #4: Firebase Setup und Basis-Services ✅  
- #5: Routing mit go_router ✅
- #15: GitHub Templates + Contribution Guidelines ✅
- #16: Release-Workflow (Tags + Firebase Deploy) ✅
- #17: CI Pipeline (Analyze + Format + Tests) ✅
- #18: RBS Styleguide Umsetzung ✅
- #20: App-Namen auf InduScore umstellen ✅
- #22: Versionierung zentral darstellen ✅

### Features (geschlossen, zu verifizieren)
- #1: Schnelleingabe Noten ✅ (verifizieren)
- #7: Klassenverwaltung (CRUD + Firestore) ✅ (vorhanden)
- #8: Fächerverwaltung ✅ (vorhanden)
- #9: Schülerverwaltung (Import + Pseudonymisierung) ✅ (vorhanden)
- #10: Leistungsnachweise + schnelle Noteneingabe ✅ (vorhanden)
- #12: Nachschreiber-Management ✅ (vorhanden)
- #25: Design bei Klassen und Fächern angleichen ✅
- #26: Große Screen-Dateien aufteilen ✅
- #36: ASV-Import mit Beziehungen ✅ (vorhanden)

---

## 🚧 OFFENE Issues (11) - Kategorisierung

### 🎯 Kritisch für v0.14.0 (Benutzerverwaltung-Release)

**#39: Benutzerverwaltung & Berechtigungssystem erweitern** 🔥
- Status: NEU erstellt
- Priorität: HIGH
- Umfang: Groß (4 Rollen, Favoriten, Berechtigungen auf allen Screens)
- **→ HAUPTFEATURE für v0.14.0**

### ⚡ Quick Wins für v0.14.0 (einfach umsetzbar)

**#35: CSV Import: Klasse direkt anlegen ermöglichen**
- Status: OPEN
- Priorität: Niedrig (aber UX-Verbesserung)
- Aufwand: Klein (1-2h)
- **→ KANDIDAT für v0.14.0** ✅

### 📋 Features mit mittlerer Priorität (später)

**#11: Automatische Berechnung der Zeugnisnote**
- Status: OPEN
- Priorität: Mittel
- Aufwand: Mittel
- **→ v0.15.0 oder später**

**#13: PDF-Export für Klassen + Noten**
- Status: OPEN
- Priorität: Mittel
- Aufwand: Mittel
- **→ v0.15.0 oder später**

**#14: Settings-Bereich (Berufe, Fächer, Jahrgänge)**
- Status: OPEN
- Priorität: Mittel
- Aufwand: Klein-Mittel
- **→ v0.15.0 oder später**

### 🔐 Zukunftsfeatures (langfristig)

**#34: E2E-Verschlüsselung für Schülernamen**
- Status: OPEN
- Priorität: Niedrig (DSGVO nice-to-have)
- Aufwand: Groß (6-8h)
- **→ v0.16.0 oder später**

**#31: Skalierung für Schulbetrieb (Performance)**
- Status: OPEN
- Priorität: Mittel (aber nicht dringend)
- Aufwand: Groß
- **→ v0.16.0 oder später**

**#21: Premium PDF Import Pipeline**
- Status: OPEN
- Priorität: Niedrig (Premium Feature)
- Aufwand: Sehr groß
- **→ Backlog**

**#19: RBS-Styleguide 1.2 vollständig implementieren**
- Status: OPEN
- Priorität: Mittel
- Aufwand: Groß
- Hinweis: #18 bereits closed, unklar was noch fehlt
- **→ Prüfen ob noch relevant oder schließen**

### 🔍 Zu prüfen

**#6: Domain-Modelle (Class, Student, Subject, Assessment, Grade, Makeup)**
- Status: OPEN
- Hinweis: Scheint bereits implementiert zu sein
- **→ VERIFIZIEREN und ggf. schließen**

---

## 🎯 Empfohlener Release-Plan v0.14.0

### Scope: Benutzerverwaltung + Quick Wins

#### Must-Have (Kern-Features)
1. **#39: Benutzerverwaltung & Berechtigungssystem** 🔥
   - 4 Rollen (Admin, Lehrer, Ausbilder, Schüler)
   - Favoriten-System
   - Berechtigungen auf allen Screens
   - Bugs fixen (User anlegen, Email ändern)

#### Nice-to-Have (Quick Wins)
2. **#35: Klasse direkt im CSV-Import anlegen**
   - Aufwand: 1-2h
   - UX-Verbesserung
   - Passt gut zum Release

#### Cleanup
3. **Issues schließen/aktualisieren:**
   - #6: Domain-Modelle → prüfen und ggf. schließen
   - #19: RBS-Styleguide → prüfen ob #18 ausreicht

---

## 📝 Aktionsplan

### Schritt 1: Verifizierung (Code-Analyse)
- [ ] #6: Domain-Modelle im Code vorhanden?
- [ ] #19: Was fehlt noch vom RBS-Styleguide?
- [ ] Alle geschlossenen Feature-Issues im Code verifizieren

### Schritt 2: Issues aktualisieren
- [ ] #6: Schließen falls implementiert
- [ ] #19: Schließen oder aktualisieren
- [ ] #11, #13, #14: Labels "v0.15.0" hinzufügen
- [ ] #31, #34: Labels "future" oder "v0.16.0"

### Schritt 3: Release v0.14.0 planen
- [ ] Milestone "v0.14.0" erstellen
- [ ] Issues zuweisen: #39 (must), #35 (nice-to-have)
- [ ] Zeitplan: 2-3 Tage Implementierung + Testing

### Schritt 4: Issue #39 starten
- [ ] Branch `feature/user-management-improvements` erstellen
- [ ] Schrittweise umsetzen (Models → Provider → UI)
- [ ] Testing parallel

---

## 📊 Nächste Releases (Ausblick)

### v0.15.0 - Features
- #11: Zeugnisnote automatisch berechnen
- #13: PDF-Export
- #14: Settings-Bereich erweitern

### v0.16.0 - Performance & Security
- #31: Skalierung (1000+ Schüler)
- #34: E2E-Verschlüsselung

### Backlog
- #21: Premium PDF Import

---

## ✅ Empfehlung für JETZT

1. **Code-Analyse durchführen** → Verifizieren welche geschlossenen Issues wirklich umgesetzt sind
2. **Issue #6 und #19 prüfen** → Schließen oder aktualisieren
3. **Milestone v0.14.0 erstellen** → Issues #39 + #35 zuweisen
4. **Mit #39 starten** → Benutzerverwaltung ist das Hauptfeature

**Soll ich mit der Code-Analyse starten? (Issues #6, #19 prüfen)**
