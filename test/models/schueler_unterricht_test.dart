import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:induscore/models/schueler_unterricht.dart';

void main() {
  group('SchuelerUnterricht', () {
    late DateTime testDate;
    late SchuelerUnterricht testUnterricht;

    setUp(() {
      testDate = DateTime(2025, 1, 15);
      testUnterricht = SchuelerUnterricht(
        id: 'unterricht1',
        studentId: 'student1',
        subjectId: 'subject1',
        lehrerId: 'lehrer1',
        gruppe: 'IT_1',
        klasseId: 'klasse1',
        createdAt: testDate,
      );
    });

    test('uniqueKey generiert korrekten Schlüssel', () {
      expect(testUnterricht.uniqueKey, 'student1_subject1_lehrer1_IT_1');
    });

    test('uniqueKey ohne Gruppe', () {
      final unterricht = SchuelerUnterricht(
        id: 'u2',
        studentId: 's2',
        subjectId: 'sub2',
        lehrerId: 'l2',
        createdAt: testDate,
      );
      expect(unterricht.uniqueKey, 's2_sub2_l2_');
    });

    test('copyWith erstellt Kopie mit geänderten Werten', () {
      final copy = testUnterricht.copyWith(
        studentId: 'student2',
        gruppe: 'AUT_2',
      );

      expect(copy.studentId, 'student2');
      expect(copy.gruppe, 'AUT_2');
      expect(copy.subjectId, testUnterricht.subjectId); // Unverändert
      expect(copy.lehrerId, testUnterricht.lehrerId); // Unverändert
    });

    test('copyWith mit allen Parametern', () {
      final newDate = DateTime(2025, 2, 1);
      final copy = testUnterricht.copyWith(
        id: 'new-id',
        studentId: 'new-student',
        subjectId: 'new-subject',
        lehrerId: 'new-lehrer',
        gruppe: 'E_1',
        klasseId: 'new-klasse',
        createdAt: newDate,
      );

      expect(copy.id, 'new-id');
      expect(copy.studentId, 'new-student');
      expect(copy.subjectId, 'new-subject');
      expect(copy.lehrerId, 'new-lehrer');
      expect(copy.gruppe, 'E_1');
      expect(copy.klasseId, 'new-klasse');
      expect(copy.createdAt, newDate);
    });

    test('toFirestore erstellt korrektes Map', () {
      final map = testUnterricht.toFirestore();

      expect(map['studentId'], 'student1');
      expect(map['subjectId'], 'subject1');
      expect(map['lehrerId'], 'lehrer1');
      expect(map['gruppe'], 'IT_1');
      expect(map['klasseId'], 'klasse1');
      expect(map['createdAt'], isA<Timestamp>());
    });

    // Note: fromFirestore tests removed - DocumentSnapshot is sealed and cannot be mocked
  });
}
