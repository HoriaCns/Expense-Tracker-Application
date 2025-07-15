import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'widgets/expense_list.dart';
import 'widgets/new_expense.dart';

void main() {
  runApp(ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFB9F1AE),
        primaryColor: Color(0xFF03ED9B),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF03ED9B),
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFFFFF),
        ),
        cardColor: Color(0xFFFFFFFF),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
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

  void _addNewExpense(String title, double amount, DateTime date) {
    final newExp = Expense(
      id: DateTime.now().toString(),
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
      builder: (_) => NewExpense(onAddExpense: _addNewExpense),
    );
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((exp) => exp.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expense Tracker"),
      ),
      body: ExpenseList(expenses: _expenses, onDelete: _deleteExpense),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _startAddExpense(context),
      ),
    );
  }
}
