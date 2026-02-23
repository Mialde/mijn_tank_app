// PRIJS TRACKER CARD
// Line chart showing fuel price trend over time

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class PriceTrackerCard extends StatelessWidget {
  final Color appColor;
  final bool isDarkMode;
  
  const PriceTrackerCard({
    super.key,
    required this.appColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final entries = provider.entries;
    
    // DEBUG
    debugPrint('💰 PRICE TRACKER:');
    debugPrint('   Total entries: ${entries.length}');
    
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Sort entries by date and get last 30
    final sortedEntries = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentEntries = sortedEntries.length > 30 
        ? sortedEntries.sublist(sortedEntries.length - 30)
        : sortedEntries;
    
    // DEBUG: Log first 5 entries
    debugPrint('   Recent entries (showing first 5):');
    for (int i = 0; i < (recentEntries.length > 5 ? 5 : recentEntries.length); i++) {
      final e = recentEntries[i];
      debugPrint('     [$i] ${DateFormat('dd-MM').format(e.date)}: €${e.pricePerLiter.toStringAsFixed(3)}/L (total: €${e.priceTotal}, liters: ${e.liters})');
    }
    
    // All entries should now have calculated pricePerLiter from fromMap()
    final validEntries = recentEntries;
    
    debugPrint('   Using all ${validEntries.length} entries');
    
    if (validEntries.isEmpty) {
      return _buildEmptyState(context, customMessage: 'Geen prijsgegevens beschikbaar.\nVoeg prijs per liter toe aan je tankbeurten.');
    }
    
    // Build price data from valid entries only
    final priceData = validEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.pricePerLiter);
    }).toList();
    
    // Calculate stats
    final prices = validEntries.map((e) => e.pricePerLiter).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    
    debugPrint('   Price stats:');
    debugPrint('     Min: €${minPrice.toStringAsFixed(3)}');
    debugPrint('     Max: €${maxPrice.toStringAsFixed(3)}');
    debugPrint('     Avg: €${avgPrice.toStringAsFixed(3)}');
    
    // Calculate savings
    final avgTankSize = validEntries.map((e) => e.liters).reduce((a, b) => a + b) / validEntries.length;
    final savings = (maxPrice - avgPrice) * avgTankSize;
    
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
                "PRIJS TRACKER",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              
              // Chart
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => appColor,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            if (spot.barIndex != 1) return null;
                            
                            return LineTooltipItem(
                              '€${spot.y.toStringAsFixed(2)}',
                              TextStyle(
                                color: isDarkMode ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '€${value.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: validEntries.length > 10 ? (validEntries.length / 5).floorToDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= validEntries.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(validEntries[index].date),
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                        left: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                      ),
                    ),
                    minY: (minPrice - 0.1) < 0 ? 0 : minPrice - 0.1,
                    maxY: maxPrice + 0.1,
                    lineBarsData: [
                      // Average line
                      LineChartBarData(
                        spots: priceData.map((p) => FlSpot(p.x, avgPrice)).toList(),
                        isCurved: false,
                        color: Colors.orange.withValues(alpha: 0.5),
                        barWidth: 1,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                      // Price line
                      LineChartBarData(
                        spots: priceData,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: appColor,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isExtreme = (spot.y - maxPrice).abs() < 0.001 || (spot.y - minPrice).abs() < 0.001;
                            return FlDotCirclePainter(
                              radius: isExtreme ? 5 : 3,
                              color: isExtreme ? Colors.red : appColor,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              appColor.withValues(alpha: 0.3),
                              appColor.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: Duration.zero,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '📈 Hoogste',
                      '€${maxPrice.toStringAsFixed(2)}',
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '📉 Laagste',
                      '€${minPrice.toStringAsFixed(2)}',
                      Colors.green,
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
                      '€${avgPrice.toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '💾 Bespaard',
                      '€${savings.toStringAsFixed(2)}',
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
  
  Widget _buildEmptyState(BuildContext context, {String? customMessage}) {
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
                  Icons.local_gas_station_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  customMessage ?? 'Nog geen tankbeurten',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (customMessage == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Voeg tankbeurten toe om prijstrends te zien',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}