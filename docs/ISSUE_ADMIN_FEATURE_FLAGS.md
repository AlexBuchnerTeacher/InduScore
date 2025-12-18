# Admin-Feature-Flags: Funktionen für Lehrer codierbar machen

## Problem / Goal

Aktuell sind die Berechtigungen **rollenbasiert und hardcoded** (Admin, Lehrer, Ausbilder, Schüler). Ein Admin kann nicht granular entscheiden, **welche Funktionen für Lehrer freigeschaltet** werden.

**Beispiel-Szenarien:**
- Schule A möchte, dass Lehrer CSV importieren dürfen → aktuell nur Admin
- Schule B möchte, dass Lehrer keine Schüler anlegen dürfen → aktuell erlaubt
- Schule C möchte, dass Lehrer keine Fächer bearbeiten dürfen → aktuell erlaubt

**Business Value:**
- **Flexibilität**: Jede Schule kann App an eigene Prozesse anpassen
- **Sicherheit**: Admin behält volle Kontrolle über Funktionen
- **Skalierbarkeit**: White-Label-Ready (unterschiedliche Kunden, unterschiedliche Workflows)
- **Einfache Verwaltung**: Admin-UI statt Code-Änderungen

## Scope

### In Scope
- **Feature-Flag-System** (Firestore-basiert, Admin-steuerbar)
- **Admin-UI** zum Aktivieren/Deaktivieren von Features für Lehrer
- **Granulare Permissions** (pro Feature, nicht nur pro Rolle)
- **Firestore-Persistenz** mit Security Rules
- **Live-Updates** (Feature-Flags ändern = sofortige Wirkung)
- **Fallback-Logik** (wenn Feature-Flags nicht geladen, sichere Defaults)

**Features zum Codieren:**
- [ ] CSV Import (Lehrer dürfen/dürfen nicht)
- [ ] Schüler anlegen (Lehrer dürfen/dürfen nicht)
- [ ] Schüler bearbeiten (Lehrer dürfen/dürfen nicht)
- [ ] Schüler löschen (Lehrer dürfen/dürfen nicht)
- [ ] Fächer anlegen (Lehrer dürfen/dürfen nicht)
- [ ] Fächer bearbeiten (Lehrer dürfen/dürfen nicht)
- [ ] Fächer löschen (Lehrer dürfen/dürfen nicht)
- [ ] Klassen anlegen (Lehrer dürfen/dürfen nicht) ← **aktuell nein**
- [ ] Klassen bearbeiten (Lehrer dürfen/dürfen nicht)
- [ ] Klassen löschen (Lehrer dürfen/dürfen nicht)
- [ ] Leistungsnachweise anlegen (Lehrer dürfen/dürfen nicht)
- [ ] Leistungsnachweise bearbeiten (Lehrer dürfen/dürfen nicht)
- [ ] Leistungsnachweise löschen (Lehrer dürfen/dürfen nicht)
- [ ] Favoriten-Toggle (Lehrer dürfen/dürfen nicht)
- [ ] Export-Funktionen (PDF, Excel)

### Out of Scope
- User-individuelle Permissions (zu komplex)
- Zeitbasierte Permissions (z.B. "nur Montags")
- Feature-Flags für Schüler/Ausbilder (erst später)
- Feature-Flags für UI-Elemente (z.B. Theme-Auswahl)

## Architektur-Blueprint

### Datenmodell (Firestore)

#### Collection: `settings`
#### Document: `features`

```json
{
  "lehrer": {
    "canImportCSV": false,
    "canCreateSchueler": true,
    "canEditSchueler": true,
    "canDeleteSchueler": false,
    "canCreateFaecher": true,
    "canEditFaecher": true,
    "canDeleteFaecher": false,
    "canCreateKlassen": false,
    "canEditKlassen": true,
    "canDeleteKlassen": false,
    "canCreateLeistungsnachweise": true,
    "canEditLeistungsnachweise": true,
    "canDeleteLeistungsnachweise": false,
    "canToggleFavorites": true,
    "canExportPDF": true,
    "canExportExcel": false
  },
  "updatedAt": "2025-12-18T15:00:00Z",
  "updatedBy": "bu-admin"
}
```

**Struktur:**
- `lehrer` (map): Feature-Flags für Lehrer-Rolle
- `canXyz` (boolean): Jede Funktion hat ein Flag
- `updatedAt` (timestamp): Letzte Änderung
- `updatedBy` (string): UID des Admins

### Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Feature-Flags: Nur Admin darf schreiben, alle authentifizierten Nutzer dürfen lesen
    match /settings/features {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rolle == 'admin';
    }
  }
}
```

### Provider-Architektur

#### 1. FeatureFlags Model

```dart
@immutable
class FeatureFlags {
  // CSV Import
  final bool canImportCSV;
  
  // Schüler
  final bool canCreateSchueler;
  final bool canEditSchueler;
  final bool canDeleteSchueler;
  
  // Fächer
  final bool canCreateFaecher;
  final bool canEditFaecher;
  final bool canDeleteFaecher;
  
