import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/grade.dart';
import '../../../models/tendenz.dart';
import '../../../models/student.dart';
import '../../../providers/app_providers.dart';
import '../noten_layout_constants.dart';

/// Basis-Mixin für gemeinsame Matrix-Funktionalität
mixin NotenMatrixBaseMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // Optimistic updates für updatedBy - zeigt Kürzel sofort an
  final Map<String, String> optimisticUpdatedBy = {};

  /// Behandelt Note-Änderung mit optimistic update
  Future<void> handleNoteChange(
    String studentId,
    String lnId,
    int? note,
    List<Grade> grades,
  ) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    // v0.33.0: Kürzel aus AppUser (NUR vom Admin gesetzt)
    final userKuerzel = await ref.read(currentUserKuerzelProvider.future);
    final effectiveKuerzel = userKuerzel.isNotEmpty && userKuerzel != '—' ? userKuerzel : null;

    final existingGrade = grades
        .where((g) => g.studentId == studentId && g.leistungsnachweisId == lnId)
        .firstOrNull;

    if (note != null) {
      // Optimistic update: Show userKuerzel immediately
      if (effectiveKuerzel != null) {
        setState(() {
          optimisticUpdatedBy['${studentId}_$lnId'] = effectiveKuerzel;
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
      // Clear optimistic state
      setState(() {
        optimisticUpdatedBy.remove('${studentId}_$lnId');
      });
    }
  }

  /// Behandelt Tendenz-Änderung
  Future<void> handleTendenzChange(
    String studentId,
    String lnId,
    Tendenz tendenz,
    List<Grade> grades,
  ) async {
    final existingGrade = grades
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
        optimisticUpdatedBy['${studentId}_$lnId'] = effectiveKuerzel;
      });
    }

    final updatedGrade = existingGrade.copyWith(
      tendenz: tendenz,
      updatedBy: effectiveKuerzel,
      updatedAt: DateTime.now(),
    );

    await firestoreService.updateGrade(updatedGrade);
  }

  /// Farbe für Note (verwendet zentrale Konstanten)
  Color _getNoteColor(int? note) {
    if (note == null) return NotenColors.empty;
    return NotenColors.getColor(note);
  }

  /// Befreiung-Badge für Schüler
  Widget buildBefreiungBadge(Student student) {
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

  /// Metadata Header (gemeinsam für alle Modi)
  Widget buildMetadataHeader() {
    return Container(
      padding: const EdgeInsets.all(RBSSpacing.sm),
      decoration: BoxDecoration(
        color: RBSColors.paper,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            'Inline-Editing aktiv',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            'Kürzel = letzter Bearbeiter',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Durchschnitts-Zelle
  Widget buildDurchschnittCell(double? schnitt, double width, {bool isBold = false}) {
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
}
