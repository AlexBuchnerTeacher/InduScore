import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/noten_statistik.dart';

void main() {
  group('NotenStatistik', () {
    test('creates instance with all fields', () {
      final statistik = NotenStatistik(
        durchschnitt: 2.5,
        anzahl: 10,
        gesamt: 15,
        verteilung: {1: 2, 2: 3, 3: 5},
      );

      expect(statistik.durchschnitt, 2.5);
      expect(statistik.anzahl, 10);
      expect(statistik.gesamt, 15);
      expect(statistik.verteilung, {1: 2, 2: 3, 3: 5});
    });

    test('creates instance with zero notes', () {
      final statistik = NotenStatistik(
        durchschnitt: null,
        anzahl: 0,
        gesamt: 10,
        verteilung: {},
      );

      expect(statistik.durchschnitt, isNull);
      expect(statistik.anzahl, 0);
      expect(statistik.gesamt, 10);
      expect(statistik.verteilung, isEmpty);
    });

    test('creates instance with perfect average (1.0)', () {
      final statistik = NotenStatistik(
        durchschnitt: 1.0,
        anzahl: 5,
        gesamt: 5,
        verteilung: {1: 5},
      );

      expect(statistik.durchschnitt, 1.0);
      expect(statistik.anzahl, 5);
    });

    test('creates instance with worst average (6.0)', () {
      final statistik = NotenStatistik(
        durchschnitt: 6.0,
        anzahl: 3,
        gesamt: 3,
        verteilung: {6: 3},
      );

      expect(statistik.durchschnitt, 6.0);
      expect(statistik.anzahl, 3);
    });

    test('creates instance with decimal values', () {
      final statistik = NotenStatistik(
        durchschnitt: 3.456,
        anzahl: 15,
        gesamt: 20,
        verteilung: {2: 5, 3: 7, 4: 3},
      );

      expect(statistik.durchschnitt, closeTo(3.456, 0.001));
      expect(statistik.anzahl, 15);
      expect(statistik.gesamt, 20);
    });

    test('verteilung shows grade distribution', () {
      final statistik = NotenStatistik(
        durchschnitt: 2.8,
        anzahl: 8,
        gesamt: 10,
        verteilung: {1: 1, 2: 3, 3: 2, 4: 2},
      );

      expect(statistik.verteilung.keys, containsAll([1, 2, 3, 4]));
      expect(statistik.verteilung[1], 1);
      expect(statistik.verteilung[2], 3);
    });

    test('null durchschnitt when no grades entered', () {
      final statistik = NotenStatistik(
        durchschnitt: null,
        anzahl: 0,
        gesamt: 5,
        verteilung: {},
      );

      expect(statistik.durchschnitt, isNull);
    });
  });
}
