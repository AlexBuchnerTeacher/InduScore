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

/// Matrix-Ansicht: Schüler (Zeilen) × Note/Tendenz (Spalten) - für einen LN
///
/// Zeigt alle Schüler mit Noten für einen spezifischen Leistungsnachweis.
/// Kompakte vertikale Liste ohne horizontales Scrollen.
class LNMatrixWidget extends ConsumerStatefulWidget {
  final Leistungsnachweis leistungsnachweis;
  final List<Student> students;
  final List<Subject> subjects;
  final List<Grade> grades;
  final Function(String studentId)? onStudentTap;

  const LNMatrixWidget({
    required this.leistungsnachweis,
    required this.students,
    required this.subjects,
    required this.grades,
    super.key,
    this.onStudentTap,
  });

  @override
  ConsumerState<LNMatrixWidget> createState() => _LNMatrixWidgetState();
}

class _LNMatrixWidgetState extends ConsumerState<LNMatrixWidget> {
  final Map<String, String> _optimisticUpdatedBy = {};

  @override
  Widget build(BuildContext context) {
    final subject = widget.subjects
        .where((s) => s.id == widget.leistungsnachweis.subjectId)
        .firstOrNull;
    final fachColor = RBSColors.fromHex(subject?.color) ?? RBSColors.courtGreen;
    final sortedStudents =
        NotenMatrixLogic.sortStudentsByName(widget.students);

    return Column(
      children: [
        // LN Info Header
        _buildLNInfoHeader(subject, fachColor),

        // Metadata
        MatrixCommonWidgets.buildMetadataHeader(
          '${widget.students.length} Schüler',
        ),

        // Student List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedStudents.length + 2, // +2 für Header und Footer
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildTableHeader();
              } else if (index == sortedStudents.length + 1) {
                return _buildFooter(sortedStudents);
              } else {
                final student = sortedStudents[index - 1];
                return _buildStudentRow(student, index - 1);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLNInfoHeader(Subject? subject, Color fachColor) {
    final ln = widget.leistungsnachweis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fachColor.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: fachColor, width: 4),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: fachColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subject?.name ?? "Fach"} - ${ln.typ.label}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: fachColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Datum: ${ln.datum.day}.${ln.datum.month}.${ln.datum.year} | '
                  'Gewichtung: ${ln.gewichtung}x',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                if (ln.beschreibung != null && ln.beschreibung!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ln.beschreibung!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(
            flex: 2,
            child: Text(
              'Schüler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 200,
            alignment: Alignment.center,
            child: const Text(
              'Note',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student, int index) {
    final grade = widget.grades
        .where(
          (g) =>
              g.studentId == student.id &&
              g.leistungsnachweisId == widget.leistungsnachweis.id,
        )
        .firstOrNull;

    final isEven = index % 2 == 0;

    return InkWell(
      onTap: widget.onStudentTap != null
          ? () => widget.onStudentTap!(student.id)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            // Name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    '${student.lastName}, ${student.firstName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (student.befreiungDeutsch || student.befreiungPuG) ...[
                    const SizedBox(width: 8),
                    MatrixCommonWidgets.buildBefreiungBadge(student),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Note
            SizedBox(
              width: 200,
              child: EditableNoteCell(
                key: ValueKey('${student.id}_${widget.leistungsnachweis.id}'),
                studentId: student.id,
                leistungsnachweisId: widget.leistungsnachweis.id,
                note: grade?.note,
                tendenz: grade?.tendenz ?? Tendenz.keine,
                updatedBy: _optimisticUpdatedBy[
                        '${student.id}_${widget.leistungsnachweis.id}'] ??
                    grade?.updatedBy,
                updatedAt: grade?.updatedAt,
                compact: false,
                onNoteChanged: (note) => _handleNoteChange(
                  student.id,
                  widget.leistungsnachweis.id,
                  note,
                ),
                onTendenzChanged: (tendenz) => _handleTendenzChange(
                  student.id,
                  widget.leistungsnachweis.id,
                  tendenz,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(List<Student> students) {
    // Berechne Durchschnitt
    final grades = widget.grades
        .where((g) => g.leistungsnachweisId == widget.leistungsnachweis.id)
        .toList();

    if (grades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RBSColors.paper,
          border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
        ),
        child: const Text(
          'Noch keine Noten erfasst',
          style: TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final sum = grades
        .map((g) => NotenMatrixLogic.getNoteWithTendenz(g.note, g.tendenz))
        .reduce((a, b) => a + b);
    final durchschnitt = sum / grades.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 40),
          const Text(
            '⌀ Durchschnitt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Container(
            width: 200,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MatrixCommonWidgets.getNoteColor(durchschnitt.round())
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MatrixCommonWidgets.getNoteColor(durchschnitt.round()),
                  width: 2,
                ),
              ),
              child: Text(
                '${durchschnitt.toStringAsFixed(2)} (${grades.length}/${students.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: MatrixCommonWidgets.getNoteColor(durchschnitt.round()),
                ),
              ),
            ),
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
