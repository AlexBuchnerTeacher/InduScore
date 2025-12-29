import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/klasse.dart';
import '../../providers/app_providers.dart';

/// Confirmation dialog for deleting a Klasse
class KlasseDeleteDialog extends ConsumerWidget {
  final Klasse klasse;

  const KlasseDeleteDialog({super.key, required this.klasse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RBSDialog(
      title: 'Klasse löschen?',
      content: Text(
        'Möchten Sie die Klasse "${klasse.name}" wirklich löschen?\n\nAlle zugehörigen Leistungsnachweise werden ebenfalls gelöscht.',
        style: RBSTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        RBSButton(
          label: 'Löschen',
          onPressed: () => _handleDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteKlasse(klasse.id);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klasse gelöscht'),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: RBSColors.dynamicRed,
          ),
        );
      }
    }
  }
}
