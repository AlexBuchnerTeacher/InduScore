import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';
import '../services/csv_import_service.dart';
import '../models/student.dart';

/// CSV Import Screen - Schülerlisten importieren
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  final CsvImportService _importService = CsvImportService();
  
  CsvAnalysisResult? _analysisResult;
  CsvImportResult? _importResult;
  Map<int, CsvColumn> _columnMapping = {};
  String? _selectedKlasseId;
  bool _isLoading = false;
  String? _fileName;
  
  // Import-Status
  bool _importing = false;
  int _importedCount = 0;
  String? _importError;
  bool _importComplete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Import'),
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            RBSCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: RBSColors.dynamicRed, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schülerlisten importieren',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Importieren Sie Schülerlisten aus CSV-Dateien (z.B. ASV-Export). '
                            'Spalten werden automatisch erkannt, können aber manuell angepasst werden.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Datei auswählen
            _buildStepCard(
              step: 1,
              title: 'CSV-Datei auswählen',
              isActive: _analysisResult == null,
              isComplete: _analysisResult != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _selectFile,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_fileName ?? 'Datei auswählen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RBSColors.dynamicRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '✓ ${_analysisResult!.rowCount} Zeilen erkannt (Delimiter: ${_analysisResult!.delimiter})',
                      style: TextStyle(color: RBSColors.courtGreen, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),

            // Step 2: Spalten zuordnen
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              _buildStepCard(
                step: 2,
                title: 'Spalten zuordnen',
                isActive: _importResult == null,
                isComplete: _importResult != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Überprüfen Sie die automatische Spaltenerkennung und passen Sie sie bei Bedarf an:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Spalten-Mapping
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < _analysisResult!.headers.length; i++)
                          _buildColumnMappingChip(i, _analysisResult!.headers[i]),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pflichtfelder-Check
                    if (!_hasRequiredFields)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bitte ordnen Sie mindestens "Vorname" und "Nachname" zu.',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Preview
                    if (_hasRequiredFields) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('Vorschau:', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildPreviewTable(),
                    ],
                    
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _hasRequiredFields ? _processImport : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Daten verarbeiten'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RBSColors.courtGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 3: Klasse auswählen & importieren
            if (_importResult != null) ...[
              const SizedBox(height: 16),
              _buildStepCard(
                step: 3,
                title: 'In Klasse importieren',
                isActive: !_importComplete,
                isComplete: _importComplete,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_importResult!.students.length} Schüler erkannt',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (_importResult!.parsedClassName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Erkannte Klasse: ${_importResult!.detectedClassName} '
                        '(${_importResult!.parsedClassName!.beruf.code} - ${_importResult!.parsedClassName!.jahrgangsstufe}. Jhg)',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                    if (_importResult!.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Warnungen: ${_importResult!.errors.length}',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                      for (final error in _importResult!.errors.take(3))
                        Text('• $error', style: TextStyle(color: Colors.orange.shade600, fontSize: 12)),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Klassen-Auswahl
                    _buildKlasseDropdown(),
                    
                    const SizedBox(height: 16),
                    
                    // Import-Buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_selectedKlasseId != null && !_importing && !_importComplete)
                              ? _importToKlasse
                              : null,
                          icon: _importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_importing 
                              ? 'Importiere... ($_importedCount/${_importResult!.students.length})'
                              : 'In Klasse importieren'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RBSColors.dynamicRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: !_importing ? _createNewKlasse : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Neue Klasse anlegen'),
                        ),
                      ],
                    ),
                    
                    if (_importError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _importError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    
                    if (_importComplete) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RBSColors.courtGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: RBSColors.courtGreen),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: RBSColors.courtGreen),
                            const SizedBox(width: 12),
                            Text(
                              '$_importedCount Schüler erfolgreich importiert!',
                              style: TextStyle(
                                color: RBSColors.courtGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required bool isActive,
    required bool isComplete,
    required Widget child,
  }) {
    return RBSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isComplete
                  ? RBSColors.courtGreen.withValues(alpha: 0.1)
                  : isActive
                      ? RBSColors.dynamicRed.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isComplete
                      ? RBSColors.courtGreen
                      : isActive
                          ? RBSColors.dynamicRed
                          : Colors.grey.shade400,
                  child: isComplete
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? RBSColors.courtGreen
                        : isActive
                            ? RBSColors.dynamicRed
                            : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnMappingChip(int index, String header) {
    final mapping = _columnMapping[index];
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(header, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            mapping?.label ?? 'Ignorieren',
            style: TextStyle(
              fontSize: 12,
              color: mapping != null ? RBSColors.dynamicRed : Colors.grey,
              fontWeight: mapping != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onPressed: () => _showColumnMappingDialog(index, header),
      backgroundColor: mapping != null 
          ? RBSColors.dynamicRed.withValues(alpha: 0.1) 
          : Colors.grey.shade100,
    );
  }

  void _showColumnMappingDialog(int index, String header) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Spalte "$header" zuordnen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    _columnMapping[index] == null 
                        ? Icons.radio_button_checked 
                        : Icons.radio_button_unchecked,
                    color: _columnMapping[index] == null ? RBSColors.dynamicRed : null,
                  ),
                  title: const Text('Ignorieren'),
                  onTap: () {
                    setState(() => _columnMapping.remove(index));
                    Navigator.pop(ctx);
                  },
                ),
                for (final col in CsvColumn.values)
                  ListTile(
                    leading: Icon(
                      _columnMapping[index] == col 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      color: _columnMapping[index] == col ? RBSColors.dynamicRed : null,
                    ),
                    title: Text(col.label),
                    onTap: () {
                      setState(() => _columnMapping[index] = col);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewTable() {
    final rows = _analysisResult!.rows.take(5).toList();
    final lastNameIdx = _columnMapping.entries
        .where((e) => e.value == CsvColumn.lastName)
        .map((e) => e.key)
        .firstOrNull;
    final firstNameIdx = _columnMapping.entries
        .where((e) => e.value == CsvColumn.firstName)
        .map((e) => e.key)
        .firstOrNull;
    final classIdx = _columnMapping.entries
        .where((e) => e.value == CsvColumn.className)
        .map((e) => e.key)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Vorname')),
            DataColumn(label: Text('Nachname')),
            DataColumn(label: Text('Klasse')),
          ],
          rows: rows.map((row) {
            return DataRow(cells: [
              DataCell(Text(firstNameIdx != null && firstNameIdx < row.length 
                  ? row[firstNameIdx] : '-')),
              DataCell(Text(lastNameIdx != null && lastNameIdx < row.length 
                  ? row[lastNameIdx] : '-')),
              DataCell(Text(classIdx != null && classIdx < row.length 
                  ? row[classIdx] : '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKlasseDropdown() {
    final klassenAsync = ref.watch(klassenProvider);
    
    return klassenAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Text('Fehler: $err'),
      data: (klassen) {
        // Wenn erkannter Klassenname passt, vorauswählen
        if (_selectedKlasseId == null && _importResult?.detectedClassName != null) {
          for (final klasse in klassen) {
            if (klasse.name == _importResult!.detectedClassName) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedKlasseId = klasse.id);
              });
              break;
            }
          }
        }
        
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Klasse auswählen',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedKlasseId,
          items: klassen.map((k) => DropdownMenuItem(
            value: k.id,
            child: Text(k.name),
          )).toList(),
          onChanged: (v) => setState(() => _selectedKlasseId = v),
        );
      },
    );
  }

  bool get _hasRequiredFields {
    return _columnMapping.values.contains(CsvColumn.lastName) &&
           _columnMapping.values.contains(CsvColumn.firstName);
  }

  Future<void> _selectFile() async {
    setState(() => _isLoading = true);
    
    try {
      // File-Input erstellen
      final input = web.document.createElement('input') as web.HTMLInputElement;
      input.type = 'file';
      input.accept = '.csv,.txt';
      
      // Event-Handler für Dateiauswahl (sync wrapper für async Logik)
      input.onchange = ((web.Event event) {
        _handleFileSelection(input);
      }).toJS;
      
      input.click();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _importError = 'Fehler: $e';
      });
    }
  }

  void _handleFileSelection(web.HTMLInputElement input) {
    final files = input.files;
    if (files != null && files.length > 0) {
      final file = files.item(0)!;
      final reader = web.FileReader();
      
      reader.onload = ((web.Event e) {
        final result = reader.result;
        if (result != null) {
          final bytes = _jsArrayBufferToUint8List(result);
          _analyzeFile(bytes, file.name);
        }
      }).toJS;
      
      reader.onerror = ((web.Event e) {
        setState(() {
          _isLoading = false;
          _importError = 'Fehler beim Lesen der Datei';
        });
      }).toJS;
      
      reader.readAsArrayBuffer(file);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Uint8List _jsArrayBufferToUint8List(JSAny arrayBuffer) {
    // Konvertiere ArrayBuffer zu Uint8List via JS interop
    final bytes = (arrayBuffer as JSArrayBuffer).toDart;
    return bytes.asUint8List();
  }

  void _analyzeFile(Uint8List bytes, String fileName) {
    try {
      final analysis = _importService.analyzeCSV(bytes);
      setState(() {
        _analysisResult = analysis;
        _columnMapping = Map.from(analysis.detectedMapping);
        _fileName = fileName;
        _isLoading = false;
        _importResult = null;
        _importComplete = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _importError = 'Fehler bei der Analyse: $e';
      });
    }
  }

  void _processImport() {
    if (_analysisResult == null) return;
    
    final result = _importService.importStudents(_analysisResult!, _columnMapping);
    setState(() {
      _importResult = result;
      _importComplete = false;
      _importError = null;
    });
  }

  Future<void> _importToKlasse() async {
    if (_importResult == null || _selectedKlasseId == null) return;
    
    setState(() {
      _importing = true;
      _importedCount = 0;
      _importError = null;
    });
    
    final firestoreService = ref.read(firestoreServiceProvider);
    
    try {
      for (final imported in _importResult!.students) {
        final student = Student(
          id: '', // wird von Firestore generiert
          firstName: imported.firstName,
          lastName: imported.lastName,
          klasseId: _selectedKlasseId!,
          eintrittsDatum: DateTime.now(),
          createdAt: DateTime.now(),
        );
        
        await firestoreService.createStudent(student);
        
        setState(() => _importedCount++);
      }
      
      setState(() {
        _importing = false;
        _importComplete = true;
      });
      
      // Provider invalidieren für Refresh
      ref.invalidate(studentsByKlasseProvider(_selectedKlasseId!));
      
    } catch (e) {
      setState(() {
        _importing = false;
        _importError = 'Import-Fehler: $e';
      });
    }
  }

  void _createNewKlasse() {
    // Dialog zum Anlegen einer neuen Klasse
    final nameController = TextEditingController(
      text: _importResult?.detectedClassName ?? '',
    );
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Klasse anlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Klassenname',
                hintText: 'z.B. BGJ22a',
              ),
              autofocus: true,
            ),
            if (_importResult?.parsedClassName != null) ...[
              const SizedBox(height: 12),
              Text(
                'Erkannt: ${_importResult!.parsedClassName!.beruf.code} - '
                '${_importResult!.parsedClassName!.jahrgangsstufe}. Jahrgang',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              Navigator.pop(ctx);
              
              // TODO: Implementiere Klassen-Erstellung
              // Für jetzt zeigen wir eine Meldung
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bitte legen Sie die Klasse im Klassen-Menü an.'),
                ),
              );
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
  }
}
