import 'leistungsnachweis.dart';
import 'grade.dart';

/// Zeugnisnote - Berechnung der Endnote aus gewichteten Leistungsnachweisen
class Zeugnisnote {
  /// Berechnet gewichteten Durchschnitt aus Noten mit ihren Gewichtungen
  /// Gibt null zurück wenn keine Noten vorhanden
  static double? berechneSchnitt(
    List<({int note, double gewichtung})> notenMitGewichtung,
  ) {
    if (notenMitGewichtung.isEmpty) return null;

    double summeGewichtet = 0;
    double summeGewichtung = 0;

    for (final eintrag in notenMitGewichtung) {
      summeGewichtet += eintrag.note * eintrag.gewichtung;
      summeGewichtung += eintrag.gewichtung;
    }

    if (summeGewichtung == 0) return null;
    return summeGewichtet / summeGewichtung;
  }
  
  /// Berechnet Schnitt aus Grades und ihren zugehörigen Leistungsnachweisen
  static double? berechneSchnittAusGrades(
    List<Grade> grades,
    Map<String, Leistungsnachweis> leistungsnachweiseById,
  ) {
    final notenMitGewichtung = <({int note, double gewichtung})>[];
    
    for (final grade in grades) {
      final ln = leistungsnachweiseById[grade.leistungsnachweisId];
      if (ln != null) {
        notenMitGewichtung.add((note: grade.note, gewichtung: ln.gewichtung));
      }
    }
    
    return berechneSchnitt(notenMitGewichtung);
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

  /// Berechnet Zeugnisnote (gerundet) aus Noten mit Gewichtungen
  static int? berechneZeugnisnote(
    List<({int note, double gewichtung})> notenMitGewichtung,
  ) {
    final schnitt = berechneSchnitt(notenMitGewichtung);
    if (schnitt == null) return null;
    return rundeNote(schnitt);
  }
  
  /// Berechnet Zeugnisnote aus Grades und Leistungsnachweisen
  static int? berechneZeugnisnoteAusGrades(
    List<Grade> grades,
    Map<String, Leistungsnachweis> leistungsnachweiseById,
  ) {
    final schnitt = berechneSchnittAusGrades(grades, leistungsnachweiseById);
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
