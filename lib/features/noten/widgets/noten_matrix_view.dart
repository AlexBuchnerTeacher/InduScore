import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/grade.dart';
import '../../../models/klasse.dart';
import '../../../models/leistungsnachweis.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import 'klassen_matrix_widget.dart';
import 'schueler_matrix_widget.dart';
import 'ln_matrix_widget.dart';

/// Modus der Matrix-Ansicht
enum MatrixViewMode {
  /// Schüler (Zeilen) × LNs gruppiert nach Fach (Spalten)
  byKlasse,

  /// LNs gruppiert nach Fach (Zeilen) × Note/Datum (Spalten) - nur 1 Schüler
  bySchueler,

  /// Schüler (Zeilen) × Note/Tendenz (Spalten) - nur 1 LN
  byLN,
}

/// Universelle Matrix-Ansicht für Noten (Router Widget)
///
/// Weicht je nach Modus an spezialisierte Widgets weiter:
/// - byKlasse → KlassenMatrixWidget
/// - bySchueler → SchuelerMatrixWidget
/// - byLN → LNMatrixWidget
///
/// Refactored from 1056 LOC → <100 LOC (F-002, Issue #54)
class NotenMatrixView extends ConsumerWidget {
  final MatrixViewMode mode;
  final String? klasseId;
  final String? schuelerId;
  final String? leistungsnachweisId;
  final List<Student> students;
  final List<Leistungsnachweis> leistungsnachweise;
  final List<Subject> subjects;
  final List<Grade> grades;
  final List<Klasse> klassen;
  final Function(String studentId)? onStudentTap;
  final Function(String leistungsnachweisId)? onLNTap;
  final Function(String subjectId)? onSubjectTap;
  final Function(String klasseId)? onKlasseTap;

  const NotenMatrixView({
    required this.mode,
    required this.students,
    required this.leistungsnachweise,
    required this.subjects,
    required this.grades,
    required this.klassen,
    super.key,
    this.klasseId,
    this.schuelerId,
    this.leistungsnachweisId,
    this.onStudentTap,
    this.onLNTap,
    this.onSubjectTap,
    this.onKlasseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (mode) {
      case MatrixViewMode.byKlasse:
        return KlassenMatrixWidget(
          students: students,
          leistungsnachweise: leistungsnachweise,
          subjects: subjects,
          grades: grades,
          onStudentTap: onStudentTap,
          onSubjectTap: onSubjectTap,
        );

      case MatrixViewMode.bySchueler:
        if (students.isEmpty || schuelerId == null) {
          return const Center(child: Text('Kein Schüler ausgewählt'));
        }
        return SchuelerMatrixWidget(
          student: students.first,
          leistungsnachweise: leistungsnachweise,
          subjects: subjects,
          grades: grades,
        );

      case MatrixViewMode.byLN:
        if (leistungsnachweise.isEmpty || leistungsnachweisId == null) {
          return const Center(child: Text('Kein Leistungsnachweis ausgewählt'));
        }
        return LNMatrixWidget(
          leistungsnachweis: leistungsnachweise.first,
          students: students,
          subjects: subjects,
          grades: grades,
          onStudentTap: onStudentTap,
        );
    }
  }
}
