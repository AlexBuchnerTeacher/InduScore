import 'package:flutter/material.dart';
import '../../core/theme/rbs_theme.dart';

/// Wiederverwendbare Dialog-Builder für häufige Dialog-Muster
class CommonDialogs {
  CommonDialogs._();

  /// Standard Bestätigungs-Dialog
  ///
  /// Zeigt einen Dialog mit Titel, Nachricht und Abbrechen/Bestätigen-Buttons.
  /// Führt [onConfirm] aus wenn bestätigt wird.
  static Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Bestätigen',
    String cancelText = 'Abbrechen',
    Color? confirmColor,
    bool isDangerous = false,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDangerous
                  ? RBSColors.error
                  : (confirmColor ?? RBSColors.dynamicRed),
              foregroundColor: RBSColors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Lösch-Bestätigungs-Dialog (rot, gefährlich)
  ///
  /// Spezialfall des Bestätigungs-Dialogs für Lösch-Operationen.
  /// Zeigt rote Warnung und führt async [onDelete] aus.
  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String itemName,
    required Future<void> Function() onDelete,
    String? additionalWarning,
    String confirmText = 'Löschen',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          'Möchten Sie "$itemName" wirklich löschen?'
          '${additionalWarning != null ? '\n\n$additionalWarning' : ''}\n\n'
          'Dies kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await onDelete();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: RBSColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RBSColors.error,
              foregroundColor: RBSColors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Info-Dialog (nur Anzeige, keine Aktion)
  ///
  /// Zeigt eine Info-Nachricht mit OK-Button.
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String closeText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(closeText),
          ),
        ],
      ),
    );
  }

  /// Fehler-Dialog (rot)
  ///
  /// Zeigt eine Fehlermeldung in roter Farbe.
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String error,
    String closeText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: RBSColors.error),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(error),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: RBSColors.error,
              foregroundColor: RBSColors.white,
            ),
            child: Text(closeText),
          ),
        ],
      ),
    );
  }

  /// Erfolg-Dialog (grün)
  ///
  /// Zeigt eine Erfolgsmeldung in grüner Farbe.
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String closeText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: RBSColors.courtGreen),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: RBSColors.courtGreen,
              foregroundColor: RBSColors.white,
            ),
            child: Text(closeText),
          ),
        ],
      ),
    );
  }

  /// Eingabe-Dialog (TextField)
  ///
  /// Zeigt Dialog mit TextField und gibt eingegebenen Text zurück.
  /// Returns null wenn abgebrochen.
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String label,
    String? initialValue,
    String? hintText,
    String confirmText = 'OK',
    String cancelText = 'Abbrechen',
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            validator: validator,
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
