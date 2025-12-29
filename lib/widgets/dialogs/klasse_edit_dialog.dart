import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/klasse.dart';
import '../../models/beruf.dart';

/// Dialog zum Erstellen oder Bearbeiten einer Klasse
///
/// Validiert Klassenname-Format (z.B. EAT321):
/// - Beruf-Code (IE, EAT, EBT, EGS)
/// - Jahrgangsstufe (1-4)
/// - Zeitgruppe (1-3)
/// - Laufende Nummer (0-9)
///
/// Callback onSave wird mit der neuen/aktualisierten Klasse aufgerufen.
class KlasseEditDialog extends ConsumerStatefulWidget {
  /// Die zu bearbeitende Klasse (null = neue Klasse)
  final Klasse? klasse;

  /// Aktuelles Schuljahr als Default
  final Schuljahr currentSchuljahr;

  /// Callback beim Speichern - gibt die neue/aktualisierte Klasse zurück
  final Future<void> Function(Klasse klasse) onSave;

  const KlasseEditDialog({
    required this.onSave,
    required this.currentSchuljahr,
    this.klasse,
    super.key,
  });

  @override
  ConsumerState<KlasseEditDialog> createState() => _KlasseEditDialogState();
}

class _KlasseEditDialogState extends ConsumerState<KlasseEditDialog> {
  late final TextEditingController _klassenNameController;
  late final TextEditingController _schuljahrController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _klassenNameController = TextEditingController(
      text: widget.klasse?.name ?? '',
    );
    _schuljahrController = TextEditingController(
      text: widget.klasse?.schuljahr.toString() ??
          widget.currentSchuljahr.toString(),
    );
  }

  @override
  void dispose() {
    _klassenNameController.dispose();
    _schuljahrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.klasse != null;

    return RBSDialog(
      title: isEdit ? 'Klasse bearbeiten' : 'Neue Klasse',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Klassenname
            RBSInput(
              label: 'Klassenname',
              hint: 'EAT321 (Beruf + Stufe + Zeitgruppe + Nummer)',
              controller: _klassenNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Klassenname eingeben';
                }
                if (value.length < 5) return 'Format: z.B. EAT321';

                final berufMatch = RegExp(r'^(IE|EAT|EBT|EGS)').firstMatch(value);
                if (berufMatch == null) {
                  return 'Beruf muss IE, EAT, EBT oder EGS sein';
                }

                final rest = value.substring(berufMatch.group(0)!.length);
                if (rest.length != 3 || int.tryParse(rest) == null) {
                  return 'Nach Beruf müssen 3 Ziffern folgen';
                }
                return null;
              },
            ),
            const SizedBox(height: RBSSpacing.md),

            // Schuljahr
            RBSInput(
              label: 'Schuljahr',
              hint: '2024/25',
              controller: _schuljahrController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Schuljahr eingeben';
                }
                try {
                  Schuljahr.fromString(value);
                  return null;
                } catch (e) {
                  return 'Format: YYYY/YY (z.B. 2024/25)';
                }
              },
            ),
            const SizedBox(height: RBSSpacing.sm),

            // Hilfetext
            Text(
              'Beispiel: EAT321\n'
              'EAT = Beruf\n'
              '3 = Jahrgangsstufe (1-4)\n'
              '2 = Zeitgruppe (1-3)\n'
              '1 = Laufende Nummer',
              style: RBSTypography.bodySmall.copyWith(
                color: RBSColors.textOnLight.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        RBSButton(
          label: isEdit ? 'Speichern' : 'Erstellen',
          onPressed: () => _handleSave(context, isEdit),
        ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context, bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    final rawName = _klassenNameController.text.trim();
    final berufMatch = RegExp(r'^(IE|EAT|EBT|EGS)').firstMatch(rawName);

    if (berufMatch == null) {
      _showError(context, 'Klassenname ungültig');
      return;
    }

    final berufCode = berufMatch.group(0)!;
    final digits = rawName.substring(berufCode.length);

    if (digits.length != 3 || int.tryParse(digits) == null) {
      _showError(context, 'Format: Beruf + 3 Ziffern, z.B. EAT321');
      return;
    }

    final jahrgangsstufe = int.parse(digits[0]);
    final zeitgruppeNummer = int.parse(digits[1]);
    final laufendeNummer = int.parse(digits[2]);

    Zeitgruppe? zeitgruppe;
    try {
      zeitgruppe = Zeitgruppe.fromNummer(zeitgruppeNummer);
    } catch (_) {
      _showError(context, 'Zeitgruppe muss 1-3 sein');
      return;
    }

    Schuljahr schuljahr;
    try {
      schuljahr = Schuljahr.fromString(_schuljahrController.text.trim());
    } on FormatException {
      _showError(context, 'Schuljahr-Format: YYYY/YY (z.B. 2024/25)');
      return;
    }

    try {
      final newKlasse = Klasse(
        id: widget.klasse?.id ?? '',
        beruf: Beruf.fromCode(berufCode),
        jahrgangsstufe: jahrgangsstufe,
        zeitgruppe: zeitgruppe,
        laufendeNummer: laufendeNummer,
        schuljahr: schuljahr,
        createdAt: widget.klasse?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.onSave(newKlasse);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Klasse aktualisiert' : 'Klasse erstellt'),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Fehler: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RBSColors.dynamicRed,
      ),
    );
  }
}
