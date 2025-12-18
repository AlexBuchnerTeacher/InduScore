# Issue: Skalierbares Theme-System mit RBS und C64-Theme

## 🎯 Problem / Goal (Business Value)

IndusCore nutzt aktuell ein "RBS"-Design, das nicht als standardisiertes Theme-Modul implementiert ist. Es fehlt:
- **Skalierbarkeit**: Neue Themes erfordern UI-Widget-Refactoring
- **Konsistenz**: Hardcodierte Farben/Styles in Komponenten
- **Flexibilität**: Kein globales Theme-Switching möglich
- **Wartbarkeit**: Theme-Änderungen berühren viele Dateien

**Business Value:**
- **Retro-Branding**: C64-Theme als Alleinstellungsmerkmal (nostalgiefaktor++)
- **White-Label Ready**: Schnelle Anpassung für andere Schulträger/Kunden
- **Developer Experience**: Token-basiert → weniger Bugs, schnellere Features
- **User Experience**: Konsistente Optik über alle Screens, keine Theme-Flicker

## 📦 Scope

### ✅ In Scope
- Skalierbare Theme-Architektur (Token-System, Registry, Factory Pattern)
- 2 Themes: **RBS** (Standard) und **C64** (Retro)
- Admin-UI für globales Theme-Switching (eine Einstellung für alle User)
- Firestore-Persistenz mit Cache-first Boot-Flow (flicker-free)
- C64-spezifische Microcopy ("READY.", "ERROR.", "SAVED.")
- Theme-spezifische Assets (Logo/Icons)
- Alle bestehenden Screens müssen Theme-kompatibel werden
- Security Rules: Nur Admin darf Theme ändern
- Light Mode Only

### ❌ Out of Scope
- Dark Mode / System-Theme-Detection
- User-individuelle Theme-Präferenzen (nur global)
- Sound-Effekte / Animationen
- Accessibility-Features (später in separatem Issue)
- Theme-Builder-UI für Non-Devs
- Internationalisierung der Microcopy (erstmal nur Deutsch)

## 📋 Anforderungen

### Funktional
1. **Theme-Switching**
   - Admin kann zwischen RBS und C64 umschalten
   - Umschaltung erfolgt live (ohne Reload)
   - Einstellung gilt global für alle Nutzer
   - RBS ist jederzeit wieder auswählbar (Rollback)

2. **Theme-Konsistenz**
   - Alle UI-Komponenten nutzen Theme-Tokens (keine Hardcodes)
   - Logo/Icons passen sich dem Theme an
   - Microcopy passt sich dem Theme an
   - DataTables, Forms, Buttons, Dialogs: einheitlicher Look

3. **Skalierbarkeit**
   - Neues Theme hinzufügen = Token-Set + Registry-Eintrag
   - Keine Widget-Änderungen nötig
   - ThemeRegistry als Single Source of Truth

4. **Persistenz**
   - Theme-Setting in Firestore: `settings/app.themeKey`
   - Local Cache (shared_preferences) für flicker-free Boot
   - Firestore Snapshot Listener für Live-Updates (graceful offline)

### Nicht-funktional
1. **Performance**: Theme-Switch < 100ms, kein UI-Freeze
2. **Robustheit**: Fallback auf RBS bei ungültigem Theme-Key
3. **Web-Fonts**: C64-Font mit Web-Fallback (keine FOIT - Flash of Invisible Text)
4. **Testing**: Widget-Tests für Theme-Switch, Golden-Tests für visuelle Regression
5. **Security**: Nur Admin darf Theme ändern (Firestore Rules)

## 🏗️ Architektur-Blueprint

### Ordnerstruktur

