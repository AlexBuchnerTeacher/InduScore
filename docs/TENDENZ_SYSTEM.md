# Tendenz-System: Nur visueller Indikator

## Übersicht

Tendenzen (+, ·, -) bei Noten dienen **ausschließlich als visueller Indikator** für die Lehrkraft. Sie werden **nicht in Berechnungen einbezogen**.

## Geschäftsregel

| Note mit Tendenz | Berechnungswert | Erklärung |
|------------------|-----------------|-----------|
| 2+ | 2.0 | Tendenz ignoriert |
| 2 | 2.0 | Neutral |
| 2- | 2.0 | Tendenz ignoriert |

**Wichtig:** Alle Durchschnittsberechnungen (Fach, Klasse, Gesamt) verwenden ausschließlich die Ganzzahl-Note.

## Begründung

Die Tendenz ist eine **pädagogische Einschätzung** der Lehrkraft:
- **+** = "Schüler tendiert zur besseren Note"
- **·** = "Neutral / keine Tendenz"
- **-** = "Schüler tendiert zur schlechteren Note"

Diese Information ist **subjektiv** und soll:
- Der Lehrkraft bei Grenzfällen helfen
- Als Gedächtnisstütze dienen
- Bei Zeugnisnoten-Findung unterstützen

Sie soll **nicht**:
- Mathematisch in den Durchschnitt einfließen
- Automatisch Noten verändern
- Die Transparenz gegenüber Schülern beeinflussen

## Implementierung

### getNoteWithTendenz (noten_matrix_logic.dart)

```dart
/// Tendenzen werden NICHT in die Berechnung einbezogen!
/// Sie dienen nur als visueller Indikator (+/-) für die Lehrkraft.
static double getNoteWithTendenz(int note, Tendenz tendenz) {
  return note.toDouble(); // Tendenz ignoriert
}
```

### Tendenz Model (tendenz.dart)

```dart
/// Tendenz einer Note (optional)
enum Tendenz {
  plus('+'),
  neutral('·'),
  minus('-');
  
  final String symbol;
  const Tendenz(this.symbol);
}
```

### UI-Darstellung

Tendenzen werden visuell als kleine Icons (+/·/-) neben der Note angezeigt:
- **Kompakte Buttons** in vertikaler Anordnung
- **Farbcodierung:** Aktive Tendenz hervorgehoben
- **Keine Auswirkung** auf angezeigte Durchschnitte

## Tests

9 Tests in `test/features/noten/tendenz_calculation_test.dart`:

1. `getNoteWithTendenz returns note without modification for Tendenz.plus`
2. `getNoteWithTendenz returns note without modification for Tendenz.neutral`
3. `getNoteWithTendenz returns note without modification for Tendenz.minus`
4. `All note values (1-6) with plus tendenz return exact note value`
5. `All note values (1-6) with neutral tendenz return exact note value`
6. `All note values (1-6) with minus tendenz return exact note value`
7. `calculateFachDurchschnitt ignores tendenz in calculation`
8. `Average of 2+, 2, 2- equals exactly 2.0`
9. `Mixed notes with different tendencies calculate correct average`

## Version

- **Eingeführt:** v0.30.1 (2025-12-30)
- **Vorher:** Tendenzen wurden mit ±0.3 berechnet
- **Grund:** Klärung mit Fachbereich - Tendenzen sind pädagogische Indikatoren
