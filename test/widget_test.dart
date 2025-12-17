import 'package:flutter_test/flutter_test.dart';
import 'package:volhub_app_copy/main.dart';

void main() {
  testWidgets('VolHub app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VolHubApp());

    // Verify app launches without crashing
    expect(find.byType(VolHubApp), findsOneWidget);
  });
}
