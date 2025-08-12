import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/spending_screen.dart';

class ChartDataPoint {
  final DateTime date;
  final double amount;
  ChartDataPoint({required this.date, required this.amount});
}

enum ChartType { bar, line }

class Chart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final ChartType chartType;
  final FilterType filterType;

  const Chart({
    super.key,
    required this.dataPoints,
    required this.chartType,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty || dataPoints.every((p) => p.amount == 0)) {
      return const Center(
        child: Text(
          "No expenses in this period.",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    // --- MODIFIED: We calculate maxAmount here to pass it to the builders ---
    final maxAmount = dataPoints.fold(0.0, (max, p) => max > p.amount ? max : p.amount);
    // Ensure we have a sensible top value, even if maxAmount is small
    final chartTopY = maxAmount == 0 ? 50.0 : (maxAmount * 1.2);


    switch (chartType) {
      case ChartType.bar:
        return _buildBarChart(context, chartTopY);
      case ChartType.line:
        return _buildLineChart(context, chartTopY);
    }
  }

  Widget _buildBarChart(BuildContext context, double maxY) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.transparent), // Hide vertical grid lines
        ),
        borderData: FlBorderData(show: false),
        titlesData: _buildAxisTitles(maxY), // MODIFIED: Pass maxY
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

  Widget _buildLineChart(BuildContext context, double maxY) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData(
          top: false,
          bottom: true,
          left: true, // Clip to the chart area
          right: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black26, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.transparent),
        ),
        titlesData: _buildAxisTitles(maxY), // MODIFIED: Pass maxY
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
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

  /// REFACTORED: This helper now builds the Y-axis (left) titles dynamically.
  FlTitlesData _buildAxisTitles(double maxY) {
    return FlTitlesData(
      // --- ADDED: Left (Y-Axis) Titles Configuration ---
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45, // Make space for the labels
          // This function determines what text to show for each interval
          getTitlesWidget: (value, meta) {
            // We don't want to show a label for the very top of the chart
            if (value == meta.max) {
              return Container();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '£${value.toInt()}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
                textAlign: TextAlign.right,
              ),
            );
          },
          // This dynamically calculates the interval between labels.
          // We aim for about 4-5 labels on the axis.
          interval: maxY / 4,
        ),
      ),
      // --- END OF ADDED SECTION ---
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if(value.toInt() >= dataPoints.length) return Container(); // Avoid range errors
            final point = dataPoints[value.toInt()];
            String text;
            switch (filterType) {
              case FilterType.week:
                text = DateFormat.E().format(point.date); // e.g., "Mon"
                break;
              case FilterType.month:
                text = DateFormat('d/M').format(point.date); // e.g., "23/7"
                break;
              case FilterType.year:
                text = DateFormat.MMM().format(point.date); // e.g., "Jul"
                break;
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 12)),
            );
          },
        ),
      ),
    );
  }
}