```
lib/
├── core/
│   └── theme/
│       ├── models/
│       │   ├── theme_key.dart              # enum ThemeKey { rbs, c64 }
│       │   ├── design_tokens.dart          # DesignTokens (colors, typography, spacing, etc.)
│       │   ├── theme_bundle.dart           # ThemeBundle (themeData + tokens + microcopy + assets)
│       │   └── microcopy_set.dart          # MicrocopySet (ok, error, saved, ready, etc.)
│       ├── tokens/
│       │   ├── rbs_tokens.dart             # RBS Design Token Definitions
│       │   └── c64_tokens.dart             # C64 Design Token Definitions
│       ├── factories/
│       │   ├── theme_factory.dart          # DesignTokens -> ThemeData (Material 3)
│       │   └── theme_bundle_factory.dart   # ThemeBundleFactory Interface
│       ├── registry/
│       │   └── theme_registry.dart         # Map<ThemeKey, ThemeBundleFactory>
│       ├── providers/
│       │   └── app_theme_provider.dart     # Riverpod: AppThemeController + AppThemeState
│       ├── widgets/
│       │   └── themed_app.dart             # MaterialApp Wrapper mit Theme-Listener
│       └── legacy/
│           └── rbs_theme.dart              # Alte RBS-Definitionen (deprecated, später entfernen)
├── features/
│   └── admin/
│       └── screens/
│           └── theme_settings_screen.dart  # Admin UI für Theme-Switch
└── assets/
    └── themes/
        ├── rbs/
        │   ├── logo.svg
        │   └── icons/
        └── c64/
            ├── logo_c64.svg
            ├── icons/
            └── fonts/
                └── C64_Pro_Mono.ttf       # Optional: Pixel Font
```

### Zentrale Klassen/Interfaces

#### 1. ThemeKey (enum)
```dart
/// Theme-Identifier (erweiterbar für neue Themes)
enum ThemeKey {
  rbs('rbs', 'RBS Standard'),
  c64('c64', 'C64 Retro');

  final String key;
  final String displayName;
  const ThemeKey(this.key, this.displayName);

  static ThemeKey fromString(String? value) {
    return values.firstWhere(
      (t) => t.key == value,
      orElse: () => ThemeKey.rbs, // Fallback
    );
  }
}
```

#### 2. DesignTokens (immutable class)
```dart
/// Design Tokens (Color, Typography, Spacing, Borders, States)
@immutable
class DesignTokens {
  // Colors
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color error;
  final Color onPrimary;
  final Color onBackground;
  // Typography
  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle body;
  final TextStyle caption;
  // Spacing
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  // Borders & Radius
  final double borderWidth;
  final double borderRadius;
  // States (Hover, Focus, Pressed)
  final Color hoverOverlay;
  final Color focusBorder;
  final double elevation;

  const DesignTokens({
    required this.primary,
    // ... alle Felder
  });
}
```

#### 3. MicrocopySet (immutable class)
```dart
@immutable
class MicrocopySet {
  final String ready;        // RBS: "Bereit" | C64: "READY."
  final String ok;           // RBS: "OK" | C64: "OK"
  final String error;        // RBS: "Fehler" | C64: "ERROR."
  final String saved;        // RBS: "Gespeichert" | C64: "SAVED."
  final String loading;      // RBS: "Laden..." | C64: "LOADING..."
  final String confirm;      // RBS: "Bestätigen" | C64: "CONFIRM"
  final String cancel;       // RBS: "Abbrechen" | C64: "CANCEL"

  const MicrocopySet({
    required this.ready,
    required this.ok,
    required this.error,
    required this.saved,
    required this.loading,
    required this.confirm,
    required this.cancel,
  });
}
```

#### 4. ThemeBundle (immutable class)
```dart
@immutable
class ThemeBundle {
  final ThemeKey key;
  final ThemeData themeData;       // Material 3 ThemeData
  final DesignTokens tokens;
  final MicrocopySet microcopy;
  final ThemeAssets assets;        // Logo/Icon Paths

  const ThemeBundle({
    required this.key,
    required this.themeData,
    required this.tokens,
    required this.microcopy,
    required this.assets,
  });
}

@immutable
class ThemeAssets {
  final String logoPath;           // z.B. 'assets/themes/rbs/logo.svg'
  final String iconStyle;          // 'outlined' | 'filled' | 'monochrome'

  const ThemeAssets({
    required this.logoPath,
    required this.iconStyle,
  });
}
```

