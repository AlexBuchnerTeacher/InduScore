import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notentool_web/main.dart';

void main() {
  testWidgets('App loads with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NotentoolApp()));

    // Verify that login screen appears
    expect(find.text('Notentool'), findsWidgets);
    expect(find.text('Anmelden'), findsOneWidget);
  });
}
