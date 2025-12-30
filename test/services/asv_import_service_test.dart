import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/services/asv_import_service.dart';

void main() {
  group('AsvImportService', () {
    group('isAsvFormat', () {
      test('erkennt ASV-Format mit typischen Headers', () {
        final headers = [
          'lokales Differenzierungsmerkmal',
          'Familienname',
          'Vornamen',
          'Klasse',
          'M/W.Kurzform',
          'Religionszugehörigkeit.Kurzform',
        ];
        expect(AsvImportService.isAsvFormat(headers), isTrue);
      });

      test('erkennt ASV-Format mit mindestens 3 Headers', () {
        final headers = [
          'lokales Differenzierungsmerkmal',
          'Familienname',
          'Vornamen',
          'Andere Spalte',
        ];
        expect(AsvImportService.isAsvFormat(headers), isTrue);
      });

      test('erkennt kein ASV-Format bei weniger als 3 Headers', () {
        final headers = [
          'lokales Differenzierungsmerkmal',
          'Familienname',
          'Andere Spalte',
        ];
        expect(AsvImportService.isAsvFormat(headers), isFalse);
      });

      test('erkennt kein ASV-Format bei fremden Headers', () {
        final headers = ['Name', 'Vorname', 'Email', 'Telefon'];
        expect(AsvImportService.isAsvFormat(headers), isFalse);
      });
    });

    group('parseAsvLine', () {
      test('parst einfache Semikolon-getrennte Zeile', () {
        final result = AsvImportService.parseAsvLine('Muster;Max;12IT11');
        expect(result, ['Muster', 'Max', '12IT11']);
      });

      test('parst Zeile mit Anführungszeichen', () {
        final result = AsvImportService.parseAsvLine('"Muster";Max;"12;IT11"');
        expect(result, ['Muster', 'Max', '12;IT11']);
      });

      test('parst leere Felder', () {
        final result = AsvImportService.parseAsvLine('Muster;;12IT11');
        expect(result, ['Muster', '', '12IT11']);
      });

      test('trimmt Leerzeichen', () {
        final result = AsvImportService.parseAsvLine('  Muster  ; Max ; 12IT11  ');
        expect(result, ['Muster', 'Max', '12IT11']);
      });
    });

    group('parseAsvCsv', () {
      test('parst leere Datei', () {
        final result = AsvImportService.parseAsvCsv('');
        expect(result.error, 'CSV-Datei ist leer');
        expect(result.rows, isNull);
      });

      test('erkennt kein ASV-Format', () {
        const csv = 'Name;Vorname;Email\nMuster;Max;max@test.de';
        final result = AsvImportService.parseAsvCsv(csv);
        expect(result.error, 'Kein ASV-Format erkannt');
      });

      test('parst gültige ASV-Datei', () {
        const csv = '''lokales Differenzierungsmerkmal;Familienname;Vornamen;Klasse;M/W.Kurzform;Religionszugehörigkeit.Kurzform
12345;Muster;Max;12IT11;M;ev''';
        final result = AsvImportService.parseAsvCsv(csv);
        expect(result.error, isNull);
        expect(result.rows, isNotNull);
        expect(result.rows!.length, 1);
        expect(result.rows!.first.nachname, 'Muster');
        expect(result.rows!.first.vorname, 'Max');
        expect(result.rows!.first.klasse, '12IT11');
      });
    });

    group('parseLehrerKuerzel', () {
      test('parst Lehrer-Kürzel-Feld', () {
        final result = AsvImportService.parseLehrerKuerzel('SDT FU-IT, NU FU-IT, BER E');
        
        expect(result.containsKey('SDT'), isTrue);
        expect(result.containsKey('NU'), isTrue);
        expect(result.containsKey('BER'), isTrue);
        expect(result['SDT'], contains('IT'));
        expect(result['BER'], contains('E'));
      });

      test('entfernt FU- Präfix', () {
        final result = AsvImportService.parseLehrerKuerzel('MU FU-IT');
        expect(result['MU'], contains('IT'));
        expect(result['MU']!.any((f) => f.contains('FU')), isFalse);
      });

      test('handhabt leeren String', () {
        final result = AsvImportService.parseLehrerKuerzel('');
        expect(result, isEmpty);
      });

      test('handhabt Lehrer mit mehreren Fächern', () {
        final result = AsvImportService.parseLehrerKuerzel('MU IT, MU D, WE E');
        expect(result['MU']!.length, 2);
        expect(result['MU'], containsAll(['IT', 'D']));
      });
    });
  });

  group('AsvParseResult', () {
    test('kann mit Error erstellt werden', () {
      final result = AsvParseResult(error: 'Test-Fehler');
      expect(result.error, 'Test-Fehler');
      expect(result.rows, isNull);
      expect(result.headers, isNull);
    });

    test('kann mit Daten erstellt werden', () {
      final result = AsvParseResult(
        rows: [],
        headers: ['Header1', 'Header2'],
      );
      expect(result.error, isNull);
      expect(result.rows, isEmpty);
      expect(result.headers, ['Header1', 'Header2']);
    });
  });

  group('AsvRow', () {
    test('kann erstellt werden mit allen Feldern', () {
      final row = AsvRow(
        asvId: '12345',
        nachname: 'Muster',
        vorname: 'Max',
        klasse: '12IT11',
        geschlecht: 'M',
        religion: 'ev',
        email: 'max@test.de',
        ausbildungsbetrieb: 'Test GmbH',
        austrittsDatum: '',
        befreiungDeutsch: false,
        befreiungPuG: true,
        lehrerFaecher: 'MU IT',
        unterricht: '',
      );

      expect(row.asvId, '12345');
      expect(row.nachname, 'Muster');
      expect(row.vorname, 'Max');
      expect(row.klasse, '12IT11');
      expect(row.befreiungDeutsch, isFalse);
      expect(row.befreiungPuG, isTrue);
    });
  });
}
