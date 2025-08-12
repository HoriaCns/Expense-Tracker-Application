import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/api/appwrite_client.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/widgets/chart.dart'; // For ChartDataPoint
import 'package:expense_tracker/widgets/filter_dialog.dart'; // For FilterCriteria

class ExpenseProvider extends ChangeNotifier {
  final AppwriteClient _appwriteClient = AppwriteClient();
  final String _userId;

  // --- Private State ---
  List<Expense> _allExpenses = [];
  bool _isLoading = true;
  String? _error;
  FilterCriteria _activeFilters = FilterCriteria(selectedCategories: {});

  // --- Public Getters ---
  List<Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterCriteria get activeFilters => _activeFilters;

  /// Returns a filtered list of expenses based on the active filters.
  List<Expense> get filteredExpenses {
    if (_activeFilters.searchText == null &&
        _activeFilters.selectedCategories.isEmpty &&
        _activeFilters.dateRange == null) {
      return _allExpenses;
    }
    return _allExpenses.where((expense) {
      if (_activeFilters.searchText != null &&
          !expense.title.toLowerCase().contains(_activeFilters.searchText!.toLowerCase())) {
        return false;
      }
      if (_activeFilters.selectedCategories.isNotEmpty &&
          !_activeFilters.selectedCategories.contains(expense.category)) {
        return false;
      }
      if (_activeFilters.dateRange != null) {
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        if (expenseDate.isBefore(_activeFilters.dateRange!.start) ||
            expenseDate.isAfter(_activeFilters.dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  ExpenseProvider(this._userId) {
    fetchExpenses();
  }

  // --- Data Fetching and Manipulation Methods ---

  Future<void> fetchExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allExpenses = await _appwriteClient.getExpenses(_userId);
    } catch (e) {
      _error = "Failed to load expenses. Please check your connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(String title, double amount, DateTime date, ExpenseCategory category) async {
    final newExp = Expense(id: '', title: title, amount: amount, date: date, category: category);
    await _appwriteClient.addExpense(newExp, _userId);
    await fetchExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _appwriteClient.updateExpense(expense);
    await fetchExpenses();
  }

  Future<void> deleteExpense(String documentId) async {
    await _appwriteClient.deleteExpense(documentId);
    _allExpenses.removeWhere((exp) => exp.id == documentId);
    notifyListeners();
  }

  // --- UI Logic Methods ---

  /// Updates the active filters and notifies listeners to rebuild the UI.
  void updateFilters(FilterCriteria newFilters) {
    _activeFilters = newFilters;
    notifyListeners();
  }

  /// Clears all active filters.
  void clearFilters() {
    _activeFilters = FilterCriteria(selectedCategories: {});
    notifyListeners();
  }

  // --- Chart Data Getters ---

  List<ChartDataPoint> get weeklyChartData {
    final now = DateTime.now();
    List<ChartDataPoint> dataPoints = [];
    final recentExpenses = _allExpenses.where((exp) {
      return exp.date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();

    final groupedByDay = groupBy(recentExpenses, (Expense exp) {
      return DateTime(exp.date.year, exp.date.month, exp.date.day);
    });

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final total = groupedByDay[day]?.fold(0.0, (sum, item) => sum + item.amount) ?? 0.0;
      dataPoints.add(ChartDataPoint(date: day, amount: total));
    }
    return dataPoints;
  }

  List<ChartDataPoint> get monthlyChartData {
    final now = DateTime.now();
    List<ChartDataPoint> dataPoints = [];
    for (int i = 3; i >= 0; i--) {
      final weekStartDate = now.subtract(Duration(days: (i * 7) + 6));
      final weekEndDate = now.subtract(Duration(days: i * 7));

      final expensesInWeek = _allExpenses.where((exp) {
        return exp.date.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
            exp.date.isBefore(weekEndDate.add(const Duration(days: 1)));
      }).toList();

      final total = expensesInWeek.fold(0.0, (sum, item) => sum + item.amount);
      dataPoints.add(ChartDataPoint(date: weekStartDate, amount: total));
    }
    return dataPoints;
  }

  List<ChartDataPoint> get yearlyChartData {
    final now = DateTime.now();
    List<ChartDataPoint> dataPoints = [];
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final expensesInMonth = _allExpenses.where((exp) {
        return exp.date.year == monthDate.year && exp.date.month == monthDate.month;
      }).toList();
      final total = expensesInMonth.fold(0.0, (sum, item) => sum + item.amount);
      dataPoints.add(ChartDataPoint(date: monthDate, amount: total));
    }
    return dataPoints;
  }
}