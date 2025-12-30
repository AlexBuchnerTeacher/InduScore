# Accessibility (Barrierefreiheit)

Dokumentation der Accessibility-Features in InduScore.

## Übersicht

InduScore implementiert Accessibility-Features für:
- Screen Reader (VoiceOver, TalkBack, NVDA)
- Tastaturnavigation
- Kontrastreiche Darstellung

---

## Implementierte Features (v0.20.0+)

### 1. Semantics Labels

Alle interaktiven Widgets haben `semanticLabel` Parameter:

#### RBSButton
```dart
RBSButton(
  onPressed: () => save(),
  label: 'Speichern',
  semanticLabel: 'Schüler speichern', // Screen Reader liest dies vor
)
```

#### RBSCard
```dart
RBSCard(
  semanticLabel: 'Schüler Max Mustermann, Klasse 12IT1',
  child: StudentContent(),
)
```

### 2. Navigation Semantics

Der `RBSDrawer` hat Semantics für alle Menüpunkte:

```dart
Semantics(
  label: 'Navigation zu Dashboard',
  button: true,
  child: ListTile(
    title: Text('Dashboard'),
    onTap: () => context.go('/'),
  ),
)
```

### 3. Widget-Hierarchie

```
lib/
├── core/widgets/
│   └── rbs_components.dart      # RBSButton, RBSCard mit semanticLabel
├── widgets/
│   └── rbs_drawer.dart          # Navigation mit Semantics
└── features/*/screens/          # Screens nutzen semantische Widgets
```

---

## Best Practices

### Do's ✅

```dart
// Explizite Semantics für komplexe Widgets
Semantics(
  label: 'Note: 2, Schüler: Max Mustermann',
  child: GradeCard(grade: grade),
)

// Button mit beschreibendem Label
RBSButton(
  label: 'Löschen',
  semanticLabel: 'Schüler Max Mustermann löschen',
)

// Bilder mit Beschreibung
Image.asset(
  'assets/logo.png',
  semanticLabel: 'InduScore Logo',
)
```

### Don'ts ❌

```dart
// Keine leeren Labels
Semantics(label: '', child: Widget())

// Keine technischen Labels
Semantics(label: 'btn_delete_123', child: Widget())

// Icons ohne Beschreibung
IconButton(
  icon: Icon(Icons.delete),
  onPressed: delete,
  // Fehlt: tooltip oder semanticLabel
)
```

---

## Checkliste für neue Widgets

- [ ] Hat das Widget ein `semanticLabel` Parameter?
- [ ] Werden Icons mit `tooltip` versehen?
- [ ] Ist der Fokus-Reihenfolge logisch?
- [ ] Sind Farben kontrastreich genug (WCAG AA)?
- [ ] Funktioniert Tastaturnavigation?

---

## Komponenten-Referenz

### RBSButton

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `label` | String | Sichtbarer Text |
| `semanticLabel` | String? | Screen Reader Text |
| `icon` | IconData? | Optional Icon |

```dart
RBSButton(
  label: 'Speichern',
  semanticLabel: 'Änderungen speichern und Dialog schließen',
  icon: Icons.save,
  onPressed: save,
)
```

### RBSCard

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `semanticLabel` | String? | Screen Reader Text |
| `child` | Widget | Karteninhalt |

```dart
RBSCard(
  semanticLabel: 'Klasse 12IT1, 25 Schüler, 3 Fächer',
  child: KlasseContent(),
)
```

### RBSDrawer

Automatische Semantics für alle Navigations-Items:
- `label`: "Navigation zu [Ziel]"
- `button`: true
- `enabled`: true

---

## Testing

### Automatisierte Tests

```dart
testWidgets('Button hat Semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RBSButton(
        label: 'Test',
        semanticLabel: 'Test Button',
        onPressed: () {},
      ),
    ),
  );

  expect(
    find.bySemanticsLabel('Test Button'),
    findsOneWidget,
  );
});
```

### Manuelle Tests

1. **VoiceOver (macOS/iOS)**
   - Cmd+F5 zum Aktivieren
   - Tab durch die App navigieren
   - Prüfen ob Labels vorgelesen werden

2. **TalkBack (Android)**
   - Einstellungen > Bedienungshilfen > TalkBack
   - Durch die App tippen
   - Prüfen ob Elemente beschrieben werden

3. **NVDA (Windows)**
   - NVDA starten
   - Chrome mit der App öffnen
   - Mit Tab navigieren

### WAVE Tool

Browser-Extension für Accessibility-Analyse:
- [WAVE Chrome Extension](https://chrome.google.com/webstore/detail/wave-evaluation-tool)

**Ziel**: 0 Critical Errors

---

## Lighthouse Accessibility Score

### Ziel: >90

```bash
# Chrome DevTools
# F12 > Lighthouse > Accessibility

# Oder CLI
lighthouse https://your-app.web.app --only-categories=accessibility
```

### Häufige Issues

| Issue | Lösung |
|-------|--------|
| Missing alt text | `semanticLabel` für Images |
| Low contrast | RBS Styleguide Farben nutzen |
| Missing form labels | `InputDecoration.labelText` |
| No focus indicators | Standard Flutter Focus behalten |

---

## WCAG 2.1 Compliance

### Level A (Minimum) ✅
- [x] Nicht-Text-Inhalte haben Alternativen
- [x] Tastaturbedienbar
- [x] Keine Tastenfallen

### Level AA (Target) 🎯
- [x] Kontrast mindestens 4.5:1
- [x] Text skalierbar auf 200%
- [ ] Fokus sichtbar (TODO: Custom Focus Styles)

### Level AAA (Optional)
- [ ] Kontrast 7:1
- [ ] Gebärdensprachvideos

---

## Farben & Kontrast

RBS Styleguide Farben erfüllen WCAG AA:

| Farbe | Hex | Kontrast auf Weiß |
|-------|-----|-------------------|
| Dynamic Red | #E3000F | 4.6:1 ✅ |
| Court Green | #007A3D | 4.8:1 ✅ |
| Growing Elder | #6B5B4F | 5.2:1 ✅ |
| Text Primary | #1A1A1A | 16.1:1 ✅ |

---

## Referenzen

- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://m3.material.io/foundations/accessible-design)
- [WAVE Tool](https://wave.webaim.org/)
