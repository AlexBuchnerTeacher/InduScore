import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/services/pdf_export_service.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/grade.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/beruf.dart';

void main() {
  group('PdfExportService', () {
    late Klasse testKlasse;
    late Student testStudent;
    late List<Subject> testSubjects;
    late List<Leistungsnachweis> testLns;
    late List<Grade> testGrades;

    setUp(() {
      final now = DateTime.now();
      
      testKlasse = Klasse(
        id: 'klasse1',
        beruf: Beruf.eat,
        jahrgangsstufe: 3,
        zeitgruppe: Zeitgruppe.zwei,
        laufendeNummer: 1,
        schuljahr: Schuljahr(2024, 2025),
        createdAt: now,
        updatedAt: now,
      );

      testStudent = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Müller',
        klasseId: 'klasse1',
        eintrittsDatum: now,
        createdAt: now,
        status: StudentStatus.aktiv,
      );

      testSubjects = [
        Subject(
          id: 'subject1',
          name: 'Deutsch',
          shortName: 'D',
          typ: FachTyp.allgemein,
          berufe: [Beruf.eat],
          createdAt: now,
        ),
        Subject(
          id: 'subject2',
          name: 'Mathematik',
          shortName: 'M',
          typ: FachTyp.allgemein,
          berufe: [Beruf.eat],
          createdAt: now,
        ),
      ];

      testLns = [
        Leistungsnachweis(
          id: 'ln1',
          bezeichnung: 'Schulaufgabe 1',
          subjectId: 'subject1',
          klasseId: 'klasse1',
          typ: LeistungsnachweisTyp.wochentest,
          datum: DateTime(2024, 10, 15),
          gewichtung: 2.0,
          createdAt: now,
          updatedAt: now,
        ),
        Leistungsnachweis(
          id: 'ln2',
          bezeichnung: 'Stegreifaufgabe 1',
          subjectId: 'subject1',
          klasseId: 'klasse1',
          typ: LeistungsnachweisTyp.wochentest,
          datum: DateTime(2024, 10, 20),
          gewichtung: 1.0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      testGrades = [
        Grade(
          id: 'grade1',
          studentId: 'student1',
          leistungsnachweisId: 'ln1',
          note: 2,
          createdAt: now,
          updatedAt: now,
        ),
        Grade(
          id: 'grade2',
          studentId: 'student1',
          leistungsnachweisId: 'ln2',
          note: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    group('generateStudentReport', () {
      test('generates non-empty PDF bytes', () {
        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes.length, greaterThan(100)); // Basic PDF structure
      });

      test('generates valid PDF header', () {
        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        // PDF files start with %PDF-
        final pdfHeader = String.fromCharCodes(pdfBytes.take(5));
        expect(pdfHeader, '%PDF-');
      });

      test('generates PDF with halbjahr parameter', () {
        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
          halbjahr: '1',
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('handles student without grades', () {
        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: [],
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('handles empty subjects list', () {
        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: [],
          leistungsnachweise: [],
          grades: [],
        );

        expect(pdfBytes, isNotEmpty);
      });
    });

    group('generateSubjectReport', () {
      test('generates non-empty PDF bytes', () {
        final students = [testStudent];

        final pdfBytes = PdfExportService.generateSubjectReport(
          subject: testSubjects[0],
          klasse: testKlasse,
          students: students,
          leistungsnachweise: testLns.where((ln) => ln.subjectId == 'subject1').toList(),
          grades: testGrades,
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('generates valid PDF header', () {
        final pdfBytes = PdfExportService.generateSubjectReport(
          subject: testSubjects[0],
          klasse: testKlasse,
          students: [testStudent],
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        final pdfHeader = String.fromCharCodes(pdfBytes.take(5));
        expect(pdfHeader, '%PDF-');
      });

      test('handles empty student list', () {
        final pdfBytes = PdfExportService.generateSubjectReport(
          subject: testSubjects[0],
          klasse: testKlasse,
          students: [],
          leistungsnachweise: testLns,
          grades: [],
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('handles single student', () {
        final pdfBytes = PdfExportService.generateSubjectReport(
          subject: testSubjects[0],
          klasse: testKlasse,
          students: [testStudent],
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('handles halbjahr parameter', () {
        final pdfBytes = PdfExportService.generateSubjectReport(
          subject: testSubjects[0],
          klasse: testKlasse,
          students: [testStudent],
          leistungsnachweise: testLns,
          grades: testGrades,
          halbjahr: '1',
        );

        expect(pdfBytes, isNotEmpty);
      });
    });

    group('Special characters handling', () {
      test('handles German umlauts in student name', () {
        final now = DateTime.now();
        final studentWithUmlauts = Student(
          id: 'special',
          firstName: 'Björn',
          lastName: 'Müller-Schröder',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.aktiv,
        );

        final pdfBytes = PdfExportService.generateStudentReport(
          student: studentWithUmlauts,
          klasse: testKlasse,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: [],
        );

        expect(pdfBytes, isNotEmpty);
      });

      test('handles special characters in subject name', () {
        final now = DateTime.now();
        final subjectWithSpecialChars = Subject(
          id: 'special_subject',
          name: 'Wirtschaft & Recht (WR)',
          shortName: 'W&R',
          typ: FachTyp.allgemein,
          berufe: [Beruf.eat],
          createdAt: now,
        );

        final pdfBytes = PdfExportService.generateStudentReport(
          student: testStudent,
          klasse: testKlasse,
          subjects: [subjectWithSpecialChars],
          leistungsnachweise: [],
          grades: [],
        );

        expect(pdfBytes, isNotEmpty);
      });
    });

    group('getFilename', () {
      test('generates filename with type and name', () {
        final filename = PdfExportService.getFilename('Schueler', 'Max_Mueller');

        expect(filename, contains('Schueler'));
        expect(filename, contains('Max_Mueller'));
        expect(filename, endsWith('.pdf'));
        expect(filename, startsWith('InduScore_'));
      });

      test('sanitizes special characters in name', () {
        final filename = PdfExportService.getFilename('Klasse', 'G12 IT 2024');

        expect(filename, contains('G12_IT_2024'));
        expect(filename, isNot(contains(' ')));
      });

      test('includes date in filename', () {
        final filename = PdfExportService.getFilename('Fach', 'Deutsch');
        final now = DateTime.now();
        final expectedDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

        expect(filename, contains(expectedDate));
      });
    });
  });
}
