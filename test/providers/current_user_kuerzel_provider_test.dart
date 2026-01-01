import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/models/app_user.dart';

/// Mock Firebase User for testing
class MockFirebaseUser extends Fake implements firebase_auth.User {
  @override
  final String? email;
  
  @override
  final String uid;
  
  @override
  final String? displayName;

  MockFirebaseUser({
    this.email,
    required this.uid,
    this.displayName,
  });
}

void main() {
  group('currentUserKuerzelProvider', () {
    test('sollte Kürzel aus AppUser.kuerzel verwenden wenn verfügbar', () async {
      final appUser = AppUser(
        id: 'test-uid',
        email: 'max.mustermann@example.com',
        name: 'Max Mustermann',
        kuerzel: 'MU',
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: 'max.mustermann@example.com',
              )),
          currentAppUserProvider.overrideWith((ref) async => appUser),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(currentAppUserProvider.future);
      
      final kuerzel = container.read(currentUserKuerzelProvider);
      expect(kuerzel, equals('MU'));
    });

    test('sollte auf E-Mail-Extraktion zurückgreifen wenn AppUser.kuerzel leer ist', () async {
      final appUser = AppUser(
        id: 'test-uid',
        email: 'john.doe@example.com',
        name: 'John Doe',
        kuerzel: '', // Empty kuerzel
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: 'john.doe@example.com',
              )),
          currentAppUserProvider.overrideWith((ref) async => appUser),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(currentAppUserProvider.future);
      
      final kuerzel = container.read(currentUserKuerzelProvider);
      // Should extract from email: john.doe -> JOHN (first part before the dot)
      expect(kuerzel, equals('JOHN'));
    });

    test('sollte "??" zurückgeben wenn kein User eingeloggt ist', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentAppUserProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(currentAppUserProvider.future);

      final kuerzel = container.read(currentUserKuerzelProvider);
      expect(kuerzel, equals('??'));
    });

    test('sollte Fallback verwenden während AppUser lädt', () async {
      final appUser = AppUser(
        id: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: 'TU',
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: 'test@example.com',
              )),
          currentAppUserProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return appUser;
          }),
        ],
      );
      addTearDown(container.dispose);

      // While AppUser is loading (no .value yet), should fall back to email extraction
      final kuerzel = container.read(currentUserKuerzelProvider);
      expect(kuerzel, equals('TEST'));
      
      // After loading completes, should use kuerzel from AppUser
      await container.read(currentAppUserProvider.future);
      final kuerzelAfterLoad = container.read(currentUserKuerzelProvider);
      expect(kuerzelAfterLoad, equals('TU'));
    });

    test('sollte Kürzel in Großbuchstaben konvertieren', () async {
      final appUser = AppUser(
        id: 'test-uid',
        email: 'abc@example.com',
        name: 'ABC User',
        kuerzel: 'abc', // lowercase input
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: 'abc@example.com',
              )),
          currentAppUserProvider.overrideWith((ref) async => appUser),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(currentAppUserProvider.future);
      
      final kuerzel = container.read(currentUserKuerzelProvider);
      // AppUser constructor converts kuerzel to uppercase
      expect(kuerzel, equals('ABC'));
    });

    test('sollte bei AppUser-Fehler auf E-Mail-Extraktion zurückgreifen', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: 'fallback@example.com',
              )),
          currentAppUserProvider.overrideWith((ref) async {
            throw Exception('Firestore error');
          }),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to complete (and error)
      try {
        await container.read(currentAppUserProvider.future);
      } catch (e) {
        // Expected to error
      }

      // When AppUser provider errors, should fall back to email extraction
      final kuerzel = container.read(currentUserKuerzelProvider);
      expect(kuerzel, equals('FALL'));
    });
  });

  group('_extractKuerzelFromEmail (indirekt)', () {
    test('sollte Kürzel korrekt extrahieren für verschiedene E-Mail-Formate', () async {
      final testCases = [
        // (firebase user email, expected kuerzel)
        ('mu@induscore.de', 'MU'),
        ('max.mustermann@example.com', 'MAX.'), // Note: includes the dot (first 4 chars of username)
        ('john@test.org', 'JOHN'),
        ('a@b.c', 'A'),
        ('verylongemailaddress@example.com', 'VERY'), // Should truncate to 4 chars
        ('AB@test.com', 'AB'),
        ('test123@example.com', 'TEST'),
      ];

      for (final testCase in testCases) {
        final email = testCase.$1;
        final expectedKuerzel = testCase.$2;

        final appUser = AppUser(
          id: 'test-uid',
          email: email,
          name: 'Test User',
          kuerzel: '', // Empty to force email extraction
          rolle: UserRole.lehrer,
          createdAt: DateTime.now(),
        );

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                  uid: 'test-uid',
                  email: email,
                )),
            currentAppUserProvider.overrideWith((ref) async => appUser),
          ],
        );
        addTearDown(container.dispose);

        // Wait for async provider to complete
        await container.read(currentAppUserProvider.future);
        
        final kuerzel = container.read(currentUserKuerzelProvider);
        expect(
          kuerzel,
          equals(expectedKuerzel),
          reason: 'Failed for email: $email',
        );
      }
    });

    test('sollte "??" zurückgeben bei fehlender E-Mail', () async {
      final appUser = AppUser(
        id: 'test-uid',
        email: '',
        name: 'Test User',
        kuerzel: '',
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => MockFirebaseUser(
                uid: 'test-uid',
                email: null, // No email
              )),
          currentAppUserProvider.overrideWith((ref) async => appUser),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(currentAppUserProvider.future);

      final kuerzel = container.read(currentUserKuerzelProvider);
      expect(kuerzel, equals('??'));
    });
  });
}
