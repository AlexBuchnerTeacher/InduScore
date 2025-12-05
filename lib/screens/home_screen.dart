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
            // Header mit Schuljahr
            Row(
              children: [
                const RBSHeadline(text: 'Dashboard', level: RBSHeadlineLevel.h2),
                const Spacer(),
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
            const RBSHeadline(text: 'Meine Klassen', level: RBSHeadlineLevel.h4),
            const SizedBox(height: RBSSpacing.sm),
            klassenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (klassen) {
                if (klassen.isEmpty) {
                  return _buildEmptyCard(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Noch keine Klassen',
                    subtitle: 'Erstelle deine erste Klasse',
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
        final isSmall = constraints.maxWidth < 500;
        final crossAxisCount = isSmall ? 2 : 4;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isSmall ? 1.5 : 1.8,
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
    );
  }
}
