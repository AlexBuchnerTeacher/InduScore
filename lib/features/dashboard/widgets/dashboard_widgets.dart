import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../core/widgets/rbs_components.dart';
import '../../../core/theme/rbs_theme.dart';

/// Zeitgruppen-Filter (Filter Chips ohne "Alle")
/// Deaktivieren aller Chips = Alle anzeigen
class ZeitgruppenFilterButton extends ConsumerWidget {
  const ZeitgruppenFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(zeitgruppenFilterProvider);
    
    return Wrap(
      spacing: 8,
      children: [
        RBSFilterChip(
          label: 'ZG1',
          selected: currentFilter.contains(1),
          color: RBSColors.courtGreen,
          onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(1),
        ),
        RBSFilterChip(
          label: 'ZG2',
          selected: currentFilter.contains(2),
          color: RBSColors.courtGreen,
          onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(2),
        ),
        RBSFilterChip(
          label: 'ZG3',
          selected: currentFilter.contains(3),
          color: RBSColors.courtGreen,
          onSelected: (_) => ref.read(zeitgruppenFilterProvider.notifier).toggle(3),
        ),
      ],
    );
  }
}

/// Empty State Card für Dashboard
class DashboardEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardEmptyCard({
    required this.icon, required this.title, required this.subtitle, required this.onTap, super.key,
  });

  @override
  Widget build(BuildContext context) {
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
}
