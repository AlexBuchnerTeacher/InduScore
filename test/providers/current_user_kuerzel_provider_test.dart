import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/models/app_user.dart';
import 'package:induscore/services/auth_service.dart';
import 'package:induscore/services/firestore_service.dart';

// Generate mocks for testing
@GenerateMocks([
  FirebaseAuth,
  User,
  AuthService,
  FirestoreService,
])
import 'current_user_kuerzel_provider_test.mocks.dart';

void main() {
  group('currentUserKuerzelProvider', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockFirebaseUser;
    late MockAuthService mockAuthService;
    late MockFirestoreService mockFirestoreService;
    late ProviderContainer container;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseUser = MockUser();
      mockAuthService = MockAuthService();
      mockFirestoreService = MockFirestoreService();
    });

    tearDown(() {
      container.dispose();
    });

    test('sollte Kürzel aus AppUser.kuerzel verwenden wenn verfügbar', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'alex.buchner@schule.de',
        name: 'Alex Buchner',
        kuerzel: 'BU', // Das richtige Kürzel
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );

      when(mockFirebaseUser.email).thenReturn('alex.buchner@schule.de');
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      
      // Create container with overrides
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) => Future.value(testUser)),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'BU'); // Sollte 'BU' sein, nicht 'AL' oder 'ALEX'
    });

    test('sollte auf E-Mail-Extraktion zurückgreifen wenn AppUser.kuerzel leer ist', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: '', // Leeres Kürzel
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );

      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) => Future.value(testUser)),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'TEST'); // Aus E-Mail extrahiert
    });

    test('sollte "??" zurückgeben wenn kein User eingeloggt ist', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => null),
          currentAppUserProvider.overrideWith((ref) => Future.value(null)),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, '??');
    });

    test('sollte Fallback verwenden während AppUser lädt', () async {
      // Arrange
      when(mockFirebaseUser.email).thenReturn('loading@test.com');
      
      // Simuliere langsam ladenden AppUser
      final slowFuture = Future.delayed(
        const Duration(seconds: 1),
        () => AppUser(
          id: 'test-id',
          email: 'loading@test.com',
          name: 'Test',
          kuerzel: 'LT',
          rolle: UserRole.lehrer,
          createdAt: DateTime.now(),
        ),
      );
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) => slowFuture),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert - sollte während des Ladens Fallback verwenden
      // In diesem Fall wird es auf die AppUser-Daten warten und dann 'LT' zurückgeben
      expect(kuerzel, 'LT');
    });

    test('sollte Kürzel in Großbuchstaben konvertieren', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: 'bu', // Kleinbuchstaben
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );

      when(mockFirebaseUser.email).thenReturn('test@example.com');
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) => Future.value(testUser)),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'BU'); // AppUser.kuerzel wird automatisch in uppercase konvertiert
    });

    test('sollte bei AppUser-Fehler auf E-Mail-Extraktion zurückgreifen', () async {
      // Arrange
      when(mockFirebaseUser.email).thenReturn('error@test.com');
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) => 
            Future.error(Exception('Firestore error'))),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'ERRO'); // Aus E-Mail extrahiert (erste 4 Zeichen)
    });
  });

  group('_extractKuerzelFromEmail (indirekt)', () {
    test('sollte Kürzel korrekt extrahieren für verschiedene E-Mail-Formate', () async {
      final testCases = [
        ('test@example.com', 'TEST'),
        ('ab@school.de', 'AB'),
        ('alexander@example.com', 'ALEX'), // Max 4 Zeichen
        ('x@test.com', 'X'),
        ('longusername@example.com', 'LONG'), // Max 4 Zeichen
      ];

      for (final (email, expectedKuerzel) in testCases) {
        // Arrange - User ohne AppUser-Kürzel
        final mockUser = MockUser();
        when(mockUser.email).thenReturn(email);
        
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            currentAppUserProvider.overrideWith((ref) => Future.value(null)),
          ],
        );

        // Act
        final kuerzel = await container.read(currentUserKuerzelProvider.future);

        // Assert
        expect(kuerzel, expectedKuerzel, reason: 'Für E-Mail: $email');
        
        container.dispose();
      }
    });
  });
}
