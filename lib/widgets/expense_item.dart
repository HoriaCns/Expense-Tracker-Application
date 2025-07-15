import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseItem extends StatelessWidget {
  final Expense expense;
  final Function(String) onDelete;

  ExpenseItem({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Padding(
            padding: EdgeInsets.all(6),
            child: FittedBox(child: Text('\$${expense.amount}')),
          ),
        ),
        title: Text(expense.title),
        subtitle: Text(DateFormat.yMMMd().format(expense.date)),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          color: Colors.red,
          onPressed: () => onDelete(expense.id),
        ),
      ),
    );
  }
}