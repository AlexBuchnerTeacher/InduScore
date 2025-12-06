import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../services/noi_export_service.dart';
import '../services/pdf_export_service.dart';
import '../models/klasse.dart';
import '../models/student.dart';
import '../models/subject.dart';

/// Export Screen - NOI/CSV/PDF Export
class NoiExportScreen extends ConsumerStatefulWidget {
  const NoiExportScreen({super.key});

  @override
  ConsumerState<NoiExportScreen> createState() => _NoiExportScreenState();
}

class _NoiExportScreenState extends ConsumerState<NoiExportScreen> {
  String? _selectedKlasseId;
  String? _selectedStudentId;
  String? _selectedSubjectId;
  String _selectedExportType = 'noi'; // noi, pdf_student, pdf_subject
  String _selectedFormat = 'xml'; // xml, csv
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
        title: const Text('Daten exportieren'),
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RBSSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export-Typ auswählen
                const RBSHeadline(
                  text: 'Export-Typ wählen',
                  level: RBSHeadlineLevel.h3,
                ),
                const SizedBox(height: RBSSpacing.md),
                
                // Export-Typ Karten
                Row(
                  children: [
                    Expanded(
                      child: _buildExportTypeCard(
                        type: 'noi',
                        icon: Icons.upload_file,
                        title: 'Zeugnisnoten',
                        subtitle: 'NOI-Format / CSV',
                        color: RBSColors.dynamicRed,
                      ),
                    ),
                    const SizedBox(width: RBSSpacing.md),
                    Expanded(
                      child: _buildExportTypeCard(
                        type: 'pdf_student',
                        icon: Icons.person,
                        title: 'Schüler-Notenblatt',
                        subtitle: 'PDF pro Schüler',
                        color: RBSColors.courtGreen,
                      ),
                    ),
                    const SizedBox(width: RBSSpacing.md),
                    Expanded(
                      child: _buildExportTypeCard(
                        type: 'pdf_subject',
                        icon: Icons.list_alt,
                        title: 'Fach-Notenliste',
                        subtitle: 'PDF pro Fach',
                        color: RBSColors.growingElder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RBSSpacing.xl),

                // Dynamische Optionen je nach Export-Typ
                if (_selectedExportType == 'noi') ...[
                  _buildNoiOptions(klassenAsync),
                ] else if (_selectedExportType == 'pdf_student') ...[
                  _buildStudentPdfOptions(klassenAsync, studentsAsync),
                ] else if (_selectedExportType == 'pdf_subject') ...[
                  _buildSubjectPdfOptions(klassenAsync, subjectsAsync),
                ],

                const SizedBox(height: RBSSpacing.xl),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canExport() && !_isExporting
                        ? () => _doExport(
                              klassenAsync.value ?? [],
                              studentsAsync.value ?? [],
                              subjectsAsync.value ?? [],
                              leistungsnachweiseAsync.value ?? [],
                              gradesAsync.value ?? [],
                            )
                        : null,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                _buildInfoBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedExportType == type;
    return InkWell(
      onTap: () => setState(() {
        _selectedExportType = type;
        // Reset selections
        _selectedStudentId = null;
        _selectedSubjectId = null;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(RBSSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(height: RBSSpacing.sm),
            Text(
              title,
              style: RBSTypography.label.copyWith(
                color: isSelected ? color : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RBSSpacing.xs),
            Text(
              subtitle,
              style: RBSTypography.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoiOptions(AsyncValue<List<Klasse>> klassenAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RBSHeadline(text: 'NOI Export Optionen', level: RBSHeadlineLevel.h4),
        const SizedBox(height: RBSSpacing.md),

        // Klasse
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
                    Text('Klasse', style: RBSTypography.label),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),
                klassenAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Fehler: $e'),
                  data: (klassen) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Klasse wählen',
                      isDense: true,
                    ),
                    items: klassen.map((k) => DropdownMenuItem(
                      value: k.id,
                      child: Text(
                        '${k.name} (${k.schuljahr})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedKlasseId = value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RBSSpacing.md),

        // Format-Auswahl
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
                    Text('Format', style: RBSTypography.label),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'xml', label: Text('XML')),
                    ButtonSegment(value: 'csv', label: Text('CSV')),
                  ],
                  selected: {_selectedFormat},
                  onSelectionChanged: (v) => setState(() => _selectedFormat = v.first),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPdfOptions(
    AsyncValue<List<Klasse>> klassenAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    final students = studentsAsync.value ?? [];
    final filteredStudents = _selectedKlasseId != null
        ? students.where((s) => s.klasseId == _selectedKlasseId && s.isAktiv).toList()
        : <Student>[];
    filteredStudents.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RBSHeadline(text: 'Schüler-Notenblatt', level: RBSHeadlineLevel.h4),
        const SizedBox(height: RBSSpacing.md),

        // Klasse
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
                    Text('Klasse', style: RBSTypography.label),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),
                klassenAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Fehler: $e'),
                  data: (klassen) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Erst Klasse wählen',
                      isDense: true,
                    ),
                    items: klassen.map((k) => DropdownMenuItem(
                      value: k.id,
                      child: Text(
                        '${k.name} (${k.schuljahr})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() {
                      _selectedKlasseId = value;
                      _selectedStudentId = null;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RBSSpacing.md),

        // Schüler
        Card(
          child: Padding(
            padding: const EdgeInsets.all(RBSSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: RBSColors.courtGreen),
                    const SizedBox(width: RBSSpacing.sm),
                    Text('Schüler', style: RBSTypography.label),
                  ],
                ),
                const SizedBox(height: RBSSpacing.sm),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _selectedKlasseId == null 
                        ? 'Erst Klasse wählen' 
                        : 'Schüler wählen',
                    isDense: true,
                  ),
                  items: filteredStudents.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${s.lastName}, ${s.firstName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: _selectedKlasseId != null
                      ? (value) => setState(() => _selectedStudentId = value)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectPdfOptions(
    AsyncValue<List<Klasse>> klassenAsync,
    AsyncValue<List<Subject>> subjectsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RBSHeadline(text: 'Fach-Notenliste', level: RBSHeadlineLevel.h4),
        const SizedBox(height: RBSSpacing.md),

        // Klasse und Fach
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school, color: RBSColors.dynamicRed),
                          const SizedBox(width: RBSSpacing.sm),
                          Text('Klasse', style: RBSTypography.label),
                        ],
                      ),
                      const SizedBox(height: RBSSpacing.sm),
                      klassenAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => Text('Fehler: $e'),
                        data: (klassen) => DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Klasse',
                            isDense: true,
                          ),
                          items: klassen.map((k) => DropdownMenuItem(
                            value: k.id,
                            child: Text(
                              k.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedKlasseId = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: RBSSpacing.md),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(RBSSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.book, color: RBSColors.growingElder),
                          const SizedBox(width: RBSSpacing.sm),
                          Text('Fach', style: RBSTypography.label),
                        ],
                      ),
                      const SizedBox(height: RBSSpacing.sm),
                      subjectsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => Text('Fehler: $e'),
                        data: (subjects) {
                          // Filtere Fächer nach Beruf der Klasse
                          final selectedKlasse = klassenAsync.maybeWhen(
                            data: (klassen) => klassen.where((k) => k.id == _selectedKlasseId).firstOrNull,
                            orElse: () => null,
                          );
                          final filteredSubjects = selectedKlasse != null
                              ? subjects.where((s) => s.berufe.contains(selectedKlasse.beruf)).toList()
                              : subjects;
                          
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: _selectedKlasseId == null ? 'Erst Klasse wählen' : 'Fach wählen',
                              isDense: true,
                            ),
                            items: filteredSubjects.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.shortName ?? s.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: _selectedKlasseId != null 
                                ? (value) => setState(() => _selectedSubjectId = value)
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    String info;
    switch (_selectedExportType) {
      case 'noi':
        info = '• Exportiert Zeugnisnoten im offiziellen NOI-Format\n'
               '• XML für Notenverwaltungssysteme, CSV für Excel\n'
               '• Nur aktive Schüler werden exportiert';
        break;
      case 'pdf_student':
        info = '• Erstellt ein Notenblatt für einen einzelnen Schüler\n'
               '• Zeigt alle Fächer mit Einzelnoten und Schnitt\n'
               '• Ideal für Elterngespräche oder Schülerakte';
        break;
      case 'pdf_subject':
        info = '• Erstellt eine Notenliste für ein Fach\n'
               '• Zeigt alle Schüler mit ihren Noten\n'
               '• Übersicht mit Schnitt und Zeugnisnote';
        break;
      default:
        info = '';
    }

    return Container(
      padding: const EdgeInsets.all(RBSSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
          const SizedBox(width: RBSSpacing.sm),
          Expanded(
            child: Text(
              info,
              style: RBSTypography.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  bool _canExport() {
    switch (_selectedExportType) {
      case 'noi':
        return _selectedKlasseId != null;
      case 'pdf_student':
        return _selectedKlasseId != null && _selectedStudentId != null;
      case 'pdf_subject':
        return _selectedKlasseId != null && _selectedSubjectId != null;
      default:
        return false;
    }
  }

  Future<void> _doExport(
    List<Klasse> klassen,
    List students,
    List subjects,
    List leistungsnachweise,
    List grades,
  ) async {
    setState(() => _isExporting = true);

    try {
      switch (_selectedExportType) {
        case 'noi':
          await _exportNoi(klassen, students, subjects, leistungsnachweise, grades);
          break;
        case 'pdf_student':
          await _exportStudentPdf(klassen, students, subjects, leistungsnachweise, grades);
          break;
        case 'pdf_subject':
          await _exportSubjectPdf(klassen, students, subjects, leistungsnachweise, grades);
          break;
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

  Future<void> _exportNoi(
    List<Klasse> klassen,
    List students,
    List subjects,
    List leistungsnachweise,
    List grades,
  ) async {
    final klasse = klassen.firstWhere((k) => k.id == _selectedKlasseId);
    final klassenStudents = students.where((s) => s.klasseId == _selectedKlasseId).toList();
    final klassenLns = leistungsnachweise.where((ln) => ln.klasseId == _selectedKlasseId).toList();
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
      );
      filename = NoiExportService.getFilename(klasse, 'xml');
      mimeType = 'application/xml';
    } else {
      content = NoiExportService.generateCsv(
        klasse: klasse,
        students: klassenStudents.cast(),
        subjects: subjects.cast(),
        leistungsnachweise: klassenLns.cast(),
        grades: klassenGrades.cast(),
      );
      filename = NoiExportService.getFilename(klasse, 'csv');
      mimeType = 'text/csv';
    }

    _downloadFile(utf8.encode(content), filename, mimeType);
  }

  Future<void> _exportStudentPdf(
    List<Klasse> klassen,
    List students,
    List subjects,
    List leistungsnachweise,
    List grades,
  ) async {
    final klasse = klassen.firstWhere((k) => k.id == _selectedKlasseId);
    final student = students.firstWhere((s) => s.id == _selectedStudentId);

    final pdfBytes = PdfExportService.generateStudentReport(
      student: student,
      klasse: klasse,
      subjects: subjects.cast(),
      leistungsnachweise: leistungsnachweise.cast(),
      grades: grades.cast(),
    );

    final filename = PdfExportService.getFilename('Schueler', student.displayName);
    _downloadFile(pdfBytes, filename, 'application/pdf');
  }

  Future<void> _exportSubjectPdf(
    List<Klasse> klassen,
    List students,
    List subjects,
    List leistungsnachweise,
    List grades,
  ) async {
    final klasse = klassen.firstWhere((k) => k.id == _selectedKlasseId);
    final subject = subjects.firstWhere((s) => s.id == _selectedSubjectId);

    final pdfBytes = PdfExportService.generateSubjectReport(
      subject: subject,
      klasse: klasse,
      students: students.cast(),
      leistungsnachweise: leistungsnachweise.cast(),
      grades: grades.cast(),
    );

    final filename = PdfExportService.getFilename('Fach', '${klasse.name}_${subject.shortName ?? subject.name}');
    _downloadFile(pdfBytes, filename, 'application/pdf');
  }

  void _downloadFile(List<int> bytes, String filename, String mimeType) {
    // Convert to Uint8List for proper JS interop
    final uint8List = Uint8List.fromList(bytes);
    final jsArray = uint8List.toJS;
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
  }
}
