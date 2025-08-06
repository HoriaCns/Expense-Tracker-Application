import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'expense_item.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(String) onDelete;
  final Function(Expense) onShare;
  final bool isSelectionMode;
  final Set<String> selectedItems;
  final Function(String) onItemTapped;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.onDelete,
    required this.onShare,
    // Add to constructor
    required this.isSelectionMode,
    required this.selectedItems,
    required this.onItemTapped,
  });

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
                color: Color(0xFF152046),
              ),
              textAlign: TextAlign.center,
            ),
        )
        : ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (ctx, i) {
              final expense = expenses[i];
              return ExpenseItem(
                expense: expense,
                onDelete: onDelete,
                onShare: onShare,
                isSelectionMode: isSelectionMode,
                isSelected: selectedItems.contains(expense.id),
                onTap: () => onItemTapped(expense.id),
              );
            }
        );
  }
}
