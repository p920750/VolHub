// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:main_volhub/main.dart';

void main() {
  testWidgets('VolHub app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the app loads with VOLHUB text
    expect(find.text('VOLHUB'), findsOneWidget);
    
    // Verify that the welcome message is present
    expect(find.text('Connecting volunteers with their next mission.'), findsOneWidget);
    
    // Verify that the welcome text is present
    expect(find.text('Welcome to your volunteer hub!'), findsOneWidget);
  });
}
