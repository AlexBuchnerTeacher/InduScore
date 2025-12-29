import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rbs_theme.dart';
import '../../core/widgets/rbs_components.dart';
import '../../models/klasse.dart';
import '../../models/beruf.dart';
import '../../providers/app_providers.dart';

/// Dialog for creating or editing a Klasse
class KlasseEditDialog extends ConsumerStatefulWidget {
  final Klasse? klasse;

  const KlasseEditDialog({super.key, this.klasse});

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
          ref.read(currentSchuljahrProvider).toString(),
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
            // Klassenname (z.B. EAT321)
            RBSInput(
              label: 'Klassenname',
              hint: 'EAT321 (Beruf + Stufe + Zeitgruppe + Nummer)',
              controller: _klassenNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Klassenname eingeben';
                }
                // Validierung: Min. 5 Zeichen (z.B. IE321 oder EAT321)
                if (value.length < 5) {
                  return 'Format: z.B. EAT321';
                }
                // Prüfe ob Beruf-Code existiert
                final berufMatch = RegExp(
                  r'^(IE|EAT|EBT|EGS)',
                ).firstMatch(value);
                if (berufMatch == null) {
                  return 'Beruf muss IE, EAT, EBT oder EGS sein';
                }
                // Prüfe Ziffern
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
          onPressed: _handleSave,
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rawName = _klassenNameController.text.trim();
    final berufMatch = RegExp(
      r'^(IE|EAT|EBT|EGS)',
    ).firstMatch(rawName);
    if (berufMatch == null) {
      _showError('Klassenname ungültig');
      return;
    }
    final berufCode = berufMatch.group(0)!;
    final digits = rawName.substring(berufCode.length);

    // Sicheres Parsen der Bestandteile, sonst Abbruch mit Meldung
    if (digits.length != 3 || int.tryParse(digits) == null) {
      _showError('Format: Beruf + 3 Ziffern, z.B. EAT321');
      return;
    }
    final jahrgangsstufe = int.parse(digits[0]);
    final zeitgruppeNummer = int.parse(digits[1]);
    final laufendeNummer = int.parse(digits[2]);

    Zeitgruppe? zeitgruppe;
    try {
      zeitgruppe = Zeitgruppe.fromNummer(zeitgruppeNummer);
    } catch (_) {
      _showError('Zeitgruppe muss 1-3 sein');
      return;
    }

    final schuljahrText = _schuljahrController.text.trim();
    Schuljahr schuljahr;
    try {
      schuljahr = Schuljahr.fromString(schuljahrText);
    } on FormatException {
      _showError('Schuljahr-Format: YYYY/YY (z.B. 2024/25)');
      return;
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
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

      if (widget.klasse != null) {
        await firestoreService.updateKlasse(newKlasse);
      } else {
        await firestoreService.createKlasse(newKlasse);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.klasse != null ? 'Klasse aktualisiert' : 'Klasse erstellt',
            ),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      _showError('Fehler: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: RBSColors.dynamicRed,
        ),
      );
    }
  }
}
