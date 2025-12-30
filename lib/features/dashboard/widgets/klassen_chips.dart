import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/klasse.dart';
import '../../../shared/widgets/feature_guard.dart';

/// Einzelner Klassen-Chip
class KlasseChip extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback onTap;

  const KlasseChip({
    required this.name, required this.color, required this.onTap, super.key,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Horizontale Liste mit Klassen-Chips
class KlassenChipsList extends ConsumerWidget {
  final List<Klasse> klassen;

  const KlassenChipsList({
    required this.klassen, super.key,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: klassen.length + 1, // +1 für "Alle" Button
        itemBuilder: (context, index) {
          if (index == klassen.length) {
            return KlasseChip(
              name: '+ Alle',
              color: Colors.grey,
              onTap: () => context.go('/klassen'),
            );
          }
          final klasse = klassen[index];
          final canAccessNoten = ref.watch(canAccessNotenProvider);
          return KlasseChip(
            name: klasse.name,
            color: _getBerufColor(klasse.beruf),
            onTap: canAccessNoten
                ? () => context.go('/noten/klasse/${klasse.id}')
                : () {},
          );
        },
      ),
    );
  }
}
