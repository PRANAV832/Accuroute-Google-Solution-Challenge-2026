// This is a basic Flutter widget test.
//
// Test for the AcuRoute application.

import 'package:flutter_test/flutter_test.dart';

import 'package:acuroute/main.dart';

void main() {
  testWidgets('AcuRoute app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AcuRouteApp());

    // Verify the splash screen shows app name
    expect(find.text('AcuRoute'), findsOneWidget);
  });
}
