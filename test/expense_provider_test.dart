// test/expense_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/category.dart';

import 'mocks.mocks.dart';

void main() {
  group('ExpenseProvider', () {
    late MockAppwriteClient mockAppwriteClient;
    late ExpenseProvider expenseProvider;

    setUp(() {
      mockAppwriteClient = MockAppwriteClient();
      expenseProvider = ExpenseProvider('test_user_id');
    });

    test('should clear filters', () {
      // Act
      expenseProvider.clearFilters();

      // Assert
      expect(expenseProvider.activeFilters.searchText, isNull);
      expect(expenseProvider.activeFilters.selectedCategories, isEmpty);
      expect(expenseProvider.activeFilters.dateRange, isNull);
    });

    test('fetchExpenses should update the expenses list on success', () async {

      final expenses = [
        Expense(id: '1', title: 'Groceries', amount: 50.0, date: DateTime.now(), category: ExpenseCategory.food),
        Expense(id: '2', title: 'Gas', amount: 30.0, date: DateTime.now(), category: ExpenseCategory.transport),
      ];
      when(mockAppwriteClient.getExpenses(any)).thenAnswer((_) async => expenses);

    });
  });
}