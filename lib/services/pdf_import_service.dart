import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/klasse.dart';

/// Ergebnis eines PDF-Imports.
class ClassImportPreview {
  final String? rawClassName;  // null wenn nicht erkannt
  final String? klassenleiterCode;
  final ParsedKlassenname? parsedName;  // null wenn nicht erkannt
  final List<ImportedStudent> students;
  final List<String> invalidLines;
  final String extractedText;  // Rohtext für Debug/manuelle Eingabe

  ClassImportPreview({
    this.rawClassName,
    this.parsedName,
    required this.students,
    this.klassenleiterCode,
    this.invalidLines = const [],
    this.extractedText = '',
  });
  
  /// Ob der Klassenname manuell eingegeben werden muss
  bool get needsManualClassName => rawClassName == null;
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

    // Für OCR: Leerzeichen aus Text entfernen für Klassenname-Suche
    final normalizedText = text.replaceAll(RegExp(r'\s+'), '');

    // Klassenname suchen - auch mit OCR-Leerzeichen (z.B. "E A T 3 3 1")
    // Suche im normalisierten Text (ohne Leerzeichen)
    final klasseRegex = RegExp(r'(IE|EAT|EBT|EGS)(\d)(\d)(\d)');
    final klasseMatch = klasseRegex.firstMatch(normalizedText);
    
    // Klassenname ist optional - kann später manuell eingegeben werden
    String? rawClassName;
    ParsedKlassenname? parsedName;
    if (klasseMatch != null) {
      rawClassName =
          '${klasseMatch.group(1)}${klasseMatch.group(2)}${klasseMatch.group(3)}${klasseMatch.group(4)}';
      parsedName = ParsedKlassenname.parse(rawClassName);
    }

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

    // Schüler extrahieren: Zeilen mit Namens-Bestandteilen (inkl. Umlaute/Bindestriche)
    final students = <ImportedStudent>[];
    final invalid = <String>[];
    
    // Regex für Klassenname (um diese Zeilen zu überspringen)
    final skipKlasseRegex = RegExp(r'(IE|EAT|EBT|EGS)\s*\d\s*\d\s*\d', caseSensitive: false);
    
    for (final line in lines) {
      // Überschriften überspringen
      if (skipKlasseRegex.hasMatch(line) || 
          line.toLowerCase().contains('klassenleiter') ||
          line.toLowerCase().contains('notenliste') ||
          line.toLowerCase().contains('schüler')) {
        continue;
      }
      
      // Namen extrahieren - versuche verschiedene Formate
      final parts = line.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        // Prüfe ob es wie ein Name aussieht (keine Zahlen, nicht zu kurz)
        final potentialName = parts.take(2).join(' ');
        if (RegExp(r'^[A-Za-zÄÖÜäöüß\-]+\s+[A-Za-zÄÖÜäöüß\-]+$').hasMatch(potentialName) &&
            parts[0].length > 1 && parts[1].length > 1) {
          students.add(
            ImportedStudent(
              lastName: parts[0],  // Nachname zuerst (typisches Listenformat)
              firstName: parts[1],
            ),
          );
          continue;
        }
      }
      
      // Kurze Zeilen als potenziell fehlerhaft aufnehmen
      if (line.split(' ').length <= 4 && line.runes.every((c) => c > 31)) {
        invalid.add(line);
      }
    }

    // Schüler können leer sein - wird dann manuell eingegeben

    return ClassImportPreview(
      rawClassName: rawClassName,
      klassenleiterCode: klassenleiterCode,
      parsedName: parsedName,
      students: students,
      invalidLines: invalid,
      extractedText: text,
    );
  }
}
