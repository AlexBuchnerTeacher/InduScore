import 'dart:typed_data';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/student.dart';
import '../models/subject.dart';
import '../models/klasse.dart';
import '../models/grade.dart';
import '../models/leistungsnachweis.dart';
import '../models/zeugnisnote.dart';

/// PDF Export Service für Notenübersichten
/// 
/// Generiert professionelle PDF-Dokumente:
/// - Notenblatt pro Schüler (alle Fächer)
/// - Notenliste pro Fach (alle Schüler)
class PdfExportService {
  // RBS Farben
  static final _dynamicRed = PdfColor(227, 6, 19);
  static final _darkGray = PdfColor(51, 51, 51);
  static final _lightGray = PdfColor(245, 245, 245);

  /// Generiert Notenblatt für einen Schüler
  /// 
  /// Zeigt alle Fächer mit Einzelnoten, Schnitt und Zeugnisnote
  static Uint8List generateStudentReport({
    required Student student,
    required Klasse klasse,
    required List<Subject> subjects,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
    String? halbjahr,
  }) {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final pageSize = page.getClientSize();

    // Fonts
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    var y = 0.0;

    // Header mit Logo-Platzhalter
    graphics.drawRectangle(
      brush: PdfSolidBrush(_dynamicRed),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 50),
    );
    graphics.drawString(
      'InduScore - Notenübersicht',
      titleFont,
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(20, 15, pageSize.width - 40, 30),
    );
    y = 70;

    // Schülerdaten
    graphics.drawString(
      'Schüler: ${student.displayName}',
      headerFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(20, y, pageSize.width / 2, 20),
    );
    graphics.drawString(
      'Klasse: ${klasse.name}',
      headerFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(pageSize.width / 2, y, pageSize.width / 2 - 20, 20),
    );
    y += 25;

