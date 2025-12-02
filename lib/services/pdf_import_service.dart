import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/klasse.dart';

/// Ergebnis eines PDF-Imports.
class ClassImportPreview {
  final String rawClassName;
  final String? klassenleiterCode;
  final ParsedKlassenname parsedName;
  final List<ImportedStudent> students;
  final List<String> invalidLines;

  ClassImportPreview({
    required this.rawClassName,
    required this.parsedName,
    required this.students,
    this.klassenleiterCode,
    this.invalidLines = const [],
  });
}

/// Schülerdatensatz aus dem Import.
class ImportedStudent {
  final String firstName;
  final String lastName;

  const ImportedStudent({
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';
}

/// Service zum Parsen von Klassenlisten-PDFs.
class PdfImportService {
  Future<ClassImportPreview> parseClassList(Uint8List bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    for (var i = 0; i < document.pages.count; i++) {
      buffer.write(extractor.extractText(startPageIndex: i, endPageIndex: i));
      buffer.write('\n');
    }
    document.dispose();

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      throw Exception('PDF enthält keinen lesbaren Text (evtl. gescanntes Bild).');
    }

    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Klassenname suchen
    final klasseRegex = RegExp(r'(IE|EAT|EBT|EGS)\\s*(\\d)(\\d)(\\d)');
    final klasseLine = lines.firstWhere(
      (l) => klasseRegex.hasMatch(l),
      orElse: () => '',
    );
    if (klasseLine.isEmpty) {
      throw Exception('Kein Klassenname im erwarteten Format gefunden (z.B. EAT321).');
    }
    final klasseMatch = klasseRegex.firstMatch(klasseLine)!;
    final rawClassName =
        '${klasseMatch.group(1)}${klasseMatch.group(2)}${klasseMatch.group(3)}${klasseMatch.group(4)}';
    final parsedName = ParsedKlassenname.parse(rawClassName);

    // Klassenleiter (heuristisch): erste Zeile mit 2-4 Großbuchstaben nach "Klassenleiter"
    String? klassenleiterCode;
    final leiterLine = lines.firstWhere(
      (l) => l.toLowerCase().contains('klassenleiter'),
      orElse: () => '',
    );
    if (leiterLine.isNotEmpty) {
      final leiterMatch = RegExp(r'([A-ZÄÖÜ]{2,4})').firstMatch(leiterLine);
      if (leiterMatch != null) {
        klassenleiterCode = leiterMatch.group(1);
      }
    }

    // Schüler extrahieren: Zeilen mit zwei Namens-Bestandteilen (inkl. Umlaute/Bindestriche)
    final nameRegex = RegExp(r'^([A-Za-zÄÖÜäöüß\\-]+)\\s+([A-Za-zÄÖÜäöüß\\-]+)$');
    final students = <ImportedStudent>[];
    final invalid = <String>[];
    for (final line in lines) {
      // Überschriften überspringen
      if (klasseRegex.hasMatch(line) || line.toLowerCase().contains('klassenleiter')) {
        continue;
      }
      final match = nameRegex.firstMatch(line);
      if (match != null) {
        students.add(
          ImportedStudent(
            firstName: match.group(1)!,
            lastName: match.group(2)!,
          ),
        );
      } else if (line.split(' ').length <= 4 && line.runes.every((c) => c > 31)) {
        // nur kurze Zeilen als potenziell fehlerhaft aufnehmen
        invalid.add(line);
      }
    }

    if (students.isEmpty) {
      throw Exception('Keine Schüler-Einträge erkannt. Bitte PDF-Format prüfen.');
    }

    return ClassImportPreview(
      rawClassName: rawClassName,
      klassenleiterCode: klassenleiterCode,
      parsedName: parsedName,
      students: students,
      invalidLines: invalid,
    );
  }
}
