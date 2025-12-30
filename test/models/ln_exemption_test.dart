import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/ln_exemption.dart';

void main() {
  group('LnExemption', () {
    test('kann erstellt werden mit allen Pflichtfeldern', () {
      final now = DateTime.now();
      final exemption = LnExemption(
        id: 'e1',
        studentId: 's1',
        leistungsnachweisId: 'ln1',
        createdAt: now,
      );

      expect(exemption.id, 'e1');
      expect(exemption.studentId, 's1');
      expect(exemption.leistungsnachweisId, 'ln1');
      expect(exemption.createdAt, now);
      expect(exemption.grund, isNull);
      expect(exemption.createdBy, isNull);
    });

    test('kann erstellt werden mit optionalen Feldern', () {
      final now = DateTime.now();
      final exemption = LnExemption(
        id: 'e2',
        studentId: 's2',
        leistungsnachweisId: 'ln2',
        createdAt: now,
        grund: 'Krankheit',
        createdBy: 'MU',
      );

      expect(exemption.grund, 'Krankheit');
      expect(exemption.createdBy, 'MU');
    });

    test('toFirestore gibt korrekte Map zurück', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final exemption = LnExemption(
        id: 'e3',
        studentId: 's3',
        leistungsnachweisId: 'ln3',
        createdAt: now,
        grund: 'Entschuldigt',
        createdBy: 'TE',
      );

      final map = exemption.toFirestore();

      expect(map['studentId'], 's3');
      expect(map['leistungsnachweisId'], 'ln3');
      expect(map['grund'], 'Entschuldigt');
      expect(map['createdBy'], 'TE');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('toFirestore ohne optionale Felder', () {
      final exemption = LnExemption(
        id: 'e4',
        studentId: 's4',
        leistungsnachweisId: 'ln4',
        createdAt: DateTime.now(),
      );

      final map = exemption.toFirestore();

      expect(map['grund'], isNull);
      expect(map['createdBy'], isNull);
    });
  });
}
