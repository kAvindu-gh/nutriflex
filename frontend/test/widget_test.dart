// lib/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/notification_page.dart';


<<<<<<< HEAD

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
<<<<<<< HEAD
    await tester.pumpWidget(const NutriFlexApp());
=======
    await tester.pumpWidget(const NotificationsPage());
>>>>>>> origin/notification-page
=======
import 'package:frontend/meal_prep_page.dart';   //  Updated to the real app

void main() {
  testWidgets('Meal Prep Builder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
>>>>>>> origin/feature/meal-prep-page

    // Basic checks that the page loads
    expect(find.text('Meal Prep Builder'), findsOneWidget);
    expect(find.text('Total Meal Calories'), findsOneWidget);
    expect(find.text('Save my recipe'), findsOneWidget);
  });
}
