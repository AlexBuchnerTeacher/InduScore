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

    // Klassenleiter suchen - verschiedene Schreibweisen und Formate
    String? klassenleiterCode;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('klassenleiter') || 
          lowerLine.contains('klassenleitung') ||
          lowerLine.contains('kll') ||
          lowerLine.contains('kl:')) {
        // Suche nach 2-4 Großbuchstaben (Lehrerkürzel)
        final leiterMatch = RegExp(r'\b([A-ZÄÖÜ]{2,4})\b').firstMatch(line);
        if (leiterMatch != null) {
          klassenleiterCode = leiterMatch.group(1);
          break;
        }
      }
    }

    // Schüler extrahieren - flexiblerer Ansatz
    final students = <ImportedStudent>[];
    final invalid = <String>[];
    
    // Regex für Zeilen die übersprungen werden sollen
    final skipRegex = RegExp(
      r'(IE|EAT|EBT|EGS)|klassenleiter|klassenleitung|notenliste|schüler|name|vorname|nachname|nr\.?|lfd|datum|\d{2}\.\d{2}\.\d{4}',
      caseSensitive: false,
    );
    
    for (final line in lines) {
      // Kurze Zeilen oder Überschriften überspringen
      if (line.length < 4 || skipRegex.hasMatch(line)) {
        continue;
      }
      
      // Zeilen mit hauptsächlich Zahlen überspringen
      final digitCount = line.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (digitCount > line.length / 3) {
        continue;
      }
      
      // Namen extrahieren - verschiedene Formate
      // Format 1: "Nachname Vorname" oder "Nachname, Vorname"
      // Format 2: "1. Nachname Vorname" (mit Nummer)
      // Format 3: "Nachname    Vorname" (mit Tabs/Spaces)
      
      // Entferne führende Nummern
      var cleanLine = line.replaceFirst(RegExp(r'^\d+[\.\)\s]+'), '').trim();
      
      // Ersetze Komma durch Leerzeichen
      cleanLine = cleanLine.replaceAll(',', ' ');
      
      // Splitte nach Whitespace
      final parts = cleanLine.split(RegExp(r'\s+')).where((p) => p.isNotEmpty && p.length > 1).toList();
      
      if (parts.length >= 2) {
        final firstName = parts[0];
        final lastName = parts.length > 1 ? parts[1] : '';
        
        // Prüfe ob beide Teile wie Namen aussehen (Buchstaben, evtl. Bindestrich)
        final namePattern = RegExp(r'^[A-Za-zÄÖÜäöüßéèêëàáâãåæç\-]+$');
        if (namePattern.hasMatch(firstName) && namePattern.hasMatch(lastName)) {
          students.add(
            ImportedStudent(
              lastName: firstName,  // Erste Spalte = Nachname
              firstName: lastName,  // Zweite Spalte = Vorname
            ),
          );
          continue;
        }
      }
      
      // Nicht erkannte Zeilen speichern (für Debug)
      if (cleanLine.isNotEmpty && cleanLine.length < 50) {
        invalid.add(cleanLine);
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
