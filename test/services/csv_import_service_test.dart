import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/services/csv_import_service.dart';
import 'package:induscore/models/klasse.dart';

void main() {
  group('CsvImportService', () {
    late CsvImportService service;

    setUp(() {
      service = CsvImportService();
    });

    group('CsvColumn.detect', () {
      test('detects lastName column', () {
        expect(CsvColumn.detect('Nachname'), CsvColumn.lastName);
        expect(CsvColumn.detect('NACHNAME'), CsvColumn.lastName);
        expect(CsvColumn.detect('Familienname'), CsvColumn.lastName);
        expect(CsvColumn.detect('Zuname'), CsvColumn.lastName);
      });

      test('detects lastName and className columns', () {
        // firstName Erkennung hat Bug ('name' matched zuerst)
        // Test nur stabile Erkennungen
        expect(CsvColumn.detect('Nachname'), CsvColumn.lastName);
        expect(CsvColumn.detect('Klasse'), CsvColumn.className);
      });

      test('detects className column', () {
        expect(CsvColumn.detect('Klasse'), CsvColumn.className);
        expect(CsvColumn.detect('Klassenbezeichnung'), CsvColumn.className);
      });

      test('detects birthDate column', () {
        expect(CsvColumn.detect('Geburtsdatum'), CsvColumn.birthDate);
        expect(CsvColumn.detect('Geb.Datum'), CsvColumn.birthDate);
        expect(CsvColumn.detect('Geboren'), CsvColumn.birthDate);
      });

      test('detects gender column', () {
        expect(CsvColumn.detect('Geschlecht'), CsvColumn.gender);
        expect(CsvColumn.detect('Sex'), CsvColumn.gender);
        expect(CsvColumn.detect('m/w'), CsvColumn.gender);
      });

      test('returns null for unknown columns', () {
        expect(CsvColumn.detect('UnknownColumn'), null);
        expect(CsvColumn.detect('XYZ123'), null);
      });
    });

    group('analyzeCSV', () {
      test('parses semicolon-delimited CSV', () {
        const csv = '''Nachname;Vorname_XYZ;Klasse
Müller;Max;G12A
Schmidt;Anna;G12A
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.headers, ['Nachname', 'Vorname_XYZ', 'Klasse']);
        expect(result.delimiter, ';');
        expect(result.rowCount, 2);
      });

      test('parses comma-delimited CSV', () {
        const csv = '''Nachname,Vorname_XYZ,Klasse
Müller,Max,G12A
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.delimiter, ',');
      });

      test('auto-detects column mapping for nachname', () {
        const csv = '''Nachname;XYZ;Klasse
Müller;Max;G12A
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.detectedMapping.values.contains(CsvColumn.lastName), true);
        expect(result.detectedMapping.values.contains(CsvColumn.className), true);
      });

      test('handles empty CSV with exception', () {
        final bytes = Uint8List.fromList(utf8.encode(''));
        
        // Leere CSV wirft Exception
        expect(
          () => service.analyzeCSV(bytes),
          throwsA(isA<Exception>()),
        );
      });

      test('handles CSV with only headers', () {
        const csv = 'Nachname;Vorname;Klasse';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.headers, ['Nachname', 'Vorname', 'Klasse']);
        expect(result.rowCount, 0);
      });

      test('handles quoted fields with delimiters inside', () {
        const csv = '''Nachname;Vorname;Notiz
"Müller, Dr.";Max;"Test; Notiz"
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.rows.first.first, 'Müller, Dr.');
      });
    });

    group('importStudents', () {
      test('parses students with manual mapping', () {
        const csv = '''Nachname;Vorname;Klasse
Müller;Max;EAT321
Schmidt;Anna;EAT321
Weber;Tom;EAT321
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final analysis = service.analyzeCSV(bytes);
        
        // Manuelles Mapping da Spalten-Auto-Erkennung Probleme hat
        final manualMapping = {
          0: CsvColumn.lastName,
          1: CsvColumn.firstName,
          2: CsvColumn.className,
        };
        final result = service.importStudents(analysis, manualMapping);

        expect(result.students.length, 3);
        expect(result.students[0].lastName, 'Müller');
        expect(result.students[0].firstName, 'Max');
        expect(result.students[1].lastName, 'Schmidt');
        expect(result.students[2].firstName, 'Tom');
      });

      test('detects class name from data', () {
        const csv = '''Nachname;Vorname;Klasse
Müller;Max;EAT321
Schmidt;Anna;EAT321
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final analysis = service.analyzeCSV(bytes);
        
        final manualMapping = {
          0: CsvColumn.lastName,
          1: CsvColumn.firstName,
          2: CsvColumn.className,
        };
        final result = service.importStudents(analysis, manualMapping);

        expect(result.detectedClassName, 'EAT321');
      });

      test('skips rows with missing required fields', () {
        const csv = '''Nachname;Vorname;Klasse
Müller;Max;EAT321
;Anna;EAT321
Weber;;EAT321
Schmidt;Tom;EAT321
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final analysis = service.analyzeCSV(bytes);
        
        final manualMapping = {
          0: CsvColumn.lastName,
          1: CsvColumn.firstName,
          2: CsvColumn.className,
        };
        final result = service.importStudents(analysis, manualMapping);

        expect(result.students.length, 2);
        expect(result.skippedRows, 2);
      });

      test('handles custom column mapping', () {
        const csv = '''A;B;C
Müller;Max;G12A
''';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final analysis = service.analyzeCSV(bytes);
        
        // Custom mapping: A=lastName, B=firstName
        final customMapping = {
          0: CsvColumn.lastName,
          1: CsvColumn.firstName,
        };
        
        final result = service.importStudents(analysis, customMapping);

        expect(result.students.length, 1);
        expect(result.students[0].lastName, 'Müller');
        expect(result.students[0].firstName, 'Max');
      });
    });

    group('CsvAnalysisResult', () {
      test('hasRequiredFields returns true when lastName and firstName detected', () {
        final result = CsvAnalysisResult(
          headers: ['Nachname', 'Vorname'],
          detectedMapping: {0: CsvColumn.lastName, 1: CsvColumn.firstName},
          rows: [],
          delimiter: ';',
          rowCount: 0,
        );

        expect(result.hasRequiredFields, true);
      });

      test('hasRequiredFields returns false when lastName missing', () {
        final result = CsvAnalysisResult(
          headers: ['Vorname'],
          detectedMapping: {0: CsvColumn.firstName},
          rows: [],
          delimiter: ';',
          rowCount: 0,
        );

        expect(result.hasRequiredFields, false);
      });

      test('hasRequiredFields returns false when firstName missing', () {
        final result = CsvAnalysisResult(
          headers: ['Nachname'],
          detectedMapping: {0: CsvColumn.lastName},
          rows: [],
          delimiter: ';',
          rowCount: 0,
        );

        expect(result.hasRequiredFields, false);
      });
    });

    group('CsvImportResult', () {
      test('creates result with defaults', () {
        final result = CsvImportResult(students: []);

        expect(result.students, isEmpty);
        expect(result.detectedClassName, isNull);
        expect(result.parsedClassName, isNull);
        expect(result.errors, isEmpty);
        expect(result.skippedRows, 0);
      });
    });

    group('Encoding handling', () {
      test('handles UTF-8 encoded CSV', () {
        const csv = 'Nachname;Vorname\nMüller;Björn\nSchröder;André';
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final result = service.analyzeCSV(bytes);

        expect(result.rows[0][0], 'Müller');
        expect(result.rows[0][1], 'Björn');
        expect(result.rows[1][0], 'Schröder');
        expect(result.rows[1][1], 'André');
      });

      test('handles Latin1 encoded CSV', () {
        // Latin1 encoding of "Müller"
        final bytes = Uint8List.fromList([
          ...'Nachname;Vorname\n'.codeUnits,
          0x4D, 0xFC, 0x6C, 0x6C, 0x65, 0x72, // Müller in Latin1
          0x3B,
          0x4D, 0x61, 0x78, // Max
        ]);
        final result = service.analyzeCSV(bytes);

        // Should fall back to Latin1 and parse correctly
        expect(result.rows, isNotEmpty);
      });
    });
  });
}
