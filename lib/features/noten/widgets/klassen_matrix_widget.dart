import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/grade.dart';
import '../../../models/leistungsnachweis.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../models/tendenz.dart';
import '../../../providers/app_providers.dart';
import '../noten_matrix_logic.dart';
import 'matrix_common_widgets.dart';

/// Matrix-Ansicht: Schüler (Zeilen) × Fächer/LNs (Spalten)
///
/// Zeigt alle Schüler einer Klasse mit Noten für alle Leistungsnachweise
/// gruppiert nach Fächern. Horizontales Scrollen für Fächer.
class KlassenMatrixWidget extends ConsumerStatefulWidget {
  final List<Student> students;
  final List<Leistungsnachweis> leistungsnachweise;
  final List<Subject> subjects;
  final List<Grade> grades;
  final Function(String studentId)? onStudentTap;
  final Function(String subjectId)? onSubjectTap;

  const KlassenMatrixWidget({
    required this.students,
    required this.leistungsnachweise,
    required this.subjects,
    required this.grades,
    super.key,
    this.onStudentTap,
    this.onSubjectTap,
  });

  @override
  ConsumerState<KlassenMatrixWidget> createState() =>
      _KlassenMatrixWidgetState();
}

class _KlassenMatrixWidgetState extends ConsumerState<KlassenMatrixWidget> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final Map<String, String> _optimisticUpdatedBy = {};

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedStudents =
        NotenMatrixLogic.sortStudentsByName(widget.students);
    final lnBySubject = NotenMatrixLogic.groupLNsBySubject(
      widget.leistungsnachweise,
    );
    final sortedSubjectIds = lnBySubject.keys.toList()
      ..sort((a, b) {
        final subjectA = widget.subjects.firstWhere((s) => s.id == a);
        final subjectB = widget.subjects.firstWhere((s) => s.id == b);
        return subjectA.name.compareTo(subjectB.name);
      });

    const leftColWidth = 170.0;
    const fachColWidth = 170.0;

    return Column(
      children: [
        // Metadata Header
        MatrixCommonWidgets.buildMetadataHeader(
          '${widget.students.length} Schüler | ${widget.subjects.length} Fächer',
        ),

        // Scrollable Table
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    _buildHeaderRow(
                      leftColWidth: leftColWidth,
                      fachColWidth: fachColWidth,
                      sortedSubjectIds: sortedSubjectIds,
                      lnBySubject: lnBySubject,
                    ),

                    // Student Rows
                    ...sortedStudents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final student = entry.value;
                      return _buildStudentRow(
                        student: student,
                        index: index,
                        leftColWidth: leftColWidth,
                        fachColWidth: fachColWidth,
                        sortedSubjectIds: sortedSubjectIds,
                        lnBySubject: lnBySubject,
                      );
                    }),

                    // Footer: Klassen-Durchschnitte
                    _buildKlassenDurchschnittFooter(
                      leftColWidth: leftColWidth,
                      fachColWidth: fachColWidth,
                      sortedSubjectIds: sortedSubjectIds,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow({
    required double leftColWidth,
    required double fachColWidth,
    required List<String> sortedSubjectIds,
    required Map<String, List<Leistungsnachweis>> lnBySubject,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Schüler-Header
          Container(
            width: leftColWidth,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Schüler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Fach-Headers
          ...sortedSubjectIds.map((subjectId) {
            final subject = widget.subjects.firstWhere(
              (s) => s.id == subjectId,
            );
            final lns = lnBySubject[subjectId] ?? [];
            final fachColor =
                RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen;

            return InkWell(
              onTap: widget.onSubjectTap != null
                  ? () => widget.onSubjectTap!(subjectId)
                  : null,
              child: Container(
                width: fachColWidth * lns.length,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fachColor.withValues(alpha: 0.1),
                  border: Border(
                    left: BorderSide(color: fachColor, width: 2),
                    right: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      subject.shortName ?? subject.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: fachColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: lns.map((ln) {
                        return Container(
                          width: fachColWidth - 8,
                          alignment: Alignment.center,
                          child: Text(
                            '${ln.typ.label} ${ln.datum.day}.${ln.datum.month}',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Gesamt-Header
          Container(
            width: 70,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RBSColors.paper,
              border: Border(
                left: BorderSide(color: Colors.grey[400]!, width: 2),
              ),
            ),
            child: const Text(
              '⌀',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow({
    required Student student,
    required int index,
    required double leftColWidth,
    required double fachColWidth,
    required List<String> sortedSubjectIds,
    required Map<String, List<Leistungsnachweis>> lnBySubject,
  }) {
    final isEven = index % 2 == 0;

    // Berechne Gesamt-Durchschnitt
    final gesamtSchnitt = NotenMatrixLogic.calculateGesamtDurchschnitt(
      studentId: student.id,
      subjectIds: sortedSubjectIds,
      leistungsnachweise: widget.leistungsnachweise,
      grades: widget.grades,
    );

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Schüler-Name
          MatrixCommonWidgets.buildStudentNameCell(
            student: student,
            index: index,
            width: leftColWidth,
            onStudentTap: widget.onStudentTap,
          ),

          // Noten-Zellen pro Fach
          ...sortedSubjectIds.map((subjectId) {
            final lns = lnBySubject[subjectId] ?? [];
            return Row(
              children: lns.map((ln) {
                final grade = widget.grades
                    .where(
                      (g) =>
                          g.studentId == student.id &&
                          g.leistungsnachweisId == ln.id,
                    )
                    .firstOrNull;

                return MatrixCommonWidgets.buildNoteCell(
                  studentId: student.id,
                  leistungsnachweisId: ln.id,
                  note: grade?.note,
                  tendenz: grade?.tendenz ?? Tendenz.keine,
                  width: fachColWidth,
                  onNoteChanged: (note) =>
                      _handleNoteChange(student.id, ln.id, note),
                  onTendenzChanged: (tendenz) =>
                      _handleTendenzChange(student.id, ln.id, tendenz),
                  updatedBy: _optimisticUpdatedBy['${student.id}_${ln.id}'] ??
                      grade?.updatedBy,
                  updatedAt: grade?.updatedAt,
                );
              }).toList(),
            );
          }),

          // Gesamt-Durchschnitt
          MatrixCommonWidgets.buildDurchschnittCell(
            gesamtSchnitt,
            70,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKlassenDurchschnittFooter({
    required double leftColWidth,
    required double fachColWidth,
    required List<String> sortedSubjectIds,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: leftColWidth,
            padding: const EdgeInsets.all(12),
            child: const Text(
              '⌀ Klasse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ...sortedSubjectIds.map((subjectId) {
            final lns = NotenMatrixLogic.groupLNsBySubject(
              widget.leistungsnachweise,
            )[subjectId] ??
                [];
            final schnitt = NotenMatrixLogic.calculateKlassenDurchschnittFach(
              subjectId: subjectId,
              students: widget.students,
              leistungsnachweise: widget.leistungsnachweise,
              grades: widget.grades,
            );

            return Container(
              width: fachColWidth * lns.length,
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: schnitt != null
                  ? Text(
                      schnitt.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MatrixCommonWidgets.getNoteColor(
                          schnitt.round(),
                        ),
                      ),
                    )
                  : Text('-', style: TextStyle(color: Colors.grey[400])),
            );
          }),
          MatrixCommonWidgets.buildDurchschnittCell(
            NotenMatrixLogic.calculateKlassenDurchschnittGesamt(
              students: widget.students,
              subjectIds: sortedSubjectIds,
              leistungsnachweise: widget.leistungsnachweise,
              grades: widget.grades,
            ),
            70,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Future<void> _handleNoteChange(
    String studentId,
    String lnId,
    int? note,
  ) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    // v0.33.0: Kürzel aus AppUser (NUR vom Admin gesetzt)
    final userKuerzel = await ref.read(currentUserKuerzelProvider.future);
    final effectiveKuerzel = userKuerzel.isNotEmpty && userKuerzel != '—' ? userKuerzel : null;

    final existingGrade = widget.grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (note != null) {
      // Optimistic update
      if (effectiveKuerzel != null) {
        setState(() {
          _optimisticUpdatedBy['${studentId}_$lnId'] = effectiveKuerzel;
        });
      }

      final grade = Grade(
        id: existingGrade?.id ?? '',
        studentId: studentId,
        leistungsnachweisId: lnId,
        note: note,
        tendenz: existingGrade?.tendenz ?? Tendenz.keine,
        kommentar: existingGrade?.kommentar,
        updatedBy: effectiveKuerzel,
        createdAt: existingGrade?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingGrade != null) {
        await firestoreService.updateGrade(grade);
      } else {
        await firestoreService.createGrade(grade);
      }
    } else if (existingGrade != null) {
      await firestoreService.deleteGrade(existingGrade.id);
      setState(() {
        _optimisticUpdatedBy.remove('${studentId}_$lnId');
      });
    }
  }

  Future<void> _handleTendenzChange(
    String studentId,
    String lnId,
    Tendenz tendenz,
  ) async {
    final existingGrade = widget.grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (existingGrade == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    // v0.33.0: Kürzel aus AppUser (NUR vom Admin gesetzt)
    final userKuerzel = await ref.read(currentUserKuerzelProvider.future);
    final effectiveKuerzel = userKuerzel.isNotEmpty && userKuerzel != '—' ? userKuerzel : null;

    // Optimistic update
    if (effectiveKuerzel != null) {
      setState(() {
        _optimisticUpdatedBy['${studentId}_$lnId'] = effectiveKuerzel;
      });
    }

    final updatedGrade = existingGrade.copyWith(
      tendenz: tendenz,
      updatedBy: effectiveKuerzel,
      updatedAt: DateTime.now(),
    );

    await firestoreService.updateGrade(updatedGrade);
  }
}
