import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fuel_entry.dart';

class TcoStackedChart extends StatelessWidget {
  final List<FuelEntry> entries;

  const TcoStackedChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Sorteer entries op datum voor een correcte grafieklijn
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                // Toon alleen voor een paar punten de datum om overlap te voorkomen
                if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                  if (value.toInt() % (sortedEntries.length > 5 ? sortedEntries.length ~/ 3 : 1) == 0) {
                    return Text(
                      DateFormat('dd/MM').format(sortedEntries[value.toInt()].date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.priceTotal);
            }).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }
}