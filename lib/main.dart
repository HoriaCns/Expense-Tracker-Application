import 'package:expense_tracker/api/appwrite_client.dart';
import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'widgets/expense_list.dart';
import 'widgets/new_expense.dart';

void main() {
  // Wrap the entire app in a ChangeNotifierProvider.
  // This makes the AuthNotifier instance available to all descendant widgets.
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
      title: 'Expense Tracker',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Color(0xFF1E1E1E),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF00DAC6),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFFFFF),
        ),
        cardColor: Color(0xFFFFFFFF),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
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
  late Future<List<Expense>> _expensesFuture;
  models.User? _currentUser;

  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _expensesFuture = Future.value([]);
    // Use the AuthNotifier to get the current user instead of a direct call.
    _loadUserDataAndExpenses();
  }

  void _loadUserDataAndExpenses() {
    // Access the user from the provider.
    final user = Provider.of<AuthNotifier>(context, listen: false).currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
        if (_currentUser != null) {
          _expensesFuture = _appwriteClient.getExpenses(_currentUser!.$id);
        }
      });
    }
  }

  void _refreshExpenses() {
    if (_currentUser != null) {
      if (mounted) {
        setState(() {
          _expensesFuture = _appwriteClient.getExpenses(_currentUser!.$id);
        });
      }
    }
  }

  void _addNewExpense(String title, double amount, DateTime date) async {
    if (_currentUser == null) return;
    final newExp = Expense(id: '', title: title, amount: amount, date: date);
    await _appwriteClient.addExpense(newExp, _currentUser!.$id);
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

  // REFACTORED: Use the AuthNotifier for signing out.
  void _signOut() {
    Provider.of<AuthNotifier>(context, listen: false).signOut();
    // No Navigator needed. The AuthGate will handle the screen change.
  }

  void _startAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewExpense(onAddExpense: _addNewExpense),
    );
  }

  void _shareExpense(Expense expense) {
    final textToShare =
        'Check out this expense: ${expense.title} for ${expense.amount.toStringAsFixed(2)} on ${DateFormat.yMd().format(expense.date)}';
    print('Sharing: $textToShare');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onItemTapped(String id) {
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

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF03ED9B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Logged in as:', style: TextStyle(color: Colors.black)),
                  Text(
                    _currentUser?.email ?? 'Loading...',
                    style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
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
        title: Text(_isSelectionMode ? '${_selectedItems.length} selected' : "Expense Tracker"),
        actions: [
          if (hasSelectedItems)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteExpenses, tooltip: 'Delete Selected'),
          TextButton(
            child: Text(_isSelectionMode ? 'Cancel' : 'Select', style: const TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedItems.clear();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          return ExpenseList(
            expenses: expenses,
            isSelectionMode: _isSelectionMode,
            selectedItems: _selectedItems,
            onItemTapped: _onItemTapped,
            onShare: _shareExpense,
            onDelete: (id) async {
              await _appwriteClient.deleteExpense(id);
              _refreshExpenses();
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startAddExpense(context),
      ),
    );
  }
}
