import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('default constructor has secure defaults', () {
      const flags = FeatureFlags();
      
      // Sichere Defaults: Lehrer können nicht alles
      expect(flags.canImportCSV, false);
      expect(flags.canDeleteSchueler, false);
      expect(flags.canCreateFaecher, false);
      expect(flags.canDeleteFaecher, false);
      expect(flags.canCreateKlassen, false);
      expect(flags.canDeleteKlassen, false);
      expect(flags.canDeleteLeistungsnachweise, false);
      expect(flags.canExportExcel, false);
      
      // Lehrer können standardmäßig
      expect(flags.canCreateSchueler, true);
      expect(flags.canEditSchueler, true);
      expect(flags.canCreateLeistungsnachweise, true);
      expect(flags.canEditLeistungsnachweise, true);
      expect(flags.canToggleFavorites, true);
      expect(flags.canExportPDF, true);
      expect(flags.canExportNOI, true);
    });

    test('admin constructor has all permissions', () {
      const flags = FeatureFlags.admin();
      
      expect(flags.canImportCSV, true);
      expect(flags.canCreateSchueler, true);
      expect(flags.canEditSchueler, true);
      expect(flags.canDeleteSchueler, true);
      expect(flags.canCreateFaecher, true);
      expect(flags.canEditFaecher, true);
      expect(flags.canDeleteFaecher, true);
      expect(flags.canCreateKlassen, true);
      expect(flags.canEditKlassen, true);
      expect(flags.canDeleteKlassen, true);
      expect(flags.canCreateLeistungsnachweise, true);
      expect(flags.canEditLeistungsnachweise, true);
      expect(flags.canDeleteLeistungsnachweise, true);
      expect(flags.canToggleFavorites, true);
      expect(flags.canExportPDF, true);
      expect(flags.canExportExcel, true);
      expect(flags.canExportNOI, true);
    });

    test('fromFirestore parses correctly', () {
      final data = {
        'canImportCSV': true,
        'canCreateSchueler': false,
        'canDeleteKlassen': true,
      };
      
      final flags = FeatureFlags.fromFirestore(data);
      
      expect(flags.canImportCSV, true);
      expect(flags.canCreateSchueler, false);
      expect(flags.canDeleteKlassen, true);
      // Fehlende Felder bekommen Defaults
      expect(flags.canEditSchueler, true);
      expect(flags.canExportExcel, false);
    });

    test('fromFirestore handles null data', () {
      final flags = FeatureFlags.fromFirestore(null);
      
      expect(flags.canImportCSV, false);
      expect(flags.canCreateSchueler, true);
    });

    test('toFirestore serializes correctly', () {
      const flags = FeatureFlags(
        canImportCSV: true,
        canDeleteSchueler: true,
      );
      
      final data = flags.toFirestore();
      
      expect(data['canImportCSV'], true);
      expect(data['canDeleteSchueler'], true);
      expect(data['canCreateSchueler'], true); // Default
      expect(data.length, 23); // Alle 23 Flags (17 + 6 neue)
    });

    test('copyWith creates modified copy', () {
      const original = FeatureFlags();
      final modified = original.copyWith(
        canImportCSV: true,
        canDeleteKlassen: true,
      );
      
      expect(original.canImportCSV, false);
      expect(modified.canImportCSV, true);
      expect(original.canDeleteKlassen, false);
      expect(modified.canDeleteKlassen, true);
      // Unveränderte Werte
      expect(modified.canCreateSchueler, original.canCreateSchueler);
    });

    test('equality works correctly', () {
      const flags1 = FeatureFlags();
      const flags2 = FeatureFlags();
      const flags3 = FeatureFlags(canImportCSV: true);
      
      expect(flags1, equals(flags2));
      expect(flags1, isNot(equals(flags3)));
    });

    test('hashCode is consistent', () {
      const flags1 = FeatureFlags();
      const flags2 = FeatureFlags();
      
      expect(flags1.hashCode, equals(flags2.hashCode));
    });
  });

  group('FeatureFlagInfo', () {
    test('all contains 23 flags', () {
      expect(FeatureFlagInfo.all.length, 23);
    });

    test('byCategory groups flags correctly', () {
      final byCategory = FeatureFlagInfo.byCategory;
      
      expect(byCategory.keys, containsAll([
        'Schüler',
        'Klassen',
        'Fächer',
        'Leistungsnachweise',
        'Import/Export',
        'Sonstige',
        'Screens',
        'Funktionen',
      ]));
      
      // Schüler hat 3 Flags
      expect(byCategory['Schüler']!.length, 3);
      
      // Import/Export hat 4 Flags
      expect(byCategory['Import/Export']!.length, 4);
      
      // Screens hat 4 Flags
      expect(byCategory['Screens']!.length, 4);
      
      // Funktionen hat 2 Flags
      expect(byCategory['Funktionen']!.length, 2);
    });

    test('all flags have required properties', () {
      for (final flag in FeatureFlagInfo.all) {
        expect(flag.key, isNotEmpty);
        expect(flag.label, isNotEmpty);
        expect(flag.description, isNotEmpty);
        expect(flag.category, isNotEmpty);
      }
    });
  });
}
