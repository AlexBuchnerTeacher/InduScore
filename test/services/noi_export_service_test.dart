import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/services/noi_export_service.dart';
import 'package:induscore/models/student.dart';
import 'package:induscore/models/subject.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/grade.dart';
import 'package:induscore/models/leistungsnachweis.dart';
import 'package:induscore/models/beruf.dart';

void main() {
  group('NoiExportService', () {
    late Klasse testKlasse;
    late List<Student> testStudents;
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

      testStudents = [
        Student(
          id: 'student1',
          firstName: 'Max',
          lastName: 'Müller',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.aktiv,
        ),
        Student(
          id: 'student2',
          firstName: 'Anna',
          lastName: 'Schmidt',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.aktiv,
        ),
        Student(
          id: 'student3',
          firstName: 'Tom',
          lastName: 'Weber',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.ausgetreten, // Inaktiv - sollte nicht exportiert werden
        ),
      ];

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
        Leistungsnachweis(
          id: 'ln3',
          bezeichnung: 'Schulaufgabe 1',
          subjectId: 'subject2',
          klasseId: 'klasse1',
          typ: LeistungsnachweisTyp.wochentest,
          datum: DateTime(2024, 11, 1),
          gewichtung: 2.0,
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
        Grade(
          id: 'grade3',
          studentId: 'student1',
          leistungsnachweisId: 'ln3',
          note: 1,
          createdAt: now,
          updatedAt: now,
        ),
        Grade(
          id: 'grade4',
          studentId: 'student2',
          leistungsnachweisId: 'ln1',
          note: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    group('generateXml', () {
      test('generates valid XML structure', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('<?xml version="1.0" encoding="UTF-8"'));
        expect(xml, contains('<zeugnisnoten-import'));
        expect(xml, contains('</zeugnisnoten-import>'));
      });

      test('includes school year in XML header', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('Schuljahr="2024/25"'));
      });

      test('includes schema version', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('Schemaversion="1.0"'));
      });

      test('includes only active students', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        // Max and Anna are active
        expect(xml, contains('<Name>Müller</Name>'));
        expect(xml, contains('<Vorname>Max</Vorname>'));
        expect(xml, contains('<Name>Schmidt</Name>'));
        expect(xml, contains('<Vorname>Anna</Vorname>'));
        
        // Tom is inactive
        expect(xml, isNot(contains('<Name>Weber</Name>')));
      });

      test('includes student IDs', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('<ID>student1</ID>'));
        expect(xml, contains('<ID>student2</ID>'));
      });

      test('includes class name in student data', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        // Klassenname wird generiert: EAT (Beruf) + 3 (Stufe) + 2 (Zeitgruppe) + 1 (Nummer)
        expect(xml, contains('<Klasse>EAT321</Klasse>'));
      });

      test('handles empty student list', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: [],
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('<zeugnisnoten-import'));
        expect(xml, contains('</zeugnisnoten-import>'));
        expect(xml, isNot(contains('<Schueler>')));
      });

      test('handles student without grades', () {
        final now = DateTime.now();
        final studentWithoutGrades = Student(
          id: 'student_new',
          firstName: 'Neu',
          lastName: 'Schüler',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.aktiv,
        );

        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: [studentWithoutGrades],
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: [],
        );

        expect(xml, contains('<Name>Schüler</Name>'));
        expect(xml, contains('<Vorname>Neu</Vorname>'));
      });

      test('escapes XML special characters', () {
        final now = DateTime.now();
        final studentWithSpecialChars = Student(
          id: 'special',
          firstName: 'Max & Anna',
          lastName: 'O\'Brien <Test>',
          klasseId: 'klasse1',
          eintrittsDatum: now,
          createdAt: now,
          status: StudentStatus.aktiv,
        );

        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: [studentWithSpecialChars],
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: [],
        );

        // Should escape & < > ' "
        expect(xml, isNot(contains('Max & Anna')));
        expect(xml, contains('&amp;'));
      });
    });

    group('XML structure', () {
      test('has Stammdaten section for each student', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('<Stammdaten>'));
        expect(xml, contains('</Stammdaten>'));
      });

      test('has Faecher section for each student', () {
        final xml = NoiExportService.generateXml(
          klasse: testKlasse,
          students: testStudents,
          subjects: testSubjects,
          leistungsnachweise: testLns,
          grades: testGrades,
        );

        expect(xml, contains('<Faecher>'));
        expect(xml, contains('</Faecher>'));
      });
    });

    group('getFilename', () {
      test('generates valid filename from class', () {
        final filename = NoiExportService.getFilename(testKlasse, 'xml');

        expect(filename, contains('EAT321'));
        expect(filename, endsWith('.xml'));
        expect(filename, contains('NOI'));
      });

      test('generates filename with date', () {
        final filename = NoiExportService.getFilename(testKlasse, 'xml');
        final now = DateTime.now();
        final year = now.year.toString();

        expect(filename, contains(year));
      });
    });
  });
}
