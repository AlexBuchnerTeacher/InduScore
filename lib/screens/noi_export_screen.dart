import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../services/noi_export_service.dart';
import '../models/klasse.dart';

/// NOI Export Screen - Export von Zeugnisnoten im XML/CSV Format
class NoiExportScreen extends ConsumerStatefulWidget {
  const NoiExportScreen({super.key});

  @override
  ConsumerState<NoiExportScreen> createState() => _NoiExportScreenState();
}

class _NoiExportScreenState extends ConsumerState<NoiExportScreen> {
  String? _selectedKlasseId;
  int _selectedHalbjahr = 1;
  String _selectedFormat = 'xml';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final klassenAsync = ref.watch(klassenProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final leistungsnachweiseAsync = ref.watch(leistungsnachweiseProvider);
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOI Export'),
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RBSSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const RBSHeadline(
                  text: 'Zeugnisnoten exportieren',
                  level: RBSHeadlineLevel.h2,
                ),
                const SizedBox(height: RBSSpacing.sm),
                Text(
                  'Exportiere Zeugnisnoten im NOI-Format für den Import in das offizielle Notenverwaltungssystem.',
                  style: RBSTypography.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: RBSSpacing.xl),

                // Klasse auswählen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(RBSSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, color: RBSColors.dynamicRed),
                            const SizedBox(width: RBSSpacing.sm),
                            Text('Klasse auswählen', style: RBSTypography.label),
                          ],
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        klassenAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, s) => Text('Fehler: $e'),
                          data: (klassen) => DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Klasse wählen',
                            ),
                            items: klassen.map((k) => DropdownMenuItem(
                              value: k.id,
                              child: Text('${k.name} (${k.schuljahr})'),
                            )).toList(),
                            onChanged: (value) {
                              setState(() => _selectedKlasseId = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RBSSpacing.md),

                // Halbjahr auswählen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(RBSSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: RBSColors.courtGreen),
                            const SizedBox(width: RBSSpacing.sm),
                            Text('Halbjahr', style: RBSTypography.label),
                          ],
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1. Halbjahr')),
                            ButtonSegment(value: 2, label: Text('2. Halbjahr')),
                          ],
                          selected: {_selectedHalbjahr},
                          onSelectionChanged: (value) {
                            setState(() => _selectedHalbjahr = value.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RBSSpacing.md),

                // Format auswählen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(RBSSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.file_present, color: RBSColors.growingElder),
                            const SizedBox(width: RBSSpacing.sm),
                            Text('Export-Format', style: RBSTypography.label),
                          ],
                        ),
                        const SizedBox(height: RBSSpacing.md),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'xml',
                              label: Text('XML'),
                              icon: Icon(Icons.code),
                            ),
                            ButtonSegment(
                              value: 'csv',
                              label: Text('CSV'),
                              icon: Icon(Icons.table_chart),
                            ),
                          ],
                          selected: {_selectedFormat},
                          onSelectionChanged: (value) {
                            setState(() => _selectedFormat = value.first);
                          },
                        ),
                        const SizedBox(height: RBSSpacing.sm),
                        Text(
                          _selectedFormat == 'xml'
                              ? 'XML: Offizielles NOI-Format für Notenverwaltungssysteme'
                              : 'CSV: Tabellen-Format für Excel/Calc',
                          style: RBSTypography.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RBSSpacing.xl),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedKlasseId == null || _isExporting
                        ? null
                        : () => _exportNoten(
                              klassenAsync.value ?? [],
                              studentsAsync.value ?? [],
                              subjectsAsync.value ?? [],
                              leistungsnachweiseAsync.value ?? [],
                              gradesAsync.value ?? [],
                            ),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isExporting ? 'Exportiere...' : 'Exportieren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RBSColors.dynamicRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: RBSSpacing.md),
                    ),
                  ),
                ),

                const SizedBox(height: RBSSpacing.xl),

                // Info-Box
                Container(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                          const SizedBox(width: RBSSpacing.sm),
                          Text('Hinweise zum Export', style: RBSTypography.label),
                        ],
                      ),
                      const SizedBox(height: RBSSpacing.sm),
                      Text(
                        '• Nur aktive Schüler werden exportiert\n'
                        '• Zeugnisnoten werden nach Berufsschul-Regel gerundet (ab 0,6 aufgerundet)\n'
                        '• Der Export enthält alle Fächer mit mindestens einer Note',
                        style: RBSTypography.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportNoten(
    List<Klasse> klassen,
    List students,
    List subjects,
    List leistungsnachweise,
    List grades,
  ) async {
    if (_selectedKlasseId == null) return;

    setState(() => _isExporting = true);

    try {
      final klasse = klassen.firstWhere((k) => k.id == _selectedKlasseId);
      final klassenStudents = students.where((s) => s.klasseId == _selectedKlasseId).toList();
      final klassenLns = leistungsnachweise.where((ln) => ln.klasseId == _selectedKlasseId).toList();
      
      // Hole nur Noten für diese LNs
      final lnIds = klassenLns.map((ln) => ln.id).toSet();
      final klassenGrades = grades.where((g) => lnIds.contains(g.leistungsnachweisId)).toList();

      String content;
      String filename;
      String mimeType;

      if (_selectedFormat == 'xml') {
        content = NoiExportService.generateXml(
          klasse: klasse,
          students: klassenStudents.cast(),
          subjects: subjects.cast(),
          leistungsnachweise: klassenLns.cast(),
          grades: klassenGrades.cast(),
          halbjahr: _selectedHalbjahr,
        );
        filename = NoiExportService.getFilename(klasse, _selectedHalbjahr, 'xml');
        mimeType = 'application/xml';
      } else {
        content = NoiExportService.generateCsv(
          klasse: klasse,
          students: klassenStudents.cast(),
          subjects: subjects.cast(),
          leistungsnachweise: klassenLns.cast(),
          grades: klassenGrades.cast(),
        );
        filename = NoiExportService.getFilename(klasse, _selectedHalbjahr, 'csv');
        mimeType = 'text/csv';
      }

      // Download im Browser triggern (neue Web-API)
      final bytes = utf8.encode(content);
      final jsArray = bytes.toJS;
      final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: mimeType));
      final url = web.URL.createObjectURL(blob);
      
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = filename;
      anchor.click();
      
      web.URL.revokeObjectURL(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export "$filename" erfolgreich!'),
            backgroundColor: RBSColors.courtGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export fehlgeschlagen: $e'),
            backgroundColor: RBSColors.dynamicRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
