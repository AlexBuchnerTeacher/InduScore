import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/providers/app_providers.dart';

void main() {
  group('DashboardStats', () {
    test('loading state ist korrekt', () {
      const stats = DashboardStats.loading;
      
      expect(stats.isLoading, true);
      expect(stats.klassenCount, 0);
      expect(stats.studentsCount, 0);
      expect(stats.subjectsCount, 0);
      expect(stats.gradesCount, 0);
    });

    test('regulärer State hat korrekte Werte', () {
      const stats = DashboardStats(
        klassenCount: 10,
        studentsCount: 250,
        subjectsCount: 15,
        gradesCount: 1000,
      );

      expect(stats.isLoading, false);
      expect(stats.klassenCount, 10);
      expect(stats.studentsCount, 250);
      expect(stats.subjectsCount, 15);
      expect(stats.gradesCount, 1000);
    });

    test('default isLoading ist false', () {
      const stats = DashboardStats(
        klassenCount: 5,
        studentsCount: 100,
        subjectsCount: 10,
        gradesCount: 500,
      );
      expect(stats.isLoading, false);
    });
  });

  group('extractZeitgruppe', () {
    test('extrahiert Zeitgruppe aus Klassennamen', () {
      expect(extractZeitgruppe('12IT11'), 1);
      expect(extractZeitgruppe('12IT12'), 1);
      expect(extractZeitgruppe('12IT21'), 2);
      expect(extractZeitgruppe('12IT31'), 3);
    });

    test('liefert null bei zu kurzem Namen', () {
      expect(extractZeitgruppe(''), isNull);
      expect(extractZeitgruppe('A'), isNull);
    });

    test('liefert null wenn vorletzte Stelle kein digit ist', () {
      expect(extractZeitgruppe('12ITAB'), isNull);
    });

    test('funktioniert mit verschiedenen Klassenformaten', () {
      expect(extractZeitgruppe('10IT11'), 1);
      expect(extractZeitgruppe('11FI21'), 2);
      expect(extractZeitgruppe('13SE32'), 3);
      expect(extractZeitgruppe('BS'), isNull); // Zu kurz
    });
  });

  group('NachschreiberStufe', () {
    test('hat drei Werte', () {
      expect(NachschreiberStufe.values.length, 3);
    });

    test('stufe1 hat Index 0', () {
      expect(NachschreiberStufe.stufe1.index, 0);
    });

    test('stufe2 hat Index 1', () {
      expect(NachschreiberStufe.stufe2.index, 1);
    });

    test('stufe3 hat Index 2', () {
      expect(NachschreiberStufe.stufe3.index, 2);
    });
  });

  group('Map Provider Pattern', () {
    test('klassenMapProvider existiert', () {
      // Provider ist definiert und kann referenziert werden
      expect(klassenMapProvider, isNotNull);
    });

    test('subjectsMapProvider existiert', () {
      expect(subjectsMapProvider, isNotNull);
    });

    test('studentsMapProvider existiert', () {
      expect(studentsMapProvider, isNotNull);
    });

    test('leistungsnachweiseMapProvider existiert', () {
      expect(leistungsnachweiseMapProvider, isNotNull);
    });
  });
}
