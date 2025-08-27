import 'package:expense_tracker/widgets/budget_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetSummaryCard displays correct information', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetSummaryCard(
            budgetAmount: 1000.00,
            totalSpent: 250.00,
            onEdit: () {},
          ),
        ),
      ),
    );

    // Act & Assert
    expect(find.text('Monthly Budget'), findsOneWidget);
    expect(find.text('£750.00 left to spend'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // You can even check the progress indicator's value.
    final progressIndicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressIndicator.value, 0.25);
  });
}