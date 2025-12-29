import 'package:firebase_auth/firebase_auth.dart';
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
import 'editable_note_cell.dart';
import 'matrix_common_widgets.dart';

/// Matrix-Ansicht: LNs pro Fach (Zeilen) × Note (Spalte) - für einen Schüler
///
/// Zeigt alle Leistungsnachweise gruppiert nach Fächern für einen einzelnen
/// Schüler. Horizontales Scrollen für viele Leistungsnachweise.
class SchuelerMatrixWidget extends ConsumerStatefulWidget {
  final Student student;
  final List<Leistungsnachweis> leistungsnachweise;
  final List<Subject> subjects;
  final List<Grade> grades;

  const SchuelerMatrixWidget({
    required this.student,
    required this.leistungsnachweise,
    required this.subjects,
    required this.grades,
    super.key,
  });

  @override
  ConsumerState<SchuelerMatrixWidget> createState() =>
      _SchuelerMatrixWidgetState();
}

class _SchuelerMatrixWidgetState extends ConsumerState<SchuelerMatrixWidget> {
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
    const lnColWidth = 170.0;

    return Column(
      children: [
        // Metadata Header
        MatrixCommonWidgets.buildMetadataHeader(
          '${widget.leistungsnachweise.length} Leistungsnachweise',
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
                    // Fach-Rows mit LNs
                    ...sortedSubjectIds.map((subjectId) {
                      final subject = widget.subjects.firstWhere(
                        (s) => s.id == subjectId,
                      );
                      final lns = lnBySubject[subjectId] ?? [];
                      final sortedLNs = NotenMatrixLogic.sortLNsByDate(lns);

                      return _buildSchuelerFachRow(
                        subject: subject,
                        lns: sortedLNs,
                        leftColWidth: leftColWidth,
                        lnColWidth: lnColWidth,
                      );
                    }),

                    // Footer: Gesamt-Durchschnitt
                    _buildSchuelerFooter(
                      leftColWidth: leftColWidth,
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

  Widget _buildSchuelerFachRow({
    required Subject subject,
    required List<Leistungsnachweis> lns,
    required double leftColWidth,
    required double lnColWidth,
  }) {
    final fachColor = RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen;
    final fachSchnitt = NotenMatrixLogic.calculateFachDurchschnitt(
      studentId: widget.student.id,
      subjectId: subject.id,
      leistungsnachweise: widget.leistungsnachweise,
      grades: widget.grades,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Fach-Name
          Container(
            width: leftColWidth,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: fachColor.withValues(alpha: 0.05)),
            child: Text(
              subject.name,
              style: TextStyle(fontWeight: FontWeight.bold, color: fachColor),
            ),
          ),

          // LN-Zellen
          ...lns.map((ln) {
            final grade = widget.grades
                .where(
                  (g) =>
                      g.studentId == widget.student.id &&
                      g.leistungsnachweisId == ln.id,
                )
                .firstOrNull;

            return Container(
              width: lnColWidth,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    ln.typ.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${ln.datum.day}.${ln.datum.month}.${ln.datum.year}',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  EditableNoteCell(
                    key: ValueKey('${widget.student.id}_${ln.id}'),
                    studentId: widget.student.id,
                    leistungsnachweisId: ln.id,
                    note: grade?.note,
                    tendenz: grade?.tendenz ?? Tendenz.keine,
                    updatedBy: _optimisticUpdatedBy[
                            '${widget.student.id}_${ln.id}'] ??
                        grade?.updatedBy,
                    updatedAt: grade?.updatedAt,
                    compact: false,
                    onNoteChanged: (note) =>
                        _handleNoteChange(widget.student.id, ln.id, note),
                    onTendenzChanged: (tendenz) =>
                        _handleTendenzChange(widget.student.id, ln.id, tendenz),
                  ),
                ],
              ),
            );
          }),

          // Fach-Durchschnitt
          MatrixCommonWidgets.buildDurchschnittCell(fachSchnitt, 80),
        ],
      ),
    );
  }

  Widget _buildSchuelerFooter({
    required double leftColWidth,
    required List<String> sortedSubjectIds,
  }) {
    final gesamtSchnitt = NotenMatrixLogic.calculateGesamtDurchschnitt(
      studentId: widget.student.id,
      subjectIds: sortedSubjectIds,
      leistungsnachweise: widget.leistungsnachweise,
      grades: widget.grades,
    );

    return Container(
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: leftColWidth,
            padding: const EdgeInsets.all(12),
            child: const Text(
              '⌀ Gesamt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: gesamtSchnitt != null
                ? Text(
                    gesamtSchnitt.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: MatrixCommonWidgets.getNoteColor(
                        gesamtSchnitt.round(),
                      ),
                    ),
                  )
                : Text('-', style: TextStyle(color: Colors.grey[400])),
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
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final userKuerzel = NotenMatrixLogic.getUserKuerzel(userEmail);

    final existingGrade = widget.grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (note != null) {
      // Optimistic update
      if (userKuerzel != null) {
        setState(() {
          _optimisticUpdatedBy['${studentId}_$lnId'] = userKuerzel;
        });
      }

      final grade = Grade(
        id: existingGrade?.id ?? '',
        studentId: studentId,
        leistungsnachweisId: lnId,
        note: note,
        tendenz: existingGrade?.tendenz ?? Tendenz.keine,
        kommentar: existingGrade?.kommentar,
        updatedBy: userKuerzel,
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
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final userKuerzel = NotenMatrixLogic.getUserKuerzel(userEmail);

    // Optimistic update
    if (userKuerzel != null) {
      setState(() {
        _optimisticUpdatedBy['${studentId}_$lnId'] = userKuerzel;
      });
    }

    final updatedGrade = existingGrade.copyWith(
      tendenz: tendenz,
      updatedBy: userKuerzel,
      updatedAt: DateTime.now(),
    );

    await firestoreService.updateGrade(updatedGrade);
  }
}
