import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../models/leistungsnachweis.dart';
import '../models/subject.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final klassenAsync = ref.watch(klassenProvider);
    final filteredKlassen = ref.watch(filteredKlassenProvider);
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final gradesAsync = ref.watch(gradesProvider);
    final currentSchuljahr = ref.watch(currentSchuljahrProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('InduScore')),
      drawer: const RBSDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RBSSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Schuljahr und Zeitgruppen-Filter
            Row(
              children: [
                const RBSHeadline(text: 'Dashboard', level: RBSHeadlineLevel.h2),
                const Spacer(),
                // Zeitgruppen-Filter
                _buildZeitgruppenFilter(ref),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RBSColors.dynamicRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RBSColors.dynamicRed),
                  ),
                  child: Text(
                    currentSchuljahr.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: RBSColors.dynamicRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RBSSpacing.lg),
            
            // Statistik-Karten
            _buildStatisticsRow(
              context,
              klassenAsync: klassenAsync,
              studentsAsync: studentsAsync,
              subjectsAsync: subjectsAsync,
              gradesAsync: gradesAsync,
            ),
            const SizedBox(height: RBSSpacing.lg),

            // Schnellzugriff: Meine Klassen
            Row(
              children: [
                const RBSHeadline(text: 'Meine Klassen', level: RBSHeadlineLevel.h4),
                if (zeitgruppenFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text('ZG$zeitgruppenFilter'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => ref.read(zeitgruppenFilterProvider.notifier).clearFilter(),
                      backgroundColor: RBSColors.courtGreen.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: RBSSpacing.sm),
            klassenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (_) {
                // Verwende gefilterte Klassen
                final klassen = filteredKlassen;
                if (klassen.isEmpty) {
                  return _buildEmptyCard(
                    context,
                    icon: Icons.school_outlined,
                    title: zeitgruppenFilter != null 
                        ? 'Keine Klassen in ZG$zeitgruppenFilter'
                        : 'Noch keine Klassen',
                    subtitle: zeitgruppenFilter != null
                        ? 'Wähle eine andere Zeitgruppe'
                        : 'Erstelle deine erste Klasse',
                    onTap: () => context.go('/klassen'),
                  );
                }
                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: klassen.length + 1, // +1 für "Alle" Button
                    itemBuilder: (context, index) {
                      if (index == klassen.length) {
                        return _buildKlasseChip(
                          context,
                          name: '+ Alle',
                          color: Colors.grey,
                          onTap: () => context.go('/klassen'),
                        );
                      }
                      final klasse = klassen[index];
                      return _buildKlasseChip(
                        context,
                        name: klasse.name,
                        color: _getBerufColor(klasse.beruf),
                        onTap: () => context.go('/noten/klasse/${klasse.id}'),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: RBSSpacing.lg),

            // Nachschreiber Section
            _buildNachschreiberSection(context, ref),
            const SizedBox(height: RBSSpacing.lg),

            // Aktuelle Leistungsnachweise
            Row(
              children: [
                const RBSHeadline(text: 'Aktuelle Leistungsnachweise', level: RBSHeadlineLevel.h4),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/leistungsnachweise'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Neu'),
                ),
              ],
            ),
            const SizedBox(height: RBSSpacing.sm),
            leistungsnachweiseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (lns) {
                // Sortiere nach Datum (neueste zuerst) und nimm die letzten 5
                final sorted = List<Leistungsnachweis>.from(lns)
                  ..sort((a, b) => b.datum.compareTo(a.datum));
                final recent = sorted.take(5).toList();

                if (recent.isEmpty) {
                  return _buildEmptyCard(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'Noch keine Leistungsnachweise',
                    subtitle: 'Erstelle deinen ersten Leistungsnachweis',
                    onTap: () => context.go('/leistungsnachweise'),
                  );
                }

                return subjectsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (subjects) => Column(
                    children: recent.map((ln) => _buildLeistungsnachweisCard(
                      context,
                      ref,
                      ln,
                      subjects,
                    )).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKlasseChip(
    BuildContext context, {
    required String name,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeistungsnachweisCard(
    BuildContext context,
    WidgetRef ref,
    Leistungsnachweis ln,
    List<Subject> subjects,
  ) {
    final klassenAsync = ref.watch(klassenProvider);

    String klasseName = '...';
    String fachName = '...';
    Color fachColor = RBSColors.dynamicRed;

    klassenAsync.whenData((klassen) {
      final klasse = klassen.where((k) => k.id == ln.klasseId).firstOrNull;
      if (klasse != null) klasseName = klasse.name;
    });

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
                style: TextStyle(fontSize: 11, color: fachColor, fontWeight: FontWeight.bold),
              ),
            ),
            Text('$klasseName • ${ln.typ.label}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypColor(ln.typ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${ln.gewichtung}x',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTypColor(ln.typ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.grey[400]),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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

  Color _getBerufColor(dynamic beruf) {
    final code = beruf.toString().split('.').last.toUpperCase();
    switch (code) {
      case 'IE':
        return RBSColors.dynamicRed;
      case 'EAT':
        return RBSColors.courtGreen;
      case 'EBT':
        return RBSColors.growingElder;
      case 'EGS':
        return Colors.blue;
      default:
        return RBSColors.dynamicRed;
    }
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

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return months[month - 1];
  }
  
  Widget _buildStatisticsRow(
    BuildContext context, {
    required AsyncValue klassenAsync,
    required AsyncValue studentsAsync,
    required AsyncValue subjectsAsync,
    required AsyncValue gradesAsync,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;
        
        if (width < 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else if (width < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.8;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        }
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              icon: Icons.school,
              label: 'Klassen',
              value: klassenAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.dynamicRed,
              onTap: () => context.go('/klassen'),
            ),
            _buildStatCard(
              icon: Icons.people,
              label: 'Schüler',
              value: studentsAsync.when(
                data: (data) => '${(data as List).where((s) => s.isAktiv).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.courtGreen,
              onTap: () => context.go('/schueler'),
            ),
            _buildStatCard(
              icon: Icons.book,
              label: 'Fächer',
              value: subjectsAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.growingElder,
              onTap: () => context.go('/faecher'),
            ),
            _buildStatCard(
              icon: Icons.grade,
              label: 'Noten',
              value: gradesAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: const Color(0xFF2E7BB5),
              onTap: () => context.go('/leistungsnachweise'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNachschreiberSection(BuildContext context, WidgetRef ref) {
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
            const RBSHeadline(text: 'Nachschreiber', level: RBSHeadlineLevel.h4),
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
          _buildNachschreiberStufeHeader('Kritisch (> 2 Wochen)', Colors.red, stufe3.length),
          ...stufe3.take(5).map((n) => _buildNachschreiberCard(context, ref, n, Colors.red)),
          if (stufe3.length > 5)
            TextButton(
              onPressed: () {}, // TODO: Alle anzeigen
              child: Text('+ ${stufe3.length - 5} weitere'),
            ),
        ],
        
        // Dringend (Stufe 2 - Orange)
        if (stufe2.isNotEmpty) ...[
          _buildNachschreiberStufeHeader('Dringend (≤ 2 Wochen)', Colors.orange, stufe2.length),
          ...stufe2.take(5).map((n) => _buildNachschreiberCard(context, ref, n, Colors.orange)),
          if (stufe2.length > 5)
            TextButton(
              onPressed: () {},
              child: Text('+ ${stufe2.length - 5} weitere'),
            ),
        ],
        
        // Neu (Stufe 1 - Gelb/Amber)
        if (stufe1.isNotEmpty) ...[
          _buildNachschreiberStufeHeader('Neu (≤ 2 Tage)', Colors.amber.shade700, stufe1.length),
          ...stufe1.take(3).map((n) => _buildNachschreiberCard(context, ref, n, Colors.amber.shade700)),
          if (stufe1.length > 3)
            TextButton(
              onPressed: () {},
              child: Text('+ ${stufe1.length - 3} weitere'),
            ),
        ],
      ],
    );
  }

  Widget _buildNachschreiberStufeHeader(String label, Color color, int count) {
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
            style: RBSTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNachschreiberCard(BuildContext context, WidgetRef ref, Nachschreiber nachschreiber, Color color) {
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
          style: RBSTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${nachschreiber.klasse.name} • $fachName • ${ln.bezeichnung}',
          style: RBSTypography.bodySmall.copyWith(fontSize: 11),
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
            // Nicht-relevant Button
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
          // Zur Noteneingabe für diesen LN navigieren
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

    if (result == true) {
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

  Widget _buildZeitgruppenFilter(WidgetRef ref) {
    final currentFilter = ref.watch(zeitgruppenFilterProvider);
    
    return SegmentedButton<int?>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      segments: const [
        ButtonSegment(value: null, label: Text('Alle')),
        ButtonSegment(value: 1, label: Text('ZG1')),
        ButtonSegment(value: 2, label: Text('ZG2')),
        ButtonSegment(value: 3, label: Text('ZG3')),
      ],
      selected: {currentFilter},
      onSelectionChanged: (selected) {
        ref.read(zeitgruppenFilterProvider.notifier).setFilter(selected.first);
      },
    );
  }
}