    graphics.drawString(
      'Schuljahr: ${klasse.schuljahr}${halbjahr != null ? " - $halbjahr. Halbjahr" : ""}',
      normalFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 20),
    );
    y += 30;

    // Trennlinie
    graphics.drawLine(
      PdfPen(_dynamicRed, width: 2),
      Offset(20, y),
      Offset(pageSize.width - 20, y),
    );
    y += 20;

    // Noten nach Fach gruppieren
    final studentGrades = grades.where((g) => g.studentId == student.id).toList();
    final lnById = {for (var ln in leistungsnachweise) ln.id: ln};
    final subjectsById = {for (var s in subjects) s.id: s};

    // Gruppiere nach Fach
    final gradesBySubject = <String, List<Grade>>{};
    for (final grade in studentGrades) {
      final ln = lnById[grade.leistungsnachweisId];
      if (ln != null) {
        gradesBySubject.putIfAbsent(ln.subjectId, () => []).add(grade);
      }
    }

    // Tabelle für jedes Fach
    for (final entry in gradesBySubject.entries) {
      final subject = subjectsById[entry.key];
      if (subject == null) continue;

      final fachGrades = entry.value;

      // Berechne Schnitt und Zeugnisnote
      final notenMitGewichtung = <({int note, double gewichtung})>[];
      for (final grade in fachGrades) {
        final ln = lnById[grade.leistungsnachweisId];
        if (ln != null) {
          notenMitGewichtung.add((note: grade.note, gewichtung: ln.gewichtung));
        }
      }
      final schnitt = Zeugnisnote.berechneSchnitt(notenMitGewichtung);
      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(notenMitGewichtung);

      // Fachüberschrift
      graphics.drawRectangle(
        brush: PdfSolidBrush(_lightGray),
        bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 22),
      );
      graphics.drawString(
        subject.name,
        headerFont,
        brush: PdfSolidBrush(_darkGray),
        bounds: Rect.fromLTWH(25, y + 4, 200, 18),
      );
      graphics.drawString(
        'Schnitt: ${schnitt?.toStringAsFixed(2) ?? "-"}  |  Zeugnisnote: ${zeugnisnote ?? "-"}',
        headerFont,
        brush: PdfSolidBrush(_dynamicRed),
        bounds: Rect.fromLTWH(pageSize.width - 220, y + 4, 200, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      y += 26;

      // Einzelnoten
      for (final grade in fachGrades) {
        final ln = lnById[grade.leistungsnachweisId];
        if (ln == null) continue;

        graphics.drawString(
          '${ln.typ.label}: ${ln.bezeichnung}',
          normalFont,
          brush: PdfSolidBrush(_darkGray),
          bounds: Rect.fromLTWH(30, y, 300, 16),
        );
        graphics.drawString(
          'Note: ${grade.note}',
          normalFont,
          brush: PdfSolidBrush(_darkGray),
          bounds: Rect.fromLTWH(340, y, 60, 16),
        );
        graphics.drawString(
          'Gewichtung: ${ln.gewichtung}x',
          smallFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)),
          bounds: Rect.fromLTWH(410, y + 1, 100, 16),
        );
        y += 18;

        // Seitenumbruch prüfen
        if (y > pageSize.height - 80) {
          document.pages.add();
          y = 30;
        }
      }

      y += 15; // Abstand zum nächsten Fach
    }

    // Footer
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    graphics.drawString(
      'Erstellt am ${dateFormat.format(DateTime.now())} mit InduScore',
      smallFont,
      brush: PdfSolidBrush(PdfColor(128, 128, 128)),
      bounds: Rect.fromLTWH(20, pageSize.height - 30, pageSize.width - 40, 20),
    );

    final bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Generiert Notenliste für ein Fach
  /// 
  /// Zeigt alle Schüler mit ihren Noten für dieses Fach
  static Uint8List generateSubjectReport({
    required Subject subject,
    required Klasse klasse,
    required List<Student> students,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
    String? halbjahr,
  }) {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final pageSize = page.getClientSize();

    // Fonts
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    final normalFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    var y = 0.0;

    // Header
    graphics.drawRectangle(
      brush: PdfSolidBrush(_dynamicRed),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 50),
    );
    graphics.drawString(
      'InduScore - Fachnoten',
      titleFont,
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(20, 15, pageSize.width - 40, 30),
    );
    y = 70;

    // Fach- und Klassendaten
    graphics.drawString(
      'Fach: ${subject.name}',
      headerFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(20, y, pageSize.width / 2, 20),
    );
    graphics.drawString(
      'Klasse: ${klasse.name}',
      headerFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(pageSize.width / 2, y, pageSize.width / 2 - 20, 20),
    );
    y += 25;

    graphics.drawString(
      'Schuljahr: ${klasse.schuljahr}${halbjahr != null ? " - $halbjahr. Halbjahr" : ""}',
      normalFont,
      brush: PdfSolidBrush(_darkGray),
      bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 20),
    );
    y += 30;

    // Trennlinie
    graphics.drawLine(
      PdfPen(_dynamicRed, width: 2),
      Offset(20, y),
      Offset(pageSize.width - 20, y),
    );
    y += 15;

    // LNs für dieses Fach
    final fachLns = leistungsnachweise
        .where((ln) => ln.subjectId == subject.id && ln.klasseId == klasse.id)
        .toList();
    fachLns.sort((a, b) => a.datum.compareTo(b.datum));

    // lnById wird für spätere Erweiterungen vorgehalten
    // final lnById = {for (var ln in fachLns) ln.id: ln};

    // Tabellenkopf
    graphics.drawRectangle(
      brush: PdfSolidBrush(_lightGray),
      bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 20),
    );

    var x = 25.0;
    graphics.drawString('Nr.', headerFont, bounds: Rect.fromLTWH(x, y + 3, 25, 16));
    x += 30;
    graphics.drawString('Schüler', headerFont, bounds: Rect.fromLTWH(x, y + 3, 150, 16));
    x += 155;

    // LN-Überschriften (gekürzt)
    final lnWidth = (pageSize.width - x - 100) / (fachLns.isNotEmpty ? fachLns.length : 1);
    for (final ln in fachLns) {
      final label = ln.bezeichnung.length > 8 
          ? '${ln.bezeichnung.substring(0, 6)}..' 
          : ln.bezeichnung;
      graphics.drawString(
        label,
        smallFont,
        bounds: Rect.fromLTWH(x, y + 4, lnWidth - 2, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      x += lnWidth;
    }

    // Schnitt und Zeugnisnote Spalten
    graphics.drawString('Ø', headerFont, bounds: Rect.fromLTWH(x, y + 3, 35, 16), 
        format: PdfStringFormat(alignment: PdfTextAlignment.center));
    graphics.drawString('Note', headerFont, bounds: Rect.fromLTWH(x + 40, y + 3, 35, 16),
        format: PdfStringFormat(alignment: PdfTextAlignment.center));

    y += 24;

    // Schüler sortieren
    final sortedStudents = students.where((s) => s.klasseId == klasse.id && s.isAktiv).toList();
    sortedStudents.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // Zeilen für jeden Schüler
    var rowNum = 1;
    for (final student in sortedStudents) {
      // Zebra-Streifen
      if (rowNum % 2 == 0) {
        graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(250, 250, 250)),
          bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 18),
        );
      }

      x = 25.0;
      graphics.drawString('$rowNum.', normalFont, bounds: Rect.fromLTWH(x, y + 2, 25, 16));
      x += 30;
      graphics.drawString(
        '${student.lastName}, ${student.firstName}',
        normalFont,
        bounds: Rect.fromLTWH(x, y + 2, 150, 16),
      );
      x += 155;

      // Noten für jeden LN
      final studentGrades = grades.where((g) => g.studentId == student.id).toList();
      final notenMitGewichtung = <({int note, double gewichtung})>[];

      for (final ln in fachLns) {
        final grade = studentGrades.firstWhere(
          (g) => g.leistungsnachweisId == ln.id,
          orElse: () => Grade(
            id: '', studentId: '', leistungsnachweisId: '', note: 0, createdAt: DateTime.now(), updatedAt: DateTime.now(),
          ),
        );
        
        if (grade.id.isNotEmpty) {
          graphics.drawString(
            '${grade.note}',
            normalFont,
            bounds: Rect.fromLTWH(x, y + 2, lnWidth - 2, 16),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          notenMitGewichtung.add((note: grade.note, gewichtung: ln.gewichtung));
        } else {
          graphics.drawString(
            '-',
            normalFont,
            brush: PdfSolidBrush(PdfColor(180, 180, 180)),
            bounds: Rect.fromLTWH(x, y + 2, lnWidth - 2, 16),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
        x += lnWidth;
      }

      // Schnitt und Zeugnisnote
      final schnitt = Zeugnisnote.berechneSchnitt(notenMitGewichtung);
      final zeugnisnote = Zeugnisnote.berechneZeugnisnote(notenMitGewichtung);

      graphics.drawString(
        schnitt?.toStringAsFixed(1) ?? '-',
        normalFont,
        brush: PdfSolidBrush(schnitt != null ? _darkGray : PdfColor(180, 180, 180)),
        bounds: Rect.fromLTWH(x, y + 2, 35, 16),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      graphics.drawString(
        zeugnisnote?.toString() ?? '-',
        headerFont,
        brush: PdfSolidBrush(zeugnisnote != null ? _dynamicRed : PdfColor(180, 180, 180)),
        bounds: Rect.fromLTWH(x + 40, y + 2, 35, 16),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      y += 18;
      rowNum++;

      // Seitenumbruch
      if (y > pageSize.height - 60) {
        document.pages.add();
        y = 30;
      }
    }

    // Klassenstatistik
    y += 20;
    graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200)),
      Offset(20, y),
      Offset(pageSize.width - 20, y),
    );
    y += 10;
    graphics.drawString(
      'Anzahl Schüler: ${sortedStudents.length}  |  Leistungsnachweise: ${fachLns.length}',
      smallFont,
      brush: PdfSolidBrush(PdfColor(128, 128, 128)),
      bounds: Rect.fromLTWH(20, y, pageSize.width - 40, 16),
    );

    // Footer
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    graphics.drawString(
      'Erstellt am ${dateFormat.format(DateTime.now())} mit InduScore',
      smallFont,
      brush: PdfSolidBrush(PdfColor(128, 128, 128)),
      bounds: Rect.fromLTWH(20, pageSize.height - 30, pageSize.width - 40, 20),
    );

    final bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Generiert Dateinamen
  static String getFilename(String type, String name) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd').format(now);
    final safeName = name.replaceAll(RegExp(r'[^\w]'), '_');
    return 'InduScore_${type}_${safeName}_$timestamp.pdf';
  }
}
