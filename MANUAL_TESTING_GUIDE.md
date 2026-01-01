# Kürzel-Caching Fix - Manual Testing Guide

## Problem Summary
Das richtige Lehrerkürzel aus dem AppUser-Profil wurde nicht korrekt bei der Noteneingabe angezeigt. Stattdessen wurden Buchstaben aus der E-Mail-Adresse extrahiert.

## Root Cause
- `currentUserKuerzelProvider` war ein regulärer `Provider<String>` der `.value` von einem `FutureProvider` las
- `.value` kann `null` sein während des Ladens oder bei Fehlern
- Keine automatische Provider-Invalidierung bei Profil-Updates

## Solution Implemented
1. **Provider-Typ geändert:** `Provider<String>` → `FutureProvider<String>`
2. **Async-Handling:** Wartet auf AppUser-Daten statt `.value` zu lesen
3. **Debug-Logging:** Bessere Nachverfolgung der Kürzel-Auflösung
4. **Provider-Invalidierung:** Bei User-Updates in user_verwaltung_screen.dart
5. **Consumer-Updates:** noten_eingabe_screen.dart und noten_uebersicht_screen.dart nutzen `.future`

## Test Scenarios

### Scenario 1: Normaler Login mit gesetztem Kürzel
**Schritte:**
1. Als User mit gesetztem Kürzel einloggen (z.B. "BU")
2. Navigiere zur Noteneingabe (Leistungsnachweise → LN auswählen)
3. Gib eine Note für einen Schüler ein

**Erwartetes Ergebnis:**
- Das Kürzel "BU" erscheint in der rechten oberen Ecke der Noten-Dropdown-Box
- Debug-Logs zeigen: `[currentUserKuerzelProvider] Using AppUser.kuerzel: BU`
- Das Kürzel stammt NICHT aus der E-Mail-Adresse

**Akzeptanzkriterium:** ✅ Kürzel wird korrekt aus AppUser.kuerzel gelesen

### Scenario 2: Login mit leerem Kürzel (Fallback)
**Schritte:**
1. Erstelle einen User ohne Kürzel oder mit leerem Kürzel
2. Logge dich mit diesem User ein
3. Navigiere zur Noteneingabe
4. Gib eine Note ein

**Erwartetes Ergebnis:**
- Fallback-Kürzel wird aus E-Mail extrahiert (z.B. "TEST" aus "test@example.com")
- Debug-Logs zeigen: `[currentUserKuerzelProvider] AppUser.kuerzel is empty, using fallback...`
- Debug-Logs zeigen: `[currentUserKuerzelProvider] Fallback kuerzel from email: TEST`

**Akzeptanzkriterium:** ✅ Fallback auf E-Mail-Extraktion funktioniert

### Scenario 3: Kürzel-Update im Admin-Bereich
**Schritte:**
1. Logge dich als Admin ein
2. Gehe zu Benutzerverwaltung
3. Bearbeite dein eigenes Kürzel (z.B. von "AB" zu "BU")
4. Speichere die Änderung
5. Navigiere zur Noteneingabe (OHNE neu einzuloggen)
6. Gib eine Note ein

**Erwartetes Ergebnis:**
- Das neue Kürzel "BU" wird sofort verwendet
- Kein App-Neustart oder Re-Login nötig
- Debug-Logs zeigen: `[currentUserKuerzelProvider] Using AppUser.kuerzel: BU`

**Akzeptanzkriterium:** ✅ Kürzel-Änderungen werden sofort übernommen

### Scenario 4: Notenübersicht-Screen
**Schritte:**
1. Logge dich ein
2. Navigiere zur Notenübersicht (Klasse auswählen)
3. Ändere eine Note in der Matrix-Ansicht

**Erwartetes Ergebnis:**
- Das korrekte Kürzel wird beim Speichern verwendet
- Kürzel erscheint in der Noten-Zelle (klein, rechts oben)

**Akzeptanzkriterium:** ✅ Kürzel funktioniert auch in Notenübersicht

### Scenario 5: Race Condition Test (Loading State)
**Schritte:**
1. Logge dich aus
2. Logge dich neu ein
3. Navigiere SOFORT zur Noteneingabe (während AppUser noch lädt)
4. Versuche eine Note einzugeben

**Erwartetes Ergebnis:**
- Während AppUser lädt, wird Fallback-Kürzel aus Firebase User E-Mail verwendet
- Sobald AppUser geladen ist, wird das richtige Kürzel verwendet
- Debug-Logs zeigen: `[currentUserKuerzelProvider] AppUser is loading, using fallback...`
- Debug-Logs zeigen später: `[currentUserKuerzelProvider] Using AppUser.kuerzel: XX`
- Keine Fehler oder `null` values

**Akzeptanzkriterium:** ✅ Keine Race-Conditions beim Provider-Loading

## Debug-Logging
Die folgenden Debug-Logs können in der Browser-Konsole beobachtet werden:

```
[currentUserKuerzelProvider] Resolving kuerzel...
[currentUserKuerzelProvider] Using AppUser.kuerzel: BU
```

oder bei Fallback:

```
[currentUserKuerzelProvider] Resolving kuerzel...
[currentUserKuerzelProvider] AppUser is loading, using fallback...
[currentUserKuerzelProvider] Fallback kuerzel from email: TEST
```

## Rollback Plan
Falls Probleme auftreten:
1. Revert commits: `git revert f6ac6dc 433cd67 c4cf0ed`
2. Der alte Code verwendete `Provider<String>` mit `.value`
3. Keine Datenbank-Migration nötig

## Files Changed
- `lib/providers/app_providers.dart` - Provider-Typ und Logik
- `lib/features/noten/screens/noten_eingabe_screen.dart` - Await .future
- `lib/features/noten/screens/noten_uebersicht_screen.dart` - Await .future
- `lib/features/users/screens/user_verwaltung_screen.dart` - Provider invalidation
- `test/providers/current_user_kuerzel_provider_test.dart` - Tests (NEU)
- `CHANGELOG.md` - Dokumentation

## Acceptance Criteria Summary
- [x] Kürzel wird korrekt aus `AppUser.kuerzel` gelesen
- [x] Bei Profile-Updates wird das Kürzel sofort aktualisiert (via Provider-Invalidierung)
- [x] Fallback auf E-Mail-Extraktion nur wenn `AppUser.kuerzel` leer/null
- [x] Konsistente Anzeige in Noteneingabe und Notenübersicht
- [x] Keine Race-Conditions beim Provider-Loading (Fallback während Loading)
- [x] Debug-Logging für bessere Nachverfolgung
- [x] Code Review bestanden (keine Duplikation, sauberer Code)
- [x] Security Check bestanden (CodeQL)

## Next Steps for Manual Testing
1. Deploy to staging environment
2. Test all 5 scenarios above
3. Monitor debug logs in browser console
4. Verify kuerzel display in both noten_eingabe and noten_uebersicht screens
5. Test with different users (with/without kuerzel set)
6. Test kuerzel updates in admin panel
