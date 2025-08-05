import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import '../constants/ProviderNameConstants.dart';

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


  /// A Helper function to find a suitable icon based on keywords in the title.
  IconData _getIconForTitle(String title) {
    final lowerCaseTitle = title.toLowerCase();
    if (lowerCaseTitle.contains(ProviderNameConstants.electric) || lowerCaseTitle.contains(ProviderNameConstants.power)) {
      return Icons.flash_on;
    } else if (lowerCaseTitle.contains(ProviderNameConstants.electric) && lowerCaseTitle.contains(ProviderNameConstants.gas)){
      return Icons.energy_savings_leaf;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.gas)) {
      return Icons.gas_meter;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.rent) || lowerCaseTitle.contains(ProviderNameConstants.mortgage) || lowerCaseTitle.contains(ProviderNameConstants.house)) {
      return Icons.house;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.grocery)) {
      return Icons.shopping_cart;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.water)) {
      return Icons.water_drop;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.fuel) || lowerCaseTitle.contains(ProviderNameConstants.petrol) || lowerCaseTitle.contains(ProviderNameConstants.diesel)) {
      return Icons.local_gas_station;
    }
    if (lowerCaseTitle.contains(ProviderNameConstants.carInsurance)) {
      return Icons.directions_car_filled;
    }
    return Icons.storefront;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isSelected ? Colors.redAccent : Color(0xFF152046);
    // Slidable widget that enables the swipe actions

    final domainGuess = expense.title.split(' ').first.toLowerCase();

    return Slidable(
      // Disable sliding when in selection mode
      enabled: !isSelectionMode,
      //Defines the actions that appear when you swipe from right to left
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          // "Share" action button
          SlidableAction(
            onPressed: (context) {
              onShare(expense);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
            borderRadius: BorderRadius.circular(12),
          ),

          // "Delete" action button
          SlidableAction(
            onPressed: (context) {
              onDelete(expense.id);
            },
            backgroundColor: Color(0xFFFE4A49),
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
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(
                    'https://logo.clearbit.com/$domainGuess.com',
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(_getIconForTitle(expense.title), size: 40, color: Colors.grey);
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900, color: Color(0xFFAA8F76)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(expense.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Color(0xFFAA8F76)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\£${expense.amount}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFAA8F76)
                        ),
                      ),
                    ],
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
