import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';

class TcoStackedChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final Car car;
  final bool isDark;

  const TcoStackedChart({
    super.key, 
    required this.entries, 
    required this.car, 
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    // 1. Bereken vaste lasten per maand
    double monthlyInsurance = car.insurance ?? 0;
    double monthlyTax = car.roadTax ?? 0;
    if (car.roadTaxFreq == 'quarter') {
      monthlyTax = monthlyTax / 3;
    }
    double fixedCosts = monthlyInsurance + monthlyTax;

    // 2. Groepeer brandstofkosten per maand (laatste 6 maanden)
    Map<String, double> monthlyFuel = _getMonthlyFuelCosts();
    List<String> lastMonths = _getLastSixMonthKeys();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(20), // Symmetrische padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Maandelijkse Kosten (TCO)", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("Brandstof + Vaste lasten", 
            style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(monthlyFuel, fixedCosts),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= lastMonths.length) return const SizedBox();
                        DateTime dt = DateFormat("yyyy-MM").parse(lastMonths[index]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat('MMM').format(dt), 
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(lastMonths.length, (i) {
                  double fuel = monthlyFuel[lastMonths[i]] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: fuel + fixedCosts,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        rodStackItems: [
                          // Brandstof (Donkerder blauw)
                          BarChartRodStackItem(0, fuel, Colors.blueAccent),
                          // Vaste lasten (Lichter blauw)
                          BarChartRodStackItem(fuel, fuel + fixedCosts, Colors.blueAccent.withOpacity(0.4)),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Brandstof", Colors.blueAccent),
              const SizedBox(width: 20),
              _buildLegendItem("Vast", Colors.blueAccent.withOpacity(0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Map<String, double> _getMonthlyFuelCosts() {
    Map<String, double> costs = {};
    for (var entry in entries) {
      DateTime dt = DateTime.parse(entry['date']);
      String key = DateFormat("yyyy-MM").format(dt);
      costs[key] = (costs[key] ?? 0) + (entry['price_total'] as num).toDouble();
    }
    return costs;
  }

  List<String> _getLastSixMonthKeys() {
    List<String> keys = [];
    DateTime now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      keys.add(DateFormat("yyyy-MM").format(DateTime(now.year, now.month - i, 1)));
    }
    return keys;
  }

  double _calculateMaxY(Map<String, double> fuel, double fixed) {
    double maxVal = 0;
    fuel.forEach((key, value) {
      if (value + fixed > maxVal) maxVal = value + fixed;
    });
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }
}