import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/widgets/rbs_drawer.dart';
import 'package:induscore/core/widgets/rbs_components.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/features/dashboard/widgets/statistics_cards.dart';
import 'package:induscore/features/dashboard/widgets/klassen_chips.dart';
import 'package:induscore/features/dashboard/widgets/nachschreiber_section.dart';
import 'package:induscore/features/dashboard/widgets/leistungsnachweise_list.dart';
import 'package:induscore/features/dashboard/widgets/dashboard_widgets.dart';

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
                const Spacer(),
                // Favoriten-Toggle (für Lehrer/Ausbilder)
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(currentAppUserProvider).value;
                    if (currentUser == null || currentUser.favoriteKlassenIds.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final favoritenFilter = ref.watch(favoritenFilterProvider);
                    return Row(
                      children: [
                        RBSFilterChip(
                          label: favoritenFilter ? 'Favoriten' : 'Alle',
                          icon: favoritenFilter ? Icons.star : Icons.star_border,
                          selected: favoritenFilter,
                          color: RBSColors.dynamicRed,
                          onSelected: (_) => ref.read(favoritenFilterProvider.notifier).toggle(),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  },
                ),
                // Zeitgruppen-Filter
                RBSFilterChip(
                  label: 'ZG1',
                  selected: zeitgruppenFilter.contains(1),
                  color: RBSColors.courtGreen,
                  onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
                ),
                const SizedBox(width: 4),
                RBSFilterChip(
                  label: 'ZG2',
                  selected: zeitgruppenFilter.contains(2),
                  color: RBSColors.courtGreen,
                  onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
                ),
                const SizedBox(width: 4),
                RBSFilterChip(
                  label: 'ZG3',
                  selected: zeitgruppenFilter.contains(3),
                  color: RBSColors.courtGreen,
                  onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
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
                    title: zeitgruppenFilter.isNotEmpty
                        ? 'Keine Klassen in ausgewählten Zeitgruppen'
                        : 'Noch keine Klassen',
                    subtitle: zeitgruppenFilter.isNotEmpty
                        ? 'Wähle andere Zeitgruppen'
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
