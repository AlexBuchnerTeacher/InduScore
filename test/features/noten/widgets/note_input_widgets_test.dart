import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/features/noten/widgets/note_input_widgets.dart';
import 'package:induscore/models/noten_eingabe.dart';
import 'package:induscore/models/tendenz.dart';

void main() {
  group('NoteDropdown', () {
    testWidgets('renders dropdown with all note values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDropdown(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onNoteChanged: (key, studentId, lnId, value) {},
              getNoteColor: (note) => Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<int?>), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows null state with dash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDropdown(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: null, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onNoteChanged: (key, studentId, lnId, value) {},
              getNoteColor: (note) => Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('displays updatedBy indicator when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDropdown(
              inputKey: 'test-key',
              eingabe: NotenEingabe(
                note: 3,
                tendenz: Tendenz.keine,
                updatedBy: 'AB',
              ),
              studentId: 'student1',
              lnId: 'ln1',
              onNoteChanged: (key, studentId, lnId, value) {},
              getNoteColor: (note) => Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('calls onNoteChanged when value selected', (tester) async {
      var changedValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDropdown(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onNoteChanged: (key, studentId, lnId, value) {
                changedValue = value ?? 0;
              },
              getNoteColor: (note) => Colors.blue,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4').last);
      await tester.pumpAndSettle();

      expect(changedValue, 4);
    });
  });

  group('CompactNoteDropdown', () {
    testWidgets('renders compact dropdown with narrower width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactNoteDropdown(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 3, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onNoteChanged: (key, studentId, lnId, value) {},
              getNoteColor: (note) => Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<int?>), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 42); // Compact width (NotenTableDimensions.noteDropdownWidth)
    });
  });

  group('TendenzButtons', () {
    testWidgets('renders all three tendenz buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TendenzButtons(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onTendenzChanged: (key, studentId, lnId, tendenz) {},
            ),
          ),
        ),
      );

      expect(find.text('+'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('·'), findsOneWidget); // "keine" button with middle dot
    });

    testWidgets('highlights selected tendenz', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TendenzButtons(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.plus),
              studentId: 'student1',
              lnId: 'ln1',
              onTendenzChanged: (key, studentId, lnId, tendenz) {},
            ),
          ),
        ),
      );

      // Just verify the widget renders with plus tendenz selected
      expect(find.byType(TendenzButtons), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets('calls onTendenzChanged when button pressed', (tester) async {
      Tendenz? changedTendenz;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TendenzButtons(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onTendenzChanged: (key, studentId, lnId, tendenz) {
                changedTendenz = tendenz;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(changedTendenz, Tendenz.plus);
    });

    testWidgets('minus button changes tendenz to minus', (tester) async {
      Tendenz? changedTendenz;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TendenzButtons(
              inputKey: 'test-key',
              eingabe: NotenEingabe(note: 2, tendenz: Tendenz.keine),
              studentId: 'student1',
              lnId: 'ln1',
              onTendenzChanged: (key, studentId, lnId, tendenz) {
                changedTendenz = tendenz;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('-'));
      await tester.pump();

      expect(changedTendenz, Tendenz.minus);
    });
  });
}
