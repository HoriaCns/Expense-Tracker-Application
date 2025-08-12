import 'package:flutter/material.dart';
import 'package:expense_tracker/api/appwrite_client.dart';
import 'package:expense_tracker/models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  final AppwriteClient _appwriteClient = AppwriteClient();
  final String _userId;

  Budget? _currentMonthBudget;
  bool _isLoading = true;
  String? _error;

  Budget? get currentMonthBudget => _currentMonthBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BudgetProvider(this._userId) {
    fetchCurrentMonthBudget();
  }

  Future<void> fetchCurrentMonthBudget() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentMonthBudget = await _appwriteClient.getBudgetForCurrentMonth(_userId);
    } on Exception catch (e) {
      // If no budget is found, Appwrite throws an exception. This is expected.
      _currentMonthBudget = null;
      // We don't set an error here unless it's an actual server/network issue.
      if (!e.toString().contains("document_not_found")) {
        _error = "Could not fetch budget data.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBudget(double amount) async {
    try {
      if (_currentMonthBudget != null) {
        // Update existing budget
        await _appwriteClient.updateBudget(_currentMonthBudget!.id, amount);
      } else {
        // Create new budget
        await _appwriteClient.createBudget(_userId, amount);
      }
      // Refresh the data
      await fetchCurrentMonthBudget();
    } catch (e) {
      _error = "Failed to set budget.";
      notifyListeners();
    }
  }
}