#### 5. ThemeBundleFactory (Interface)
```dart
abstract class ThemeBundleFactory {
  ThemeBundle create();
}

// Implementierung pro Theme:
class RbsThemeBundleFactory implements ThemeBundleFactory {
  @override
  ThemeBundle create() {
    final tokens = RbsTokens.tokens;
    return ThemeBundle(
      key: ThemeKey.rbs,
      themeData: ThemeFactory.createThemeData(tokens),
      tokens: tokens,
      microcopy: RbsTokens.microcopy,
      assets: const ThemeAssets(
        logoPath: 'assets/themes/rbs/logo.svg',
        iconStyle: 'outlined',
      ),
    );
  }
}
```

#### 6. ThemeRegistry (Singleton)
```dart
class ThemeRegistry {
  static final ThemeRegistry instance = ThemeRegistry._();
  ThemeRegistry._();

  final Map<ThemeKey, ThemeBundleFactory> _registry = {
    ThemeKey.rbs: RbsThemeBundleFactory(),
    ThemeKey.c64: C64ThemeBundleFactory(),
  };

  ThemeBundle getThemeBundle(ThemeKey key) {
    final factory = _registry[key] ?? _registry[ThemeKey.rbs]!;
    return factory.create();
  }

  List<ThemeKey> get availableThemes => _registry.keys.toList();
}
```

#### 7. AppThemeProvider (Riverpod)
```dart
@immutable
class AppThemeState {
  final ThemeKey currentKey;
  final ThemeBundle bundle;
  final bool isLoading;

  const AppThemeState({
    required this.currentKey,
    required this.bundle,
    this.isLoading = false,
  });
}

class AppThemeController extends StateNotifier<AppThemeState> {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  StreamSubscription? _firestoreListener;

  AppThemeController(this._firestore, this._prefs)
      : super(AppThemeState(
          currentKey: ThemeKey.rbs,
          bundle: ThemeRegistry.instance.getThemeBundle(ThemeKey.rbs),
        )) {
    _initTheme();
  }

  Future<void> _initTheme() async {
    // 1. Cache lesen
    final cachedKey = _prefs.getString('app_themeKey');
    if (cachedKey != null) {
      final key = ThemeKey.fromString(cachedKey);
      _setTheme(key, saveToCache: false);
    }

    // 2. Firestore lesen + Listener
    _firestoreListener = _firestore
        .collection('settings')
        .doc('app')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final key = ThemeKey.fromString(snapshot.data()?['themeKey']);
        _setTheme(key);
      }
    });
  }

  void _setTheme(ThemeKey key, {bool saveToCache = true}) {
    if (saveToCache) {
      _prefs.setString('app_themeKey', key.key);
    }
    state = AppThemeState(
      currentKey: key,
      bundle: ThemeRegistry.instance.getThemeBundle(key),
    );
  }

  Future<void> setTheme(ThemeKey key, String adminUid) async {
    state = state.copyWith(isLoading: true);
    await _firestore.collection('settings').doc('app').set({
      'themeKey': key.key,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
    });
    _setTheme(key);
    state = state.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    _firestoreListener?.cancel();
    super.dispose();
  }
}

final appThemeProvider = StateNotifierProvider<AppThemeController, AppThemeState>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppThemeController(firestore, prefs);
});
```

## 💾 Datenmodell in Firestore

### Collection: `settings`
### Document: `app`

```json
{
  "themeKey": "rbs",
  "updatedAt": "2025-12-18T14:30:00Z",
  "updatedBy": "bu-admin"
}
```

**Felder:**
- `themeKey` (string): "rbs" | "c64" (später erweiterbar)
- `updatedAt` (timestamp): Server-Timestamp der letzten Änderung
- `updatedBy` (string): UID des Admins, der Theme geändert hat

