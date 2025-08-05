import 'package:expense_tracker/api/appwrite_client.dart';
import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:expense_tracker/screens/spending_screen.dart'; // Import the new screen
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
        scaffoldBackgroundColor: const Color(0xFF96A4D3),
        primaryColor: const Color(0x00000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF96A4D3),
          secondary: const Color(0xFFAA8F76),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF152046),
          foregroundColor: Color(0xFFAA8F76),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFFFFF),
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
  late Future<List<Expense>> _expensesFuture;
  models.User? _currentUser;

  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _expensesFuture = Future.value([]);
    _loadUserDataAndExpenses();
  }

  void _loadUserDataAndExpenses() {
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

  void _signOut() {
    Provider.of<AuthNotifier>(context, listen: false).signOut();
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

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF152046)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Logged in as:', style: TextStyle(color: Colors.white)),
                  Text(
                    _currentUser?.email ?? 'Loading...',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
        title: Text(_isSelectionMode ? '${_selectedItems.length} selected' : "Finora"),
        actions: [
          if (hasSelectedItems)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteExpenses, tooltip: 'Delete Selected'),

            if(_selectedIndex == 0)
              TextButton(
                child: Text(_isSelectionMode ? 'Cancel' : 'Select', style: const TextStyle(color: Color(0xFFAA8F76))),
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

          final List<Widget> pages = [
            // Page 0: Home (Expense List)
            ExpenseList(
              expenses: expenses,
              isSelectionMode: _isSelectionMode,
              selectedItems: _selectedItems,
              onItemTapped: _onItemTappedForSelection,
              onShare: _shareExpense,
              onDelete: (id) async {
                await _appwriteClient.deleteExpense(id);
                _refreshExpenses();
              },
            ),
            // Page 1: The new SpendingScreen
            SpendingScreen(expenses: expenses),
          ];

          return pages[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights), // A more fitting icon for "Spending"
            label: 'Spending', // UPDATED: Label is now "Spending"
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF1E1E1E),
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 && !_isSelectionMode
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startAddExpense(context),
      )
          : null,
    );
  }
}
