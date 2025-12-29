import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:induscore/widgets/profile/favorites_manager.dart';
import 'package:induscore/services/firestore_service.dart';
import 'package:induscore/models/klasse.dart';
import 'package:induscore/models/beruf.dart';
import 'package:induscore/providers/app_providers.dart';
import 'package:induscore/core/theme/rbs_theme.dart';

@GenerateMocks([FirestoreService])
import 'favorites_manager_test.mocks.dart';

void main() {
  group('FavoritesManager Widget Tests', () {
    late MockFirestoreService mockFirestoreService;

    final mockKlassen = [
      Klasse(
        id: 'klasse-1',
        beruf: Beruf.ie,
        jahrgangsstufe: 1,
        zeitgruppe: Zeitgruppe.eins,
        laufendeNummer: 1,
        schuljahr: Schuljahr.current(),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Klasse(
        id: 'klasse-2',
        beruf: Beruf.eat,
        jahrgangsstufe: 2,
        zeitgruppe: Zeitgruppe.zwei,
        laufendeNummer: 1,
        schuljahr: Schuljahr.current(),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Klasse(
        id: 'klasse-3',
        beruf: Beruf.ebt,
        jahrgangsstufe: 1,
        zeitgruppe: Zeitgruppe.eins,
        laufendeNummer: 1,
        schuljahr: Schuljahr.current(),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    Widget createTestWidget({
      List<String> initialFavorites = const [],
      List<Klasse>? klassen,
      bool isLoading = false,
      Object? error,
    }) {
      return ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(mockFirestoreService),
          klassenProvider.overrideWith((ref) {
            if (error != null) {
              return Stream.error(error);
            }
            if (isLoading) {
              // Return empty stream to show loading state
              return const Stream.empty();
            }
            return Stream.value(klassen ?? mockKlassen);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FavoritesManager(
              userId: 'test-user-id',
              currentFavorites: initialFavorites,
            ),
          ),
        ),
      );
    }

    testWidgets('renders list of all klassen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('IE111'), findsOneWidget);
      expect(find.text('EAT221'), findsOneWidget);
      expect(find.text('EBT111'), findsOneWidget);
    });

    testWidgets('shows checkbox for each klasse', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
    });

    testWidgets('pre-selects favorite klassen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialFavorites: ['klasse-1', 'klasse-2']),
      );
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );

      final checkboxList = checkboxes.toList();
      expect(checkboxList[0].value, isTrue); // klasse-1 selected
      expect(checkboxList[1].value, isTrue); // klasse-2 selected
      expect(checkboxList[2].value, isFalse); // klasse-3 not selected
    });

    testWidgets('toggles checkbox on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially not selected
      var checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, isFalse);

      // Tap to select
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, isTrue);

      // Tap again to deselect
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('saves favorites when save button clicked', (tester) async {
      when(mockFirestoreService.updateFavoriteKlassen(any, any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select first klasse
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      // Click save button
      await tester.tap(find.text('Favoriten speichern'));
      await tester.pumpAndSettle();

      verify(mockFirestoreService.updateFavoriteKlassen(
        'test-user-id',
        ['klasse-1'],
      )).called(1);
    });

    testWidgets('calls firestoreService.updateFavoriteKlassen', (tester) async {
      when(mockFirestoreService.updateFavoriteKlassen(any, any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select multiple klassen
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoriten speichern'));
      await tester.pumpAndSettle();

      verify(mockFirestoreService.updateFavoriteKlassen(
        'test-user-id',
        ['klasse-1', 'klasse-3'],
      )).called(1);
    });

    testWidgets('shows success snackbar after saving', (tester) async {
      when(mockFirestoreService.updateFavoriteKlassen(any, any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoriten speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Favoriten erfolgreich gespeichert'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(RBSColors.success));
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      when(mockFirestoreService.updateFavoriteKlassen(any, any))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoriten speichern'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fehler beim Speichern'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(RBSColors.error));
    });

    testWidgets('shows empty state when no klassen available', (tester) async {
      await tester.pumpWidget(createTestWidget(klassen: []));
      await tester.pumpAndSettle();

      expect(find.text('Keine Klassen verfügbar'), findsOneWidget);
    });

    testWidgets('displays info text about dashboard', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Favoriten werden auf dem Dashboard angezeigt',
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles select all klassen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select all checkboxes
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.tap(find.byType(CheckboxListTile).at(2));
      await tester.pumpAndSettle();

      // Verify all are selected
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      for (final checkbox in checkboxes) {
        expect(checkbox.value, isTrue);
      }

      // Verify count text
      expect(find.text('3 Klassen ausgewählt'), findsOneWidget);
    });

    testWidgets('handles deselect all klassen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialFavorites: ['klasse-1', 'klasse-2', 'klasse-3'],
        ),
      );
      await tester.pumpAndSettle();

      // Deselect all
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.tap(find.byType(CheckboxListTile).at(2));
      await tester.pumpAndSettle();

      // Verify all are deselected
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      for (final checkbox in checkboxes) {
        expect(checkbox.value, isFalse);
      }
    });

    testWidgets('persists selection after widget rebuild', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select first klasse
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      // Trigger rebuild by pumping again
      await tester.pump();

      // Verify selection is still there
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('displays selected count correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no count shown (0 selected)
      expect(find.textContaining('ausgewählt'), findsNothing);

      // Select one
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('1 Klasse ausgewählt'), findsOneWidget);

      // Select another
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pumpAndSettle();

      expect(find.text('2 Klassen ausgewählt'), findsOneWidget);
    });

    testWidgets('save button disabled when no changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Button should be disabled initially (no changes)
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Favoriten speichern'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('save button enabled after changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Make a change
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      // Button should be enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Favoriten speichern'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays klasse subtitle with beruf and schuljahr', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final currentYear = Schuljahr.current().toString();
      expect(
        find.textContaining('Industrieelektroniker • $currentYear'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Elektroniker für Automatisierungstechnik • $currentYear'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Elektroniker für Betriebstechnik • $currentYear'),
        findsOneWidget,
      );
    });

    testWidgets('checkbox active color is dynamicRed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(checkbox.activeColor, equals(RBSColors.dynamicRed));
    });

    testWidgets('shows loading state when fetching klassen', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when fetching klassen fails', (tester) async {
      await tester.pumpWidget(
        createTestWidget(error: Exception('Failed to load')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Fehler beim Laden'), findsOneWidget);
    });

    testWidgets('info card has green background color', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      // Info icon should be visible with court green color
      final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(icon.color, equals(RBSColors.courtGreen));
    });

    testWidgets('headline shows "Klassen auswählen"', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Klassen auswählen'), findsOneWidget);
    });
  });
}
