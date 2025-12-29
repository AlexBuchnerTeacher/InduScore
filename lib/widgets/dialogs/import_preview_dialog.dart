import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/rbs_spacing.dart';
import '../../core/constants/rbs_typography.dart';
import '../../core/constants/rbs_colors.dart';
import '../../models/klasse.dart';
import '../../models/schuljahr.dart';
import '../../models/student.dart';
import '../../providers/firestore_service_provider.dart';
import '../../services/pdf_import_service.dart';
import 'merge_students_dialog.dart';

/// Dialog zur Vorschau und Bestätigung eines Klassen-Imports aus PDF.
///
/// Zeigt die geparsten Schüler an (bis zu 20) und ermöglicht:
/// - Manuelle Eingabe des Klassennamens
/// - Eingabe des Klassenleiters (optional)
/// - Anzeige ungültiger Zeilen
/// - Prüfung ob Klasse bereits existiert → MergeDialog
/// - Anlegen neuer Klasse mit Schülern
class ImportPreviewDialog extends ConsumerStatefulWidget {
  final ClassImportPreview preview;
  final Schuljahr schuljahr;

  const ImportPreviewDialog({
    super.key,
    required this.preview,
    required this.schuljahr,
  });

  @override
  ConsumerState<ImportPreviewDialog> createState() =>
      _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends ConsumerState<ImportPreviewDialog> {
  late final TextEditingController _klassenameController;
  late final TextEditingController _klassenleiterController;
  bool _isSaving = false;
  String? _klassenameError;

  @override
  void initState() {
    super.initState();
    _klassenameController = TextEditingController(
      text: widget.preview.suggestedName,
    );
    _klassenleiterController = TextEditingController();
  }

  @override
  void dispose() {
    _klassenameController.dispose();
    _klassenleiterController.dispose();
    super.dispose();
  }

  bool _validateKlassenname(String name) {
    final parsed = ParsedKlassenname.parse(name);
    if (parsed == null) {
      setState(
        () => _klassenameError = 'Ungültiges Format (erwartet: z.B. EAT321)',
      );
      return false;
    }
    setState(() => _klassenameError = null);
    return true;
  }

  Future<Klasse?> _findExistingKlasse(String name) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final allKlassen = await firestoreService.getKlassenForSchuljahr(
      widget.schuljahr,
    );
    return allKlassen.where((k) => k.name == name).firstOrNull;
  }

  Future<void> _performImport() async {
    final name = _klassenameController.text.trim();
    if (!_validateKlassenname(name)) return;

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Prüfen ob Klasse existiert
      final existingKlasse = await _findExistingKlasse(name);

      if (existingKlasse != null) {
        // Merge-Dialog zeigen
        final existingStudents = await firestoreService.getStudentsForKlasse(
          existingKlasse.id,
        );

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => MergeStudentsDialog(
            existingKlasse: existingKlasse,
            existingStudents: existingStudents,
            newStudents: widget.preview.students,
            schuljahr: widget.schuljahr,
          ),
        );

        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      // Eintrittsdatum abfragen
      if (!mounted) return;
      final eintrittsDatum = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: 'Eintrittsdatum für alle Schüler',
      );

      if (eintrittsDatum == null) {
        setState(() => _isSaving = false);
        return;
      }

      // Neue Klasse mit Schülern erstellen
      final now = DateTime.now();
      final parsed = ParsedKlassenname.parse(name)!;

      final newKlasse = Klasse(
        id: '',
        name: name,
        beruf: parsed.beruf,
        jahrgangsstufe: parsed.jahrgangsstufe,
        zeitgruppe: parsed.zeitgruppe,
        schuljahr: widget.schuljahr,
        klassenleiter: _klassenleiterController.text.trim().isEmpty
            ? null
            : _klassenleiterController.text.trim(),
        createdAt: now,
      );

      final students = widget.preview.students
          .map(
            (s) => Student(
              id: '',
              firstName: s.firstName,
              lastName: s.lastName,
              klasseId: '', // wird in Firestore gesetzt
              eintrittsDatum: eintrittsDatum,
              createdAt: now,
            ),
          )
          .toList();

      await firestoreService.importKlasseMitSchuelern(newKlasse, students);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Klasse $name mit ${students.length} Schülern importiert',
          ),
          backgroundColor: RBSColors.courtGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Import: $e'),
          backgroundColor: RBSColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Klasse importieren'),
      content: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Klassenname
              TextField(
                controller: _klassenameController,
                decoration: InputDecoration(
                  labelText: 'Klassenname *',
                  hintText: 'z.B. EAT321',
                  errorText: _klassenameError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) =>
                    _validateKlassenname(_klassenameController.text.trim()),
              ),
              const SizedBox(height: RBSSpacing.md),

              // Klassenleiter
              TextField(
                controller: _klassenleiterController,
                decoration: const InputDecoration(
                  labelText: 'Klassenleiter (optional)',
                  hintText: 'Kürzel des Klassenleiters',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: RBSSpacing.md),

              // Schüler-Vorschau
              Text(
                '${widget.preview.students.length} Schüler gefunden:',
                style: RBSTypography.label,
              ),
              const SizedBox(height: RBSSpacing.xs),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.preview.students.length > 20
                      ? 21 // 20 Einträge + "weitere"-Hinweis
                      : widget.preview.students.length,
                  itemBuilder: (context, index) {
                    if (index == 20) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '... und ${widget.preview.students.length - 20} weitere',
                          style: RBSTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    final student = widget.preview.students[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, size: 16),
                      title: Text(
                        '${student.lastName}, ${student.firstName}',
                        style: RBSTypography.bodySmall,
                      ),
                    );
                  },
                ),
              ),

              // Ungültige Zeilen
              if (widget.preview.invalidLines.isNotEmpty) ...[
                const SizedBox(height: RBSSpacing.md),
                ExpansionTile(
                  title: Text(
                    '${widget.preview.invalidLines.length} ungültige Zeilen',
                    style: RBSTypography.label.copyWith(
                      color: RBSColors.warning,
                    ),
                  ),
                  leading: const Icon(
                    Icons.warning_amber,
                    color: RBSColors.warning,
                  ),
                  children: widget.preview.invalidLines
                      .map(
                        (line) => ListTile(
                          dense: true,
                          title: Text(line, style: RBSTypography.bodySmall),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _performImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: RBSColors.textOnRed,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Importieren'),
        ),
      ],
    );
  }
}
