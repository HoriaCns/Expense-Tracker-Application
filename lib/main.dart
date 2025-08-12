import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:expense_tracker/providers/budget_provider.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/spending_screen.dart';
import 'package:expense_tracker/widgets/filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'widgets/expense_list.dart';
import 'widgets/new_expense.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProxyProvider<AuthNotifier, ExpenseProvider?>(
          create: (_) => null,
          update: (context, auth, previous) {
            final user = auth.currentUser;
            if (user == null) return null;
            if (previous?.allExpenses.isNotEmpty ?? false) return previous;
            return ExpenseProvider(user.$id);
          },
        ),
        // --- ADDED: BudgetProvider ---
        ChangeNotifierProxyProvider<AuthNotifier, BudgetProvider?>(
          create: (_) => null,
          update: (context, auth, previous) {
            final user = auth.currentUser;
            if (user == null) return null;
            if (previous != null) return previous;
            return BudgetProvider(user.$id);
          },
        ),
      ],
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
  // All state related to expenses or filters has been removed.
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};
  int _selectedIndex = 0;
  FilterType _spendingScreenFilter = FilterType.week;

  bool _isFilterActive(BuildContext context) {
    final provider = context.read<ExpenseProvider?>();
    if (provider == null) return false;
    final filters = provider.activeFilters;
    return filters.searchText != null ||
        filters.selectedCategories.isNotEmpty ||
        filters.dateRange != null;
  }

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
      _selectedIndex = 2;
    });
  }

  void _deleteExpenses() {
    final provider = context.read<ExpenseProvider?>();
    if (provider == null) return;

    for (String id in _selectedItems) {
      provider.deleteExpense(id);
    }

    if (mounted) {
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _signOut() {
    Provider.of<AuthNotifier>(context, listen: false).signOut();
  }

  void _startAddOrEditExpense(BuildContext context, {Expense? expense}) {
    final provider = context.read<ExpenseProvider?>();
    if (provider == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewExpense(
        onAddExpense: provider.addExpense,
        onUpdateExpense: provider.updateExpense,
        expenseToEdit: expense,
      ),
    );
  }

  void _openFilterDialog() {
    final provider = context.read<ExpenseProvider?>();
    if (provider == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterDialog(
        initialFilters: provider.activeFilters,
        onApplyFilters: (newFilters) {
          // Check if applying the filter would result in an empty list
          final potentialResult = provider.allExpenses.where((expense) {
            // This is a simplified check. A full check would be more complex.
            if (newFilters.searchText != null &&
                !expense.title.toLowerCase().contains(newFilters.searchText!.toLowerCase())) {
              return false;
            }
            return true;
          }).toList();

          final hasActiveFilters = newFilters.searchText != null ||
              newFilters.selectedCategories.isNotEmpty ||
              newFilters.dateRange != null;

          if (potentialResult.isEmpty && hasActiveFilters) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No expenses found for the selected filters.'),
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }
          // The provider now handles the filter state
          provider.updateFilters(newFilters);
        },
      ),
    );
  }

  // The _getFilteredExpenses method has been removed from here.

  void _shareExpense(Expense expense) {
    final textToShare =
        'Check out this expense: ${expense.title} for ${expense.amount.toStringAsFixed(2)} on ${DateFormat.yMd().format(expense.date)}';
    print('Sharing: $textToShare');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon!'), duration: Duration(seconds: 2)),
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
    final authNotifier = context.watch<AuthNotifier>();
    final expenseProvider = context.watch<ExpenseProvider?>();

    if (expenseProvider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasSelectedItems = _selectedItems.isNotEmpty;
    // Get both total and filtered lists from the provider
    final allExpenses = expenseProvider.allExpenses;
    final filteredExpenses = expenseProvider.filteredExpenses;

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
                  const Text('Logged in as:', style: TextStyle(color: Colors.white)),
                  Text(
                    authNotifier.currentUser?.email ?? 'Loading...',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Sign Out'), onTap: _signOut),
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
        actions: _selectedIndex == 1
            ? [
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(Icons.filter_list, color: _isFilterActive(context) ? Colors.yellow : Colors.white),
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
                if (value == 'select') {
                  setState(() => _isSelectionMode = true);
                } else if (value == 'clear_filter') {
                  context.read<ExpenseProvider?>()?.clearFilters();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'select', child: Text('Select Items')),
                if (_isFilterActive(context))
                  const PopupMenuItem<String>(value: 'clear_filter', child: Text('Clear Filter')),
              ],
            ),
          if (_isSelectionMode)
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
      body: Builder(
        builder: (context) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (expenseProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(expenseProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700], fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => expenseProvider.fetchExpenses(),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Widget> pages = [
            HomeScreen(
              allExpenses: allExpenses,
              onEditExpense: (expense) => _startAddOrEditExpense(context, expense: expense),
              onNavigateToSpending: _navigateToSpendingTab,
            ),
            ExpenseList(
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
              onShare: _shareExpense,
              onDelete: (id) => context.read<ExpenseProvider?>()?.deleteExpense(id),
            ),
            SpendingScreen(
              initialFilter: _spendingScreenFilter,
              onFilterChanged: (newFilter) => setState(() => _spendingScreenFilter = newFilter),
            ),
          ];

          return pages[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Spending'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E1E1E),
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1 && !_isSelectionMode
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startAddOrEditExpense(context),
      )
          : null,
    );
  }
}