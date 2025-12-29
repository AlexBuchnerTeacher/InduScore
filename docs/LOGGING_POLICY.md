# InduScore - Logging & Privacy Policy

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-12-29  
**Erstellt gemäß:** Issue #51 Finding F09

> **Ziel:** Verhindern von PII (Personally Identifiable Information) Leaks in Logs, Debug-Ausgaben und Error-Messages

---

## Inhaltsverzeichnis
1. [Grundprinzipien](#1-grundprinzipien)
2. [Was NIEMALS geloggt werden darf](#2-was-niemals-geloggt-werden-darf)
3. [Was geloggt werden darf](#3-was-geloggt-werden-darf)
4. [Code-Beispiele](#4-code-beispiele)
5. [Error-Logging Strategie](#5-error-logging-strategie)
6. [Firestore Security Rules](#6-firestore-security-rules)
7. [Enforcement](#7-enforcement)

---

## 1. Grundprinzipien

### 1.1 Privacy by Design

**Regel:** Logs dürfen KEINE personenbezogenen Daten enthalten, die Schüler oder Lehrer identifizieren können.

**Begründung:**
- 📜 **DSGVO-Konformität:** Logs sind technische Daten, dürfen aber keine PII enthalten
- 🔒 **Security:** Logs werden oft in externe Services gesendet (Firebase Crashlytics)
- 🎯 **Best Practice:** IDs statt Namen loggen → genauso nützlich für Debugging

### 1.2 Log-Levels

**Empfohlene Log-Levels:**
- `debugPrint()`: Development-only, wird in Release-Builds entfernt
- `print()`: ⚠️ VERMEIDEN (bleibt in Release-Builds!)
- `FirebaseCrashlytics.recordError()`: Production Error-Logging (wenn implementiert)

---

## 2. Was NIEMALS geloggt werden darf

### 2.1 Personenbezogene Daten (PII)

❌ **VERBOTEN zu loggen:**

| Kategorie | Beispiele | Begründung |
|-----------|-----------|------------|
| **Namen** | `firstName`, `lastName`, `displayName` | Identifiziert Person direkt |
| **Kontaktdaten** | `email`, `telefon`, `adresse` | Sensible Daten |
| **Credentials** | `password`, `token`, `apiKey` | Sicherheitsrisiko |
| **Demografische Daten** | `geburtsdatum`, `alter`, `geschlecht` | Datenschutz |
| **Notizen/Kommentare** | Freitextfelder mit Namen | Kann PII enthalten |

### 2.2 Konkrete Feld-Namen aus InduScore

❌ **Diese Felder NIEMALS loggen:**
```dart
// Student Model
student.firstName          // ❌ PII
student.lastName           // ❌ PII
student.displayName        // ❌ PII (kombiniert firstName + lastName)

// AppUser Model
user.email                 // ❌ PII
user.displayName           // ❌ PII
user.kuerzel               // ⚠️ OK nur in Development, NICHT in Production!

// Lehrer, Ausbilder
lehrer.name                // ❌ PII
```

---

## 3. Was geloggt werden darf

### 3.1 Nicht-personenbezogene Daten

✅ **ERLAUBT zu loggen:**

| Kategorie | Beispiele | Verwendung |
|-----------|-----------|------------|
| **IDs** | `studentId`, `klasseId`, `userId`, `gradeId` | Identifiziert Entität, nicht Person |
| **Enums** | `UserRole`, `StudentStatus`, `MatrixViewMode` | Technische Werte |
| **Zahlen** | `value` (Note), `punkte`, `maxPunkte` | Berechnungen |
| **Timestamps** | `createdAt`, `updatedAt`, `datum` | Zeitstempel |
| **Booleans** | `isBerücksichtigt`, `isLoggedIn` | Flags |
| **Counts** | `students.length`, `totalGrades` | Aggregationen |

### 3.2 Konkrete Feld-Namen aus InduScore

✅ **Diese Felder DÜRFEN geloggt werden:**
```dart
// IDs (eindeutig, aber nicht personenbezogen im Log-Kontext)
student.id                 // ✅ OK
student.klasseId           // ✅ OK
student.berufId            // ✅ OK

// Enums
student.status             // ✅ OK (z.B. "aktiv", "archiviert")
user.rolle                 // ✅ OK (z.B. "lehrer", "admin")

// Zahlen
grade.value                // ✅ OK (z.B. 2.5)
grade.punkte               // ✅ OK (z.B. 45)

// Booleans
grade.isBerücksichtigt     // ✅ OK
```

---

## 4. Code-Beispiele

### 4.1 FALSCH (PII-Leak)

❌ **NIEMALS SO:**
```dart
// ❌ FALSCH: Student-Name wird geloggt
debugPrint('Student ${student.displayName} gespeichert');

// ❌ FALSCH: Email wird geloggt
debugPrint('User logged in: ${user.email}');

// ❌ FALSCH: Vollständiges Student-Objekt (enthält Namen)
debugPrint('Student created: $student');

// ❌ FALSCH: Liste mit Namen
debugPrint('Students: ${students.map((s) => s.displayName).join(", ")}');

// ❌ FALSCH: Error-Message mit Namen
throw Exception('Student ${student.lastName} nicht gefunden');
```

### 4.2 KORREKT (Privacy-Safe)

✅ **SO IST ES RICHTIG:**
```dart
// ✅ KORREKT: Nur ID loggen
debugPrint('Student ${student.id} gespeichert');

// ✅ KORREKT: Nur Rolle loggen (bei Login)
debugPrint('User logged in with role: ${user.rolle}');

// ✅ KORREKT: Nur relevante Felder
debugPrint('Student created: ID=${student.id}, Status=${student.status}');

// ✅ KORREKT: Count statt Namen
debugPrint('Loaded ${students.length} students for Klasse ${klasseId}');

// ✅ KORREKT: Error-Message mit ID
throw Exception('Student mit ID ${student.id} nicht gefunden');

// ✅ KORREKT: Aggregationen
debugPrint('Durchschnitt für LN ${leistungsnachweisId}: ${average}');
```

### 4.3 Spezialfall: Development vs Production

**Development (nur lokal):**
```dart
// ⚠️ OK in Development (nicht in Git committen!)
if (kDebugMode) {
  debugPrint('DEBUG: Student ${student.displayName} (${student.id})');
}
```

**Production (Firebase Crashlytics):**
```dart
// ✅ Nur IDs und technische Infos
FirebaseCrashlytics.instance.recordError(
  error,
  stack,
  reason: 'Failed to save student ${student.id}',
);
```

---

## 5. Error-Logging Strategie

### 5.1 User-facing Errors (UI)

**Regel:** Deutsche, user-friendly Messages OHNE technische Details

✅ **KORREKT:**
```dart
try {
  await firestoreService.saveStudent(student);
  RBSSnackBar.show(
    context,
    'Schüler erfolgreich gespeichert',
    type: RBSSnackBarType.success,
  );
} catch (e) {
  RBSSnackBar.show(
    context,
    'Fehler beim Speichern. Bitte erneut versuchen.',
    type: RBSSnackBarType.error,
  );
  // Log technischen Fehler (ohne PII!)
  debugPrint('Error saving student ${student.id}: $e');
}
```

❌ **FALSCH:**
```dart
RBSSnackBar.show(
  context,
  'Error: $e',  // ❌ Technischer Stack-Trace für User
);
```

### 5.2 Firestore Exception Handling

**Beispiel aus auth_service.dart:**
```dart
String _handleAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'Kein Benutzer mit dieser E-Mail gefunden.';  // ✅ User-friendly
    case 'wrong-password':
      return 'Falsches Passwort.';  // ✅ User-friendly
    case 'email-already-in-use':
      return 'E-Mail-Adresse wird bereits verwendet.';  // ✅ User-friendly
    default:
      // ✅ Generische Message, technischer Error wird geloggt
      debugPrint('Auth error: ${e.code}');
      return 'Anmeldefehler. Bitte später erneut versuchen.';
  }
}
```

---

## 6. Firestore Security Rules

### 6.1 Pre-Login Read-Access (Kürzel-Lookup)

**Aktueller Zustand (firestore.rules):**
```javascript
match /app_users/{userId} {
  // Pre-Login Read für Kürzel-Lookup
  allow read: if request.auth == null;
  allow write: if isAdmin();
}
```

**Security-Hinweis:**
- ⚠️ Ermöglicht Enumeration aller Kürzel (z.B. "BU", "MU")
- ✅ **AKZEPTIERT**, weil: Kürzel sind nicht sensitiv (keine Namen)
- 📝 Dokumentiert in `firestore.rules` Zeile 9

**Alternative (höhere Security, schlechtere Performance):**
- Cloud Function für Kürzel-zu-Email-Lookup → Rate-Limiting möglich
- **Entscheidung:** Aktueller Ansatz OK für schulische Nutzung

---

## 7. Enforcement

### 7.1 Code-Review Checklist

**Vor jedem PR-Merge prüfen:**
- [ ] Keine `print()` Statements (nutze `debugPrint()`)
- [ ] Keine PII in `debugPrint()` Ausgaben
- [ ] Keine PII in Exception-Messages
- [ ] Keine PII in `FirebaseCrashlytics.recordError()`
- [ ] User-facing Errors sind deutsch und user-friendly

### 7.2 Automatische Checks (geplant)

**CI-Check erstellen:**
```bash
# Grep-Check für potenzielle PII-Leaks
grep -r "displayName\|firstName\|lastName\|email" lib/ | grep -i "print\|log"
```

**Pre-Commit Hook:**
```bash
# Warnung bei print() Statements
if git diff --cached --name-only | grep -q '\.dart$'; then
  if git diff --cached | grep -q 'print('; then
    echo "⚠️  WARNING: print() statement found. Use debugPrint() instead!"
    exit 1
  fi
fi
```

### 7.3 Grep-Check (manuell)

**Führe regelmäßig aus:**
```bash
# Suche nach potenziellem PII-Logging
grep -rn "print.*displayName\|print.*email\|print.*firstName\|print.*lastName" lib/

# Sollte 0 Treffer haben!
```

**Wenn Treffer gefunden:**
1. Code reviewen
2. PII durch IDs ersetzen
3. Commit mit `fix(security): Remove PII from logs`

---

## 8. Firebase Crashlytics (geplant)

### 8.1 Setup (Issue #51 F10)

**Nach Implementierung:**
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crashlytics Setup
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

### 8.2 Custom Error Logging

✅ **KORREKT:**
```dart
try {
  await riskyOperation();
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(
    e,
    stack,
    reason: 'Failed to process LN ${leistungsnachweisId}',  // ✅ Nur ID
  );
}
```

❌ **FALSCH:**
```dart
FirebaseCrashlytics.instance.recordError(
  e,
  stack,
  reason: 'Failed for student ${student.displayName}',  // ❌ PII!
);
```

---

## 9. FAQ

### Q: Darf ich Kürzel loggen (z.B. "BU")?

**A:** ⚠️ **Nur in Development!**
- Kürzel sind NICHT eindeutig personenbezogen (kein voller Name)
- ABER: Können in Kombination mit anderen Daten identifizierend sein
- **Regel:** In Production NUR UserID loggen

```dart
// Development OK
if (kDebugMode) {
  debugPrint('Login attempt for Kürzel: ${kuerzel}');
}

// Production
debugPrint('Login attempt for UserID: ${userId}');
```

### Q: Darf ich Exception-Messages mit Namen werfen?

**A:** ❌ **NEIN!**

```dart
// ❌ FALSCH
throw Exception('Student ${student.lastName} nicht gefunden');

// ✅ KORREKT
throw Exception('Student mit ID ${student.id} nicht gefunden');
```

### Q: Wie logge ich komplexe Objekte?

**A:** Nur relevante, nicht-personenbezogene Felder

```dart
// ❌ FALSCH
debugPrint('Student: ${student.toString()}');  // Könnte PII enthalten

// ✅ KORREKT
debugPrint('Student: id=${student.id}, status=${student.status}, klasse=${student.klasseId}');
```

---

## 10. Zusammenfassung

### Goldene Regeln

1. 🚫 **NIEMALS Namen oder Emails loggen**
2. ✅ **Immer IDs statt personenbezogene Daten**
3. 🔍 **Pre-Commit: Grep-Check für PII-Leaks**
4. 📝 **User-facing Errors: Deutsch & user-friendly**
5. 🛡️ **Production-Logs: Nur technische Infos**

### Bei Fragen

**Issue öffnen mit Label:** `security`, `privacy`

---

**Compliance:** Diese Policy entspricht DSGVO Art. 25 (Privacy by Design) und Art. 32 (Sicherheit der Verarbeitung)