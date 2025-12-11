import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';
import '../models/klasse.dart';
import '../models/beruf.dart';
import '../models/student.dart';
import '../providers/app_providers.dart';
import '../services/pdf_import_service.dart';

class KlassenScreen extends ConsumerStatefulWidget {
  const KlassenScreen({super.key});

  @override
  ConsumerState<KlassenScreen> createState() => _KlassenScreenState();
}

class _KlassenScreenState extends ConsumerState<KlassenScreen> {
  String? _selectedBeruf;
  String? _selectedSchuljahr;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final filteredByZG = ref.watch(filteredKlassenProvider);
    final zeitgruppenFilter = ref.watch(zeitgruppenFilterProvider);
    final currentSchuljahr = ref.watch(currentSchuljahrProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        title: const Text('Klassenverwaltung'),
        actions: [
          // Import Button - deutlich sichtbar
          Padding(
            padding: const EdgeInsets.only(right: RBSSpacing.sm),
            child: _isImporting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _handlePdfImport,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'PDF Import',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showKlasseDialog(context),
            tooltip: 'Neue Klasse',
          ),
        ],
      ),
      drawer: const RBSDrawer(),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(RBSSpacing.md),
            color: RBSColors.paper,
            child: Wrap(
              spacing: RBSSpacing.sm,
              runSpacing: RBSSpacing.sm,
              children: [
                // Zeitgruppen Filter Chip (zeigt aktiven Filter)
                if (zeitgruppenFilter != null)
                  Chip(
                    label: Text('ZG$zeitgruppenFilter'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => ref.read(zeitgruppenFilterProvider.notifier).clearFilter(),
                    backgroundColor: RBSColors.courtGreen.withValues(alpha: 0.2),
                  ),
                // Schuljahr Filter
                RBSFilterChip(
                  label: _selectedSchuljahr ?? currentSchuljahr.toString(),
                  selected: _selectedSchuljahr != null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSchuljahr = selected
                          ? currentSchuljahr.toString()
                          : null;
                    });
                  },
                ),
                // Beruf Filter
                ...Beruf.values.map(
                  (beruf) => RBSFilterChip(
                    label: beruf.code,
                    selected: _selectedBeruf == beruf.code,
                    color: _getBerufColor(beruf),
                    onSelected: (selected) {
                      setState(() {
                        _selectedBeruf = selected ? beruf.code : null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Klassen List
          Expanded(
            child: klassenAsync.when(
              data: (klassen) {
                // Start with ZG-filtered classes
                var filteredKlassen = filteredByZG;
                if (_selectedSchuljahr != null) {
                  filteredKlassen = filteredKlassen
                      .where(
                        (k) => k.schuljahr.toString() == _selectedSchuljahr,
                      )
                      .toList();
                }
                if (_selectedBeruf != null) {
                  filteredKlassen = filteredKlassen
                      .where((k) => k.beruf.code == _selectedBeruf)
                      .toList();
                }

                if (filteredKlassen.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: RBSColors.textOnLight.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        Text(
                          'Keine Klassen gefunden',
                          style: RBSTypography.h4.copyWith(
                            color: RBSColors.textOnLight.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: RBSSpacing.sm),
                        RBSButton(
                          label: 'Erste Klasse erstellen',
                          icon: Icons.add,
                          onPressed: () => _showKlasseDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  itemCount: filteredKlassen.length,
                  itemBuilder: (context, index) {
                    final klasse = filteredKlassen[index];
                    return _buildKlasseCard(context, klasse);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Fehler: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKlasseCard(BuildContext context, Klasse klasse) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showKlasseDialog(context, klasse: klasse),
              tooltip: 'Bearbeiten',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, klasse),
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

  void _showKlasseDialog(BuildContext context, {Klasse? klasse}) {
    final isEdit = klasse != null;
    final klassenNameController = TextEditingController(
      text: klasse?.name ?? '',
    );
    final schuljahrController = TextEditingController(
      text:
          klasse?.schuljahr.toString() ??
          ref.read(currentSchuljahrProvider).toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => RBSDialog(
        title: isEdit ? 'Klasse bearbeiten' : 'Neue Klasse',
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Klassenname (z.B. EAT321)
              RBSInput(
                label: 'Klassenname',
                hint: 'EAT321 (Beruf + Stufe + Zeitgruppe + Nummer)',
                controller: klassenNameController,
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
                controller: schuljahrController,
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final rawName = klassenNameController.text.trim();
              final berufMatch = RegExp(r'^(IE|EAT|EBT|EGS)')
                  .firstMatch(rawName);
              if (berufMatch == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Klassenname ungültig')),
                );
                return;
              }
              final berufCode = berufMatch.group(0)!;
              final digits = rawName.substring(berufCode.length);

              // Sicheres Parsen der Bestandteile, sonst Abbruch mit Meldung
              if (digits.length != 3 || int.tryParse(digits) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Format: Beruf + 3 Ziffern, z.B. EAT321'),
                  ),
                );
                return;
              }
              final jahrgangsstufe = int.parse(digits[0]);
              final zeitgruppeNummer = int.parse(digits[1]);
              final laufendeNummer = int.parse(digits[2]);

              Zeitgruppe? zeitgruppe;
              try {
                zeitgruppe = Zeitgruppe.fromNummer(zeitgruppeNummer);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zeitgruppe muss 1-3 sein'),
                  ),
                );
                return;
              }

              final schuljahrText = schuljahrController.text.trim();
              Schuljahr schuljahr;
              try {
                schuljahr = Schuljahr.fromString(schuljahrText);
              } on FormatException {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schuljahr-Format: YYYY/YY (z.B. 2024/25)'),
                  ),
                );
                return;
              }

              try {
                final firestoreService = ref.read(firestoreServiceProvider);
                final newKlasse = Klasse(
                  id: klasse?.id ?? '',
                  beruf: Beruf.fromCode(berufCode),
                  jahrgangsstufe: jahrgangsstufe,
                  zeitgruppe: zeitgruppe,
                  laufendeNummer: laufendeNummer,
                  schuljahr: schuljahr,
                  createdAt: klasse?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (isEdit) {
                  await firestoreService.updateKlasse(newKlasse);
                } else {
                  await firestoreService.createKlasse(newKlasse);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Klasse aktualisiert' : 'Klasse erstellt',
                      ),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, Klasse klasse) {
    showDialog(
      context: context,
      builder: (context) => RBSDialog(
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
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.deleteKlasse(klasse.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Klasse gelöscht'),
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
      ),
    );
  }

  Future<void> _handlePdfImport() async {
    final schuljahr = ref.read(currentSchuljahrProvider);
    try {
      setState(() => _isImporting = true);
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (picked == null) return;
      final file = picked.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF konnte nicht gelesen werden.')),
          );
        }
        return;
      }

      final importService = PdfImportService();
      final preview = await importService.parseClassList(bytes);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _ImportPreviewDialog(
          preview: preview,
          schuljahr: schuljahr,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

class _ImportPreviewDialog extends ConsumerStatefulWidget {
  final ClassImportPreview preview;
  final Schuljahr schuljahr;

  const _ImportPreviewDialog({
    required this.preview,
    required this.schuljahr,
  });

  @override
  ConsumerState<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends ConsumerState<_ImportPreviewDialog> {
  bool _isSaving = false;
  late TextEditingController _klassenameController;
  late TextEditingController _klassenleiterController;
  String? _klassenameError;

  @override
  void initState() {
    super.initState();
    _klassenameController = TextEditingController(
      text: widget.preview.rawClassName ?? '',
    );
    _klassenleiterController = TextEditingController(
      text: widget.preview.klassenleiterCode ?? '',
    );
  }

  @override
  void dispose() {
    _klassenameController.dispose();
    _klassenleiterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final students = preview.students;
    final needsManualInput = preview.needsManualClassName;

    return AlertDialog(
      title: const Text('Klassenliste importieren'),
      content: SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Klassenname - editierbar wenn nicht erkannt
              if (needsManualInput) ...[
                Container(
                  padding: const EdgeInsets.all(RBSSpacing.sm),
                  decoration: BoxDecoration(
                    color: RBSColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RBSColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: RBSColors.warning),
                      const SizedBox(width: RBSSpacing.sm),
                      Expanded(
                        child: Text(
                          'Klassenname nicht erkannt. Bitte manuell eingeben:',
                          style: RBSTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RBSSpacing.sm),
              ],
              TextField(
                controller: _klassenameController,
                decoration: InputDecoration(
                  labelText: 'Klassenname',
                  hintText: 'z.B. EAT331',
                  errorText: _klassenameError,
                  prefixIcon: const Icon(Icons.class_),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _klassenameError = null),
              ),
              const SizedBox(height: RBSSpacing.sm),
              TextField(
                controller: _klassenleiterController,
                decoration: const InputDecoration(
                  labelText: 'Klassenleiter (optional)',
                  hintText: 'z.B. BUC',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: RBSSpacing.md),
              Text(
                'Gefundene Schüler (${students.length}):',
                style: RBSTypography.bodyMedium,
              ),
              const SizedBox(height: RBSSpacing.xs),
              if (students.isEmpty)
                Container(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  decoration: BoxDecoration(
                    color: RBSColors.offwhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Keine Schüler erkannt. Sie können nach dem Import manuell hinzugefügt werden.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...students.take(20).map((s) => ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: Text('${s.lastName}, ${s.firstName}'),
                    )),
              if (students.length > 20)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '... und ${students.length - 20} weitere',
                    style: RBSTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              if (preview.invalidLines.isNotEmpty) ...[
                const SizedBox(height: RBSSpacing.sm),
                ExpansionTile(
                  title: Text(
                    'Nicht erkannte Zeilen (${preview.invalidLines.length})',
                    style: RBSTypography.bodySmall,
                  ),
                  children: preview.invalidLines.take(10)
                      .map((l) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: RBSSpacing.md,
                              vertical: 2,
                            ),
                            child: Text(
                              l,
                              style: RBSTypography.bodySmall
                                  .copyWith(color: Colors.grey),
                            ),
                          ))
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
          onPressed: _isSaving ? null : _importNow,
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
              : const Text('Import durchführen'),
        ),
      ],
    );
  }

  Future<void> _importNow() async {
    // Validiere Klassennamen
    final klassenname = _klassenameController.text.trim().toUpperCase();
    if (klassenname.isEmpty) {
      setState(() => _klassenameError = 'Klassenname erforderlich');
      return;
    }
    
    // Versuche Klassenname zu parsen
    ParsedKlassenname parsed;
    try {
      parsed = ParsedKlassenname.parse(klassenname);
    } catch (e) {
      setState(() => _klassenameError = 'Ungültiges Format (z.B. EAT331)');
      return;
    }

    final preview = widget.preview;
    final firestoreService = ref.read(firestoreServiceProvider);
    final now = DateTime.now();

    try {
      setState(() => _isSaving = true);

      // Prüfe ob Klasse bereits existiert
      final existingKlasse = await firestoreService.findExistingKlasse(
        berufCode: parsed.beruf.code,
        jahrgangsstufe: parsed.jahrgangsstufe,
        zeitgruppeNummer: parsed.zeitgruppe.nummer,
        laufendeNummer: parsed.laufendeNummer,
        schuljahr: widget.schuljahr.toString(),
      );

      if (existingKlasse != null) {
        // Klasse existiert -> Merge-Dialog anzeigen
        if (!mounted) return;
        setState(() => _isSaving = false);
        
        final existingStudents = await firestoreService.getStudentsByKlasseOnce(existingKlasse.id);
        
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _MergeDialog(
            existingKlasse: existingKlasse,
            existingStudents: existingStudents,
            newStudents: preview.students,
            schuljahr: widget.schuljahr,
          ),
        );
        
        if (mounted) Navigator.pop(context);
        return;
      }

      // Neue Klasse anlegen
      final klasse = Klasse(
        id: '',
        beruf: parsed.beruf,
        jahrgangsstufe: parsed.jahrgangsstufe,
        zeitgruppe: parsed.zeitgruppe,
        laufendeNummer: parsed.laufendeNummer,
        schuljahr: widget.schuljahr,
        createdAt: now,
        updatedAt: now,
      );

      // Eintrittsdatum abfragen
      if (!mounted) return;
      final eintrittsDatum = await _askForEintrittsDatum(context, now);
      if (eintrittsDatum == null) {
        setState(() => _isSaving = false);
        return; // Abgebrochen
      }

      final students = preview.students
          .map((s) => Student(
                id: '',
                firstName: s.firstName,
                lastName: s.lastName,
                klasseId: '',
                eintrittsDatum: eintrittsDatum,
                createdAt: now,
              ))
          .toList();

      await firestoreService.importKlasseMitSchuelern(
        klasse: klasse,
        schueler: students,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Klasse ${klasse.name} mit ${students.length} Schülern importiert.'),
          backgroundColor: RBSColors.courtGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import fehlgeschlagen: $e'),
          backgroundColor: RBSColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<DateTime?> _askForEintrittsDatum(BuildContext context, DateTime defaultDate) async {
    return showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Eintrittsdatum der Schüler',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
  }
}

/// Dialog für das Zusammenführen von Schülern bei existierender Klasse
class _MergeDialog extends ConsumerStatefulWidget {
  final Klasse existingKlasse;
  final List<Student> existingStudents;
  final List<ImportedStudent> newStudents;
  final Schuljahr schuljahr;

  const _MergeDialog({
    required this.existingKlasse,
    required this.existingStudents,
    required this.newStudents,
    required this.schuljahr,
  });

  @override
  ConsumerState<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<_MergeDialog> {
  bool _isSaving = false;
  DateTime _eintrittsDatum = DateTime.now();
  
  // Manuelles Matching: Key = "vorname nachname" (lowercase), Value = existing Student ID
  final Map<String, String> _manualMatching = {};
  
  // Berechnete Listen
  late List<_MatchedStudent> _matched;
  late List<ImportedStudent> _newOnly;
  late List<Student> _missing;

  @override
  void initState() {
    super.initState();
    _calculateMatches();
  }

  void _calculateMatches() {
    _matched = [];
    _newOnly = [];
    _missing = [];
    
    final matchedExistingIds = <String>{};
    
    for (final newStudent in widget.newStudents) {
      final key = '${newStudent.firstName.toLowerCase()} ${newStudent.lastName.toLowerCase()}';
      
      // Manuelles Matching?
      if (_manualMatching.containsKey(key)) {
        final existingId = _manualMatching[key]!;
        final existing = widget.existingStudents.firstWhere((s) => s.id == existingId);
        _matched.add(_MatchedStudent(newStudent: newStudent, existingStudent: existing, isManual: true));
        matchedExistingIds.add(existingId);
        continue;
      }
      
      // Automatisches Matching nach Name
      final existing = widget.existingStudents.where((e) => 
        e.firstName.toLowerCase() == newStudent.firstName.toLowerCase() &&
        e.lastName.toLowerCase() == newStudent.lastName.toLowerCase()
      ).firstOrNull;
      
      if (existing != null) {
        _matched.add(_MatchedStudent(newStudent: newStudent, existingStudent: existing, isManual: false));
        matchedExistingIds.add(existing.id);
      } else {
        _newOnly.add(newStudent);
      }
    }
    
    // Fehlende (existierende ohne Match)
    for (final existing in widget.existingStudents) {
      if (!matchedExistingIds.contains(existing.id)) {
        _missing.add(existing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return AlertDialog(
      title: Text('Klasse ${widget.existingKlasse.name} existiert bereits'),
      content: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Box
              Container(
                padding: const EdgeInsets.all(RBSSpacing.sm),
                decoration: BoxDecoration(
                  color: RBSColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RBSColors.info),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: RBSColors.info),
                    const SizedBox(width: RBSSpacing.sm),
                    Expanded(
                      child: Text(
                        'Die Klasse hat bereits ${widget.existingStudents.length} Schüler. '
                        'Bestehende Schüler werden beibehalten, neue hinzugefügt.',
                        style: RBSTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RBSSpacing.md),
              
              // Eintrittsdatum für neue Schüler
              if (_newOnly.isNotEmpty) ...[
                Text('Eintrittsdatum für neue Schüler:', style: RBSTypography.label),
                const SizedBox(height: RBSSpacing.xs),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _eintrittsDatum,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _eintrittsDatum = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(dateFormat.format(_eintrittsDatum)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RBSSpacing.md),
              ],
              
              // Matched Students (grün)
              if (_matched.isNotEmpty) ...[
                _buildSectionHeader(
                  'Erkannte Schüler (${_matched.length})',
                  Icons.check_circle,
                  RBSColors.courtGreen,
                ),
                ...(_matched.take(10).map((m) => ListTile(
                  dense: true,
                  leading: Icon(
                    m.isManual ? Icons.link : Icons.check,
                    color: RBSColors.courtGreen,
                    size: 20,
                  ),
                  title: Text('${m.newStudent.lastName}, ${m.newStudent.firstName}'),
                  subtitle: m.isManual 
                      ? Text('Manuell: ${m.existingStudent.displayName}', 
                          style: const TextStyle(fontStyle: FontStyle.italic))
                      : null,
                ))),
                if (_matched.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text('... und ${_matched.length - 10} weitere',
                        style: RBSTypography.bodySmall),
                  ),
                const SizedBox(height: RBSSpacing.sm),
              ],
              
              // New Students (blau)
              if (_newOnly.isNotEmpty) ...[
                _buildSectionHeader(
                  'Neue Schüler (${_newOnly.length})',
                  Icons.person_add,
                  RBSColors.info,
                ),
                ...(_newOnly.map((s) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_add, color: RBSColors.info, size: 20),
                  title: Text('${s.lastName}, ${s.firstName}'),
                  trailing: _missing.isNotEmpty 
                      ? _buildMatchDropdown(s)
                      : null,
                ))),
                const SizedBox(height: RBSSpacing.sm),
              ],
              
              // Missing Students (orange/rot)
              if (_missing.isNotEmpty) ...[
                _buildSectionHeader(
                  'Nicht mehr im PDF (${_missing.length})',
                  Icons.warning_amber,
                  RBSColors.warning,
                ),
                ...(_missing.map((s) => ListTile(
                  dense: true,
                  leading: Tooltip(
                    message: 'Eintritt: ${dateFormat.format(s.eintrittsDatum)}',
                    child: const Icon(Icons.warning_amber, color: RBSColors.warning, size: 20),
                  ),
                  title: Text(s.displayName),
                  subtitle: const Text('Wird als ausgetreten markiert?'),
                ))),
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
        if (_missing.isNotEmpty)
          TextButton(
            onPressed: _isSaving ? null : () => _performMerge(markMissingAsAusgetreten: false),
            child: const Text('Nur neue hinzufügen'),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _performMerge(markMissingAsAusgetreten: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: RBSColors.dynamicRed,
            foregroundColor: RBSColors.textOnRed,
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_missing.isNotEmpty ? 'Übernehmen & Austritte markieren' : 'Übernehmen'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RBSSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: RBSSpacing.xs),
          Text(title, style: RBSTypography.label.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildMatchDropdown(ImportedStudent newStudent) {
    final key = '${newStudent.firstName.toLowerCase()} ${newStudent.lastName.toLowerCase()}';
    final currentMatch = _manualMatching[key];
    
    return DropdownButton<String?>(
      value: currentMatch,
      hint: const Text('Zuordnen...', style: TextStyle(fontSize: 12)),
      underline: const SizedBox(),
      isDense: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Neuer Schüler', style: TextStyle(fontSize: 12)),
        ),
        ..._missing.map((existing) => DropdownMenuItem(
          value: existing.id,
          child: Text(existing.displayName, style: const TextStyle(fontSize: 12)),
        )),
      ],
      onChanged: (value) {
        setState(() {
          if (value == null) {
            _manualMatching.remove(key);
          } else {
            _manualMatching[key] = value;
          }
          _calculateMatches();
        });
      },
    );
  }

  Future<void> _performMerge({required bool markMissingAsAusgetreten}) async {
    try {
      setState(() => _isSaving = true);
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();
      
      // Neue Schüler erstellen
      final newStudentsToAdd = _newOnly.map((s) => Student(
        id: '',
        firstName: s.firstName,
        lastName: s.lastName,
        klasseId: widget.existingKlasse.id,
        eintrittsDatum: _eintrittsDatum,
        createdAt: now,
      )).toList();
      
      // Merge durchführen
      final result = await firestoreService.mergeStudentsIntoKlasse(
        klasseId: widget.existingKlasse.id,
        neueSchueler: newStudentsToAdd,
        existierendeSchueler: widget.existingStudents,
        manuellesMatching: _manualMatching,
      );
      
      // Fehlende als ausgetreten markieren
      if (markMissingAsAusgetreten && result.unmatched.isNotEmpty) {
        await firestoreService.markStudentsAsAusgetreten(
          result.unmatched.map((s) => s.id).toList(),
          now,
        );
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      
      final message = StringBuffer('Import abgeschlossen: ');
      if (result.added.isNotEmpty) {
        message.write('${result.added.length} neue Schüler');
      }
      if (markMissingAsAusgetreten && result.unmatched.isNotEmpty) {
        if (result.added.isNotEmpty) message.write(', ');
        message.write('${result.unmatched.length} als ausgetreten markiert');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.toString()),
          backgroundColor: RBSColors.courtGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: RBSColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MatchedStudent {
  final ImportedStudent newStudent;
  final Student existingStudent;
  final bool isManual;

  _MatchedStudent({
    required this.newStudent,
    required this.existingStudent,
    required this.isManual,
  });
}