import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
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
    final currentSchuljahr = ref.watch(currentSchuljahrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klassenverwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showKlasseDialog(context),
            tooltip: 'Neue Klasse',
          ),
          IconButton(
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            onPressed: _isImporting ? null : _handlePdfImport,
            tooltip: 'Klasseliste importieren (PDF)',
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
                // Apply filters
                var filteredKlassen = klassen;
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
        onTap: () => context.go('/noten/klasse/${klasse.id}'),
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
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text('${s.lastName}, ${s.firstName}'),
                    );
                  },
                ),
              ),
            if (preview.invalidLines.isNotEmpty) ...[
              const SizedBox(height: RBSSpacing.sm),
              ExpansionTile(
                title: Text(
                  'Nicht erkannte Zeilen (${preview.invalidLines.length})',
                  style: RBSTypography.bodySmall,
                ),
                children: preview.invalidLines
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
    try {
      setState(() => _isSaving = true);
      final firestoreService = ref.read(firestoreServiceProvider);
      
      final klasse = Klasse(
        id: '',
        beruf: parsed.beruf,
        jahrgangsstufe: parsed.jahrgangsstufe,
        zeitgruppe: parsed.zeitgruppe,
        laufendeNummer: parsed.laufendeNummer,
        schuljahr: widget.schuljahr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final students = preview.students
          .asMap()
          .entries
          .map(
            (entry) => Student(
              id: '',
              pseudonym: Student.generatePseudonym(entry.key),
              firstName: entry.value.firstName,
              lastName: entry.value.lastName,
              klasseId: '', // Will be set by importKlasseMitSchuelern
              createdAt: DateTime.now(),
            ),
          )
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
}