## 🔒 Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Theme Settings: Nur Admin darf schreiben, alle dürfen lesen
    match /settings/app {
      allow read: if true;
      allow write: if request.auth != null 
                   && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rolle == 'admin';
    }
  }
}
```

## 🎨 C64-Theme Vorgaben (Design Guidelines)

### Farben
- **Primary**: `#3F51B5` (C64 Blau) oder `#7C71DA` (helleres Blau)
- **Background**: `#352879` (dunkles Lila) oder `#F7F7F7` (hellgrau für Light Mode)
- **Surface**: `#FFFFFF` mit `1-2px` schwarzem Rahmen
- **Text**: `#000000` (schwarz) oder `#FFFFFF` (invertiert bei Selection)
- **Error**: `#D32F2F` (rot, kräftig)
- **Border**: `1-2px solid #000000`, `border-radius: 0-2px`

### Typography
- **Font Family**: Monospace/Pixel-Font (z.B. `C64 Pro Mono`, `Press Start 2P`)
- **Fallback**: `'Courier New', Courier, monospace`
- **Sizes**: 
  - Heading: `16-20px` (bold, uppercase)
  - Body: `12-14px` (normal)
  - Caption: `10-12px` (klein, für Meta-Info)
- **Letter-Spacing**: `0.5-1px` (leicht erhöht für Retro-Look)

### Spacing & Layout
- **Spacing**: 8px Grid (xs=4, sm=8, md=16, lg=24)
- **Border-Radius**: `0-2px` (harte Kanten)
- **Elevation**: Keine Shadows, stattdessen `border` + `background contrast`
- **Cards**: Weiße Box mit `1px` schwarzem Rahmen, kein Shadow

### Komponenten-Spezifikationen

#### Buttons
- **Primary**: Schwarzer Hintergrund, weißer Text, `border: 2px solid black`
- **Hover**: Invertiert (weißer Hintergrund, schwarzer Text)
- **Focus**: Doppelter Rahmen (`outline: 2px solid`)
- **Disabled**: Grau mit gestricheltem Rahmen

#### Forms (Inputs, TextFields)
- **Default**: Weißer Hintergrund, `1px` schwarzer Rahmen
- **Focus**: `2px` Rahmen, optional Block-Cursor Animation
- **Error**: Roter Rahmen + Error-Text in Monospace
- **Label**: Uppercase, klein (12px)

#### DataTables
- **Header**: Schwarzer Hintergrund, weißer Text, kein Sorting-Icon (nur Pfeil ↑↓)
- **Rows**: Alternierend weiß/hellgrau (`#F0F0F0`)
- **Selection**: Invertiert (schwarzer Hintergrund, weißer Text)
- **Hover**: Leichter Rahmen-Highlight

#### Dialogs
- **Container**: Weißer Hintergrund, `2px` schwarzer Rahmen, kein Shadow
- **Title**: Uppercase, Monospace, `border-bottom: 1px solid`
- **Actions**: Buttons wie oben (schwarz/weiß Invertierung)

#### Icons & Logo
- **Style**: Monochrom, pixelig/blocky (8x8 oder 16x16 Grid)
- **Logo**: ASCII-Art-Style "INDUSCORE" oder Pixel-Grafik
- **Icon Set**: Custom Pixel-Icons oder Material Icons mit `size: 16-20` (klein)

### Microcopy (C64-Stil)
- **READY.** (statt "Bereit")
- **ERROR.** (statt "Fehler")
- **SAVED.** (statt "Gespeichert")
- **LOADING...** (statt "Laden...")
- **OK** / **CONFIRM** / **CANCEL** (Uppercase, kurz)

## 📝 Implementierungsplan (Checklist)

