import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/features/noten/noten_matrix_logic.dart';
import 'package:induscore/models/tendenz.dart';

void main() {
  group('NotenMatrixLogic - Tendenz Berechnung', () {
    group('getNoteWithTendenz ignoriert Tendenzen', () {
      test('Note 2 mit Tendenz.plus gibt 2.0 zurück (nicht 1.7)', () {
        final result = NotenMatrixLogic.getNoteWithTendenz(2, Tendenz.plus);
        expect(result, equals(2.0));
        expect(result, isNot(equals(1.7))); // Würde mit Tendenz 1.7 sein
      });

      test('Note 2 mit Tendenz.minus gibt 2.0 zurück (nicht 2.3)', () {
        final result = NotenMatrixLogic.getNoteWithTendenz(2, Tendenz.minus);
        expect(result, equals(2.0));
        expect(result, isNot(equals(2.3))); // Würde mit Tendenz 2.3 sein
      });

      test('Note 2 mit Tendenz.keine gibt 2.0 zurück', () {
        final result = NotenMatrixLogic.getNoteWithTendenz(2, Tendenz.keine);
        expect(result, equals(2.0));
      });

      test('alle Tendenzen ergeben gleichen Wert für gleiche Note', () {
        const note = 3;
        final plusResult = NotenMatrixLogic.getNoteWithTendenz(note, Tendenz.plus);
        final minusResult = NotenMatrixLogic.getNoteWithTendenz(note, Tendenz.minus);
        final keineResult = NotenMatrixLogic.getNoteWithTendenz(note, Tendenz.keine);

        expect(plusResult, equals(keineResult));
        expect(minusResult, equals(keineResult));
        expect(plusResult, equals(3.0));
      });
    });

    group('Tendenzen sind nur visuelle Indikatoren', () {
      test('Note 1 mit allen Tendenzen gibt immer 1.0', () {
        expect(NotenMatrixLogic.getNoteWithTendenz(1, Tendenz.plus), equals(1.0));
        expect(NotenMatrixLogic.getNoteWithTendenz(1, Tendenz.keine), equals(1.0));
        expect(NotenMatrixLogic.getNoteWithTendenz(1, Tendenz.minus), equals(1.0));
      });

      test('Note 6 mit allen Tendenzen gibt immer 6.0', () {
        expect(NotenMatrixLogic.getNoteWithTendenz(6, Tendenz.plus), equals(6.0));
        expect(NotenMatrixLogic.getNoteWithTendenz(6, Tendenz.keine), equals(6.0));
        expect(NotenMatrixLogic.getNoteWithTendenz(6, Tendenz.minus), equals(6.0));
      });

      test('Durchschnittsberechnung verwendet nur Ganzzahl-Noten', () {
        // Simulation: 3 Noten mit verschiedenen Tendenzen
        // Note 2+, 3, 4- sollte Durchschnitt 3.0 sein (nicht 2.7, 3.0, 4.3 = 3.33)
        final noten = [
          NotenMatrixLogic.getNoteWithTendenz(2, Tendenz.plus),  // 2.0
          NotenMatrixLogic.getNoteWithTendenz(3, Tendenz.keine), // 3.0
          NotenMatrixLogic.getNoteWithTendenz(4, Tendenz.minus), // 4.0
        ];
        
        final durchschnitt = noten.reduce((a, b) => a + b) / noten.length;
        expect(durchschnitt, equals(3.0)); // Nicht 3.33!
      });
    });

    group('Rückgabetyp ist immer double', () {
      test('Rückgabewert ist double, nicht int', () {
        final result = NotenMatrixLogic.getNoteWithTendenz(3, Tendenz.keine);
        expect(result, isA<double>());
        expect(result, equals(3.0));
      });

      test('alle Noten 1-6 werden korrekt konvertiert', () {
        for (int note = 1; note <= 6; note++) {
          final result = NotenMatrixLogic.getNoteWithTendenz(note, Tendenz.keine);
          expect(result, equals(note.toDouble()));
        }
      });
    });
  });
}
