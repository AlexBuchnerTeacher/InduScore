import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../features/dashboard/widgets/statistics_cards.dart';
import '../features/dashboard/widgets/klassen_chips.dart';
import '../features/dashboard/widgets/nachschreiber_section.dart';
import '../features/dashboard/widgets/leistungsnachweise_list.dart';
import '../features/dashboard/widgets/dashboard_widgets.dart';

/// Haupt-Dashboard Screen
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
                const ZeitgruppenFilterButton(),
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
            
            // Statistik-Karten (4 Kacheln)
            DashboardStatisticsGrid(
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
                if (filteredKlassen.isEmpty) {
                  return DashboardEmptyCard(
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
                return KlassenChipsList(klassen: filteredKlassen);
              },
            ),
            const SizedBox(height: RBSSpacing.lg),

            // Nachschreiber Section
            const NachschreiberSection(),
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
              data: (lns) => subjectsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (subjects) => LeistungsnachweiseList(
                  leistungsnachweise: lns,
                  subjects: subjects,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
