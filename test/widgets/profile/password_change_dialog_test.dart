import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:induscore/widgets/profile/password_change_dialog.dart';
import 'package:induscore/services/auth_service.dart';
import 'package:induscore/core/theme/rbs_theme.dart';

@GenerateMocks([AuthService])
import 'password_change_dialog_test.mocks.dart';

void main() {
  group('PasswordChangeDialog Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => PasswordChangeDialog(
                    authService: mockAuthService,
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders dialog with password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Aktuelles Passwort'), findsOneWidget);
      expect(find.text('Neues Passwort'), findsOneWidget);
      expect(find.text('Passwort bestätigen'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('all password fields are obscured', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in textFields) {
        expect(field.obscureText, isTrue);
      }
    });

    testWidgets('calls authService.changePassword with valid input', (tester) async {
      when(mockAuthService.changePassword(any, any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Aktuelles Passwort'),
        'oldPassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Neues Passwort'),
        'newPassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Passwort bestätigen'),
        'newPassword123',
      );

      await tester.tap(find.text('Passwort ändern').last);
      await tester.pumpAndSettle();

      verify(mockAuthService.changePassword('oldPassword123', 'newPassword123'))
          .called(1);
    });

    testWidgets('shows success snackbar when password changed', (tester) async {
      when(mockAuthService.changePassword(any, any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Aktuelles Passwort'),
        'oldPassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Neues Passwort'),
        'newPassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Passwort bestätigen'),
        'newPassword123',
      );

      await tester.tap(find.text('Passwort ändern').last);
      await tester.pumpAndSettle();

      expect(find.text('Passwort erfolgreich geändert'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(RBSColors.success));
    });

    testWidgets('shows error snackbar on failure', (tester) async {
      when(mockAuthService.changePassword(any, any))
          .thenThrow('Falsches Passwort.');

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Aktuelles Passwort'),
        'wrongPassword',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Neues Passwort'),
        'newPassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Passwort bestätigen'),
        'newPassword123',
      );

      await tester.tap(find.text('Passwort ändern').last);
      await tester.pumpAndSettle();

      expect(find.text('Falsches Passwort.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(RBSColors.error));
    });

    testWidgets('closes dialog on cancel button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockAuthService.changePassword(any, any));
    });

    testWidgets('dialog has rounded corners', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      final shape = alertDialog.shape as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        equals(BorderRadius.circular(RBSBorderRadius.medium)),
      );
    });

    testWidgets('password fields have appropriate icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
