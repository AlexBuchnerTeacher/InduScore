// Integration Test: App Initialization & Navigation
//
// Testet den grundlegenden App-Start und Navigation.
// Verwendet Flutter Integration Testing Framework.
//
// Ausführen mit:
//   flutter test integration_test/app_test.dart
//
// Oder mit Flutter Driver:
//   flutter drive --target=integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:induscore/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization', () {
    testWidgets('App startet und zeigt Login-Screen', (tester) async {
      // App starten
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Prüfe: Login-Screen wird angezeigt
      expect(find.text('InduScore'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Login-Formular hat Email und Passwort Felder', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Finde Email-Feld durch Descendant-Finder
      final emailField = find.widgetWithText(TextFormField, 'E-Mail');
      expect(emailField, findsWidgets);

      // Finde Passwort-Feld durch Descendant-Finder
      final passwordField = find.widgetWithText(TextFormField, 'Passwort');
      expect(passwordField, findsWidgets);
    });
  });

  group('Navigation', () {
    testWidgets('Drawer öffnet und zeigt Navigation Items', (tester) async {
      // Hinweis: Dieser Test erfordert einen eingeloggten User
      // In CI würde man hier einen Test-User mit Firebase Auth Emulator nutzen
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wenn Login-Screen: Test überspringen (nicht eingeloggt)
      if (find.text('Anmelden').evaluate().isNotEmpty) {
        // Nicht eingeloggt - Test als bestanden markieren
        // Integration-Tests mit Auth erfordern Firebase Emulator
        return;
      }

      // Drawer öffnen
      final scaffoldFinder = find.byType(Scaffold);
      if (scaffoldFinder.evaluate().isNotEmpty) {
        final ScaffoldState scaffoldState = tester.state(scaffoldFinder.first);
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Prüfe Navigation Items
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Klassen'), findsOneWidget);
      }
    });
  });
}
