import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/shared/widgets/app_snack_bars.dart';

void main() {
  group('AppSnackBars', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) => child),
        ),
      );
    }

    testWidgets('showSuccess displays green snackbar with check icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showSuccess(context, 'Erfolg!'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Erfolg!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showError displays red snackbar with error icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showError(context, 'Fehler!'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Fehler!'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showError with error object appends error message',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showError(
              context,
              'Speichern fehlgeschlagen',
              error: 'Network timeout',
            ),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Speichern fehlgeschlagen: Network timeout'), findsOneWidget);
    });

    testWidgets('showWarning displays orange snackbar with warning icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showWarning(context, 'Achtung!'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Achtung!'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('showInfo displays blue snackbar with info icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showInfo(context, 'Information'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Information'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('showSimple displays basic snackbar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showSimple(context, 'Einfache Nachricht'),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Einfache Nachricht'), findsOneWidget);
    });

    testWidgets('snackbar with action shows action button', (tester) async {
      var actionPressed = false;

      await tester.pumpWidget(buildTestWidget(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AppSnackBars.showSuccess(
              context,
              'Gelöscht',
              action: AppSnackBars.undoAction(
                onPressed: () => actionPressed = true,
              ),
            ),
            child: const Text('Show'),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Rückgängig'), findsOneWidget);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();

      expect(actionPressed, isTrue);
    });

    test('undoAction creates SnackBarAction with correct label', () {
      final action = AppSnackBars.undoAction(onPressed: () {});
      expect(action.label, 'Rückgängig');
    });

    test('detailsAction creates SnackBarAction with correct label', () {
      final action = AppSnackBars.detailsAction(onPressed: () {});
      expect(action.label, 'Details');
    });

    test('defaultDuration is 3 seconds', () {
      expect(AppSnackBars.defaultDuration, const Duration(seconds: 3));
    });

    test('longDuration is 5 seconds', () {
      expect(AppSnackBars.longDuration, const Duration(seconds: 5));
    });
  });
}
