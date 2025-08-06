import 'package:expense_tracker/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

final Map<ExpenseCategory, Category> _categoryMap = {
  for (var cat in availableCategories) cat.type: cat
};

// REVERTED: Changed back to a StatelessWidget and removed animation logic.
class ExpenseItem extends StatelessWidget {
  final Expense expense;
  final Function(String) onDelete;
  final Function(Expense) onShare;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const ExpenseItem({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onShare,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isSelected ? Colors.orange : Color(0xFF152046);
    final category = _categoryMap[expense.category] ?? _categoryMap[ExpenseCategory.other]!;
    final domainGuess = expense.title.split(' ').first.toLowerCase();

    return Slidable(
      enabled: !isSelectionMode,
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onShare(expense),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (context) => onDelete(expense.id),
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // --- RESTORED: Static colored shadow ---
          elevation: 8,
          shadowColor: category.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    'https://logo.clearbit.com/$domainGuess.com',
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(category.icon, color: category.color, size: 32);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(expense.date),
                        style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAA8F76),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '£${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
