import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';

// A data class to hold the selected filter values.
class FilterCriteria {
  final String? searchText;
  final Set<ExpenseCategory> selectedCategories;
  final DateTimeRange? dateRange;

  FilterCriteria({
    this.searchText,
    required this.selectedCategories,
    this.dateRange,
  });
}

class FilterDialog extends StatefulWidget {
  final FilterCriteria initialFilters;
  final Function(FilterCriteria) onApplyFilters;

  const FilterDialog({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late final TextEditingController _searchController;
  late Set<ExpenseCategory> _selectedCategories;
  late DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialFilters.searchText);
    _selectedCategories = Set.from(widget.initialFilters.selectedCategories);
    _dateRange = widget.initialFilters.dateRange;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (pickedRange != null) {
      setState(() {
        _dateRange = pickedRange;
      });
    }
  }

  void _applyFilters() {
    final criteria = FilterCriteria(
      searchText: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      selectedCategories: _selectedCategories,
      dateRange: _dateRange,
    );
    widget.onApplyFilters(criteria);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Expenses', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            // --- Search Field ---
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by title...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            // --- Category Filter ---
            Text('Filter by Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category.type);
                return FilterChip(
                  label: Text(category.name),
                  avatar: Icon(category.icon, color: isSelected ? Colors.white : category.color),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category.type);
                      } else {
                        _selectedCategories.remove(category.type);
                      }
                    });
                  },
                  selectedColor: category.color,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // --- Date Range Filter ---
            Text('Filter by Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dateRange == null
                        ? 'No date range selected'
                        : '${DateFormat.yMMMd().format(_dateRange!.start)} - ${DateFormat.yMMMd().format(_dateRange!.end)}',
                    style: TextStyle(color: Color(0xFF152046)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _presentDatePicker,
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dateRange = null),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            // --- Action Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
