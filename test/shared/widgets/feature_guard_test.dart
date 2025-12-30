import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/feature_flags.dart';

void main() {
  group('canUseFeatureProvider', () {
    test('returns true when feature flag is true', () {
      // Arrange - simuliere FeatureFlags mit canUseFilter = true
      const flags = FeatureFlags(canUseFilter: true);
      
      // Act & Assert
      expect(flags.canUseFilter, true);
    });

    test('returns false when feature flag is false', () {
      // Arrange
      const flags = FeatureFlags(canUseFilter: false);
      
      // Act & Assert
      expect(flags.canUseFilter, false);
    });
  });

  group('Screen Access Providers - Default Values', () {
    test('canAccessKlassen defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canAccessKlassen, true);
    });

    test('canAccessSchueler defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canAccessSchueler, true);
    });

    test('canAccessFaecher defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canAccessFaecher, true);
    });

    test('canAccessNoten defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canAccessNoten, true);
    });
  });

  group('Function Providers - Default Values', () {
    test('canUseFilter defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canUseFilter, true);
    });

    test('canUseNachschreiber defaults to true', () {
      const flags = FeatureFlags();
      expect(flags.canUseNachschreiber, true);
    });
  });

  group('Screen Access - Disabled', () {
    test('canAccessKlassen can be disabled', () {
      const flags = FeatureFlags(canAccessKlassen: false);
      expect(flags.canAccessKlassen, false);
    });

    test('canAccessSchueler can be disabled', () {
      const flags = FeatureFlags(canAccessSchueler: false);
      expect(flags.canAccessSchueler, false);
    });

    test('canAccessFaecher can be disabled', () {
      const flags = FeatureFlags(canAccessFaecher: false);
      expect(flags.canAccessFaecher, false);
    });

    test('canAccessNoten can be disabled', () {
      const flags = FeatureFlags(canAccessNoten: false);
      expect(flags.canAccessNoten, false);
    });
  });

  group('Functions - Disabled', () {
    test('canUseFilter can be disabled', () {
      const flags = FeatureFlags(canUseFilter: false);
      expect(flags.canUseFilter, false);
    });

    test('canUseNachschreiber can be disabled', () {
      const flags = FeatureFlags(canUseNachschreiber: false);
      expect(flags.canUseNachschreiber, false);
    });
  });

  group('Admin FeatureFlags', () {
    test('Admin has all screen access flags enabled', () {
      const flags = FeatureFlags.admin();
      expect(flags.canAccessKlassen, true);
      expect(flags.canAccessSchueler, true);
      expect(flags.canAccessFaecher, true);
      expect(flags.canAccessNoten, true);
    });

    test('Admin has all function flags enabled', () {
      const flags = FeatureFlags.admin();
      expect(flags.canUseFilter, true);
      expect(flags.canUseNachschreiber, true);
    });
  });
}
