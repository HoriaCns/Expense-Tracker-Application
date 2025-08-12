import 'package:flutter/material.dart';

class BudgetSummaryCard extends StatelessWidget {
  final double budgetAmount;
  final double totalSpent;
  final VoidCallback onEdit;

  const BudgetSummaryCard({
    super.key,
    required this.budgetAmount,
    required this.totalSpent,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final double amountLeft = budgetAmount - totalSpent;
    final double percentSpent = budgetAmount > 0 ? (totalSpent / budgetAmount).clamp(0.0, 1.0) : 0.0;
    final Color progressColor = percentSpent > 0.9 ? Colors.red : (percentSpent > 0.7 ? Colors.orange : Colors.green);

    return Card(
      elevation: 6,
      shadowColor: Colors.deepPurple,
      color: const Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Budget',
                  style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: onEdit,
                  tooltip: 'Edit Budget',
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '£${amountLeft.toStringAsFixed(2)} left to spend',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: amountLeft >= 0 ? const Color(0xFF03ED9B) : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentSpent,
                minHeight: 12,
                backgroundColor: Colors.grey.shade700,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: £${totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  'Budget: £${budgetAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}