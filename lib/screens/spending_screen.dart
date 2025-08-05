import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
// UPDATED: Import the chart widget to get access to ChartType and ChartDataPoint
import '../widgets/chart.dart';

// REMOVED: The duplicate enum definition has been removed from this file.

class SpendingScreen extends StatefulWidget {
  final List<Expense> expenses;

  const SpendingScreen({super.key, required this.expenses});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  ChartType _selectedChartType = ChartType.bar;
  FilterType _selectedFilter = FilterType.week;

  /// Processes the raw expense list based on the selected filter.
  List<ChartDataPoint> get _filteredExpenseData {
    final now = DateTime.now();
    List<Expense> filteredExpenses = [];

    // Filter the expenses based on the selected time range
    switch (_selectedFilter) {
      case FilterType.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filteredExpenses = widget.expenses.where((exp) => exp.date.isAfter(weekAgo)).toList();
        break;
      case FilterType.month:
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filteredExpenses = widget.expenses.where((exp) => exp.date.isAfter(monthAgo)).toList();
        break;
      case FilterType.year:
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        filteredExpenses = widget.expenses.where((exp) => exp.date.isAfter(yearAgo)).toList();
        break;
    }

    // Group the filtered expenses. For this example, we'll group by day for all filters.
    Map<DateTime, double> groupedData = {};
    for (var expense in filteredExpenses) {
      final day = DateTime(expense.date.year, expense.date.month, expense.date.day);
      groupedData[day] = (groupedData[day] ?? 0) + expense.amount;
    }

    return groupedData.entries
        .map((entry) => ChartDataPoint(date: entry.key, amount: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // --- Filter Buttons ---
          SegmentedButton<FilterType>(
            segments: const [
              ButtonSegment(value: FilterType.week, label: Text('Week'), icon: Icon(Icons.calendar_view_week)),
              ButtonSegment(value: FilterType.month, label: Text('Month'), icon: Icon(Icons.calendar_view_month)),
              ButtonSegment(value: FilterType.year, label: Text('Year'), icon: Icon(Icons.calendar_today)),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),

          // --- Chart Display ---
          Expanded(
            child: Chart(
              dataPoints: _filteredExpenseData,
              chartType: _selectedChartType,
            ),
          ),
          const SizedBox(height: 16),

          // --- Chart Type Switcher ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Chart Type:", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [_selectedChartType == ChartType.bar, _selectedChartType == ChartType.line],
                onPressed: (index) {
                  setState(() {
                    _selectedChartType = index == 0 ? ChartType.bar : ChartType.line;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.black,
                fillColor: Theme.of(context).colorScheme.secondary,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.bar_chart)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.show_chart)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Note: A Pie Chart is most useful with expense categories, which we can add in the next phase!",
            style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

// This enum is also defined in this file for the filter buttons.
enum FilterType { week, month, year }
