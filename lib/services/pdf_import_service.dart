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
/// 
/// Unterstützt verschiedene OCR-Formate der Klassenlisten:
/// - Namen auf einer Zeile: "Nachname, Vorname DD.MM.YYYY"
/// - Namen auf separaten Zeilen: "Nachname, Vorname" gefolgt von "DD.MM.YYYY"
/// - Mit führenden Nummern: "10. Nachname, Vorname"
/// - Klassenname in Überschrift: "Klassenliste ... EAT331"
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

    // Klassenname suchen - verschiedene Varianten:
    // 1. Im normalisierten Text (für OCR mit Leerzeichen: "E A T 3 3 1")
    // 2. In Zeilen wie "Klassenliste mit Notenspalten EAT331"
    final klasseRegex = RegExp(r'(IE|EAT|EBT|EGS)(\d)(\d)(\d)');
    final klasseMatch = klasseRegex.firstMatch(normalizedText);
    
    String? rawClassName;
    ParsedKlassenname? parsedName;
    if (klasseMatch != null) {
      rawClassName =
          '${klasseMatch.group(1)}${klasseMatch.group(2)}${klasseMatch.group(3)}${klasseMatch.group(4)}';
      parsedName = ParsedKlassenname.parse(rawClassName);
    }
    
    // Klassenleiter suchen - verschiedene Formate
    // Format 1: "Klassenleitung: Vorname Nachname" → Vollständiger Name
    // Format 2: "Klassenleiter: XXX" → Kürzel (2-4 Großbuchstaben)
    // Der Nutzer kann das Kürzel im Dialog manuell anpassen
    String? klassenleiterCode;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('klassenleitung') || lowerLine.contains('klassenleiter')) {
        // Extrahiere den Namen nach dem Doppelpunkt
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1 && colonIndex < line.length - 1) {
          final leiterName = line.substring(colonIndex + 1).trim();
          // Suche zuerst nach Kürzel (2-4 Großbuchstaben allein stehend)
          final kuerzelMatch = RegExp(r'^([A-ZÄÖÜ]{2,4})$').firstMatch(leiterName);
          if (kuerzelMatch != null) {
            // Es ist bereits ein Kürzel
            klassenleiterCode = kuerzelMatch.group(1);
          } else if (leiterName.isNotEmpty) {
            // Es ist ein voller Name - diesen übernehmen
            // Der Nutzer kann im Dialog das Kürzel selbst eintragen
            klassenleiterCode = leiterName;
          }
        }
        break;
      }
    }

    // Schüler extrahieren - robuster Multi-Format Parser
    final students = <ImportedStudent>[];
    final invalid = <String>[];
    
    // Pattern für Zeilen die komplett übersprungen werden sollen
    final skipPatterns = [
      'klassenleiter', 'klassenleitung', 'notenliste', 'klassenliste',
      'berufsschule', 'städt.', 'schuljahr', 'stand:', 'seite',
      'schülerzahl', 'davon', 'männl', 'weibl', 
      'schriftlich', 'mündlich', 'gesamt',  // Notenspalten-Header
    ];
    
    // Zeilen die nur "Name" oder ähnliche Header sind
    final headerPatterns = RegExp(r'^(name|vorname|nachname|nr\.?|lfd\.?)$', caseSensitive: false);
    
    // Datum-Pattern (DD.MM.YYYY)
    final datePattern = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    
    // Reine Nummer-Zeile (z.B. "10." "11." "12.")
    final pureNumberPattern = RegExp(r'^\d+\.?$');
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Kurze Zeilen überspringen
      if (line.length < 3) continue;
      
      // Header/Meta-Zeilen überspringen
      final lowerLine = line.toLowerCase();
      if (skipPatterns.any((p) => lowerLine.contains(p))) continue;
      if (headerPatterns.hasMatch(line)) continue;
      
      // Reine Datumszeilen überspringen (gehören zum vorherigen Namen)
      if (datePattern.hasMatch(line)) continue;
      
      // Reine Nummern überspringen (z.B. "10." "11.")
      if (pureNumberPattern.hasMatch(line)) continue;
      
      // Zeilen die nur aus Zahlen/Sonderzeichen bestehen überspringen
      final letterCount = line.replaceAll(RegExp(r'[^a-zA-ZäöüÄÖÜßéèêëàáâ]'), '').length;
      if (letterCount < 3) continue;
      
      // Versuche Namen zu extrahieren
      final student = _parseStudentLine(line);
      if (student != null) {
        students.add(student);
      } else if (line.length < 60 && letterCount >= 4) {
        invalid.add(line);
      }
    }

    return ClassImportPreview(
      rawClassName: rawClassName,
      klassenleiterCode: klassenleiterCode,
      parsedName: parsedName,
      students: students,
      invalidLines: invalid,
      extractedText: text,
    );
  }
  
  /// Versucht aus einer Zeile einen Schülernamen zu extrahieren.
  /// 
  /// Unterstützte Formate:
  /// - "Nachname, Vorname"
  /// - "Nachname, Vorname DD.MM.YYYY"
  /// - "10. Nachname, Vorname"
  /// - "Nachname Vorname" (ohne Komma)
  ImportedStudent? _parseStudentLine(String line) {
    // Entferne führende Nummer (z.B. "10." oder "1)" oder "16. ")
    var cleanLine = line.replaceFirst(RegExp(r'^\d+[\.\)\s]+'), '').trim();
    
    // Entferne Geburtsdatum (DD.MM.YYYY) - kann am Ende oder irgendwo stehen
    cleanLine = cleanLine.replaceAll(RegExp(r'\d{2}\.\d{2}\.\d{4}'), '').trim();
    
    // Entferne trailing Pipes oder Sonderzeichen
    cleanLine = cleanLine.replaceAll(RegExp(r'[\|]+'), '').trim();
    
    // Entferne mehrfache Leerzeichen
    cleanLine = cleanLine.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    if (cleanLine.isEmpty || cleanLine.length < 3) return null;
    
    // Format: "Nachname, Vorname" (mit Komma) - bevorzugt
    if (cleanLine.contains(',')) {
      final commaIndex = cleanLine.indexOf(',');
      final lastName = cleanLine.substring(0, commaIndex).trim();
      final firstName = cleanLine.substring(commaIndex + 1).trim();
      
      if (_isValidName(lastName) && _isValidName(firstName)) {
        return ImportedStudent(lastName: lastName, firstName: firstName);
      }
    }
    
    // Format: "Nachname Vorname" (ohne Komma, durch Leerzeichen getrennt)
    final parts = cleanLine.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      // Erster Teil = Nachname, Rest = Vorname(n)
      final lastName = parts[0];
      final firstName = parts.sublist(1).join(' ');
      
      if (_isValidName(lastName) && _isValidName(firstName)) {
        return ImportedStudent(lastName: lastName, firstName: firstName);
      }
    }
    
    return null;
  }
  
  /// Prüft ob ein String wie ein gültiger Name aussieht.
  bool _isValidName(String name) {
    if (name.isEmpty || name.length < 2) return false;
    // Name sollte hauptsächlich aus Buchstaben bestehen (inkl. Umlaute, Bindestriche, Apostrophe)
    final validChars = RegExp(r"^[A-Za-zÄÖÜäöüßéèêëàáâãåæçñíìîïóòôõøúùûýÿ\-\'\s]+$");
    return validChars.hasMatch(name);
  }
}
