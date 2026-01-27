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
          // Use AsyncValue.data to provide synchronous value
          currentAppUserProvider.overrideWith((ref) async => testUser),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'BU'); // Sollte 'BU' sein, nicht 'AL' oder 'ALEX'
    });

    // v0.33.0: Kürzel wird NUR vom Admin vergeben, keine E-Mail-Extraktion mehr
    test('sollte "—" zurückgeben wenn AppUser.kuerzel leer ist', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: '', // Leeres Kürzel - Admin muss es setzen
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
          currentAppUserProvider.overrideWith((ref) async => testUser),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert - v0.33.0: Kein Fallback auf E-Mail, nur Platzhalter
      expect(kuerzel, '—'); // Platzhalter, Admin muss Kürzel setzen
    });

    // v0.33.0: "—" statt "??" als Platzhalter
    test('sollte "—" zurückgeben wenn kein User eingeloggt ist', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => null),
          currentAppUserProvider.overrideWith((ref) async => null),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, '—');
    });

    test('sollte auf AppUser warten und dann Kürzel zurückgeben', () async {
      // Arrange
      when(mockFirebaseUser.email).thenReturn('loading@test.com');
      
      // Simuliere langsam ladenden AppUser
      final testUser = AppUser(
        id: 'test-id',
        email: 'loading@test.com',
        name: 'Test',
        kuerzel: 'LT',
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          // Simulate async loading - still completes synchronously in tests
          currentAppUserProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return testUser;
          }),
        ],
      );

      // Act - this will wait for the AppUser to load
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert - should wait for AppUser and return its kuerzel
      expect(kuerzel, 'LT');
    });

    test('sollte Kürzel direkt verwenden (Großschreibung wird beim Setzen garantiert)', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: 'BU', // Admin setzt immer Großbuchstaben
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );

      when(mockFirebaseUser.email).thenReturn('test@example.com');
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) async => testUser),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert
      expect(kuerzel, 'BU');
    });

    // v0.33.0: Kein E-Mail-Fallback mehr
    test('sollte "—" zurückgeben bei AppUser ohne Kürzel (kein E-Mail-Fallback)', () async {
      // Arrange - Test with AppUser that has no kuerzel set
      final testUser = AppUser(
        id: 'test-user-id',
        email: 'error@test.com',
        name: 'Error User',
        kuerzel: '', // Empty kuerzel - Admin muss es setzen
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      when(mockFirebaseUser.email).thenReturn('error@test.com');
      
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          currentUserProvider.overrideWith((ref) => mockFirebaseUser),
          currentAppUserProvider.overrideWith((ref) async => testUser),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert - v0.33.0: Kein E-Mail-Fallback, nur Platzhalter
      expect(kuerzel, '—');
    });
  });

  // v0.33.0: E-Mail-Extraktion wurde entfernt, diese Tests sind obsolet
  group('Kürzel Admin-Only (v0.33.0)', () {
    test('leere Kürzel werden nicht aus E-Mail generiert', () async {
      // Arrange - User ohne Kürzel
      final mockUser = MockUser();
      when(mockUser.email).thenReturn('test@example.com');
      
      final testAppUser = AppUser(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        kuerzel: '', // Leer - muss vom Admin gesetzt werden
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );
      
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          currentAppUserProvider.overrideWith((ref) async => testAppUser),
        ],
      );

      // Act
      final kuerzel = await container.read(currentUserKuerzelProvider.future);

      // Assert - Platzhalter, NICHT aus E-Mail generiert
      expect(kuerzel, '—');
      expect(kuerzel, isNot('TEST')); // NICHT aus E-Mail
      
      container.dispose();
    });
  });
}
