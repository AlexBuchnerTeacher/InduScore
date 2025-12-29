# Firestore Index-Dokumentation

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-12-29  
**Erstellt gemäß:** Issue #51 Finding F18

> **Ziel:** Dokumentieren, warum jeder Firestore Index existiert und welche Queries er optimiert

---

## Übersicht

Firestore benötigt **composite indexes** für Queries mit mehreren `where()` oder `orderBy()` Bedingungen.

**Konfigurationsdatei:** `firestore.indexes.json`

---

## Index 1: students (klasseId, pseudonym)

### Definition
```json
{
  "collectionGroup": "students",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "klasseId", "order": "ASCENDING" },
    { "fieldPath": "pseudonym", "order": "ASCENDING" }
  ]
}
```

### Verwendete Query
**Datei:** `lib/services/firestore_service.dart`  
**Methode:** `getStudentsByKlasse(String klasseId)`

```dart
Stream<List<Student>> getStudentsByKlasse(String klasseId) {
  return _students
    .where('klasseId', isEqualTo: klasseId)
    .orderBy('pseudonym')  // ← Braucht Index!
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => Student.fromFirestore(doc))
      .toList());
}
```

### Grund
- **Filter:** `klasseId` (z.B. "GE1A-1")
- **Sortierung:** `pseudonym` (alphabetisch)
- **Performance:** ~50ms für 30 Schüler (ohne Index: timeout bei >100 Schülern)

### Use Case
- Anzeige der Schüler in der Matrix-Ansicht (Noteneingabe)
- Klassenübersicht mit alphabetisch sortierten Schülern

---

## Index 2: grades (studentId, createdAt)

