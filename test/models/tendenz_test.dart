import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/tendenz.dart';

void main() {
  group('Tendenz enum', () {
    test('fromString returns correct Tendenz for plus symbol', () {
      expect(Tendenz.fromString('+'), Tendenz.plus);
    });

    test('fromString returns correct Tendenz for minus symbol', () {
      expect(Tendenz.fromString('-'), Tendenz.minus);
    });

    test('fromString returns keine for empty string', () {
      expect(Tendenz.fromString(''), Tendenz.keine);
    });

    test('fromString returns keine for null', () {
      expect(Tendenz.fromString(null), Tendenz.keine);
    });

    test('fromString returns keine for invalid value', () {
      expect(Tendenz.fromString('invalid'), Tendenz.keine);
      expect(Tendenz.fromString('*'), Tendenz.keine);
    });

    test('symbol property returns correct string', () {
      expect(Tendenz.plus.symbol, '+');
      expect(Tendenz.minus.symbol, '-');
      expect(Tendenz.keine.symbol, '');
    });

    test('enum has exactly 3 values', () {
      expect(Tendenz.values.length, 3);
      expect(Tendenz.values, containsAll([Tendenz.plus, Tendenz.minus, Tendenz.keine]));
    });
  });
}
