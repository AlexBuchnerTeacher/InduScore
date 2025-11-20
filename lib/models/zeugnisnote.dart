import 'leistungsnachweis.dart';

/// Zeugnisnote - Berechnung der Endnote aus gewichteten Leistungsnachweisen
class Zeugnisnote {
  /// Berechnet gewichteten Durchschnitt aus Leistungsnachweisen
  /// Gibt null zurück wenn keine Noten vorhanden
  static double? berechneSchnitt(
    Map<LeistungsnachweisTyp, List<double>> notenByTyp,
  ) {
    if (notenByTyp.isEmpty) return null;

    double summeGewichtet = 0;
    double summeGewichtung = 0;

    notenByTyp.forEach((typ, noten) {
      if (noten.isNotEmpty) {
        final durchschnitt = noten.reduce((a, b) => a + b) / noten.length;
        summeGewichtet += durchschnitt * typ.gewichtung;
        summeGewichtung += typ.gewichtung;
      }
    });

    if (summeGewichtung == 0) return null;
    return summeGewichtet / summeGewichtung;
  }

  /// Rundet Notendurchschnitt nach Berufsschul-Regel:
  /// < 0.6 → abrunden (2.5 → 2)
  /// ≥ 0.6 → aufrunden (2.6 → 3)
  static int rundeNote(double schnitt) {
    final ganzzahl = schnitt.floor();
    final nachkomma = schnitt - ganzzahl;

    if (nachkomma < 0.6) {
      return ganzzahl;
    } else {
      return ganzzahl + 1;
    }
  }

  /// Berechnet Zeugnisnote (gerundet) aus Leistungsnachweisen
  static int? berechneZeugnisnote(
    Map<LeistungsnachweisTyp, List<double>> notenByTyp,
  ) {
    final schnitt = berechneSchnitt(notenByTyp);
    if (schnitt == null) return null;
    return rundeNote(schnitt);
  }

  /// Formatiert Notenschnitt für Anzeige (z.B. "2.45")
  static String formatSchnitt(double schnitt) {
    return schnitt.toStringAsFixed(2);
  }

  /// Gibt Tendenz-Text zurück (z.B. "knapp besser")
  static String getTendenz(double schnitt) {
    final gerundet = rundeNote(schnitt);
    final differenz = schnitt - gerundet;

    if (differenz.abs() < 0.1) {
      return 'genau';
    } else if (differenz < -0.4) {
      return 'deutlich besser';
    } else if (differenz < 0) {
      return 'knapp besser';
    } else if (differenz < 0.2) {
      return 'knapp schlechter';
    } else {
      return 'deutlich schlechter';
    }
  }
}