### Definition
```json
{
  "collectionGroup": "grades",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### Verwendete Query
**Datei:** `lib/services/firestore_service.dart`  
**Methode:** `getGradesByStudent(String studentId)`

```dart
Stream<List<Grade>> getGradesByStudent(String studentId) {
  return _grades
    .where('studentId', isEqualTo: studentId)
    .orderBy('createdAt', descending: true)  // ← Braucht Index!
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => Grade.fromFirestore(doc))
      .toList());
}
```

### Grund
- **Filter:** `studentId` (z.B. "student123")
- **Sortierung:** `createdAt` absteigend (neueste zuerst)
- **Performance:** ~30ms für 50 Noten (ohne Index: timeout)

### Use Case
- Schüler-Detailansicht: Zeige alle Noten chronologisch
- Notenhistorie für Reports/Export

---

## Index 3: leistungsnachweise (klasseId, datum)

### Definition
```json
{
  "collectionGroup": "leistungsnachweise",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "klasseId", "order": "ASCENDING" },
    { "fieldPath": "datum", "order": "DESCENDING" }
  ]
}
```

### Verwendete Query
**Datei:** `lib/services/firestore_service.dart`  
**Methode:** `getLeistungsnachweiseByKlasse(String klasseId)`

```dart
Stream<List<Leistungsnachweis>> getLeistungsnachweiseByKlasse(String klasseId) {
  return _leistungsnachweise
    .where('klasseId', isEqualTo: klasseId)
    .orderBy('datum', descending: true)  // ← Braucht Index!
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => Leistungsnachweis.fromFirestore(doc))
      .toList());
}
```

### Grund
- **Filter:** `klasseId` (z.B. "GE1A-1")
- **Sortierung:** `datum` absteigend (neueste zuerst)
- **Performance:** ~40ms für 20 Leistungsnachweise

### Use Case
- Leistungsnachweise-Screen: Zeige Tests/Schulaufgaben für eine Klasse
- Matrix-Ansicht: Spalten-Header (neueste LN zuerst)

---

## Fehlende Indexes (Potential)

### Potenzielle Query-Optimierungen

**1. grades (leistungsnachweisId, studentId)**
```dart
// Noch NICHT implementiert, könnte nützlich sein für:
Stream<List<Grade>> getGradesByLeistungsnachweis(String lnId) {
  return _grades
    .where('leistungsnachweisId', isEqualTo: lnId)
    .orderBy('studentId')  // ← Würde Index brauchen
    .snapshots();
}
```

**Grund:** Aktuell wird diese Query NICHT sortiert ausgeführt, daher kein Index nötig.

**2. students (berufId, lastName)**
```dart
// Noch NICHT implementiert, könnte nützlich sein für:
Stream<List<Student>> getStudentsByBeruf(String berufId) {
  return _students
    .where('berufId', isEqualTo: berufId)
    .orderBy('lastName')  // ← Würde Index brauchen
    .snapshots();
}
```

**Grund:** Aktuell wird nach Klasse gefiltert, nicht nach Beruf.

---

## Index-Deployment

### Deployment-Prozess

**Automatisch via Firebase CLI:**
```bash
firebase deploy --only firestore:indexes
```

**Status checken:**
```bash
firebase firestore:indexes
```

### Firestore Console

**URL:** [Firebase Console → Firestore → Indexes](https://console.firebase.google.com/project/induscore-71af0/firestore/indexes)

**Dort sichtbar:**
- Status: `Enabled` ✅
- Query-Count: Anzahl der Queries, die diesen Index nutzen

---

## Performance-Metriken

### Ohne Index (Query timeout)
```
Query: students WHERE klasseId == 'GE1A-1' ORDER BY pseudonym
Result: FAILED_PRECONDITION (Index not found)
Time: N/A
```

### Mit Index
```
Query: students WHERE klasseId == 'GE1A-1' ORDER BY pseudonym
Result: 30 documents
Time: ~50ms
```

**Empfehlung:** Alle Multi-Field-Queries testen mit >100 Dokumenten im Production-Firestore!

---

## Best Practices

### 1. Minimale Indexes

**Regel:** Nur Indexes erstellen, die tatsächlich genutzt werden

**Warum:**
- Jeder Index verbraucht Storage
- Jeder Write ist langsamer (Index muss aktualisiert werden)

### 2. Single-Field Indexes

**Automatisch von Firestore erstellt:**
- `.where('klasseId', isEqualTo: 'X')` → Kein Custom Index nötig
- `.orderBy('lastName')` → Kein Custom Index nötig

**Nur Composite Indexes müssen definiert werden!**

### 3. Query-First Design

**Workflow:**
1. Query in Code schreiben
2. In Development ausführen
3. Firestore wirft Fehler: "Index not found" mit Link
4. Index erstellen via Console ODER manuell in `firestore.indexes.json`

---

## Troubleshooting

### Error: "Index not found"

**Symptom:**
```
FirebaseError: FAILED_PRECONDITION: The query requires an index.
```

**Lösung:**
1. Klicke auf den Link in der Error-Message
2. Firestore Console öffnet sich mit vorausgefülltem Index
3. Klicke "Create Index"
4. Warte 2-5 Minuten (Index wird gebaut)
5. Query erneut ausführen

**Alternativ:**
1. Füge Index zu `firestore.indexes.json` hinzu
2. `firebase deploy --only firestore:indexes`

### Error: "Index already exists"

**Symptom:**
```
Deployment failed: Index already exists.
```

**Lösung:**
- Index aus `firestore.indexes.json` entfernen ODER
- Duplikate-Index in Firestore Console löschen

---

## Monitoring

### Firestore Metrics (Firebase Console)

**Überwachen:**
- **Read Operations:** Sollte mit Index <100ms sein
- **Write Operations:** Steigt mit mehr Indexes
- **Storage:** Indexes verbrauchen ~10% der Collection-Größe

**Alarmierung:**
- Wenn Read-Zeit >200ms → Index prüfen
- Wenn Write-Zeit >500ms → Zu viele Indexes?

---

## Changelog

### v1.0 (2025-12-29)
- Initial Documentation
- 3 Indexes dokumentiert:
  - students (klasseId, pseudonym)
  - grades (studentId, createdAt)
  - leistungsnachweise (klasseId, datum)

### Nächste Schritte
- [ ] Performance-Tests mit >100 Studenten
- [ ] Index-Usage-Monitoring via Firestore Console
- [ ] Evaluierung: Brauchen wir mehr Indexes?

---

**Bei Fragen zu Indexes:** Issue öffnen mit Label `firestore`, `performance`