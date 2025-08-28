import 'package:expense_tracker/providers/budget_provider.dart';
import 'package:expense_tracker/screens/budget_screen.dart';
import 'package:expense_tracker/screens/spending_screen.dart';
import 'package:expense_tracker/widgets/budget_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  double _calculateTotal(List<Expense> expenses, DateTime start, DateTime end) {
    return expenses
        .where((exp) => !exp.date.isBefore(start) && exp.date.isBefore(end))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final totalToday = _calculateTotal(allExpenses, todayStart, tomorrowStart);
    final totalWeek = _calculateTotal(allExpenses, weekStart, tomorrowStart);
    final totalMonth = _calculateTotal(allExpenses, monthStart, tomorrowStart);

    final recentExpenses = List<Expense>.from(allExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Watch the BudgetProvider
    final budgetProvider = context.watch<BudgetProvider?>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      children: [
        Consumer<BudgetProvider?>(
          builder: (context, budgetProvider, child) {
            if (budgetProvider != null && budgetProvider.currentMonthBudget != null) {
              return BudgetSummaryCard(
                budgetAmount: budgetProvider.currentMonthBudget!.amount,
                totalSpent: totalMonth,
                onEdit: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
                },
              );
            } else {
              // Show a prompt to set a budget if one doesn't exist
              return Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.add_chart, color: Colors.deepPurple),
                  title: const Text('Set a Monthly Budget', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Track your spending against a goal.', style: TextStyle(color: Colors.black54)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
                  },
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),

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
        const Divider(color: Colors.black26, height: 24, thickness: 1.0),
        if (recentExpenses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No recent transactions to show.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          )
        else
          ...recentExpenses.take(5).map((expense) {
            return ExpenseItem(
              expense: expense,
              onDelete: (id) {},
              onShare: (exp) {},
              isSelectionMode: false,
              isSelected: false,
              onTap: () => onEditExpense(expense),
            );
          }),
      ],
    );
  }
}