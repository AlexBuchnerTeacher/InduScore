import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/grade.dart';
import '../../../models/klasse.dart';
import '../../../models/leistungsnachweis.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/app_providers.dart';
import '../noten_matrix_logic.dart';
import 'editable_note_cell.dart';

/// Modus der Matrix-Ansicht
enum MatrixViewMode {
  /// Schüler (Zeilen) × LNs gruppiert nach Fach (Spalten)
  byKlasse,

  /// LNs gruppiert nach Fach (Zeilen) × Note/Datum (Spalten) - nur 1 Schüler
  bySchueler,

  /// Schüler (Zeilen) × Note/Tendenz (Spalten) - nur 1 LN
  byLN,
}

/// Universelle Matrix-Ansicht für Noten
/// 
/// Zentrale Komponente für alle Noten-Ansichten.
/// Unterstützt 3 verschiedene Modi mit unterschiedlichen Layouts.
/// 
/// Features:
/// - Horizontal scrollbare Fächer (byKlasse, bySchueler)
/// - Sticky left column für Schüler/Info
/// - Inline-Editing mit EditableNoteCell
/// - Fach-Durchschnitte, Klassen-Durchschnitte
/// - Cross-Linking (Namen klickbar)
/// - Metadata-Anzeige (updatedBy bei jeder Note)
/// 
/// UI Guidelines: <300 Zeilen (reine Darstellung)
class NotenMatrixView extends ConsumerStatefulWidget {
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
    super.key,
    required this.mode,
    this.klasseId,
    this.schuelerId,
    this.leistungsnachweisId,
    required this.students,
    required this.leistungsnachweise,
    required this.subjects,
    required this.grades,
    required this.klassen,
    this.onStudentTap,
    this.onLNTap,
    this.onSubjectTap,
    this.onKlasseTap,
  });

  @override
  ConsumerState<NotenMatrixView> createState() => _NotenMatrixViewState();
}

