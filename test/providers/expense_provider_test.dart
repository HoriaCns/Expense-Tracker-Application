import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/widgets/filter_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart'; // Import the generated mock

void main() {
  group('ExpenseProvider', () {
    late MockAppwriteClient mockAppwriteClient;
    late ExpenseProvider expenseProvider;

    setUp(() {
      mockAppwriteClient = MockAppwriteClient();
      // CORRECTED: Pass the mock client via the new constructor parameter
      expenseProvider = ExpenseProvider('test_user_id', appwriteClient: mockAppwriteClient);
    });

    // This test will now work correctly!
    test('should filter expenses by search text', () {
      // Arrange
      // We set the initial state directly on the provider's public list
      expenseProvider.allExpenses = [
        Expense(id: '1', title: 'Coffee', amount: 3.50, date: DateTime.now(), category: ExpenseCategory.food),
        Expense(id: '2', title: 'Bus Ticket', amount: 2.00, date: DateTime.now(), category: ExpenseCategory.transport),
      ];
      final filters = FilterCriteria(searchText: 'Coffee', selectedCategories: {});

      // Act
      expenseProvider.updateFilters(filters);

      // Assert
      expect(expenseProvider.filteredExpenses.length, 1);
      expect(expenseProvider.filteredExpenses.first.title, 'Coffee');
    });

    // You can also now test methods that call the AppwriteClient
    test('fetchExpenses should load expenses from the client', () async {
      // Arrange
      final mockExpenses = [
        Expense(id: '1', title: 'Test from mock', amount: 10.0, date: DateTime.now(), category: ExpenseCategory.other)
      ];
      // Tell the mock what to do when getExpenses is called
      when(mockAppwriteClient.getExpenses(any)).thenAnswer((_) async => mockExpenses);

      // Act
      await expenseProvider.fetchExpenses();

      // Assert
      expect(expenseProvider.allExpenses.length, 1);
      expect(expenseProvider.allExpenses.first.title, 'Test from mock');
      expect(expenseProvider.isLoading, isFalse);
      expect(expenseProvider.error, isNull);
    });
  });
}