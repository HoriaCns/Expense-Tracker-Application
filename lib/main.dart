import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/expense.dart';
import 'widgets/expense_list.dart';
import 'widgets/new_expense.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

void main() {
  runApp(ExpenseApp());
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
      home: ExpenseHome(),
    );
  }
}

class ExpenseHome extends StatefulWidget {
  @override
  _ExpenseHomeState createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  final List<Expense> _expenses = [];

  // New state variables for selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  void _addNewExpense(String title, double amount, DateTime date) {
    final newExp = Expense(
      id: uuid.v4(),
      title: title,
      amount: amount,
      date: date,
    );

    setState(() {
      _expenses.add(newExp);
    });
  }

  void _startAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // This makes the modal take up the full screen and scrollable
      isScrollControlled: true,
      // This gives the modal nice rounded corners on top
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewExpense(onAddExpense: _addNewExpense),
    );
  }

// This function deletes all items stored in the _selectedItems set
  void _deleteExpenses() {
    setState(() {
      _expenses.removeWhere((exp) => _selectedItems.contains(exp.id));
      _selectedItems.clear(); // Clear the selection set
      _isSelectionMode = false; // Exit selection mode
    });
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

  // Toggle the selection status of a single item
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF03ED9B)),
              child: Text(
                'Expense Tracker Menu',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Closes the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          // Show a different title when in selection mode
          _isSelectionMode
              ? '${_selectedItems.length} selected'
              : "Expense Tracker",
        ),
        actions: [
          // If items are selected, show a delete icon
          if (hasSelectedItems)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteExpenses,
              tooltip: 'Delete Selected',
            ),
          // The main "Select" / "Cancel" button
          TextButton(
            child: Text(
              _isSelectionMode ? 'Cancel' : 'Select',
              style: const TextStyle(color: Colors.black),
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedItems.clear(); // Clear selections when toggling mode
              });
            },
          ),
        ],
      ),
      body: ExpenseList(
        expenses: _expenses,
        isSelectionMode: _isSelectionMode,
        selectedItems: _selectedItems,
        onItemTapped: _onItemTapped,
        onShare: _shareExpense,
        // For single-item delete via slide
        onDelete: (id) {
          setState(() {
            _expenses.removeWhere((exp) => exp.id == id);
          });
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null // Hide the FAB when in selection mode
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _startAddExpense(context),
            ),
    );
  }
}
