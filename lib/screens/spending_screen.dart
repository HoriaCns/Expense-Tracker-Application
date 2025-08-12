import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/chart.dart';

enum FilterType { week, month, year }

class SpendingScreen extends StatefulWidget {
  final FilterType initialFilter;
  final Function(FilterType) onFilterChanged;

  const SpendingScreen({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  ChartType _selectedChartType = ChartType.bar;
  late FilterType _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant SpendingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedFilter = widget.initialFilter;
      });
    }
  }

  /// This getter now simply asks the provider for the correct data list.
  List<ChartDataPoint> _getChartData(BuildContext context) {
    final provider = context.read<ExpenseProvider?>();
    if (provider == null) return [];

    switch (_selectedFilter) {
      case FilterType.week:
        return provider.weeklyChartData;
      case FilterType.month:
        return provider.monthlyChartData;
      case FilterType.year:
        return provider.yearlyChartData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData(context);

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
              widget.onFilterChanged(newSelection.first);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Chart(
              dataPoints: chartData,
              chartType: _selectedChartType,
              filterType: _selectedFilter,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Chart Type:", style: TextStyle(color: Colors.black)),
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