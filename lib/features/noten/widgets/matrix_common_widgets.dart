import 'package:flutter/material.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/student.dart';
import '../../../models/tendenz.dart';
import 'editable_note_cell.dart';

/// Gemeinsame Widgets für Matrix-Ansichten
class MatrixCommonWidgets {
  MatrixCommonWidgets._();

  /// Zeigt Befreiung-Badges (D, PuG) für Schüler an
  static Widget buildBefreiungBadge(Student student) {
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

  /// Durchschnitt-Zelle mit Farbcodierung
  static Widget buildDurchschnittCell(
    double? schnitt,
    double width, {
    bool isBold = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: schnitt != null
          ? Text(
              schnitt.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: getNoteColor(schnitt.round()),
              ),
            )
          : Text('-', style: TextStyle(color: Colors.grey[400])),
    );
  }

  /// Editable Note Cell Wrapper
  static Widget buildNoteCell({
    required String studentId,
    required String leistungsnachweisId,
    required int? note,
    required Tendenz tendenz,
    required double width,
    required Function(int?) onNoteChanged,
    required Function(Tendenz) onTendenzChanged,
    String? updatedBy,
    DateTime? updatedAt,
    bool compact = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: EditableNoteCell(
        key: ValueKey('${studentId}_$leistungsnachweisId'),
        studentId: studentId,
        leistungsnachweisId: leistungsnachweisId,
        note: note,
        tendenz: tendenz,
        updatedBy: updatedBy,
        updatedAt: updatedAt,
        compact: compact,
        onNoteChanged: onNoteChanged,
        onTendenzChanged: onTendenzChanged,
      ),
    );
  }

  /// Metadata Header (Anzahl Schüler/Fächer/LNs)
  static Widget buildMetadataHeader(String text) {
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

  /// Farbcodierung für Noten (1-6)
  static Color getNoteColor(int note) {
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

  /// Schüler-Name Zelle (klickbar, mit Befreiung-Badge)
  static Widget buildStudentNameCell({
    required Student student,
    required int index,
    required double width,
    void Function(String)? onStudentTap,
  }) {
    return InkWell(
      onTap: onStudentTap != null ? () => onStudentTap(student.id) : null,
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
              buildBefreiungBadge(student),
          ],
        ),
      ),
    );
  }
}
