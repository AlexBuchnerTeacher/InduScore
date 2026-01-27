import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/student.dart';
import '../../../models/klasse.dart';
import '../../../models/subject.dart';
import '../../../models/grade.dart';
import '../../../models/leistungsnachweis.dart';
import '../../../shared/widgets/app_snack_bars.dart';

/// Service zum Teilen von Schülernoten
/// 
/// Erstellt einen formatierten Text mit allen Fachnoten eines Schülers
/// zum Kopieren in die Zwischenablage.
class ShareStudentGrades {
  /// Erstellt formatierten Text für Schülernoten
  static String formatGrades({
    required Student student,
    required Klasse klasse,
    required List<Subject> subjects,
    required List<Grade> grades,
    required List<Leistungsnachweis> leistungsnachweise,
  }) {
    final buffer = StringBuffer();
    
    // Header mit Schülerdaten
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('📚 NOTENÜBERSICHT');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln();
    buffer.writeln('👤 ${student.firstName} ${student.lastName}');
    buffer.writeln('🏫 Klasse: ${klasse.name}');
    buffer.writeln('📅 Schuljahr: ${klasse.schuljahr}');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('NOTEN NACH FACH');
    buffer.writeln('───────────────────────────────────');
    
    // Gruppiere Grades nach Subject
    final gradesBySubject = <String, List<Grade>>{};
    for (final grade in grades.where((g) => g.studentId == student.id)) {
      final ln = leistungsnachweise.firstWhere(
        (l) => l.id == grade.leistungsnachweisId,
        orElse: () => Leistungsnachweis(
          id: '',
          subjectId: '',
          klasseId: '',
          bezeichnung: '',
          typ: LeistungsnachweisTyp.wochentest,
          datum: DateTime.now(),
          gewichtung: 1.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (ln.id.isNotEmpty && ln.klasseId == student.klasseId) {
        gradesBySubject.putIfAbsent(ln.subjectId, () => []).add(grade);
      }
    }
    
    // Sortiere Fächer und formatiere Noten
    final sortedSubjects = subjects
        .where((s) => gradesBySubject.containsKey(s.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    
    for (final subject in sortedSubjects) {
      final subjectGrades = gradesBySubject[subject.id] ?? [];
      if (subjectGrades.isEmpty) continue;
      
      // Fach-Header
      buffer.writeln();
      buffer.writeln('📖 ${subject.name}');
      
      // Noten auflisten
      for (final grade in subjectGrades) {
        final ln = leistungsnachweise.firstWhere(
          (l) => l.id == grade.leistungsnachweisId,
        );
        buffer.writeln('   • ${ln.bezeichnung}: ${grade.note}');
      }
      
      // Fach-Durchschnitt
      final avg = subjectGrades.map((g) => g.note).reduce((a, b) => a + b) / 
                  subjectGrades.length;
      buffer.writeln('   ──────────────');
      buffer.writeln('   Ø ${avg.toStringAsFixed(1)}');
    }
    
    // Gesamtdurchschnitt
    final allGrades = grades.where((g) => g.studentId == student.id).toList();
    if (allGrades.isNotEmpty) {
      final gesamtAvg = allGrades.map((g) => g.note).reduce((a, b) => a + b) / 
                        allGrades.length;
      buffer.writeln();
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('📊 GESAMTDURCHSCHNITT: ${gesamtAvg.toStringAsFixed(2)}');
      buffer.writeln('═══════════════════════════════════');
    }
    
    // Footer
    buffer.writeln();
    buffer.writeln('Erstellt mit InduScore');
    buffer.writeln('Stand: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}');
    
    return buffer.toString();
  }
  
  /// Kopiert Noten in die Zwischenablage und zeigt Feedback
  static Future<void> shareToClipboard({
    required BuildContext context,
    required Student student,
    required Klasse klasse,
    required List<Subject> subjects,
    required List<Grade> grades,
    required List<Leistungsnachweis> leistungsnachweise,
  }) async {
    final text = formatGrades(
      student: student,
      klasse: klasse,
      subjects: subjects,
      grades: grades,
      leistungsnachweise: leistungsnachweise,
    );
    
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      AppSnackBars.showSuccess(
        context,
        'Noten von ${student.firstName} ${student.lastName} in Zwischenablage kopiert!',
      );
    }
  }
  
  /// Zeigt Teilen-Dialog mit Vorschau
  static void showShareDialog({
    required BuildContext context,
    required Student student,
    required Klasse klasse,
    required List<Subject> subjects,
    required List<Grade> grades,
    required List<Leistungsnachweis> leistungsnachweise,
  }) {
    final text = formatGrades(
      student: student,
      klasse: klasse,
      subjects: subjects,
      grades: grades,
      leistungsnachweise: leistungsnachweise,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.share, color: RBSColors.dynamicRed),
            const SizedBox(width: 8),
            const Text('Noten teilen'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('In Zwischenablage kopieren'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                Navigator.pop(context);
                AppSnackBars.showSuccess(context, 'In Zwischenablage kopiert!');
              }
            },
          ),
        ],
      ),
    );
  }
}
