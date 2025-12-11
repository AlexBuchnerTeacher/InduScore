import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

/// Zeitgruppen-Filter (Segmented Button)
class ZeitgruppenFilterButton extends ConsumerWidget {
  const ZeitgruppenFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

/// Empty State Card für Dashboard
class DashboardEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
