// LAATST BIJGEWERKT: 2026-02-16 23:45 UTC
// WIJZIGING: Gradient above line, working period selector, balanced padding, accent line on gradient
// REDEN: User refinements for better visual hierarchy and functionality

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/time_period.dart';

class DistanceConsumptionCard extends StatefulWidget {
  const DistanceConsumptionCard({super.key});

  @override
  State<DistanceConsumptionCard> createState() => _DistanceConsumptionCardState();
}

class _DistanceConsumptionCardState extends State<DistanceConsumptionCard> {
  TimePeriod _selectedPeriod = TimePeriod.oneMonth;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Filter entries based on selected period
    final allEntries = provider.entries.toList();
    final now = DateTime.now();
    final filteredEntries = allEntries.where((entry) {
      switch (_selectedPeriod) {
        case TimePeriod.oneMonth:
          return entry.date.isAfter(now.subtract(const Duration(days: 30)));
        case TimePeriod.sixMonths:
          return entry.date.isAfter(now.subtract(const Duration(days: 180)));
        case TimePeriod.oneYear:
          return entry.date.isAfter(now.subtract(const Duration(days: 365)));
        case TimePeriod.allTime:
          return true;
      }
    }).toList();
    
    // Take max 8 entries, reversed for chronological order
    final entries = filteredEntries.take(8).toList().reversed.toList();
    
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 24, 10, 24), // Card padding - adjust right value
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and period selector
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 20), // Compensate card padding - matches (24 - 10)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AFSTAND & VERBRUIK",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                    letterSpacing: 1.0,
                  ),
                ),
                _buildCompactSelector(context, appColor),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Chart - adjustable padding for fine-tuning position
          Padding(
            padding: const EdgeInsets.only(
              left: 0,   // Negative = extend left (use Transform if needed)
              right: 5,  // Negative = extend right (use Transform if needed)
            ),
            child: SizedBox(
              height: 160,
              child: _buildChart(context, entries, appColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelector(BuildContext context, Color appColor) {
    final Map<TimePeriod, String> labels = {
      TimePeriod.oneMonth: '1M',
      TimePeriod.sixMonths: '6M',
      TimePeriod.oneYear: '1J',
      TimePeriod.allTime: 'All',
    };
    
    return Row(
      children: TimePeriod.values.map((p) {
        final isSelected = _selectedPeriod == p;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPeriod = p;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? appColor : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                    ),
            ),
            child: Text(
              labels[p]!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(BuildContext context, List entries, Color appColor) {
    if (entries.length < 2) {
      return const Center(
        child: Text('Minimaal 2 tankbeurten nodig voor grafiek'),
      );
    }
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate chart data - distance = odometer difference between entries
    final chartData = <FlSpot>[];
    final consumptionData = <FlSpot>[];
    
    for (int i = 0; i < entries.length - 1; i++) {
      final currentEntry = entries[i];
      final nextEntry = entries[i + 1];
      
      // Distance = difference in odometer
      final km = (nextEntry.odometer - currentEntry.odometer).abs();
      
      // Consumption = km per liter
      final consumption = currentEntry.liters > 0 ? (km / currentEntry.liters) : 0;
      
      chartData.add(FlSpot(i.toDouble(), km));
      consumptionData.add(FlSpot(i.toDouble(), consumption));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 0), // Match visual balance
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            // Left Y-axis: KM values (green)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) {
                    // Show "km" label at bottom
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'km',
                        style: TextStyle(
                          color: appColor.withValues(alpha: 0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    );
                  }
                  if (value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  
                  // Calculate KM value
                  final kmValue = ((value - 16) / 4 * 100 + 450).round();
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '$kmValue',
                      style: TextStyle(
                        color: appColor.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Right Y-axis: km/l values (white) - NO AXIS LINE
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) {
                    // Show "km/l" label at bottom
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'km/l',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  if (value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              // Only bottom border (no right Y-axis line)
              bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            ),
          ),
          minY: 16,
          maxY: 20,
          lineBarsData: [
            // Consumption line (BELOW - theme-aware, thinner)
            LineChartBarData(
              spots: consumptionData,
              isCurved: true,
              color: isDarkMode ? Colors.white : Colors.black87,
              barWidth: 2, // Thinner (was 3)
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
            
            // Gradient area for distance (ABOVE - with accent line on top)
            LineChartBarData(
              spots: chartData.map((spot) {
                // Map km (450-550) to upper half (18-20)
                final normalizedY = 18 + ((spot.y - 450) / 100 * 2);
                return FlSpot(spot.x, normalizedY.clamp(18.0, 20.0));
              }).toList(),
              isCurved: true,
              color: appColor, // Thin accent line on top
              barWidth: 1.5, // Thin accent line
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    appColor.withValues(alpha: 0.4),
                    appColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            // Only show tooltip for consumption line (index 0 now)
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  if (spot.barIndex != 0) return null; // Skip gradient layer
                  
                  final index = spot.x.toInt();
                  if (index >= entries.length - 1) return null;
                  
                  final currentEntry = entries[index];
                  final nextEntry = entries[index + 1];
                  final km = (nextEntry.odometer - currentEntry.odometer).abs();
                  final consumption = currentEntry.liters > 0 
                      ? (km / currentEntry.liters).toStringAsFixed(1) 
                      : '0';
                      
                  return LineTooltipItem(
                    'Afstand: ${km.toInt()} km\nVerbruik: $consumption km/l',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: Duration.zero, // Disable animations
      ),
    );
  }
}