  // Klassen
  final bool canCreateKlassen;
  final bool canEditKlassen;
  final bool canDeleteKlassen;
  
  // Leistungsnachweise
  final bool canCreateLeistungsnachweise;
  final bool canEditLeistungsnachweise;
  final bool canDeleteLeistungsnachweise;
  
  // Sonstige
  final bool canToggleFavorites;
  final bool canExportPDF;
  final bool canExportExcel;
  
  const FeatureFlags({
    this.canImportCSV = false,
    this.canCreateSchueler = true,
    this.canEditSchueler = true,
    this.canDeleteSchueler = false,
    this.canCreateFaecher = true,
    this.canEditFaecher = true,
    this.canDeleteFaecher = false,
    this.canCreateKlassen = false,
    this.canEditKlassen = true,
    this.canDeleteKlassen = false,
    this.canCreateLeistungsnachweise = true,
    this.canEditLeistungsnachweise = true,
    this.canDeleteLeistungsnachweise = false,
    this.canToggleFavorites = true,
    this.canExportPDF = true,
    this.canExportExcel = false,
  });
  
  factory FeatureFlags.fromFirestore(Map<String, dynamic> data) {
    return FeatureFlags(
      canImportCSV: data['canImportCSV'] ?? false,
      canCreateSchueler: data['canCreateSchueler'] ?? true,
      canEditSchueler: data['canEditSchueler'] ?? true,
      canDeleteSchueler: data['canDeleteSchueler'] ?? false,
      // ... alle Felder
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'canImportCSV': canImportCSV,
      'canCreateSchueler': canCreateSchueler,
      'canEditSchueler': canEditSchueler,
      'canDeleteSchueler': canDeleteSchueler,
      // ... alle Felder
    };
  }
}
```

#### 2. FeatureFlagsProvider (Riverpod)

```dart
class FeatureFlagsController extends StateNotifier<FeatureFlags> {
  final FirebaseFirestore _firestore;
  StreamSubscription? _listener;
  
  FeatureFlagsController(this._firestore)
      : super(const FeatureFlags()) {  // Sichere Defaults
    _initFeatureFlags();
  }
  
  Future<void> _initFeatureFlags() async {
    _listener = _firestore
        .collection('settings')
        .doc('features')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()?['lehrer'] as Map<String, dynamic>?;
        if (data != null) {
          state = FeatureFlags.fromFirestore(data);
        }
      }
    });
  }
  
  Future<void> updateFeatureFlags(FeatureFlags flags, String adminUid) async {
    await _firestore.collection('settings').doc('features').set({
      'lehrer': flags.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
    });
  }
  
  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }
}

final featureFlagsProvider = StateNotifierProvider<FeatureFlagsController, FeatureFlags>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FeatureFlagsController(firestore);
});
```

#### 3. Permission Provider Refactoring

```dart
// Aktuell (hardcoded):
final canCreateDataProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  return user?.rolle == UserRole.admin;
});

// Neu (Feature-Flags):
final canCreateSchuelerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  final flags = ref.watch(featureFlagsProvider);
  
  // Admin kann immer
  if (user?.rolle == UserRole.admin) return true;
  
  // Lehrer nur wenn Feature-Flag gesetzt
  if (user?.rolle == UserRole.lehrer) return flags.canCreateSchueler;
  
  return false;
});

final canCreateKlassenProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  final flags = ref.watch(featureFlagsProvider);
  
  if (user?.rolle == UserRole.admin) return true;
  if (user?.rolle == UserRole.lehrer) return flags.canCreateKlassen;
  
  return false;
});

