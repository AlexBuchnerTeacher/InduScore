import 'package:flutter/material.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/klasse.dart';

/// Bestätigungsdialog zum Löschen einer Klasse
///
/// Warnt dass alle zugehörigen Leistungsnachweise ebenfalls gelöscht werden.
/// Callback onDelete wird bei Bestätigung aufgerufen.
class KlasseDeleteDialog extends StatelessWidget {
  /// Die zu löschende Klasse
  final Klasse klasse;

  /// Callback beim Löschen
  final Future<void> Function() onDelete;

  const KlasseDeleteDialog({
    required this.klasse,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          onPressed: () async {
            try {
              await onDelete();

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
          },
        ),
      ],
    );
  }
}
