// EFFICIENCY MONITOR CARD
// Shows fuel consumption (km/L) trend with bar chart background

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class EfficiencyMonitorCard extends StatelessWidget {
  final Color appColor;
  final bool isDarkMode;
  
  const EfficiencyMonitorCard({
    super.key,
    required this.appColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final entries = provider.entries;
    
    if (entries.length < 2) {
      return _buildEmptyState(context);
    }
    
    // Sort by date and get last 10 entries
    final sortedEntries = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentEntries = sortedEntries.length > 10 
        ? sortedEntries.sublist(sortedEntries.length - 10)
        : sortedEntries;
    
    // Calculate efficiency (km/L) for each entry
    final efficiencyData = <FlSpot>[];
    final litersData = <FlSpot>[];
    double totalDistance = 0;
    
    for (int i = 0; i < recentEntries.length - 1; i++) {
      final current = recentEntries[i];
      final next = recentEntries[i + 1];
      
      final distance = (next.odometer - current.odometer).abs();
      final efficiency = current.liters > 0 ? distance / current.liters : 0.0;
      
      efficiencyData.add(FlSpot(i.toDouble(), efficiency.toDouble())); // FIX: toDouble()
      litersData.add(FlSpot(i.toDouble(), (current.liters / 2.5).toDouble())); // FIX: toDouble()
      totalDistance += distance;
    }
    
    // Calculate stats
    final efficiencies = efficiencyData.map((e) => e.y).toList();
    final avgEfficiency = efficiencies.reduce((a, b) => a + b) / efficiencies.length;
    final bestEfficiency = efficiencies.reduce((a, b) => a > b ? a : b);
    final worstEfficiency = efficiencies.reduce((a, b) => a < b ? a : b);
    
    return Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "EFFICIENCY MONITOR",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Brandstofverbruik in km/liter per tankbeurt",
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Combined chart
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 25,
                    minY: 0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value * 2.5).toInt()}L',
                              style: TextStyle(
                                color: Colors.blue.withValues(alpha: 0.7),
                                fontSize: 9,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= efficiencyData.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                        left: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                      ),
                    ),
                    barGroups: efficiencyData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final efficiency = entry.value.y;
                      final liters = index < litersData.length ? litersData[index].y : 0.0;
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          // Background bar (liters)
                          BarChartRodData(
                            toY: liters,
                            color: Colors.blue.withValues(alpha: 0.2),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          // Foreground bar (efficiency)
                          BarChartRodData(
                            toY: efficiency,
                            color: appColor,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  duration: Duration.zero,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(appColor, 'km/L'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.blue.withValues(alpha: 0.4), 'Liters'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '🎯 Beste',
                      '${bestEfficiency.toStringAsFixed(1)} km/L',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '😬 Slechtste',
                      '${worstEfficiency.toStringAsFixed(1)} km/L',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '📊 Gemiddeld',
                      '${avgEfficiency.toStringAsFixed(1)} km/L',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '📏 Afstand',
                      '${totalDistance.toStringAsFixed(0)} km',
                      appColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Minimaal 2 tankbeurten nodig',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voeg meer tankbeurten toe om efficiency te meten',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}