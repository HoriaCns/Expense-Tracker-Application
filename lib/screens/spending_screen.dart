import 'package:collection/collection.dart'; // Add this import for groupBy
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../widgets/chart.dart';

enum FilterType { week, month, year }

class SpendingScreen extends StatefulWidget {
  final List<Expense> expenses;

  const SpendingScreen({super.key, required this.expenses});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  ChartType _selectedChartType = ChartType.bar;
  FilterType _selectedFilter = FilterType.week;

  /// REFACTORED: This getter now contains robust logic to group data
  /// correctly for each filter type.
  List<ChartDataPoint> get _filteredExpenseData {
    final now = DateTime.now();
    List<ChartDataPoint> dataPoints = [];

    switch (_selectedFilter) {
      case FilterType.week:
      // Group by day for the last 7 days
        final recentExpenses = widget.expenses.where((exp) {
          return exp.date.isAfter(now.subtract(const Duration(days: 7)));
        }).toList();

        final groupedByDay = groupBy(recentExpenses, (Expense exp) {
          return DateTime(exp.date.year, exp.date.month, exp.date.day);
        });

        for (int i = 6; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day - i);
          final total = groupedByDay[day]?.fold(0.0, (sum, item) => sum + item.amount) ?? 0.0;
          dataPoints.add(ChartDataPoint(date: day, amount: total));
        }
        break;

      case FilterType.month:
      // Group by week for the last 4 weeks
        for (int i = 3; i >= 0; i--) {
          final weekStartDate = now.subtract(Duration(days: (i * 7) + 6));
          final weekEndDate = now.subtract(Duration(days: i * 7));

          final expensesInWeek = widget.expenses.where((exp) {
            return exp.date.isAfter(weekStartDate.subtract(const Duration(days: 1))) && exp.date.isBefore(weekEndDate.add(const Duration(days: 1)));
          }).toList();

          final total = expensesInWeek.fold(0.0, (sum, item) => sum + item.amount);
          // Use the start of the week as the representative date
          dataPoints.add(ChartDataPoint(date: weekStartDate, amount: total));
        }
        break;

      case FilterType.year:
      // Group by month for the last 12 months
        for (int i = 11; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i, 1);

          final expensesInMonth = widget.expenses.where((exp) {
            return exp.date.year == monthDate.year && exp.date.month == monthDate.month;
          }).toList();

          final total = expensesInMonth.fold(0.0, (sum, item) => sum + item.amount);
          dataPoints.add(ChartDataPoint(date: monthDate, amount: total));
        }
        break;
    }
    return dataPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
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
          Expanded(
            child: Chart(
              dataPoints: _filteredExpenseData,
              chartType: _selectedChartType,
              // Pass the selected filter to the chart for correct label formatting
              filterType: _selectedFilter,
            ),
          ),
          const SizedBox(height: 16),
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
