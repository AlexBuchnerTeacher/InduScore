import 'package:flutter/material.dart';
import 'package:induscore/core/theme/rbs_theme.dart';

/// Einheitliche SnackBar-Typen für die gesamte App.
///
/// Stellt konsistente Erfolgs-, Fehler-, Warn- und Info-Meldungen bereit.
/// Verwendet RBS-Styleguide-Farben für visuelles Feedback.
///
/// Beispiel:
/// ```dart
/// AppSnackBars.showSuccess(context, 'Gespeichert!');
/// AppSnackBars.showError(context, 'Fehler beim Speichern');
/// ```
class AppSnackBars {
  AppSnackBars._(); // Prevent instantiation

  /// Standard-Dauer für SnackBars (3 Sekunden)
  static const Duration defaultDuration = Duration(seconds: 3);

  /// Längere Dauer für wichtige Meldungen (5 Sekunden)
  static const Duration longDuration = Duration(seconds: 5);

  /// Zeigt eine Erfolgs-SnackBar (grün)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: RBSColors.success,
      icon: Icons.check_circle_outline,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Zeigt eine Fehler-SnackBar (rot)
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
    Object? error,
  }) {
    final displayMessage = error != null ? '$message: $error' : message;
    _show(
      context,
      message: displayMessage,
      backgroundColor: RBSColors.error,
      icon: Icons.error_outline,
      duration: duration ?? longDuration,
      action: action,
    );
  }

  /// Zeigt eine Warn-SnackBar (orange)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: RBSColors.warning,
      icon: Icons.warning_amber_outlined,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Zeigt eine Info-SnackBar (blau)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: RBSColors.info,
      icon: Icons.info_outline,
      duration: duration ?? defaultDuration,
      action: action,
    );
  }

  /// Zeigt eine einfache SnackBar ohne Styling
  static void showSimple(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? defaultDuration,
      ),
    );
  }

  /// Interne Methode zum Anzeigen einer styled SnackBar
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // Vorherige SnackBar verstecken
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: action,
      ),
    );
  }

  /// Erstellt eine SnackBarAction für "Rückgängig"
  static SnackBarAction undoAction({
    required VoidCallback onPressed,
    String label = 'Rückgängig',
  }) {
    return SnackBarAction(
      label: label,
      textColor: Colors.white,
      onPressed: onPressed,
    );
  }

  /// Erstellt eine SnackBarAction für "Details"
  static SnackBarAction detailsAction({
    required VoidCallback onPressed,
    String label = 'Details',
  }) {
    return SnackBarAction(
      label: label,
      textColor: Colors.white,
      onPressed: onPressed,
    );
  }
}