### Phase 1: Architektur & Modelle (10 Tasks)
- [ ] `ThemeKey` enum erstellen (`lib/core/theme/models/theme_key.dart`)
- [ ] `DesignTokens` Klasse erstellen (`lib/core/theme/models/design_tokens.dart`)
- [ ] `MicrocopySet` Klasse erstellen (`lib/core/theme/models/microcopy_set.dart`)
- [ ] `ThemeAssets` Klasse erstellen (`lib/core/theme/models/theme_bundle.dart`)
- [ ] `ThemeBundle` Klasse erstellen (`lib/core/theme/models/theme_bundle.dart`)
- [ ] `ThemeBundleFactory` Interface erstellen (`lib/core/theme/factories/theme_bundle_factory.dart`)
- [ ] `ThemeFactory` für Material 3 erstellen (`lib/core/theme/factories/theme_factory.dart`)
  - [ ] ColorScheme aus Tokens generieren
  - [ ] TextTheme aus Tokens generieren
  - [ ] ButtonTheme aus Tokens generieren
  - [ ] InputDecorationTheme aus Tokens generieren

### Phase 2: RBS Theme Migration (8 Tasks)
- [ ] `RbsTokens` definieren (`lib/core/theme/tokens/rbs_tokens.dart`)
  - [ ] Farben aus bestehendem `rbs_theme.dart` extrahieren
  - [ ] Typography aus bestehendem Code extrahieren
  - [ ] Spacing-Konstanten extrahieren
  - [ ] Microcopy-Set definieren (deutsch, modern)
- [ ] `RbsThemeBundleFactory` implementieren
- [ ] RBS Logo/Assets in `assets/themes/rbs/` ablegen
- [ ] `rbs_theme.dart` als `@deprecated` markieren
- [ ] Alle RBS-Hardcodes in Widgets durch Theme-Zugriff ersetzen (iterativ)

### Phase 3: C64 Theme Implementierung (10 Tasks)
- [ ] `C64Tokens` definieren (`lib/core/theme/tokens/c64_tokens.dart`)
  - [ ] C64-Farben definieren (siehe Vorgaben)
  - [ ] Monospace-Typography definieren
  - [ ] Harte Kanten (borderRadius: 0-2)
  - [ ] Microcopy-Set (C64-Stil: READY., ERROR.)
- [ ] `C64ThemeBundleFactory` implementieren
- [ ] C64 Logo/Assets erstellen und in `assets/themes/c64/` ablegen
  - [ ] ASCII-Art Logo oder Pixel-Logo
  - [ ] Pixel-Icons (optional)
- [ ] C64-Font (`C64_Pro_Mono.ttf`) einbinden
  - [ ] Font-Datei in `assets/themes/c64/fonts/` ablegen
  - [ ] `pubspec.yaml` Font-Definition
  - [ ] Fallback auf `Courier New` bei Font-Load-Failure
- [ ] C64-spezifische Widget-Overrides testen (Button, TextField, DataTable)

### Phase 4: Theme Registry & Provider (7 Tasks)
- [ ] `ThemeRegistry` Singleton erstellen (`lib/core/theme/registry/theme_registry.dart`)
- [ ] RBS + C64 in Registry registrieren
- [ ] `AppThemeState` Model erstellen
- [ ] `AppThemeController` (Riverpod StateNotifier) implementieren
  - [ ] Cache-first Init (_initTheme mit SharedPreferences)
  - [ ] Firestore Snapshot Listener
  - [ ] setTheme-Methode (mit Admin-UID)
  - [ ] Graceful Offline Handling
- [ ] `appThemeProvider` Provider erstellen
- [ ] `ThemedApp` Widget erstellen (MaterialApp Wrapper mit Theme-Listener)

### Phase 5: Firestore & Persistence (5 Tasks)
- [ ] Firestore `settings/app` Dokument-Struktur definieren
- [ ] Security Rules für `settings/app` implementieren (nur Admin write)
- [ ] Initiale Firestore-Daten setzen (`themeKey: "rbs"`)
- [ ] SharedPreferences Setup für Cache (`app_themeKey`)
- [ ] Boot-Flow testen (Cache -> Firestore -> Listener)

### Phase 6: Admin UI (6 Tasks)
- [ ] `ThemeSettingsScreen` erstellen (`lib/features/admin/screens/theme_settings_screen.dart`)
- [ ] Theme-Auswahl UI (Segmented Button oder Dropdown)
  - [ ] Dynamisch aus `ThemeRegistry.availableThemes` generieren
  - [ ] Live-Preview (sofort umschalten)
