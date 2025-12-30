import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:induscore/features/profile/screens/profile_screen.dart';
import 'package:induscore/models/app_user.dart';
import 'package:induscore/core/theme/rbs_theme.dart';
import 'package:induscore/providers/app_providers.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    final mockAppUser = AppUser(
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      kuerzel: 'TU',
      rolle: UserRole.lehrer,
      status: UserStatus.aktiv,
      favoriteKlassenIds: ['klasse-1', 'klasse-2'],
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 12, 29),
    );

    Widget createTestWidget(AppUser? user, {bool isLoading = false, Object? error}) {
      return ProviderScope(
        overrides: [
          currentAppUserProvider.overrideWith((ref) {
            if (error != null) {
              return Future.error(error);
            }
            if (isLoading) {
              return Future.delayed(
                const Duration(seconds: 10),
                () => user,
              );
            }
            return Future.value(user);
          }),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('renders ProfileScreen with AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Mein Profil'), findsOneWidget);
    });

    testWidgets('AppBar has Dynamic Red background color', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(RBSColors.dynamicRed));
      expect(appBar.foregroundColor, equals(RBSColors.white));
    });

    testWidgets('shows 3 tabs: Profil, Sicherheit, Favoriten', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Sicherheit'), findsOneWidget);
      expect(find.text('Favoriten'), findsOneWidget);
    });

    testWidgets('tab switching works correctly - Profil to Sicherheit', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      // Initially on Profil tab
      expect(find.text('Profil'), findsOneWidget);

      // Tap on Sicherheit tab
      await tester.tap(find.text('Sicherheit'));
      await tester.pumpAndSettle();

      // Verify Sicherheit tab content is visible
      expect(find.text('Passwort'), findsOneWidget);
      expect(find.text('Passwort ändern'), findsAtLeastNWidgets(1));
    });

    testWidgets('tab switching works correctly - Profil to Favoriten', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      // Tap on Favoriten tab
      await tester.tap(find.text('Favoriten'));
      await tester.pumpAndSettle();

      // Verify Favoriten tab content is visible
      expect(find.text('Klassen auswählen'), findsOneWidget);
    });

    testWidgets('tab switching cycles through all tabs', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      // Go to Sicherheit
      await tester.tap(find.text('Sicherheit'));
      await tester.pumpAndSettle();
      expect(find.text('Passwort'), findsOneWidget);

      // Go to Favoriten
      await tester.tap(find.text('Favoriten'));
      await tester.pumpAndSettle();
      expect(find.text('Klassen auswählen'), findsOneWidget);

      // Go back to Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching user data', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser, isLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Complete the pending timer to avoid test failure
      await tester.pumpAndSettle(const Duration(seconds: 11));
    });

    testWidgets('displays user data in Profil tab', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      // User info should be displayed in ProfileInfoSection
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('shows error message when user fetch fails', (tester) async {
      await tester.pumpWidget(
        createTestWidget(null, error: Exception('Network error')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Fehler'), findsOneWidget);
      expect(find.textContaining('Exception: Network error'), findsOneWidget);
    });

    testWidgets('displays "Benutzer nicht gefunden" when user is null', (tester) async {
      await tester.pumpWidget(createTestWidget(null));
      await tester.pumpAndSettle();

      expect(find.text('Benutzer nicht gefunden'), findsOneWidget);
    });

    testWidgets('TabController is properly initialized with 3 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller?.length, equals(3));
    });

    testWidgets('TabBar uses white color for labels and indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, equals(RBSColors.white));
      expect(tabBar.indicatorColor, equals(RBSColors.white));
    });

    testWidgets('TabBar uses semi-transparent white for unselected labels', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(
        tabBar.unselectedLabelColor,
        equals(RBSColors.white.withValues(alpha: 0.7)),
      );
    });

    testWidgets('Scaffold has paper background color', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(RBSColors.paper));
    });

    testWidgets('AppBar title uses RobotoCondensed bold font', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Mein Profil'));
      expect(titleText.style?.fontFamily, equals('RobotoCondensed'));
      expect(titleText.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('renders TabBarView with 3 children', (tester) async {
      await tester.pumpWidget(createTestWidget(mockAppUser));
      await tester.pumpAndSettle();

      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.children.length, equals(3));
    });

    testWidgets('error state shows error text with red color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(null, error: Exception('Test error')),
      );
      await tester.pumpAndSettle();

      final errorText = tester.widget<Text>(
        find.textContaining('Fehler'),
      );
      expect(errorText.style?.color, equals(RBSColors.error));
    });

    testWidgets('user null state shows grey text', (tester) async {
      await tester.pumpWidget(createTestWidget(null));
      await tester.pumpAndSettle();

      final notFoundText = tester.widget<Text>(
        find.text('Benutzer nicht gefunden'),
      );
      expect(notFoundText.style?.fontFamily, equals('OpenSans'));
      expect(notFoundText.style?.color, equals(Colors.grey));
    });
  });
}
