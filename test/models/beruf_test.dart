import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/beruf.dart';

void main() {
  group('Beruf', () {
    test('fromCode returns correct Beruf', () {
      expect(Beruf.fromCode('EAT'), Beruf.eat);
      expect(Beruf.fromCode('IE'), Beruf.ie);
      expect(Beruf.fromCode('EBT'), Beruf.ebt);
      expect(Beruf.fromCode('EGS'), Beruf.egs);
    });

    test('fromCode throws for invalid code', () {
      expect(
        () => Beruf.fromCode('INVALID'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Beruf properties are correct', () {
      expect(Beruf.eat.code, 'EAT');
      expect(Beruf.eat.name, 'Elektroniker für Automatisierungstechnik');

      expect(Beruf.ie.code, 'IE');
      expect(Beruf.ie.name, 'Industrieelektroniker');

      expect(Beruf.ebt.code, 'EBT');
      expect(Beruf.egs.code, 'EGS');
    });

    test('all Berufe have unique codes', () {
      final codes = Beruf.values.map((b) => b.code).toSet();
      expect(codes.length, Beruf.values.length);
    });

    test('enum has exactly 4 values', () {
      expect(Beruf.values.length, 4);
    });
  });

  group('Zeitgruppe', () {
    test('fromNummer returns correct Zeitgruppe', () {
      expect(Zeitgruppe.fromNummer(1), Zeitgruppe.eins);
      expect(Zeitgruppe.fromNummer(2), Zeitgruppe.zwei);
      expect(Zeitgruppe.fromNummer(3), Zeitgruppe.drei);
    });

    test('fromNummer throws for invalid nummer', () {
      expect(
        () => Zeitgruppe.fromNummer(0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Zeitgruppe.fromNummer(99),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Zeitgruppe properties are correct', () {
      expect(Zeitgruppe.eins.nummer, 1);
      expect(Zeitgruppe.eins.name, 'Zeitgruppe 1');

      expect(Zeitgruppe.zwei.nummer, 2);
      expect(Zeitgruppe.zwei.name, 'Zeitgruppe 2');

      expect(Zeitgruppe.drei.nummer, 3);
      expect(Zeitgruppe.drei.name, 'Zeitgruppe 3');
    });

    test('all Zeitgruppen have unique nummers', () {
      final nummers = Zeitgruppe.values.map((z) => z.nummer).toSet();
      expect(nummers.length, Zeitgruppe.values.length);
    });
  });

  group('Schuljahr', () {
    test('fromString parses valid Schuljahr with slash', () {
      final sj = Schuljahr.fromString('2024/25');
      expect(sj.startYear, 2024);
      expect(sj.endYear, 2025);
    });

    test('fromString parses valid Schuljahr with dash', () {
      final sj = Schuljahr.fromString('2024-25');
      expect(sj.startYear, 2024);
      expect(sj.endYear, 2025);
    });

    test('fromString handles 4-digit end year', () {
      final sj = Schuljahr.fromString('2024/2025');
      expect(sj.startYear, 2024);
      expect(sj.endYear, 2025);
    });

    test('fromString throws for invalid format', () {
      expect(
        () => Schuljahr.fromString('invalid'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Schuljahr.fromString(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('current returns correct Schuljahr', () {
      final sj = Schuljahr.current();
      final now = DateTime.now();
      
      if (now.month >= 8) {
        expect(sj.startYear, now.year);
        expect(sj.endYear, now.year + 1);
      } else {
        expect(sj.startYear, now.year - 1);
        expect(sj.endYear, now.year);
      }
    });

    test('toString formats correctly', () {
      final sj = Schuljahr(2024, 2025);
      expect(sj.toString(), '2024/25');
    });

    test('equality works correctly', () {
      final sj1 = Schuljahr(2024, 2025);
      final sj2 = Schuljahr(2024, 2025);
      final sj3 = Schuljahr(2023, 2024);

      expect(sj1 == sj2, true);
      expect(sj1 == sj3, false);
    });

    test('hashCode is consistent', () {
      final sj1 = Schuljahr(2024, 2025);
      final sj2 = Schuljahr(2024, 2025);

      expect(sj1.hashCode, sj2.hashCode);
    });
  });
}
