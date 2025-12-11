import '../../models/grade.dart';
import '../../models/leistungsnachweis.dart';
import '../../models/student.dart';

/// Business Logic für NotenMatrixView
/// 
/// Enthält:
/// - Durchschnitts-Berechnungen (Fach, Klasse, Gesamt)
/// - Gruppierung nach Fach/Klasse
/// - Sortierung
/// - Note-zu-Farbe Mapping
/// 
/// Keine UI-Logik, reiner Dart Code
class NotenMatrixLogic {
  /// Berechnet gewichteten Durchschnitt für ein Fach eines Schülers
  static double? calculateFachDurchschnitt({
    required String studentId,
    required String subjectId,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final fachLNs = leistungsnachweise
        .where((ln) => ln.subjectId == subjectId)
        .toList();

    if (fachLNs.isEmpty) return null;

    double summe = 0;
    double gewichtSumme = 0;

    for (final ln in fachLNs) {
      final grade = grades
          .where(
            (g) => g.studentId == studentId && g.leistungsnachweisId == ln.id,
          )
          .firstOrNull;

      if (grade != null) {
        final noteWithTendenz = getNoteWithTendenz(grade.note, grade.tendenz);
        summe += noteWithTendenz * ln.gewichtung.toDouble();
        gewichtSumme += ln.gewichtung;
      }
    }

    return gewichtSumme > 0 ? summe / gewichtSumme : null;
  }

  /// Berechnet Gesamt-Durchschnitt über alle Fächer eines Schülers
  static double? calculateGesamtDurchschnitt({
    required String studentId,
    required List<String> subjectIds,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final fachSchnitte = <double>[];

    for (final subjectId in subjectIds) {
      final schnitt = calculateFachDurchschnitt(
        studentId: studentId,
        subjectId: subjectId,
        leistungsnachweise: leistungsnachweise,
        grades: grades,
      );
      if (schnitt != null) fachSchnitte.add(schnitt);
    }

    if (fachSchnitte.isEmpty) return null;

    return fachSchnitte.reduce((a, b) => a + b) / fachSchnitte.length;
  }

  /// Berechnet Klassen-Durchschnitt für ein Fach
  static double? calculateKlassenDurchschnittFach({
    required String subjectId,
    required List<Student> students,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final schnitte = students
        .map(
          (s) => calculateFachDurchschnitt(
            studentId: s.id,
            subjectId: subjectId,
            leistungsnachweise: leistungsnachweise,
            grades: grades,
          ),
        )
        .where((s) => s != null)
        .cast<double>()
        .toList();

    if (schnitte.isEmpty) return null;

    return schnitte.reduce((a, b) => a + b) / schnitte.length;
  }

  /// Berechnet Gesamt-Klassen-Durchschnitt
  static double? calculateKlassenDurchschnittGesamt({
    required List<Student> students,
    required List<String> subjectIds,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final schnitte = students
        .map(
          (s) => calculateGesamtDurchschnitt(
            studentId: s.id,
            subjectIds: subjectIds,
            leistungsnachweise: leistungsnachweise,
            grades: grades,
          ),
        )
        .where((s) => s != null)
        .cast<double>()
        .toList();

    if (schnitte.isEmpty) return null;

    return schnitte.reduce((a, b) => a + b) / schnitte.length;
  }

  /// Gruppiert Leistungsnachweise nach Fach
  static Map<String, List<Leistungsnachweis>> groupLNsBySubject(
    List<Leistungsnachweis> leistungsnachweise,
  ) {
    final grouped = <String, List<Leistungsnachweis>>{};
    for (final ln in leistungsnachweise) {
      grouped.putIfAbsent(ln.subjectId, () => []).add(ln);
    }
    return grouped;
  }

  /// Gruppiert Leistungsnachweise nach Klasse
  static Map<String, List<Leistungsnachweis>> groupLNsByKlasse(
    List<Leistungsnachweis> leistungsnachweise,
  ) {
    final grouped = <String, List<Leistungsnachweis>>{};
    for (final ln in leistungsnachweise) {
      grouped.putIfAbsent(ln.klasseId, () => []).add(ln);
    }
    return grouped;
  }

  /// Sortiert Leistungsnachweise nach Datum (neueste zuerst)
  static List<Leistungsnachweis> sortLNsByDate(
    List<Leistungsnachweis> leistungsnachweise,
  ) {
    final sorted = List<Leistungsnachweis>.from(leistungsnachweise);
    sorted.sort((a, b) => b.datum.compareTo(a.datum));
    return sorted;
  }

  /// Sortiert Schüler nach Nachname, Vorname
  static List<Student> sortStudentsByName(List<Student> students) {
    final sorted = List<Student>.from(students);
    sorted.sort((a, b) {
      final lastNameCmp = a.lastName.compareTo(b.lastName);
      if (lastNameCmp != 0) return lastNameCmp;
      return a.firstName.compareTo(b.firstName);
    });
    return sorted;
  }

  /// Konvertiert Note mit Tendenz zu double-Wert
  static double getNoteWithTendenz(int note, Tendenz tendenz) {
    switch (tendenz) {
      case Tendenz.plus:
        return note - 0.3; // 2+ = 1.7
      case Tendenz.minus:
        return note + 0.3; // 2- = 2.3
      case Tendenz.keine:
        return note.toDouble();
    }
  }

  /// Extrahiert Benutzer-Kürzel aus Email
  /// Unterstützt Formate:
  /// - vorname.nachname@domain -> VN
  /// - bu@domain -> BU
  /// - v.n@domain -> VN
  static String? getUserKuerzel(String? email) {
    if (email == null || !email.contains('@')) return null;
    
    final localPart = email.split('@')[0];
    final parts = localPart.split('.');
    
    if (parts.length >= 2) {
      // Format: vorname.nachname@domain
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (localPart.length >= 2) {
      // Format: bu@domain -> BU (erste 2 Buchstaben)
      return localPart.substring(0, 2).toUpperCase();
    }
    
    return null;
  }
}
