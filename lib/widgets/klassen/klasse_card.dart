import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/klasse.dart';
import '../../models/beruf.dart';
import '../../providers/permissions_providers.dart';

/// Klassen-Karte für die ListView
///
/// Zeigt Klasse mit Avatar (Beruf-Code), Name, Beschreibung.
/// Für Admins/Lehrer: Edit + Delete Buttons.
/// Navigiert zu Klassen-Detail beim Tap.
class KlasseCard extends ConsumerWidget {
  /// Die anzuzeigende Klasse
  final Klasse klasse;

  /// Callback für "Bearbeiten" Button
  final VoidCallback onEdit;

  /// Callback für "Löschen" Button
  final VoidCallback onDelete;

  const KlasseCard({
    required this.klasse,
    required this.onEdit,
    required this.onDelete,
    super.key,
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
        trailing: canCreate
            ? Row(
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
              )
            : null,
      ),
    );
  }

  /// Farbe basierend auf Beruf
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
