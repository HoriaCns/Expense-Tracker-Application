import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'expense_item.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(String) onDelete;

  ExpenseList({required this.expenses, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return expenses.isEmpty
        ? Center(
            child: Text(
              'Welcome! There are no expenses added yet! Please use the button below to add some information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Color(0xDD000000),
              ),
              textAlign: TextAlign.center,
            ),
        )
        : ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (ctx, i) => ExpenseItem(
              expense: expenses[i],
              onDelete: onDelete,
            ),
        );
  }
}
