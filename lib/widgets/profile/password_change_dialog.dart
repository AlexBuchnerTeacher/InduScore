import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';

/// Dialog zum Passwort ändern mit Re-Authentifizierung
/// 
/// Fordert den User auf:
/// 1. Aktuelles Passwort eingeben (zur Re-Authentifizierung)
/// 2. Neues Passwort eingeben (mind. 6 Zeichen)
/// 3. Neues Passwort bestätigen
/// 
/// Zeigt Erfolg/Fehler über SnackBars an.
class PasswordChangeDialog extends StatefulWidget {
  /// Der AuthService für Passwort-Änderung
  final AuthService authService;

  const PasswordChangeDialog({super.key, required this.authService});

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      // Erfolg - Dialog schließen und SnackBar zeigen
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwort erfolgreich geändert'),
          backgroundColor: RBSColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      // Fehler anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: RBSColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: RBSColors.dynamicRed),
          SizedBox(width: RBSSpacing.sm),
          Text(
            'Passwort ändern',
            style: TextStyle(
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RBSInput(
                label: 'Aktuelles Passwort',
                controller: _currentPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte aktuelles Passwort eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: RBSSpacing.md),
              RBSInput(
                label: 'Neues Passwort',
                controller: _newPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_open,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte neues Passwort eingeben';
                  }
                  if (value.length < 6) {
                    return 'Passwort muss mindestens 6 Zeichen lang sein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: RBSSpacing.md),
              RBSInput(
                label: 'Passwort bestätigen',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.check,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Passwort bestätigen';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwörter stimmen nicht überein';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        RBSButton(
          label: 'Passwort ändern',
          onPressed: _isLoading ? null : _changePassword,
          isLoading: _isLoading,
          icon: Icons.save,
        ),
      ],
    );
  }
}
