import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/grade.dart';
import 'package:induscore/models/tendenz.dart';

void main() {
  group('Grade', () {
    test('creates grade with all fields', () {
      final grade = Grade(
        id: 'grade1',
        studentId: 'student1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.plus,
        kommentar: 'Gut gemacht',
        updatedBy: 'AB',
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 16),
      );

      expect(grade.id, 'grade1');
      expect(grade.studentId, 'student1');
      expect(grade.leistungsnachweisId, 'ln1');
      expect(grade.note, 2);
      expect(grade.tendenz, Tendenz.plus);
      expect(grade.kommentar, 'Gut gemacht');
      expect(grade.updatedBy, 'AB');
    });

    test('noteFormatiert formats note with tendenz plus', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.plus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.noteFormatiert, '2+');
    });

    test('noteFormatiert formats note with tendenz minus', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 3,
        tendenz: Tendenz.minus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.noteFormatiert, '3-');
    });

    test('noteFormatiert formats note without tendenz', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 1,
        tendenz: Tendenz.keine,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.noteFormatiert, '1');
    });

    test('toFirestore converts to map correctly', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.plus,
        kommentar: 'Test',
        updatedBy: 'AB',
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 16),
      );

      final map = grade.toFirestore();

      expect(map['studentId'], 's1');
      expect(map['leistungsnachweisId'], 'ln1');
      expect(map['note'], 2);
      expect(map['tendenz'], '+');
      expect(map['kommentar'], 'Test');
      expect(map['updatedBy'], 'AB');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('toFirestore handles null kommentar', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 3,
        tendenz: Tendenz.keine,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = grade.toFirestore();
      expect(map['kommentar'], isNull);
    });

    test('toFirestore handles null updatedBy', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 3,
        tendenz: Tendenz.keine,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = grade.toFirestore();
      expect(map['updatedBy'], isNull);
    });

    test('copyWith creates copy with changed values', () {
      final original = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.keine,
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      final copy = original.copyWith(
        note: 3,
        tendenz: Tendenz.plus,
        kommentar: 'Updated',
      );

      expect(copy.id, 'g1');
      expect(copy.studentId, 's1');
      expect(copy.note, 3);
      expect(copy.tendenz, Tendenz.plus);
      expect(copy.kommentar, 'Updated');
    });

    test('copyWith preserves unchanged values', () {
      final original = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.plus,
        kommentar: 'Original',
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      final copy = original.copyWith(note: 3);

      expect(copy.studentId, 's1');
      expect(copy.leistungsnachweisId, 'ln1');
      expect(copy.tendenz, Tendenz.plus);
      expect(copy.kommentar, 'Original');
    });

    test('grades with different notes are different', () {
      final grade1 = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.keine,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final grade2 = grade1.copyWith(note: 3);

      expect(grade1.note, 2);
      expect(grade2.note, 3);
    });

    test('noteFormatiert handles all valid notes 1-6', () {
      for (int note = 1; note <= 6; note++) {
        final grade = Grade(
          id: 'g$note',
          studentId: 's1',
          leistungsnachweisId: 'ln1',
          note: note,
          tendenz: Tendenz.keine,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(grade.noteFormatiert, '$note');
      }
    });

    test('hasKommentar returns true when kommentar exists', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.keine,
        kommentar: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.hasKommentar, true);
    });

    test('hasKommentar returns false when kommentar is null', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.keine,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.hasKommentar, false);
    });

    test('hasKommentar returns false when kommentar is empty', () {
      final grade = Grade(
        id: 'g1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        note: 2,
        tendenz: Tendenz.keine,
        kommentar: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(grade.hasKommentar, false);
    });
  });
}
