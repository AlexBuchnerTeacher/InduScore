import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/leistungsnachweis.dart';
import '../../../models/subject.dart';
import '../../../providers/app_providers.dart';

/// Karte für einzelnen Leistungsnachweis
class LeistungsnachweisCard extends ConsumerWidget {
  final Leistungsnachweis ln;
  final List<Subject> subjects;

  const LeistungsnachweisCard({
    required this.ln, required this.subjects, super.key,
  });

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return months[month - 1];
  }

  Color _getTypColor(LeistungsnachweisTyp typ) {
    switch (typ) {
      case LeistungsnachweisTyp.wochentest:
        return Colors.blue;
      case LeistungsnachweisTyp.praktisch:
        return RBSColors.courtGreen;
      case LeistungsnachweisTyp.muendlich:
        return Colors.orange;
      case LeistungsnachweisTyp.mitarbeit:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimized: Use map provider for O(1) lookup instead of list iteration
    final klassenMap = ref.watch(klassenMapProvider);

    String klasseName = '...';
    String fachName = '...';
    Color fachColor = RBSColors.dynamicRed;

    // O(1) lookup instead of .where().firstOrNull
    final klasse = klassenMap[ln.klasseId];
    if (klasse != null) klasseName = klasse.name;

    final subject = subjects.where((s) => s.id == ln.subjectId).firstOrNull;
    if (subject != null) {
      fachName = subject.shortName ?? subject.name;
      fachColor = RBSColors.fromHex(subject.color) ?? RBSColors.dynamicRed;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go('/noten/${ln.id}'),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: fachColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${ln.datum.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: fachColor,
                ),
              ),
              Text(
                _getMonthShort(ln.datum.month),
                style: TextStyle(
                  fontSize: 10,
                  color: fachColor,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          ln.bezeichnung,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: fachColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fachName,
                style: TextStyle(fontSize: 11, color: fachColor),
              ),
            ),
            Text('• $klasseName', style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _getTypColor(ln.typ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                ln.typ.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _getTypColor(ln.typ),
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }
}

/// Liste mit aktuellen Leistungsnachweisen
class LeistungsnachweiseList extends ConsumerWidget {
  final List<Leistungsnachweis> leistungsnachweise;
  final List<Subject> subjects;

  const LeistungsnachweiseList({
    required this.leistungsnachweise, required this.subjects, super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sortiere nach Datum (neueste zuerst) und nimm die letzten 5
    final sorted = List<Leistungsnachweis>.from(leistungsnachweise)
      ..sort((a, b) => b.datum.compareTo(a.datum));
    final recent = sorted.take(5).toList();

    if (recent.isEmpty) {
      return Card(
        child: InkWell(
          onTap: () => context.go('/leistungsnachweise'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Noch keine Leistungsnachweise', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Erstelle deinen ersten Leistungsnachweis', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: recent.map((ln) => LeistungsnachweisCard(
        ln: ln,
        subjects: subjects,
      )).toList(),
    );
  }
}
