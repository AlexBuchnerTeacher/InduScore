import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/beruf.dart';
import '../../models/klasse.dart';
import '../../providers/permissions_providers.dart';

/// Card widget for displaying a Klasse in a list
class KlasseCard extends ConsumerWidget {
  final Klasse klasse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const KlasseCard({
    super.key,
    required this.klasse,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreate = ref.watch(canCreateDataProvider);

    return RBSCard(
      child: ListTile(
        onTap: () => context.go('/klassen/${klasse.id}'),
        leading: CircleAvatar(
          backgroundColor: _getBerufColor(klasse.beruf),
          child: Text(
            klasse.beruf.code,
            style: RBSTypography.bodyMedium.copyWith(
              color: RBSColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(klasse.name, style: RBSTypography.h4),
        subtitle: Text(klasse.beruf.name, style: RBSTypography.bodySmall),
        trailing: !canCreate
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Bearbeiten',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Löschen',
                  ),
                ],
              ),
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
