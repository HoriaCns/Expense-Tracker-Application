// test/expense_provider_test.dart
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mocks.mocks.dart';

void main() async {
  // FIX: Move this to the very first line of main()
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load the .env file for the test environment
  await dotenv.load(fileName: ".env");

  group('ExpenseProvider', () {
    late MockAppwriteClient mockAppwriteClient;
    late ExpenseProvider expenseProvider;

    setUp(() {
      // This will run before each test
      mockAppwriteClient = MockAppwriteClient();
      expenseProvider = ExpenseProvider('test_user_id', appwriteClient: mockAppwriteClient);
    });

    // This is a simple test that doesn't need the mock
    test('should clear filters', () {
      // Act
      expenseProvider.clearFilters();

      // Assert
      expect(expenseProvider.activeFilters.searchText, isNull);
      expect(expenseProvider.activeFilters.selectedCategories, isEmpty);
      expect(expenseProvider.activeFilters.dateRange, isNull);
    });

    // This test now uses the mock to simulate a successful API call
    test('fetchExpenses should update the expenses list on success', () async {
      // Arrange
      final expenses = [
        Expense(id: '1', title: 'Groceries', amount: 50.0, date: DateTime.now(), category: ExpenseCategory.food),
        Expense(id: '2', title: 'Gas', amount: 30.0, date: DateTime.now(), category: ExpenseCategory.transport),
      ];
      // Tell the mock what to return when getExpenses is called
      when(mockAppwriteClient.getExpenses(any)).thenAnswer((_) async => expenses);

      // Act
      await expenseProvider.fetchExpenses();

      // Assert
      expect(expenseProvider.allExpenses, expenses);
      expect(expenseProvider.isLoading, isFalse);
      expect(expenseProvider.error, isNull);
    });

    test('fetchExpenses should handle errors gracefully', () async {
      // Arrange
      when(mockAppwriteClient.getExpenses(any)).thenThrow(Exception('Failed to connect'));

      // Act
      await expenseProvider.fetchExpenses();

      // Assert
      expect(expenseProvider.allExpenses, isEmpty);
      expect(expenseProvider.isLoading, isFalse);
      expect(expenseProvider.error, isNotNull);
    });
  });
}