- [ ] Save-Button mit Firestore-Persistenz
- [ ] Feedback (SnackBar mit Microcopy: "SAVED." oder "Gespeichert")
- [ ] Admin-Only Guard (canManageUsers check)
- [ ] Navigation einbinden (z.B. in Admin-Menü)

### Phase 7: Widget-Migration (12 Tasks)
- [ ] `RBSButton` auf Theme-Tokens umstellen
- [ ] `RBSInput` auf Theme-Tokens umstellen
- [ ] `RBSCard` auf Theme-Tokens umstellen
- [ ] `RBSDrawer` auf Theme-Tokens umstellen
- [ ] DataTables auf Theme-Tokens umstellen
- [ ] Dialogs auf Theme-Tokens umstellen
- [ ] AppBar auf Theme-Tokens umstellen
- [ ] Chips/Tags auf Theme-Tokens umstellen
- [ ] ListTiles auf Theme-Tokens umstellen
- [ ] Login-Screen auf Theme-Tokens umstellen
- [ ] Dashboard auf Theme-Tokens umstellen
- [ ] Alle weiteren Screens durchgehen und Hardcodes entfernen

### Phase 8: Testing & QA (8 Tasks)
- [ ] Widget-Test: Theme-Switch (RBS <-> C64)
- [ ] Widget-Test: ThemeRegistry (Fallback auf RBS bei ungültigem Key)
- [ ] Widget-Test: AppThemeController (Cache + Firestore Flow)
- [ ] Integration-Test: Admin UI (Theme ändern, persistieren)
- [ ] Golden-Test: RBS Theme (Haupt-Screens)
- [ ] Golden-Test: C64 Theme (Haupt-Screens)
- [ ] Manual Smoke-Test: Alle Screens in RBS durchklicken
- [ ] Manual Smoke-Test: Alle Screens in C64 durchklicken

### Phase 9: Dokumentation & Cleanup (5 Tasks)
- [ ] README.md Update: Theme-System Dokumentation
- [ ] `THEMING.md` Guide erstellen (für künftige Themes)
- [ ] Changelog Update (Version Bump)
- [ ] Alte `rbs_theme.dart` entfernen (wenn alle Migrationen abgeschlossen)
- [ ] Code Review & Refactoring

## ✅ Akzeptanzkriterien

### Muss-Kriterien
1. **Theme-Switching funktioniert**
   - [ ] Admin kann in Admin-UI zwischen RBS und C64 umschalten
   - [ ] Theme-Änderung erfolgt live (< 100ms, kein Reload)
   - [ ] Alle Screens zeigen das neue Theme sofort
   - [ ] RBS ist jederzeit wieder auswählbar (Rollback)

2. **Persistenz & Boot**
   - [ ] Theme-Setting wird in Firestore gespeichert (`settings/app.themeKey`)
   - [ ] Theme wird im Cache gespeichert (SharedPreferences)
   - [ ] App startet mit gecachtem Theme (kein Flackern)
   - [ ] Firestore-Update zieht Theme live nach (bei mehreren offenen Tabs)

3. **Theme-Konsistenz**
   - [ ] Alle UI-Komponenten nutzen Theme-Tokens (keine Hardcodes)
   - [ ] Logo/Icons passen sich dem Theme an
   - [ ] Microcopy passt sich dem Theme an (z.B. "SAVED." in C64)
   - [ ] DataTables, Forms, Buttons, Dialogs: einheitlicher Look pro Theme

4. **C64-Theme Requirements**
   - [ ] Monospace/Pixel-Font wird geladen (mit Fallback)
   - [ ] Harte Kanten (borderRadius: 0-2px)
   - [ ] Schwarze Rahmen (1-2px)
   - [ ] Alternating Table Rows
   - [ ] Invertierte Selection (schwarz auf weiß → weiß auf schwarz)
   - [ ] Microcopy in C64-Stil ("READY.", "ERROR.")

