import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/beruf.dart';
import '../../providers/app_providers.dart';

/// Filter section for Klassen screen
/// 
/// Provides filters for:
/// - Zeitgruppen (ZG1, ZG2, ZG3)
/// - Schuljahr
/// - Beruf (IE, EAT, EBT, EGS)
class KlassenFilterSection extends ConsumerWidget {
  final Set<String> selectedBerufe;
  final String? selectedSchuljahr;
  final ValueChanged<Set<String>> onBerufeChanged;
  final ValueChanged<String?> onSchuljahrChanged;

  const KlassenFilterSection({
    super.key,
    required this.selectedBerufe,
    required this.selectedSchuljahr,
    required this.onBerufeChanged,
    required this.onSchuljahrChanged,
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
              onSchuljahrChanged(
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
                onBerufeChanged(newSelection);
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
