import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/klasse.dart';
import '../models/grade.dart';
import '../models/leistungsnachweis.dart';
import '../models/zeugnisnote.dart';

/// NOI (Noten-Online-Import) Export Service
/// 
/// Generiert XML-Dateien im bayerischen NOI-Format für den Import
/// in das offizielle Notenverwaltungssystem.
/// 
/// Angepasst für Berufsschule (Notensystem 1-6, Halbjahre)
class NoiExportService {
  
  /// Generiert NOI-XML für eine Klasse
  /// 
  /// [klasse] - Die zu exportierende Klasse
  /// [students] - Alle Schüler der Klasse
  /// [subjects] - Alle Fächer
  /// [leistungsnachweise] - Alle LNs der Klasse
  /// [grades] - Alle Noten
  static String generateXml({
    required Klasse klasse,
    required List<Student> students,
    required List<Subject> subjects,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    // XML Header nach ASV-Spezifikation
    // Das Root-Element heißt 'zeugnisnoten-import' (mit i!)
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<zeugnisnoten-import');
    buffer.writeln('    Schuljahr="${klasse.schuljahr}"');
    buffer.writeln('    Schemaversion="1.0"');
    buffer.writeln('    Generierungsdatum="${dateFormat.format(now)}">');
    
    // Map für schnellen Zugriff
    final subjectsById = {for (var s in subjects) s.id: s};
    final lnById = {for (var ln in leistungsnachweise) ln.id: ln};
    
    // Für jeden Schüler
    for (final student in students.where((s) => s.isAktiv)) {
      buffer.writeln('    <Schueler>');
      buffer.writeln('        <Stammdaten>');
      buffer.writeln('            <ID>${_escapeXml(student.id)}</ID>');
      buffer.writeln('            <Name>${_escapeXml(student.lastName)}</Name>');
      buffer.writeln('            <Vorname>${_escapeXml(student.firstName)}</Vorname>');
      buffer.writeln('            <Klasse>${_escapeXml(klasse.name)}</Klasse>');
      buffer.writeln('        </Stammdaten>');
      
      // Noten des Schülers
      final studentGrades = grades.where((g) => g.studentId == student.id).toList();
      
      // Gruppiere nach Fach
      final gradesBySubject = <String, List<Grade>>{};
      for (final grade in studentGrades) {
        final ln = lnById[grade.leistungsnachweisId];
        if (ln != null) {
          gradesBySubject.putIfAbsent(ln.subjectId, () => []).add(grade);
        }
      }
      
      buffer.writeln('        <Faecher>');
      
      for (final entry in gradesBySubject.entries) {
        final subject = subjectsById[entry.key];
        if (subject == null) continue;
        
        final fachGrades = entry.value;
        
        // Berechne Durchschnitte
        final notenMitGewichtung = <({int note, double gewichtung})>[];
        double summeSchriftlich = 0;
        int countSchriftlich = 0;
        double summeMuendlich = 0;
        int countMuendlich = 0;
        
        for (final grade in fachGrades) {
          final ln = lnById[grade.leistungsnachweisId];
          if (ln != null) {
            notenMitGewichtung.add((note: grade.note, gewichtung: ln.gewichtung));
            
            // Unterscheide schriftlich/mündlich anhand Gewichtung
            // Gewichtung >= 2 = schriftlich (Wochentest mit hoher Gewichtung)
            // Gewichtung < 2 = mündlich/praktisch
            if (ln.gewichtung >= 2) {
              summeSchriftlich += grade.note;
              countSchriftlich++;
            } else {
              summeMuendlich += grade.note;
              countMuendlich++;
            }
          }
        }
        
        final schnittGesamt = Zeugnisnote.berechneSchnitt(notenMitGewichtung);
        final zeugnisnote = Zeugnisnote.berechneZeugnisnote(notenMitGewichtung);
        final schnittSchriftlich = countSchriftlich > 0 
            ? summeSchriftlich / countSchriftlich 
            : null;
        final schnittMuendlich = countMuendlich > 0 
            ? summeMuendlich / countMuendlich 
            : null;
        
        buffer.writeln('            <Fach>');
        buffer.writeln('                <Kurzform>${_escapeXml(subject.shortName ?? subject.name)}</Kurzform>');
        buffer.writeln('                <Name>${_escapeXml(subject.name)}</Name>');
        buffer.writeln('                <Typ>${subject.typ.code}</Typ>');
        buffer.writeln('                <Leistung>');
        
        if (schnittMuendlich != null) {
          buffer.writeln('                    <Schnitt_Muendlich>${schnittMuendlich.toStringAsFixed(2)}</Schnitt_Muendlich>');
        }
        if (schnittSchriftlich != null) {
          buffer.writeln('                    <Schnitt_Schriftlich>${schnittSchriftlich.toStringAsFixed(2)}</Schnitt_Schriftlich>');
        }
        if (schnittGesamt != null) {
          buffer.writeln('                    <Schnitt_Gesamt>${schnittGesamt.toStringAsFixed(2)}</Schnitt_Gesamt>');
        }
        if (zeugnisnote != null) {
          buffer.writeln('                    <Zeugnisnote>$zeugnisnote</Zeugnisnote>');
        }
        
        buffer.writeln('                    <Anzahl_Noten>${fachGrades.length}</Anzahl_Noten>');
        buffer.writeln('                </Leistung>');
        
        // Einzelnoten
        buffer.writeln('                <Einzelnoten>');
        for (final grade in fachGrades) {
          final ln = lnById[grade.leistungsnachweisId];
          if (ln != null) {
            buffer.writeln('                    <Note>');
            buffer.writeln('                        <Wert>${grade.note}</Wert>');
            buffer.writeln('                        <Typ>${ln.typ.label}</Typ>');
            buffer.writeln('                        <Bezeichnung>${_escapeXml(ln.bezeichnung)}</Bezeichnung>');
            buffer.writeln('                        <Gewichtung>${ln.gewichtung}</Gewichtung>');
            buffer.writeln('                        <Datum>${dateFormat.format(grade.createdAt)}</Datum>');
            buffer.writeln('                    </Note>');
          }
        }
        buffer.writeln('                </Einzelnoten>');
        
        buffer.writeln('            </Fach>');
      }
      
      buffer.writeln('        </Faecher>');
      buffer.writeln('    </Schueler>');
    }
    
    buffer.writeln('</zeugnisnoten-import>');
    
    return buffer.toString();
  }
  
  /// Generiert CSV als Alternative zum XML
  static String generateCsv({
    required Klasse klasse,
    required List<Student> students,
    required List<Subject> subjects,
    required List<Leistungsnachweis> leistungsnachweise,
    required List<Grade> grades,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Nachname;Vorname;Fach;Schnitt;Zeugnisnote;Anzahl Noten');
    
    final subjectsById = {for (var s in subjects) s.id: s};
    final lnById = {for (var ln in leistungsnachweise) ln.id: ln};
    
    for (final student in students.where((s) => s.isAktiv)) {
      final studentGrades = grades.where((g) => g.studentId == student.id).toList();
      
      // Gruppiere nach Fach
      final gradesBySubject = <String, List<Grade>>{};
      for (final grade in studentGrades) {
        final ln = lnById[grade.leistungsnachweisId];
        if (ln != null) {
          gradesBySubject.putIfAbsent(ln.subjectId, () => []).add(grade);
        }
      }
      
      for (final entry in gradesBySubject.entries) {
        final subject = subjectsById[entry.key];
        if (subject == null) continue;
        
        final fachGrades = entry.value;
        final notenMitGewichtung = <({int note, double gewichtung})>[];
        
        for (final grade in fachGrades) {
          final ln = lnById[grade.leistungsnachweisId];
          if (ln != null) {
            notenMitGewichtung.add((note: grade.note, gewichtung: ln.gewichtung));
          }
        }
        
        final schnitt = Zeugnisnote.berechneSchnitt(notenMitGewichtung);
        final zeugnisnote = Zeugnisnote.berechneZeugnisnote(notenMitGewichtung);
        
        buffer.writeln([
          student.lastName,
          student.firstName,
          subject.shortName ?? subject.name,
          schnitt?.toStringAsFixed(2) ?? '-',
          zeugnisnote?.toString() ?? '-',
          fachGrades.length.toString(),
        ].join(';'));
      }
    }
    
    return buffer.toString();
  }
  
  /// Escape XML special characters
  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
  
  /// Generiert Dateinamen für Export
  static String getFilename(Klasse klasse, String extension) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(now);
    return 'NOI_${klasse.name}_$timestamp.$extension';
  }
}
