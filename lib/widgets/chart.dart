import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A dedicated data class for chart points. This is more robust than using a Map.
class ChartDataPoint {
  final DateTime date;
  final double amount;
  ChartDataPoint({required this.date, required this.amount});
}

// An enum to define the chart type, passed from the parent widget.
enum ChartType { bar, line }

class Chart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final ChartType chartType;

  const Chart({
    super.key,
    required this.dataPoints,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Text(
          "No expenses in this period.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    // Use a switch statement to build the selected chart type.
    switch (chartType) {
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.line:
        return _buildLineChart(context);
    }
  }

  /// Builds the Bar Chart with interactive tooltips.
  Widget _buildBarChart(BuildContext context) {
    final maxAmount = dataPoints.fold(0.0, (max, p) => max > p.amount ? max : p.amount);

    return BarChart(
      BarChartData(
        maxY: maxAmount == 0 ? 10 : maxAmount * 1.2,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _buildAxisTitles(),
        // --- Interactivity Logic ---
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // UPDATED: This is the correct way to set the tooltip color.
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

  /// Builds the Line Chart.
  Widget _buildLineChart(BuildContext context) {
    final maxAmount = dataPoints.fold(0.0, (max, p) => max > p.amount ? max : p.amount);

    return LineChart(
      LineChartData(
        maxY: maxAmount == 0 ? 10 : maxAmount * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: _buildAxisTitles(),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
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

  /// Helper to build the axis titles, reusable for both charts.
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
            // Show fewer labels if there's a lot of data to prevent overlap
            final interval = (dataPoints.length / 7).ceil();
            if (value.toInt() % interval != 0) {
              return const SizedBox.shrink();
            }
            final date = dataPoints[value.toInt()].date;
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(DateFormat.E().format(date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            );
          },
        ),
      ),
    );
  }
}
