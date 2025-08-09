import 'package:expense_tracker/api/appwrite_client.dart';
import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/spending_screen.dart';
import 'package:expense_tracker/widgets/filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'widgets/expense_list.dart';
import 'widgets/new_expense.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthNotifier(),
      child: ExpenseApp(),
    ),
  );
}

class ExpenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFDEE8DD),
        primaryColor: const Color(0x00000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFBFBFB),
          secondary: const Color(0xFF03ED9B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFFBFBFB),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFBFBFB),
        ),
        cardColor: const Color(0xFFFFFFFF),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const AuthGate(),
    );
  }
}

class ExpenseHome extends StatefulWidget {
  const ExpenseHome({super.key});

  @override
  _ExpenseHomeState createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  final AppwriteClient _appwriteClient = AppwriteClient();
  late Future<void> _loadExpensesFuture;
  models.User? _currentUser;

  List<Expense> _allExpenses = []; // Holds the master list of all expenses
  FilterCriteria _activeFilters = FilterCriteria(selectedCategories: {});

  bool get _isFilterActive =>
      _activeFilters.searchText != null ||
      _activeFilters.selectedCategories.isNotEmpty ||
      _activeFilters.dateRange != null;

  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};
  int _selectedIndex = 0;

  FilterType _spendingScreenFilter = FilterType.week;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_isSelectionMode) {
        _isSelectionMode = false;
        _selectedItems.clear();
      }
    });
  }

  void _navigateToSpendingTab(FilterType filter) {
    setState(() {
      _spendingScreenFilter = filter;
      _selectedIndex = 2; // Index 2 is the "Spending" tab
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExpensesFuture = _loadUserDataAndExpenses();
  }

  Future<void> _loadUserDataAndExpenses() async {
    final user = Provider.of<AuthNotifier>(context, listen: false).currentUser;
    if (user != null) {
      _currentUser = user;
      final expenses = await _appwriteClient.getExpenses(user.$id);
      if (mounted) {
        setState(() {
          _allExpenses = expenses;
        });
      }
    }
  }

  void _refreshExpenses() {
    if (mounted) {
      setState(() {
        _loadExpensesFuture = _loadUserDataAndExpenses();
      });
    }
  }

  void _addNewExpense(
    String title,
    double amount,
    DateTime date,
    ExpenseCategory category,
  ) async {
    if (_currentUser == null) return;
    final newExp = Expense(
      id: '',
      title: title,
      amount: amount,
      date: date,
      category: category,
    );
    await _appwriteClient.addExpense(newExp, _currentUser!.$id);
    _refreshExpenses();
  }

  void _updateExpense(Expense expense) async {
    await _appwriteClient.updateExpense(expense);
    _refreshExpenses();
  }

  void _deleteExpenses() async {
    for (String id in _selectedItems) {
      await _appwriteClient.deleteExpense(id);
    }
    if (mounted) {
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
    _refreshExpenses();
  }

  void _signOut() {
    Provider.of<AuthNotifier>(context, listen: false).signOut();
  }

  void _startAddOrEditExpense(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewExpense(
        onAddExpense: _addNewExpense,
        onUpdateExpense: _updateExpense,
        expenseToEdit: expense, // Pass the expense if we are editing
      ),
    );
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterDialog(
        initialFilters: _activeFilters,
        onApplyFilters: (newFilters) {
          final potentialResult = _getFilteredExpenses(
            _allExpenses,
            newFilters,
          );
          // UPDATED: Check if any filters were actually applied before checking the result
          final hasActiveFilters =
              newFilters.searchText != null ||
              newFilters.selectedCategories.isNotEmpty ||
              newFilters.dateRange != null;

          if (potentialResult.isEmpty && hasActiveFilters) {
            // If the result is empty, show the SnackBar and do NOT apply the new filters.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No expenses found for the selected filters.'),
                duration: Duration(seconds: 5),
              ),
            );
            return; // Exit the function here.
          }

          // If there are results, apply the new filters and rebuild the UI.
          setState(() {
            _activeFilters = newFilters;
          });
        },
      ),
    );
  }

  List<Expense> _getFilteredExpenses(
    List<Expense> allExpenses,
    FilterCriteria filters,
  ) {
    if (filters.searchText == null &&
        filters.selectedCategories.isEmpty &&
        filters.dateRange == null) {
      return allExpenses;
    }
    return allExpenses.where((expense) {
      if (filters.searchText != null &&
          !expense.title.toLowerCase().contains(
            filters.searchText!.toLowerCase(),
          )) {
        return false;
      }
      if (filters.selectedCategories.isNotEmpty &&
          !filters.selectedCategories.contains(expense.category)) {
        return false;
      }
      if (filters.dateRange != null) {
        final expenseDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        if (expenseDate.isBefore(filters.dateRange!.start) ||
            expenseDate.isAfter(filters.dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _shareExpense(Expense expense) {
    final textToShare =
        'Check out this expense: ${expense.title} for ${expense.amount.toStringAsFixed(2)} on ${DateFormat.yMd().format(expense.date)}';
    print('Sharing: $textToShare');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onItemTappedForSelection(String id) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedItems.contains(id)) {
          _selectedItems.remove(id);
        } else {
          _selectedItems.add(id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedItems = _selectedItems.isNotEmpty;
    final filteredExpenses = _getFilteredExpenses(_allExpenses, _activeFilters);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0x6C000000)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Logged in as:',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    _currentUser?.email ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: _isSelectionMode
            ? Text('${_selectedItems.length} selected')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/Finora.png', height: 32),
                  const SizedBox(width: 8),
                  const Text("Finora"),
                ],
              ),
        actions:
            _selectedIndex ==
                1 // Only show actions on the "Expenses" tab
            ? [
                if (!_isSelectionMode)
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: _isFilterActive ? Colors.yellow : Colors.white,
                    ),
                    onPressed: _openFilterDialog,
                    tooltip: 'Filter Expenses',
                  ),
                if (hasSelectedItems)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteExpenses,
                    tooltip: 'Delete Selected',
                  ),
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        if (value == 'select') {
                          _isSelectionMode = true;
                        } else if (value == 'clear_filter') {
                          _activeFilters = FilterCriteria(
                            selectedCategories: {},
                          );
                        }
                      });
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'select',
                            child: Text('Select Items'),
                          ),
                          if (_isFilterActive)
                            const PopupMenuItem<String>(
                              value: 'clear_filter',
                              child: Text('Clear Filter'),
                            ),
                        ],
                  ),
                if (_isSelectionMode)
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedItems.clear();
                      });
                    },
                  ),
              ]
            : null,
      ),
      body: FutureBuilder<void>(
        future: _loadExpensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<Widget> pages = [
            HomeScreen(
              allExpenses: _allExpenses,
              onEditExpense: (expense) => _startAddOrEditExpense(context, expense: expense),
              onNavigateToSpending: _navigateToSpendingTab
            ),
            // Page 0: New Home Screen
            ExpenseList(
              // Page 1: The original list of expenses
              expenses: filteredExpenses,
              isSelectionMode: _isSelectionMode,
              selectedItems: _selectedItems,
              onItemTapped: (expense) {
                if (_isSelectionMode) {
                  _onItemTappedForSelection(expense.id);
                } else {
                  _startAddOrEditExpense(context, expense: expense);
                }
              },
              onShare: (expense) {},
              onDelete: (id) async {
                await _appwriteClient.deleteExpense(id);
                _refreshExpenses();
              },
            ),
            SpendingScreen(
              expenses: _allExpenses,
              initialFilter: _spendingScreenFilter,
              onFilterChanged: (newFilter) {
                setState(() {
                  _spendingScreenFilter = newFilter;
                });
              },
            ),
            // Page 2: The spending dashboard
          ];

          return pages[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // UPDATED: The list of items now has 3 entries
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Spending',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E1E1E),
        onTap: _onItemTapped,
      ),
      // UPDATED: The FAB is now only visible on the "Expenses" tab (index 1)
      floatingActionButton: _selectedIndex == 1 && !_isSelectionMode
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _startAddOrEditExpense(context),
            )
          : null,
    );
  }
}