// ... analog für alle anderen Permissions
```

### Admin-UI

#### Screen: `feature_flags_screen.dart`

```dart
class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final controller = ref.read(featureFlagsProvider.notifier);
    final currentUser = ref.watch(currentAppUserProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Feature-Verwaltung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Funktionen für Lehrer', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // CSV Import
          SwitchListTile(
            title: const Text('CSV Import'),
            subtitle: const Text('Lehrer dürfen CSV-Dateien importieren'),
            value: flags.canImportCSV,
            onChanged: (value) {
              controller.updateFeatureFlags(
                flags.copyWith(canImportCSV: value),
                currentUser!.id,
              );
            },
          ),
          
          const Divider(),
          Text('Schüler-Verwaltung', style: Theme.of(context).textTheme.titleMedium),
          
          SwitchListTile(
            title: const Text('Schüler anlegen'),
            value: flags.canCreateSchueler,
            onChanged: (value) => controller.updateFeatureFlags(
              flags.copyWith(canCreateSchueler: value),
              currentUser!.id,
            ),
          ),
          
          SwitchListTile(
            title: const Text('Schüler bearbeiten'),
            value: flags.canEditSchueler,
            onChanged: (value) => controller.updateFeatureFlags(
              flags.copyWith(canEditSchueler: value),
              currentUser!.id,
            ),
          ),
          
          SwitchListTile(
            title: const Text('Schüler löschen'),
            value: flags.canDeleteSchueler,
            onChanged: (value) => controller.updateFeatureFlags(
              flags.copyWith(canDeleteSchueler: value),
              currentUser!.id,
            ),
          ),
          
          // ... analog für Fächer, Klassen, Leistungsnachweise
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}
```

## Implementierungsplan

### Phase 1: Datenmodell & Provider (8 Tasks)
- [ ] `FeatureFlags` Model erstellen (`lib/models/feature_flags.dart`)
- [ ] `FeatureFlagsController` (Riverpod) implementieren
- [ ] `featureFlagsProvider` Provider erstellen
- [ ] Firestore Collection `settings/features` initialisieren
- [ ] Security Rules für `settings/features` implementieren
- [ ] Default-Werte definieren (sichere Defaults)
- [ ] Fallback-Logik implementieren (wenn Firestore offline)
- [ ] Unit-Tests für FeatureFlags Model

### Phase 2: Permission Provider Refactoring (15 Tasks)
- [ ] `canImportCSVProvider` auf Feature-Flags umstellen
- [ ] `canCreateSchuelerProvider` auf Feature-Flags umstellen
- [ ] `canEditSchuelerProvider` auf Feature-Flags umstellen
- [ ] `canDeleteSchuelerProvider` auf Feature-Flags umstellen
- [ ] `canCreateFaecherProvider` auf Feature-Flags umstellen
- [ ] `canEditFaecherProvider` auf Feature-Flags umstellen
- [ ] `canDeleteFaecherProvider` auf Feature-Flags umstellen
- [ ] `canCreateKlassenProvider` auf Feature-Flags umstellen (aktuell: `canCreateDataProvider`)
- [ ] `canEditKlassenProvider` auf Feature-Flags umstellen
- [ ] `canDeleteKlassenProvider` auf Feature-Flags umstellen
- [ ] `canCreateLeistungsnachweiseProvider` bereits vorhanden (prüfen)
- [ ] `canEditLeistungsnachweiseProvider` bereits vorhanden (prüfen)
- [ ] `canDeleteLeistungsnachweiseProvider` hinzufügen
- [ ] `canToggleFavoritesProvider` hinzufügen
- [ ] `canExportProvider` hinzufügen (PDF, Excel)

### Phase 3: Admin-UI (5 Tasks)
- [ ] `FeatureFlagsScreen` erstellen (`lib/features/admin/screens/feature_flags_screen.dart`)
- [ ] UI-Layout mit SwitchListTiles
- [ ] Gruppierung (Schüler, Fächer, Klassen, etc.)
- [ ] Speichern in Firestore
- [ ] Feedback (SnackBar: "Feature-Flags gespeichert")

### Phase 4: Integration & Testing (6 Tasks)
- [ ] Navigation zu `FeatureFlagsScreen` im Admin-Menü
- [ ] Widget-Tests für Permission Provider
- [ ] Integration-Test: Admin aktiviert/deaktiviert Features
- [ ] Manual Test: Lehrer sieht nur freigeschaltete Funktionen
- [ ] Firestore Security Rules testen
- [ ] Offline-Modus testen (Fallback-Logik)

### Phase 5: Dokumentation & Migration (4 Tasks)
- [ ] Dokumentation für Admins (wie Feature-Flags nutzen)
- [ ] Migration-Guide: Alte Permission Provider → Neue Feature-Flags
- [ ] Changelog Update
- [ ] Release Notes

## Akzeptanzkriterien

### Muss-Kriterien
- [ ] Admin kann in Admin-UI alle Features für Lehrer aktivieren/deaktivieren
- [ ] Feature-Flags werden in Firestore gespeichert
- [ ] Lehrer sehen nur freigeschaltete Funktionen (Buttons, Menü-Einträge)
- [ ] Security Rules verhindern, dass Lehrer Feature-Flags ändern
- [ ] Feature-Flags werden live aktualisiert (ohne Reload)
- [ ] Sichere Defaults (wenn Firestore nicht erreichbar)
- [ ] Admin behält immer alle Rechte (unabhängig von Feature-Flags)

### Kann-Kriterien
- [ ] Preset-Profile (z.B. "Volle Rechte", "Eingeschränkt", "Nur Lesen")
- [ ] Feature-Flag-History (wer hat wann was geändert)
- [ ] Bulk-Operations (alle Features auf einmal aktivieren/deaktivieren)

## Risiken & Notes

- **Risiko**: Zu viele Feature-Flags = UI überfrachtet
  - **Mitigation**: Gruppierung, Tabs, Suche
- **Risiko**: Lehrer können wichtige Funktionen nicht nutzen (falsch konfiguriert)
  - **Mitigation**: Sinnvolle Defaults, Admin-Dokumentation
- **Risiko**: Performance (viele Provider-Checks)
  - **Mitigation**: Feature-Flags cachen, nicht jedes Mal neu laden
- **Note**: Feature-Flags sollten mit Theme-System kompatibel sein
- **Note**: Später erweiterbar für andere Rollen (Ausbilder, Schüler)

---

**Geschätzter Aufwand**: 15-20h (1 Entwickler)  
**Priorität**: High (wichtig für White-Label und Flexibilität)  
**Labels**: `enhancement`, `admin`, `permissions`, `feature-flags`
