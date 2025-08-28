// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add new expense test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Assuming the user is already logged in and on the home screen.
    // In a real test, you'd also want to test the login flow.

    // Find the "Expenses" tab and tap it.
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();

    // Tap the floating action button to add a new expense.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter the expense details.
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Test Expense');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.34');

    // MODIFICATION START
    // Tap the button to open the date picker
    await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
    await tester.pumpAndSettle();

    // Find the confirmation button and tap it. This is more reliable than finding by text "OK".
    await tester.tap(find.byWidgetPredicate((widget) => widget is TextButton && widget.child is Text && (widget.child as Text).data == 'OK'));
    await tester.pumpAndSettle();
    // MODIFICATION END

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Save the expense.
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    // Verify that the new expense is displayed in the list.
    expect(find.text('Test Expense'), findsOneWidget);
    // Note: The amount is formatted, so we need to find it by its formatted string.
    expect(find.text('£12.34'), findsOneWidget);
  });
}