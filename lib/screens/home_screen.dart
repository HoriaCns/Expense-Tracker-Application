import 'package:expense_tracker/screens/spending_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../widgets/expense_item.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  final List<Expense> allExpenses;
  final Function(Expense) onEditExpense;
  final Function(FilterType) onNavigateToSpending;

  const HomeScreen({
    super.key,
    required this.allExpenses,
    required this.onEditExpense,
    required this.onNavigateToSpending,
  });

  // Helper to calculate total for a given period
  double _calculateTotal(List<Expense> expenses, DateTime start, DateTime end) {
    return expenses
        .where((exp) => exp.date.isAfter(start) && exp.date.isBefore(end))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final totalToday = _calculateTotal(allExpenses, todayStart, now.add(const Duration(days: 1)));
    final totalWeek = _calculateTotal(allExpenses, weekStart, now.add(const Duration(days: 1)));
    final totalMonth = _calculateTotal(allExpenses, monthStart, now.add(const Duration(days: 1)));

    // Sort expenses by date to get the most recent ones
    final recentExpenses = List<Expense>.from(allExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(36.0),
      physics: BouncingScrollPhysics(),
      children: [
        // --- Summary Cards ---
        SummaryCard(
          title: 'Spent Today',
          amount: '£${totalToday.toStringAsFixed(2)}',
          icon: Icons.today,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Spent This Week',
          amount: '£${totalWeek.toStringAsFixed(2)}',
          icon: Icons.calendar_view_week,
          color: Colors.blue,
          onTap: () => onNavigateToSpending(FilterType.week),
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Spent This Month',
          amount: '£${totalMonth.toStringAsFixed(2)}',
          icon: Icons.calendar_month,
          color: Colors.purple,
          onTap: () => onNavigateToSpending(FilterType.month),
        ),
        const SizedBox(height: 24),

        // --- Recent Transactions ---
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const Divider(color: Colors.black, height: 24, thickness: 5.0),
        if (recentExpenses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No recent transactions to show.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          )
        else
        // Take the first 5 recent expenses, or fewer if the list is short
          ...recentExpenses.take(5).map((expense) {
            return ExpenseItem(
              expense: expense,
              onDelete: (id) {}, // Delete is handled on the Expenses screen
              onShare: (exp) {}, // Share is handled on the Expenses screen
              isSelectionMode: false,
              isSelected: false,
              onTap: () => onEditExpense(expense), // Allow editing from the dashboard
            );
          }),
      ],
    );
  }
}
