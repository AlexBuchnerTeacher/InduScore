import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/tendenz.dart';

void main() {
  group('NotenEingabe', () {
    test('creates instance with all fields', () {
      final eingabe = NotenEingabe(
        note: 2,
        tendenz: Tendenz.plus,
        kommentar: 'Test comment',
        existingGradeId: 'grade123',
        updatedBy: 'Test User',
      );

      expect(eingabe.note, 2);
      expect(eingabe.tendenz, Tendenz.plus);
      expect(eingabe.kommentar, 'Test comment');
      expect(eingabe.existingGradeId, 'grade123');
      expect(eingabe.updatedBy, 'Test User');
    });

    test('creates instance with null note', () {
      final eingabe = NotenEingabe(
        note: null,
        tendenz: Tendenz.keine,
        updatedBy: null,
      );

      expect(eingabe.note, isNull);
      expect(eingabe.tendenz, Tendenz.keine);
      expect(eingabe.updatedBy, isNull);
    });

    test('creates instance with minimum valid note (1)', () {
      final eingabe = NotenEingabe(
        note: 1,
        tendenz: Tendenz.keine,
        updatedBy: 'User',
      );

      expect(eingabe.note, 1);
    });

    test('creates instance with maximum valid note (6)', () {
      final eingabe = NotenEingabe(
        note: 6,
        tendenz: Tendenz.keine,
        updatedBy: 'User',
      );

      expect(eingabe.note, 6);
    });

    test('creates instance with plus tendenz', () {
      final eingabe = NotenEingabe(
        note: 3,
        tendenz: Tendenz.plus,
        updatedBy: 'User',
      );

      expect(eingabe.tendenz, Tendenz.plus);
    });

    test('creates instance with minus tendenz', () {
      final eingabe = NotenEingabe(
        note: 3,
        tendenz: Tendenz.minus,
        updatedBy: 'User',
      );

      expect(eingabe.tendenz, Tendenz.minus);
    });

    test('creates instance without updatedBy', () {
      final eingabe = NotenEingabe(
        note: 4,
        tendenz: Tendenz.keine,
        updatedBy: null,
      );

      expect(eingabe.updatedBy, isNull);
    });
  });
}
