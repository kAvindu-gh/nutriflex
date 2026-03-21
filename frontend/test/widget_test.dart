// lib/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/meal_prep_page.dart';   //  Updated to the real app

void main() {
  testWidgets('Meal Prep Builder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Basic checks that the page loads
    expect(find.text('Meal Prep Builder'), findsOneWidget);
    expect(find.text('Total Meal Calories'), findsOneWidget);
    expect(find.text('Save my recipe'), findsOneWidget);
  });
}
