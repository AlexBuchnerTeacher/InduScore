import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/subject.dart';

/// Callback für Fach-Detail-Dialog
typedef OnFachDetailTap =
    void Function(
      Subject? subject,
      List<Leistungsnachweis> leistungsnachweise,
      List<Student> students, {
      String? highlightStudentId,
    });

/// Widget für die Fächer-Matrix (Schüler × Fächer)
class FaecherMatrixWidget extends StatelessWidget {
  final List<Student> students;
  final List<String> sortedSubjectIds;
  final Map<String, List<Leistungsnachweis>> lnBySubject;
  final List<Subject> subjects;
  final Map<String, Map<String, double?>> studentFachSchnitte;
  final Map<String, double?> studentGesamtSchnitte;
  final OnFachDetailTap onFachDetailTap;
  final Color Function(int) getNoteColor;

  const FaecherMatrixWidget({
    required this.students, required this.sortedSubjectIds, required this.lnBySubject, required this.subjects, required this.studentFachSchnitte, required this.studentGesamtSchnitte, required this.onFachDetailTap, required this.getNoteColor, super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Berechne Spaltenbreite
    const fachSpaltenBreite = 85.0;
    final tableWidth =
        180.0 + (sortedSubjectIds.length * fachSpaltenBreite) + 80;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (fixiert)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: _buildHeaderRow(fachSpaltenBreite),
            ),
          ),

          // Body (scrollbar vertikal und horizontal)
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: tableWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Schüler-Zeilen
                      ...students.asMap().entries.map((entry) {
                        return _buildStudentRow(
                          entry.key,
                          entry.value,
                          fachSpaltenBreite,
                        );
                      }),

                      // Footer mit Klassen-Durchschnitten
                      _buildFooterRow(fachSpaltenBreite),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(double fachSpaltenBreite) {
    return Container(
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        children: [
          // Schüler-Spalte
          Container(
            width: 170,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Text(
              'Schüler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          // Fach-Spalten
          ...sortedSubjectIds.map((subjectId) {
            final subject = subjects
                .where((s) => s.id == subjectId)
                .firstOrNull;
            final fachColor =
                RBSColors.fromHex(subject?.color) ?? RBSColors.courtGreen;
            final lnCount = lnBySubject[subjectId]?.length ?? 0;

            return InkWell(
              onTap: () => onFachDetailTap(
                subject,
                lnBySubject[subjectId] ?? [],
                students,
              ),
              child: Container(
                width: fachSpaltenBreite,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: fachColor.withValues(alpha: 0.1),
                  border: Border(left: BorderSide(color: fachColor, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      subject?.shortName ?? subject?.name ?? '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: fachColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$lnCount LN',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Gesamt-Spalte
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: RBSColors.dynamicRed.withValues(alpha: 0.1),
            ),
            child: const Column(
              children: [
                Text(
                  '⌀',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Gesamt', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    int index,
    Student student,
    double fachSpaltenBreite,
  ) {
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Schüler-Name
          Container(
            width: 170,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${student.lastName}, ${student.firstName}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Befreiungs-Indikatoren
                      if (student.befreiungDeutsch || student.befreiungPuG) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: [
                            if (student.befreiungDeutsch) 'Befreiung Deutsch',
                            if (student.befreiungPuG) 'Befreiung PuG',
                          ].join(', '),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'B',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Fach-Durchschnitte
          ...sortedSubjectIds.map((subjectId) {
            final schnitt = studentFachSchnitte[student.id]?[subjectId];
            final subject = subjects
                .where((s) => s.id == subjectId)
                .firstOrNull;

            return InkWell(
              onTap: () => onFachDetailTap(
                subject,
                lnBySubject[subjectId] ?? [],
                students,
                highlightStudentId: student.id,
              ),
              child: Container(
                width: fachSpaltenBreite,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                alignment: Alignment.center,
                child: schnitt != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getNoteColor(
                            schnitt.round(),
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: getNoteColor(
                              schnitt.round(),
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          schnitt.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: getNoteColor(schnitt.round()),
                          ),
                        ),
                      )
                    : Text('-', style: TextStyle(color: Colors.grey[400])),
              ),
            );
          }),
          // Gesamt-Durchschnitt
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            alignment: Alignment.center,
            child: studentGesamtSchnitte[student.id] != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getNoteColor(
                        studentGesamtSchnitte[student.id]!.round(),
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getNoteColor(
                          studentGesamtSchnitte[student.id]!.round(),
                        ),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      studentGesamtSchnitte[student.id]!.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: getNoteColor(
                          studentGesamtSchnitte[student.id]!.round(),
                        ),
                      ),
                    ),
                  )
                : Text('-', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterRow(double fachSpaltenBreite) {
    return Container(
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 170,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Text(
              '⌀ Klasse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ...sortedSubjectIds.map((subjectId) {
            final schnitte = students
                .map((s) => studentFachSchnitte[s.id]?[subjectId])
                .where((s) => s != null)
                .cast<double>()
                .toList();
            final klassenSchnitt = schnitte.isNotEmpty
                ? schnitte.reduce((a, b) => a + b) / schnitte.length
                : null;

            return Container(
              width: fachSpaltenBreite,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              alignment: Alignment.center,
              child: klassenSchnitt != null
                  ? Text(
                      klassenSchnitt.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: getNoteColor(klassenSchnitt.round()),
                      ),
                    )
                  : Text('-', style: TextStyle(color: Colors.grey[400])),
            );
          }),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            alignment: Alignment.center,
            child: () {
              final alleSchnitte = studentGesamtSchnitte.values
                  .where((s) => s != null)
                  .cast<double>()
                  .toList();
              final gesamtSchnitt = alleSchnitte.isNotEmpty
                  ? alleSchnitte.reduce((a, b) => a + b) / alleSchnitte.length
                  : null;
              return gesamtSchnitt != null
                  ? Text(
                      gesamtSchnitt.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: getNoteColor(gesamtSchnitt.round()),
                      ),
                    )
                  : Text('-', style: TextStyle(color: Colors.grey[400]));
            }(),
          ),
        ],
      ),
    );
  }
}
