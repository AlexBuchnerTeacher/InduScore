import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../providers/app_providers.dart';

/// Nachschreiber-Section mit Stufen-Gruppierung
class NachschreiberSection extends ConsumerWidget {
  const NachschreiberSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nachschreiber = ref.watch(filteredNachschreiberProvider);

    if (nachschreiber.isEmpty) {
      return const SizedBox.shrink(); // Keine Nachschreiber = Section ausblenden
    }

    // Gruppiere nach Eskalationsstufe
    final stufe3 = nachschreiber.where((n) => n.stufe == NachschreiberStufe.stufe3).toList();
    final stufe2 = nachschreiber.where((n) => n.stufe == NachschreiberStufe.stufe2).toList();
    final stufe1 = nachschreiber.where((n) => n.stufe == NachschreiberStufe.stufe1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Nachschreiber', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: nachschreiber.isNotEmpty 
                    ? (stufe3.isNotEmpty ? Colors.red : (stufe2.isNotEmpty ? Colors.orange : Colors.amber))
                    : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${nachschreiber.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RBSSpacing.sm),
        
        // Kritisch (Stufe 3 - Rot)
        if (stufe3.isNotEmpty) ...[
          _NachschreiberStufeHeader(label: 'Kritisch (> 2 Wochen)', color: Colors.red, count: stufe3.length),
          ...stufe3.take(5).map((n) => _NachschreiberCard(nachschreiber: n, color: Colors.red)),
          if (stufe3.length > 5)
            TextButton(
              onPressed: () => context.go('/leistungsnachweise'),
              child: Text('+ ${stufe3.length - 5} weitere'),
            ),
        ],
        
        // Dringend (Stufe 2 - Orange)
        if (stufe2.isNotEmpty) ...[
          _NachschreiberStufeHeader(label: 'Dringend (≤ 2 Wochen)', color: Colors.orange, count: stufe2.length),
          ...stufe2.take(5).map((n) => _NachschreiberCard(nachschreiber: n, color: Colors.orange)),
          if (stufe2.length > 5)
            TextButton(
              onPressed: () {},
              child: Text('+ ${stufe2.length - 5} weitere'),
            ),
        ],
        
        // Neu (Stufe 1 - Gelb/Amber)
        if (stufe1.isNotEmpty) ...[
          _NachschreiberStufeHeader(label: 'Neu (≤ 2 Tage)', color: Colors.amber.shade700, count: stufe1.length),
          ...stufe1.take(3).map((n) => _NachschreiberCard(nachschreiber: n, color: Colors.amber.shade700)),
          if (stufe1.length > 3)
            TextButton(
              onPressed: () {},
              child: Text('+ ${stufe1.length - 3} weitere'),
            ),
        ],
      ],
    );
  }
}

/// Header für Nachschreiber-Stufe
class _NachschreiberStufeHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _NachschreiberStufeHeader({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: RBSSpacing.sm, bottom: RBSSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Karte für einzelnen Nachschreiber
class _NachschreiberCard extends ConsumerWidget {
  final Nachschreiber nachschreiber;
  final Color color;

  const _NachschreiberCard({
    required this.nachschreiber,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = nachschreiber.student;
    final ln = nachschreiber.leistungsnachweis;
    final fachName = nachschreiber.subject?.shortName ?? nachschreiber.subject?.name ?? 'Unbekannt';

    return Card(
      margin: const EdgeInsets.only(bottom: RBSSpacing.xs),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.warning_amber, color: color, size: 18),
        ),
        title: Text(
          student.displayName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${nachschreiber.klasse.name} • $fachName • ${ln.bezeichnung}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${nachschreiber.tageAlt}d',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.block, size: 18),
              color: Colors.grey,
              tooltip: 'Als nicht relevant markieren',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showExemptionDialog(context, ref, nachschreiber),
            ),
          ],
        ),
        onTap: () {
          context.go('/noten/klasse/${ln.klasseId}');
        },
      ),
    );
  }

  Future<bool> _showExemptionDialog(BuildContext context, WidgetRef ref, Nachschreiber nachschreiber) async {
    final student = nachschreiber.student;
    final ln = nachschreiber.leistungsnachweis;
    final fachName = nachschreiber.subject?.shortName ?? nachschreiber.subject?.name ?? 'Unbekannt';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LN als nicht relevant markieren?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student.displayName} wird von diesem Leistungsnachweis befreit:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ln.bezeichnung, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$fachName • ${nachschreiber.klasse.name}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Der Schüler erscheint nicht mehr in der Nachschreiber-Liste für diesen LN.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Befreien'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createLnExemption(
        studentId: student.id,
        leistungsnachweisId: ln.id,
        grund: 'Nicht relevant',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.displayName} von "${ln.bezeichnung}" befreit'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () async {
                await firestoreService.deleteLnExemption(student.id, ln.id);
              },
            ),
          ),
        );
      }
      return true;
    }
    return false;
  }
}
