import 'dart:convert';
import 'dart:typed_data';

import '../models/klasse.dart';
import 'pdf_import_service.dart'; // Für ImportedStudent

/// Erkannte CSV-Spalten
enum CsvColumn {
  lastName('Nachname', ['nachname', 'familienname', 'name', 'zuname']),
  firstName('Vorname', ['vorname', 'rufname']),
  className('Klasse', ['klasse', 'klassenbezeichnung', 'klassenname']),
  birthDate('Geburtsdatum', ['geburtsdatum', 'geb.datum', 'geb', 'geboren']),
  gender('Geschlecht', ['geschlecht', 'sex', 'm/w']),
  status('Status', ['status', 'aktiv']),
  entryDate('Eintrittsdatum', ['eintritt', 'eintrittsdatum', 'aufnahme']),
  exitDate('Austrittsdatum', ['austritt', 'austrittsdatum', 'abgang']);

  final String label;
  final List<String> keywords;

  const CsvColumn(this.label, this.keywords);

  /// Versucht eine Spaltenüberschrift zu matchen
  static CsvColumn? detect(String header) {
    final normalized = header.toLowerCase().trim();
    for (final col in CsvColumn.values) {
      for (final keyword in col.keywords) {
        if (normalized.contains(keyword)) {
          return col;
        }
      }
    }
    return null;
  }
}

/// Ergebnis der CSV-Analyse
class CsvAnalysisResult {
  final List<String> headers;
  final Map<int, CsvColumn> detectedMapping;
  final List<List<String>> rows;
  final String delimiter;
  final int rowCount;

  CsvAnalysisResult({
    required this.headers,
    required this.detectedMapping,
    required this.rows,
    required this.delimiter,
    required this.rowCount,
  });

  /// Ob die Pflichtfelder erkannt wurden
  bool get hasRequiredFields =>
      detectedMapping.values.contains(CsvColumn.lastName) &&
      detectedMapping.values.contains(CsvColumn.firstName);
}

/// CSV Import Ergebnis
class CsvImportResult {
  final List<ImportedStudent> students;
  final String? detectedClassName;
  final ParsedKlassenname? parsedClassName;
  final List<String> errors;
  final int skippedRows;

  CsvImportResult({
    required this.students,
    this.detectedClassName,
    this.parsedClassName,
    this.errors = const [],
    this.skippedRows = 0,
  });
}

/// Service zum Importieren von Schülerlisten aus CSV-Dateien
/// 
/// Unterstützt verschiedene CSV-Formate:
/// - Semikolon-getrennt (ASV-Standard)
/// - Komma-getrennt
/// - Tab-getrennt
/// - Mit/ohne Anführungszeichen
class CsvImportService {
  
  /// Analysiert eine CSV-Datei und erkennt Spalten automatisch
  CsvAnalysisResult analyzeCSV(Uint8List bytes) {
    // Versuche verschiedene Encodings
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      // Fallback auf Latin1 (Windows-1252)
      content = latin1.decode(bytes);
    }

    // Erkenne Delimiter
    final delimiter = _detectDelimiter(content);
    
    // Parse CSV
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      throw Exception('CSV-Datei ist leer');
    }

    // Header-Zeile
    final headers = _parseLine(lines.first, delimiter);
    
    // Spalten automatisch erkennen
    final detectedMapping = <int, CsvColumn>{};
    for (var i = 0; i < headers.length; i++) {
      final detected = CsvColumn.detect(headers[i]);
      if (detected != null) {
        detectedMapping[i] = detected;
      }
    }

    // Datenzeilen parsen
    final rows = <List<String>>[];
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final row = _parseLine(lines[i], delimiter);
      if (row.isNotEmpty) {
        rows.add(row);
      }
    }

    return CsvAnalysisResult(
      headers: headers,
      detectedMapping: detectedMapping,
      rows: rows,
      delimiter: delimiter,
      rowCount: rows.length,
    );
  }

  /// Importiert Schüler mit dem gegebenen Spalten-Mapping
  CsvImportResult importStudents(
    CsvAnalysisResult analysis,
    Map<int, CsvColumn> mapping,
  ) {
    final students = <ImportedStudent>[];
    final errors = <String>[];
    var skipped = 0;
    String? detectedClassName;

    // Finde Spaltenindizes
    int? lastNameIdx, firstNameIdx, classNameIdx;
    for (final entry in mapping.entries) {
      switch (entry.value) {
        case CsvColumn.lastName:
          lastNameIdx = entry.key;
          break;
        case CsvColumn.firstName:
          firstNameIdx = entry.key;
          break;
        case CsvColumn.className:
          classNameIdx = entry.key;
          break;
        default:
          break;
      }
    }

    if (lastNameIdx == null || firstNameIdx == null) {
      throw Exception('Nachname und Vorname müssen zugeordnet sein');
    }

    // Schüler extrahieren
    for (var i = 0; i < analysis.rows.length; i++) {
      final row = analysis.rows[i];
      
      try {
        if (lastNameIdx >= row.length || firstNameIdx >= row.length) {
          errors.add('Zeile ${i + 2}: Nicht genug Spalten');
          skipped++;
          continue;
        }

        final lastName = row[lastNameIdx].trim();
        final firstName = row[firstNameIdx].trim();

        if (lastName.isEmpty || firstName.isEmpty) {
          skipped++;
          continue;
        }

        students.add(ImportedStudent(
          firstName: firstName,
          lastName: lastName,
        ));

        // Klassenname aus erster gültiger Zeile
        if (detectedClassName == null && classNameIdx != null && classNameIdx < row.length) {
          final className = row[classNameIdx].trim();
          if (className.isNotEmpty) {
            detectedClassName = className;
          }
        }
      } catch (e) {
        errors.add('Zeile ${i + 2}: $e');
        skipped++;
      }
    }

    ParsedKlassenname? parsedClassName;
    if (detectedClassName != null) {
      parsedClassName = ParsedKlassenname.parse(detectedClassName);
    }

    return CsvImportResult(
      students: students,
      detectedClassName: detectedClassName,
      parsedClassName: parsedClassName,
      errors: errors,
      skippedRows: skipped,
    );
  }

  /// Erkennt den Delimiter einer CSV-Datei
  String _detectDelimiter(String content) {
    final firstLines = content.split('\n').take(5).join('\n');
    
    // Zähle Vorkommen verschiedener Delimiter
    final counts = {
      ';': ';'.allMatches(firstLines).length,
      ',': ','.allMatches(firstLines).length,
      '\t': '\t'.allMatches(firstLines).length,
    };

    // Der häufigste gewinnt (ASV nutzt meistens ;)
    var maxCount = 0;
    var delimiter = ';';
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        delimiter = entry.key;
      }
    }

    return delimiter;
  }

  /// Parst eine CSV-Zeile mit Berücksichtigung von Anführungszeichen
  List<String> _parseLine(String line, String delimiter) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
      i++;
    }

    result.add(buffer.toString());
    return result;
  }
}
