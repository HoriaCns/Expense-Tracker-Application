import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Expense Flow', (WidgetTester tester) async {
    // Arrange
    app.main(); // Start the app
    await tester.pumpAndSettle();

    // This is a simplified example. A real test would need to handle the login flow.
    // For now, we'll assume the user is logged in and on the ExpenseHome screen.

    // Act
    // Navigate to the expenses list
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();

    // Tap the add expense button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Fill out the new expense form
    await tester.enterText(find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == 'Title'), 'Test Expense');
    await tester.enterText(find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == 'Amount'), '12.34');
    await tester.tap(find.text('Select Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Save the expense
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Test Expense'), findsOneWidget);
    expect(find.text('£12.34'), findsOneWidget);
  });
}