5. **Skalierbarkeit**
   - [ ] Neues Theme hinzufügen erfordert nur:
     - [ ] Token-Set definieren (`XyzTokens`)
     - [ ] Factory implementieren (`XyzThemeBundleFactory`)
     - [ ] In Registry registrieren
   - [ ] Keine UI-Widget-Änderungen nötig

6. **Security**
   - [ ] Nur Admin kann Theme ändern (Firestore Rules)
   - [ ] Non-Admin sehen Theme-Settings-Screen nicht

### Kann-Kriterien (Nice-to-Have)
- [ ] Theme-Preview in Admin-UI (kleine Vorschau-Kacheln)
- [ ] Theme-History (wer hat wann welches Theme aktiviert)
- [ ] A/B-Test-Modus (verschiedene Themes für verschiedene User-Gruppen)

## 🧪 Smoke-Tests (Manuell)

### Test 1: Theme-Switch (RBS → C64 → RBS)
1. Als Admin einloggen
2. Admin-UI → Theme-Einstellungen öffnen
3. C64 auswählen → "Speichern"
4. Prüfen: Alle Screens zeigen C64-Theme (Monospace, Rahmen, Microcopy)
5. RBS auswählen → "Speichern"
6. Prüfen: Alle Screens zeigen wieder RBS-Theme
7. **Erwartung**: Kein Flackern, sofortige Umschaltung, konsistent über alle Screens

### Test 2: Cache-First Boot
1. Theme auf C64 setzen
2. App neu laden (Ctrl+R im Browser)
3. Prüfen: C64-Theme wird sofort geladen (kein RBS-Flash)
4. **Erwartung**: Kein Theme-Flackern, gecachtes Theme wird sofort angezeigt

### Test 3: Firestore Live-Update
1. In Tab 1 als Admin eingeloggt
2. In Tab 2 ebenfalls eingeloggt
3. In Tab 1 Theme auf C64 ändern
4. Prüfen: Tab 2 wechselt automatisch zu C64 (Firestore Listener)
5. **Erwartung**: Live-Update in < 1s, kein manueller Reload nötig

### Test 4: Offline-Modus
1. App mit RBS-Theme starten
2. DevTools → Network offline schalten
3. Versuchen, Theme auf C64 zu ändern
4. Prüfen: Graceful Error (z.B. "Offline - Theme wird nicht gespeichert")
5. Online gehen → Theme-Änderung erneut versuchen
6. **Erwartung**: Keine Crashes, klare Fehlermeldung, Retry funktioniert

### Test 5: Non-Admin User
1. Als Lehrer einloggen
2. Prüfen: Theme-Einstellungen nicht im Menü sichtbar
3. Direkter URL-Aufruf der Theme-Settings (falls Route existiert)
4. **Erwartung**: "Zugriff verweigert" Screen oder 404

### Test 6: Ungültiger Theme-Key in Firestore
1. In Firestore `settings/app.themeKey` manuell auf `"foobar"` setzen
2. App neu laden
3. Prüfen: Fallback auf RBS-Theme (keine Crashes)
4. **Erwartung**: App funktioniert, zeigt RBS-Theme

## 🧪 Test-Plan (Optional - für CI/CD)

### Widget-Tests
```dart
// test/core/theme/theme_registry_test.dart
testWidgets('ThemeRegistry returns RBS theme by default', (tester) async {
  final bundle = ThemeRegistry.instance.getThemeBundle(ThemeKey.rbs);
  expect(bundle.key, ThemeKey.rbs);
  expect(bundle.themeData, isNotNull);
});

testWidgets('ThemeRegistry falls back to RBS on invalid key', (tester) async {
  final bundle = ThemeRegistry.instance.getThemeBundle(ThemeKey.fromString('invalid'));
  expect(bundle.key, ThemeKey.rbs);
});
```