class _NotenMatrixViewState extends ConsumerState<NotenMatrixView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  
  // Optimistic updates für updatedBy - zeigt Kürzel sofort an
  final Map<String, String> _optimisticUpdatedBy = {};

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case MatrixViewMode.byKlasse:
        return _buildByKlasseView();
      case MatrixViewMode.bySchueler:
        return _buildBySchuelerView();
      case MatrixViewMode.byLN:
        return _buildByLNView();
    }
  }

  /// Matrix: Schüler (Zeilen) × Fächer/LNs (Spalten)
  Widget _buildByKlasseView() {
    final sortedStudents = NotenMatrixLogic.sortStudentsByName(widget.students);
    final lnBySubject = NotenMatrixLogic.groupLNsBySubject(widget.leistungsnachweise);
    final sortedSubjectIds = lnBySubject.keys.toList()
      ..sort((a, b) {
        final subjectA = widget.subjects.firstWhere((s) => s.id == a);
        final subjectB = widget.subjects.firstWhere((s) => s.id == b);
        return subjectA.name.compareTo(subjectB.name);
      });

    const leftColWidth = 170.0;
    final fachColWidth = 120.0; // 120 - 8 (padding) = 112px für EditableNoteCell (>101px benötigt)

    return Column(
      children: [
        // Metadata Header
        _buildMetadataHeader(),

        // Scrollable Table
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
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
            final subject = widget.subjects.firstWhere((s) => s.id == subjectId);
            final lns = lnBySubject[subjectId] ?? [];
            final fachColor = RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen;

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
              border: Border(left: BorderSide(color: Colors.grey[400]!, width: 2)),
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

    // Berechne Durchschnitte
    final fachSchnitte = <String, double?>{};
    for (final subjectId in sortedSubjectIds) {
      fachSchnitte[subjectId] = NotenMatrixLogic.calculateFachDurchschnitt(
        studentId: student.id,
        subjectId: subjectId,
        leistungsnachweise: widget.leistungsnachweise,
        grades: widget.grades,
      );
    }

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
          // Schüler-Name (Sticky)
          _buildStudentNameCell(student, index, leftColWidth),

          // Noten-Zellen pro Fach
          ...sortedSubjectIds.map((subjectId) {
            final lns = lnBySubject[subjectId] ?? [];
            return Row(
              children: lns.map((ln) {
                return _buildNoteCell(
                  student: student,
                  ln: ln,
                  width: fachColWidth,
                );
              }).toList(),
            );
          }),

          // Gesamt-Durchschnitt
          _buildDurchschnittCell(gesamtSchnitt, 70, isBold: true),
        ],
      ),
    );
  }

  Widget _buildStudentNameCell(Student student, int index, double width) {
    return InkWell(
      onTap: widget.onStudentTap != null ? () => widget.onStudentTap!(student.id) : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Text(
              '${index + 1}.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${student.lastName}, ${student.firstName}',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (student.befreiungDeutsch || student.befreiungPuG)
              _buildBefreiungBadge(student),
          ],
        ),
      ),
    );
  }

  Widget _buildBefreiungBadge(Student student) {
    final kuerzel = <String>[];
    if (student.befreiungDeutsch) kuerzel.add('D');
    if (student.befreiungPuG) kuerzel.add('PuG');
    
    return Tooltip(
      message: [
        if (student.befreiungDeutsch) 'Befreiung Deutsch',
        if (student.befreiungPuG) 'Befreiung PuG',
      ].join(', '),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          kuerzel.join(', '),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCell({
    required Student student,
    required Leistungsnachweis ln,
    required double width,
  }) {
    // Suche Grade - entweder aus widget.grades oder aus lokalem State
    final grade = widget.grades
        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
        .firstOrNull;

    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: EditableNoteCell(
        key: ValueKey('${student.id}_${ln.id}'),
        studentId: student.id,
        leistungsnachweisId: ln.id,
        note: grade?.note,
        tendenz: grade?.tendenz ?? Tendenz.keine,
        updatedBy: _optimisticUpdatedBy['${student.id}_${ln.id}'] ?? grade?.updatedBy,
        updatedAt: grade?.updatedAt,
        compact: true,
        onNoteChanged: (note) => _handleNoteChange(student.id, ln.id, note),
        onTendenzChanged: (tendenz) => _handleTendenzChange(student.id, ln.id, tendenz),
      ),
    );
  }

  Widget _buildDurchschnittCell(double? schnitt, double width, {bool isBold = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: schnitt != null
          ? Text(
              schnitt.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: _getNoteColor(schnitt.round()),
              ),
            )
          : Text('-', style: TextStyle(color: Colors.grey[400])),
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
            final lns = NotenMatrixLogic.groupLNsBySubject(widget.leistungsnachweise)[subjectId] ?? [];
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
                        color: _getNoteColor(schnitt.round()),
                      ),
                    )
                  : Text('-', style: TextStyle(color: Colors.grey[400])),
            );
          }),
          _buildDurchschnittCell(
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

  /// Matrix: LNs pro Fach (Zeilen) × Note (Spalte) - für einen Schüler
  Widget _buildBySchuelerView() {
    if (widget.students.isEmpty || widget.schuelerId == null) {
      return const Center(child: Text('Kein Schüler ausgewählt'));
    }

    final student = widget.students.first;
    final lnBySubject = NotenMatrixLogic.groupLNsBySubject(widget.leistungsnachweise);
    final sortedSubjectIds = lnBySubject.keys.toList()
      ..sort((a, b) {
        final subjectA = widget.subjects.firstWhere((s) => s.id == a);
        final subjectB = widget.subjects.firstWhere((s) => s.id == b);
        return subjectA.name.compareTo(subjectB.name);
      });

    const leftColWidth = 170.0;
    final lnColWidth = 120.0; // Match byKlasse for consistency

    return Column(
      children: [
        // Metadata Header
        _buildMetadataHeader(),

        // Scrollable Table
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  _buildSchuelerHeaderRow(
                    leftColWidth: leftColWidth,
                    lnColWidth: lnColWidth,
                    sortedSubjectIds: sortedSubjectIds,
                    lnBySubject: lnBySubject,
                  ),

                  // Fach-Rows mit LNs
                  ...sortedSubjectIds.map((subjectId) {
                    final subject = widget.subjects.firstWhere((s) => s.id == subjectId);
                    final lns = lnBySubject[subjectId] ?? [];
                    final sortedLNs = NotenMatrixLogic.sortLNsByDate(lns);

                    return _buildSchuelerFachRow(
                      subject: subject,
                      lns: sortedLNs,
                      student: student,
                      leftColWidth: leftColWidth,
                      lnColWidth: lnColWidth,
                    );
                  }),

                  // Footer: Gesamt-Durchschnitt
                  _buildSchuelerFooter(
                    leftColWidth: leftColWidth,
                    lnColWidth: lnColWidth,
                    sortedSubjectIds: sortedSubjectIds,
                    student: student,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchuelerHeaderRow({
    required double leftColWidth,
    required double lnColWidth,
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
          Container(
            width: leftColWidth,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Fach / Leistungsnachweis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...sortedSubjectIds.map((subjectId) {
            final subject = widget.subjects.firstWhere((s) => s.id == subjectId);
            final lns = lnBySubject[subjectId] ?? [];
            final fachColor = RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen;

            return Container(
              width: lnColWidth * lns.length,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fachColor.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(color: fachColor, width: 2),
                  right: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Text(
                subject.shortName ?? subject.name,
                style: TextStyle(fontWeight: FontWeight.bold, color: fachColor),
                textAlign: TextAlign.center,
              ),
            );
          }),
          Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            child: const Text(
              '⌀ Fach',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchuelerFachRow({
    required Subject subject,
    required List<Leistungsnachweis> lns,
    required Student student,
    required double leftColWidth,
    required double lnColWidth,
  }) {
    final fachColor = RBSColors.fromHex(subject.color) ?? RBSColors.courtGreen;
    final fachSchnitt = NotenMatrixLogic.calculateFachDurchschnitt(
      studentId: student.id,
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
            decoration: BoxDecoration(
              color: fachColor.withValues(alpha: 0.05),
            ),
            child: Text(
              subject.name,
              style: TextStyle(fontWeight: FontWeight.bold, color: fachColor),
            ),
          ),

          // LN-Zellen
          ...lns.map((ln) {
            return Container(
              width: lnColWidth,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    ln.typ.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${ln.datum.day}.${ln.datum.month}.${ln.datum.year}',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  EditableNoteCell(
                    key: ValueKey('${student.id}_${ln.id}'),
                    studentId: student.id,
                    leistungsnachweisId: ln.id,
                    note: widget.grades
                        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
                        .firstOrNull
                        ?.note,
                    tendenz: widget.grades
                        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
                        .firstOrNull
                        ?.tendenz ?? Tendenz.keine,
                    updatedBy: widget.grades
                        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
                        .firstOrNull
                        ?.updatedBy,
                    updatedAt: widget.grades
                        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
                        .firstOrNull
                        ?.updatedAt,
                    compact: false,
                    onNoteChanged: (note) => _handleNoteChange(student.id, ln.id, note),
                    onTendenzChanged: (tendenz) => _handleTendenzChange(student.id, ln.id, tendenz),
                  ),
                ],
              ),
            );
          }),

          // Fach-Durchschnitt
          _buildDurchschnittCell(fachSchnitt, 80),
        ],
      ),
    );
  }

  Widget _buildSchuelerFooter({
    required double leftColWidth,
    required double lnColWidth,
    required List<String> sortedSubjectIds,
    required Student student,
  }) {
    final gesamtSchnitt = NotenMatrixLogic.calculateGesamtDurchschnitt(
      studentId: student.id,
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
                      color: _getNoteColor(gesamtSchnitt.round()),
                    ),
                  )
                : Text('-', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  /// Matrix: Schüler (Zeilen) × Note (Spalte) - für einen LN
  Widget _buildByLNView() {
    if (widget.leistungsnachweise.isEmpty || widget.leistungsnachweisId == null) {
      return const Center(child: Text('Kein Leistungsnachweis ausgewählt'));
    }

    final ln = widget.leistungsnachweise.first;
    final subject = widget.subjects
        .where((s) => s.id == ln.subjectId)
        .firstOrNull;
    final fachColor = RBSColors.fromHex(subject?.color) ?? RBSColors.courtGreen;
    final sortedStudents = NotenMatrixLogic.sortStudentsByName(widget.students);

    return Column(
      children: [
        // LN Info Header
        _buildLNInfoHeader(ln, subject, fachColor),

        // Metadata
        _buildMetadataHeader(),

        // Student List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedStudents.length + 2, // +2 für Header und Footer
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildLNTableHeader();
              } else if (index == sortedStudents.length + 1) {
                return _buildLNFooter(sortedStudents, ln);
              } else {
                final student = sortedStudents[index - 1];
                return _buildLNStudentRow(student, ln, index - 1);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLNInfoHeader(Leistungsnachweis ln, Subject? subject, Color fachColor) {
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

  Widget _buildLNTableHeader() {
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

  Widget _buildLNStudentRow(Student student, Leistungsnachweis ln, int index) {
    final grade = widget.grades
        .where((g) => g.studentId == student.id && g.leistungsnachweisId == ln.id)
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
                    _buildBefreiungBadge(student),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Note
            SizedBox(
              width: 200,
              child: EditableNoteCell(
                key: ValueKey('${student.id}_${ln.id}'),
                studentId: student.id,
                leistungsnachweisId: ln.id,
                note: grade?.note,
                tendenz: grade?.tendenz ?? Tendenz.keine,
                updatedBy: _optimisticUpdatedBy['${student.id}_${ln.id}'] ?? grade?.updatedBy,
                updatedAt: grade?.updatedAt,
                compact: false,
                onNoteChanged: (note) => _handleNoteChange(student.id, ln.id, note),
                onTendenzChanged: (tendenz) => _handleTendenzChange(student.id, ln.id, tendenz),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLNFooter(List<Student> students, Leistungsnachweis ln) {
    // Berechne Durchschnitt
    final grades = widget.grades
        .where((g) => g.leistungsnachweisId == ln.id)
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
                color: _getNoteColor(durchschnitt.round()).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getNoteColor(durchschnitt.round()),
                  width: 2,
                ),
              ),
              child: Text(
                '${durchschnitt.toStringAsFixed(2)} (${grades.length}/${students.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getNoteColor(durchschnitt.round()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataHeader() {
    String text = '';
    switch (widget.mode) {
      case MatrixViewMode.byKlasse:
        text = '${widget.students.length} Schüler | ${widget.subjects.length} Fächer';
        break;
      case MatrixViewMode.bySchueler:
        text = '${widget.leistungsnachweise.length} Leistungsnachweise';
        break;
      case MatrixViewMode.byLN:
        text = '${widget.students.length} Schüler';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: RBSColors.paper,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _getNoteColor(int note) {
    switch (note) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.green[600]!;
      case 3:
        return Colors.orange[700]!;
      case 4:
        return Colors.orange[800]!;
      case 5:
        return Colors.red[700]!;
      case 6:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleNoteChange(String studentId, String lnId, int? note) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final userKuerzel = NotenMatrixLogic.getUserKuerzel(userEmail);

    final existingGrade = widget.grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (note != null) {
      // Optimistic update: Show userKuerzel immediately
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
      // Clear optimistic state
      setState(() {
        _optimisticUpdatedBy.remove('${studentId}_$lnId');
      });
    }
  }

  Future<void> _handleTendenzChange(String studentId, String lnId, Tendenz tendenz) async {
    final existingGrade = widget.grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (existingGrade == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final userKuerzel = NotenMatrixLogic.getUserKuerzel(userEmail);

    // Optimistic update: Show userKuerzel immediately
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
