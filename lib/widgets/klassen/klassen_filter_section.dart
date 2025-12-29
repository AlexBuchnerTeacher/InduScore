import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/beruf.dart';
import '../../providers/app_providers.dart';

/// Filter-Section für Klassenverwaltung
///
/// Bietet Filter für:
/// - Zeitgruppen (ZG1, ZG2, ZG3)
/// - Schuljahr (aktuelles Schuljahr)
/// - Berufe (alle verfügbaren Berufe)
///
/// Verwendet Riverpod für Zeitgruppen-Filter (global),
/// lokale Callbacks für Beruf/Schuljahr-Filter.
class KlassenFilterSection extends ConsumerWidget {
  /// Aktuell ausgewählte Berufe
  final Set<String> selectedBerufe;

  /// Aktuell ausgewähltes Schuljahr (null = alle)
  final String? selectedSchuljahr;

  /// Callback wenn Berufe-Filter geändert wird
  final ValueChanged<Set<String>> onBerufFilterChanged;

  /// Callback wenn Schuljahr-Filter geändert wird
  final ValueChanged<String?> onSchuljahrFilterChanged;

  const KlassenFilterSection({
    required this.selectedBerufe,
    required this.selectedSchuljahr,
    required this.onBerufFilterChanged,
    required this.onSchuljahrFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);
    final currentSchuljahr = ref.watch(currentSchuljahrProvider);

    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      color: RBSColors.paper,
      child: Wrap(
        spacing: RBSSpacing.sm,
        runSpacing: RBSSpacing.sm,
        children: [
          // Zeitgruppen-Filter
          RBSFilterChip(
            label: 'ZG1',
            selected: zeitgruppenFilter.contains(1),
            color: RBSColors.courtGreen,
            onSelected: (_) =>
                ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
          ),
          RBSFilterChip(
            label: 'ZG2',
            selected: zeitgruppenFilter.contains(2),
            color: RBSColors.courtGreen,
            onSelected: (_) =>
                ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
          ),
          RBSFilterChip(
            label: 'ZG3',
            selected: zeitgruppenFilter.contains(3),
            color: RBSColors.courtGreen,
            onSelected: (_) =>
                ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
          ),

          // Schuljahr Filter
          RBSFilterChip(
            label: selectedSchuljahr ?? currentSchuljahr.toString(),
            selected: selectedSchuljahr != null,
            onSelected: (selected) {
              onSchuljahrFilterChanged(
                selected ? currentSchuljahr.toString() : null,
              );
            },
          ),

          // Beruf Filter
          ...Beruf.values.map(
            (beruf) => RBSFilterChip(
              label: beruf.code,
              selected: selectedBerufe.contains(beruf.code),
              color: _getBerufColor(beruf),
              onSelected: (_) {
                final newSelection = Set<String>.from(selectedBerufe);
                if (newSelection.contains(beruf.code)) {
                  newSelection.remove(beruf.code);
                } else {
                  newSelection.add(beruf.code);
                }
                onBerufFilterChanged(newSelection);
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getBerufColor(Beruf beruf) {
    switch (beruf) {
      case Beruf.ie:
        return RBSColors.dynamicRed;
      case Beruf.eat:
        return RBSColors.courtGreen;
      case Beruf.ebt:
        return RBSColors.growingElder;
      case Beruf.egs:
        return const Color(0xFF2E7BB5); // Blue
    }
  }
}