### Golden-Tests (Visuelle Regression)
```dart
// test/golden/rbs_theme_test.dart
testWidgets('Login Screen - RBS Theme', (tester) async {
  await tester.pumpWidget(ThemedApp(
    themeBundle: ThemeRegistry.instance.getThemeBundle(ThemeKey.rbs),
    child: LoginScreen(),
  ));
  await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_rbs.png'));
});

// test/golden/c64_theme_test.dart
testWidgets('Login Screen - C64 Theme', (tester) async {
  await tester.pumpWidget(ThemedApp(
    themeBundle: ThemeRegistry.instance.getThemeBundle(ThemeKey.c64),
    child: LoginScreen(),
  ));
  await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_c64.png'));
});
```

### Integration-Tests
```dart
// integration_test/theme_switch_test.dart
testWidgets('Admin switches theme from RBS to C64', (tester) async {
  // 1. Login als Admin
  // 2. Navigate to Theme-Settings
  // 3. Select C64
  // 4. Save
  // 5. Verify Firestore update
  // 6. Verify UI shows C64 theme
});
```

## ⚠️ Risiken & Notes

### Bekannte Risiken
1. **Theme-Flicker beim Boot**
   - **Risiko**: Cache-Load zu langsam, kurzer RBS-Flash vor C64
   - **Mitigation**: SharedPreferences synchron lesen, Theme sofort setzen

2. **Font Loading (FOIT - Flash of Invisible Text)**
   - **Risiko**: C64-Font lädt langsam, Text kurz unsichtbar
   - **Mitigation**: Font mit `fontDisplay: swap` laden, Fallback auf Courier

3. **Firestore Offline-Modus**
   - **Risiko**: Listener schlägt fehl, Theme wird nicht synchronisiert
   - **Mitigation**: Graceful Degradation, Cache als Source of Truth

4. **Widget-Migration Aufwand**
   - **Risiko**: Viele Widgets mit Hardcodes, lange Migration
   - **Mitigation**: Iteratives Vorgehen, Screen für Screen

5. **Material 3 Subtheme-Komplexität**
   - **Risiko**: ThemeFactory wird sehr groß und komplex
   - **Mitigation**: Factory in Sub-Factories aufteilen (ButtonThemeFactory, InputThemeFactory, etc.)

6. **C64-Font License**
   - **Risiko**: Font möglicherweise nicht lizenziert für kommerzielle Nutzung
   - **Mitigation**: Open-Source-Font verwenden (z.B. Press Start 2P, C64 Pro Mono - SIL Open Font License)

### Notes
- **Performance**: Theme-Switch muss schnell sein (< 100ms). ThemeData-Objekte ggf. cachen.
- **Testing**: Golden-Tests nur für kritische Screens (Login, Dashboard, Admin-UI). Sonst zu aufwändig.
- **Rollout**: Theme-System in Feature-Branch entwickeln, dann PR mit Review.
- **Backwards Compatibility**: Alte `rbs_theme.dart` deprecaten, aber nicht sofort löschen (Deprecation-Phase).
- **Dokumentation**: `THEMING.md` schreiben, damit künftige Entwickler neue Themes einfach hinzufügen können.

## 📚 Zusätzliche Ressourcen

### Material 3 Theming
- https://m3.material.io/develop/flutter
- https://docs.flutter.dev/ui/design/material

### C64 Fonts & Assets
- **Press Start 2P**: https://fonts.google.com/specimen/Press+Start+2P (Open Source)
- **C64 Pro Mono**: https://style64.org/c64-truetype (SIL Open Font License)
- **C64 Color Palette**: https://www.c64-wiki.com/wiki/Color

### Riverpod State Management
- https://riverpod.dev/docs/concepts/providers
- https://riverpod.dev/docs/concepts/reading

### Flutter Golden Tests
- https://docs.flutter.dev/testing/integration-tests
- https://pub.dev/packages/golden_toolkit

---

**Geschätzter Aufwand**: 20-30h (1 Entwickler)  
**Priorität**: Medium (Nice-to-Have Feature)  
**Labels**: `enhancement`, `design`, `theme`, `architecture`, `c64`
