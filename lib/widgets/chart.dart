import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/spending_screen.dart'; // Import to get access to FilterType

class ChartDataPoint {
  final DateTime date;
  final double amount;
  ChartDataPoint({required this.date, required this.amount});
}

enum ChartType { bar, line }

class Chart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final ChartType chartType;
  final FilterType filterType; // Add this to know how to format labels

  const Chart({
    super.key,
    required this.dataPoints,
    required this.chartType,
    required this.filterType, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty || dataPoints.every((p) => p.amount == 0)) {
      return const Center(
        child: Text(
          "No expenses in this period.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    switch (chartType) {
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.line:
        return _buildLineChart(context);
    }
  }

  Widget _buildBarChart(BuildContext context) {
    final maxAmount = dataPoints.fold(0.0, (max, p) => max > p.amount ? max : p.amount);

    return BarChart(
      BarChartData(
        maxY: maxAmount == 0 ? 10 : maxAmount * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 2),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 2),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _buildAxisTitles(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = dataPoints[group.x.toInt()];
              final date = DateFormat.yMMMd().format(point.date);
              final amount = '£${point.amount.toStringAsFixed(2)}';
              return BarTooltipItem(
                '$amount\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [TextSpan(text: date, style: const TextStyle(color: Colors.white70))],
              );
            },
          ),
        ),
        barGroups: dataPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.amount,
                color: Theme.of(context).colorScheme.secondary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final maxAmount = dataPoints.fold(0.0, (max, p) => max > p.amount ? max : p.amount);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxAmount == 0 ? 10 : maxAmount * 1.2,
        clipData: const FlClipData(
          top: false,
          bottom: true,
          left: false,
          right: false,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 1),
        ),
        titlesData: _buildAxisTitles(),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.amount);
            }).toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// REFACTORED: This helper now uses the filterType to render the correct labels.
  FlTitlesData _buildAxisTitles() {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final point = dataPoints[value.toInt()];
            String text;
            switch (filterType) {
              case FilterType.week:
                text = DateFormat.E().format(point.date); // e.g., "Mon"
                break;
              case FilterType.month:
              // For the month view, show the start date of the week
                text = DateFormat('d/M').format(point.date); // e.g., "23/7"
                break;
              case FilterType.year:
                text = DateFormat.MMM().format(point.date); // e.g., "Jul"
                break;
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 12)),
            );
          },
        ),
      ),
    );
  }
}
