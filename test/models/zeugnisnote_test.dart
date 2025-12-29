import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/zeugnisnote.dart';

void main() {
  group('Zeugnisnote.berechneSchnitt', () {
    test('berechnet gewichteten Durchschnitt korrekt', () {
      final noten = [
        (note: 2, gewichtung: 1.0),
        (note: 3, gewichtung: 1.0),
        (note: 4, gewichtung: 1.0),
      ];

      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, 3.0);
    });

    test('berechnet gewichteten Durchschnitt mit unterschiedlichen Gewichtungen', () {
      final noten = [
        (note: 2, gewichtung: 2.0), // 4.0
        (note: 4, gewichtung: 1.0), // 4.0
      ];
      // (4.0 + 4.0) / 3.0 = 2.666...

      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, closeTo(2.6667, 0.001));
    });

    test('gibt null zurück bei leerer Liste', () {
      final noten = <({int note, double gewichtung})>[];
      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, isNull);
    });

    test('gibt null zurück wenn Summe der Gewichtungen 0 ist', () {
      final noten = [
        (note: 2, gewichtung: 0.0),
        (note: 3, gewichtung: 0.0),
      ];

      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, isNull);
    });

    test('berechnet korrekt mit nur einer Note', () {
      final noten = [(note: 3, gewichtung: 1.0)];
      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, 3.0);
    });

    test('berechnet korrekt mit sehr unterschiedlichen Gewichtungen', () {
      final noten = [
        (note: 1, gewichtung: 5.0), // 5.0
        (note: 5, gewichtung: 1.0), // 5.0
      ];
      // (5.0 + 5.0) / 6.0 = 1.6667

      final schnitt = Zeugnisnote.berechneSchnitt(noten);
      expect(schnitt, closeTo(1.6667, 0.001));
    });
  });

  group('Zeugnisnote.rundeNote', () {
    test('rundet bei Nachkomma < 0.6 ab', () {
      expect(Zeugnisnote.rundeNote(2.5), 2);
      expect(Zeugnisnote.rundeNote(2.59), 2);
      expect(Zeugnisnote.rundeNote(3.4), 3);
      expect(Zeugnisnote.rundeNote(1.1), 1);
      expect(Zeugnisnote.rundeNote(4.0), 4);
    });

    test('rundet bei Nachkomma >= 0.6 auf', () {
      expect(Zeugnisnote.rundeNote(2.6), 3);
      expect(Zeugnisnote.rundeNote(2.7), 3);
      expect(Zeugnisnote.rundeNote(3.9), 4);
      expect(Zeugnisnote.rundeNote(1.6), 2);
      expect(Zeugnisnote.rundeNote(4.8), 5);
    });

    test('behandelt exakte Grenze 0.6 korrekt', () {
      expect(Zeugnisnote.rundeNote(2.6), 3);
      expect(Zeugnisnote.rundeNote(3.6), 4);
    });

    test('behandelt Ganzzahlen korrekt', () {
      expect(Zeugnisnote.rundeNote(1.0), 1);
      expect(Zeugnisnote.rundeNote(2.0), 2);
      expect(Zeugnisnote.rundeNote(3.0), 3);
      expect(Zeugnisnote.rundeNote(6.0), 6);
    });

    test('behandelt sehr kleine Nachkommastellen', () {
      expect(Zeugnisnote.rundeNote(2.01), 2);
      expect(Zeugnisnote.rundeNote(2.001), 2);
    });

    test('behandelt Nachkommastellen nahe an 1.0', () {
      expect(Zeugnisnote.rundeNote(2.99), 3);
      expect(Zeugnisnote.rundeNote(3.999), 4);
    });
  });

  group('Zeugnisnote.berechneZeugnisnote', () {
    test('berechnet und rundet Zeugnisnote korrekt (abrunden)', () {
      final noten = [
        (note: 2, gewichtung: 1.0),
        (note: 3, gewichtung: 1.0),
      ];
      // Schnitt: 2.5 → rundet zu 2

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, 2);
    });

    test('berechnet und rundet Zeugnisnote korrekt (aufrunden)', () {
      final noten = [
        (note: 2, gewichtung: 1.0),
        (note: 3, gewichtung: 2.0),
      ];
      // Schnitt: (2 + 6) / 3 = 2.6667 → rundet zu 3

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, 3);
    });

    test('gibt null zurück bei leerer Notenliste', () {
      final noten = <({int note, double gewichtung})>[];
      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, isNull);
    });

    test('gibt null zurück wenn Schnitt nicht berechnet werden kann', () {
      final noten = [
        (note: 2, gewichtung: 0.0),
      ];

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, isNull);
    });

    test('berechnet korrekt mit komplexem Beispiel', () {
      final noten = [
        (note: 2, gewichtung: 2.0), // 4.0
        (note: 3, gewichtung: 1.5), // 4.5
        (note: 4, gewichtung: 1.0), // 4.0
        (note: 1, gewichtung: 0.5), // 0.5
      ];
      // Summe gewichtet: 13.0
      // Summe Gewichtung: 5.0
      // Schnitt: 2.6 → rundet zu 3

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, 3);
    });

    test('berechnet korrekt knapp unter Rundungsgrenze', () {
      final noten = [
        (note: 2, gewichtung: 3.0), // 6.0
        (note: 3, gewichtung: 2.0), // 6.0
      ];
      // Schnitt: 12.0 / 5.0 = 2.4 → rundet zu 2

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, 2);
    });

    test('berechnet korrekt exakt auf Rundungsgrenze', () {
      final noten = [
        (note: 2, gewichtung: 2.0), // 4.0
        (note: 3, gewichtung: 3.0), // 9.0
      ];
      // Schnitt: 13.0 / 5.0 = 2.6 → rundet zu 3

      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(noten);
      expect(zeugnisnote, 3);
    });
  });

  group('Zeugnisnote.formatSchnitt', () {
    test('formatiert Schnitt mit 2 Nachkommastellen', () {
      expect(Zeugnisnote.formatSchnitt(2.5), '2.50');
      expect(Zeugnisnote.formatSchnitt(3.666666), '3.67');
      expect(Zeugnisnote.formatSchnitt(1.0), '1.00');
      expect(Zeugnisnote.formatSchnitt(4.123), '4.12');
    });
  });

  group('Zeugnisnote.getTendenz', () {
    // Die Tendenz vergleicht den Schnitt mit der gerundeten Note
    // differenz = schnitt - gerundet
    // Beispiel: schnitt 2.1 rundet zu 2 → differenz = 0.1 (positiv, "knapp schlechter")
    // Beispiel: schnitt 2.7 rundet zu 3 → differenz = -0.3 (negativ, "knapp besser")

    test('gibt "genau" für sehr kleine Differenz', () {
      // schnitt = 2.0 → gerundet = 2 → diff = 0.0
      expect(Zeugnisnote.getTendenz(2.0), 'genau');
      // schnitt = 2.05 → gerundet = 2 → diff = 0.05 (< 0.1)
      expect(Zeugnisnote.getTendenz(2.05), 'genau');
      // schnitt = 2.95 → gerundet = 3 → diff = -0.05 (abs < 0.1)
      expect(Zeugnisnote.getTendenz(2.95), 'genau');
    });

    test('gibt "knapp besser" für kleine negative Differenz (-0.4 <= diff < 0)', () {
      // schnitt = 2.7 → gerundet = 3 → diff = -0.3
      expect(Zeugnisnote.getTendenz(2.7), 'knapp besser');
      // schnitt = 3.75 → gerundet = 4 → diff = -0.25
      expect(Zeugnisnote.getTendenz(3.75), 'knapp besser');
      // schnitt = 2.65 → gerundet = 3 → diff = -0.35
      expect(Zeugnisnote.getTendenz(2.65), 'knapp besser');
    });

    test('gibt "knapp schlechter" für kleine positive Differenz (0 <= diff < 0.2)', () {
      // schnitt = 2.1 → gerundet = 2 → diff = 0.1
      expect(Zeugnisnote.getTendenz(2.1), 'knapp schlechter');
      // schnitt = 3.15 → gerundet = 3 → diff = 0.15
      expect(Zeugnisnote.getTendenz(3.15), 'knapp schlechter');
    });

    test('gibt "deutlich schlechter" für große positive Differenz (>= 0.2)', () {
      // schnitt = 2.3 → gerundet = 2 → diff = 0.3
      expect(Zeugnisnote.getTendenz(2.3), 'deutlich schlechter');
      // schnitt = 3.5 → gerundet = 3 → diff = 0.5
      expect(Zeugnisnote.getTendenz(3.5), 'deutlich schlechter');
    });
  });
}
