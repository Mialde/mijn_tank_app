// DISTANCE & CONSUMPTION CARD
// M-size: Square with Totaal/Laatste selector

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/time_period.dart';
import '../models/card_config.dart';

class DistanceConsumptionCard extends StatefulWidget {
  final CardSize size;
  
  const DistanceConsumptionCard({
    super.key,
    this.size = CardSize.xl,
  });

  @override
  State<DistanceConsumptionCard> createState() => _DistanceConsumptionCardState();
}

class _DistanceConsumptionCardState extends State<DistanceConsumptionCard> {
  TimePeriod _selectedPeriod = TimePeriod.oneMonth;
  bool _showTotal = true; // true = Totaal, false = Laatste

  @override
  Widget build(BuildContext context) {
    return widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);
  }

  // XL: Full version
  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final filteredEntries = _getFilteredEntries(provider);
    final entries = filteredEntries.take(8).toList().reversed.toList();
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }

    return Container(
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
      padding: const EdgeInsets.fromLTRB(0, 24, 10, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 20),
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
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 160,
              child: _buildChart(context, entries, appColor),
            ),
          ),
        ],
      ),
    );
  }

  // M: Square with selector
  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptySquare(context, isDarkMode);
    }
    
    // Calculate metrics
    final sortedEntries = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final totalDistance = sortedEntries.last.odometer - sortedEntries.first.odometer;
    
    double lastTripKm = 0;
    if (sortedEntries.length >= 2) {
      lastTripKm = (sortedEntries.last.odometer - sortedEntries[sortedEntries.length - 2].odometer).abs();
    }
    
    final displayValue = _showTotal ? totalDistance : lastTripKm;
    final displayLabel = _showTotal ? 'km totaal' : 'km laatste rit';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, color: appColor, size: 40),
            const SizedBox(height: 12),
            Text(
              NumberFormat('#,###', 'nl_NL').format(displayValue.round()),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: appColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).hintColor,
              ),
            ),
            const Spacer(),
            _buildModeSelector(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectorButton(
            context,
            icon: Icons.trending_up,
            label: 'Totaal',
            isSelected: _showTotal,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showTotal = true),
          ),
          _buildSelectorButton(
            context,
            icon: Icons.refresh,
            label: 'Laatste',
            isSelected: !_showTotal,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showTotal = false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? (isDarkMode ? Colors.black : Colors.white)
                    : Theme.of(context).hintColor,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : Theme.of(context).hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List _getFilteredEntries(DataProvider provider) {
    final allEntries = provider.entries.toList();
    final now = DateTime.now();
    return allEntries.where((entry) {
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
          onTap: () => setState(() => _selectedPeriod = p),
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
                  : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
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
      return const Center(child: Text('Minimaal 2 tankbeurten nodig'));
    }
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chartData = <FlSpot>[];
    final consumptionData = <FlSpot>[];
    
    for (int i = 0; i < entries.length - 1; i++) {
      final currentEntry = entries[i];
      final nextEntry = entries[i + 1];
      final km = (nextEntry.odometer - currentEntry.odometer).abs();
      final consumption = currentEntry.liters > 0 ? (km / currentEntry.liters) : 0;
      
      chartData.add(FlSpot(i.toDouble(), km));
      consumptionData.add(FlSpot(i.toDouble(), consumption));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == meta.min) {
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
                if (value == meta.max) return const SizedBox.shrink();
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
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value == meta.min) {
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
                if (value == meta.max) return const SizedBox.shrink();
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
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
          ),
        ),
        minY: 16,
        maxY: 20,
        lineBarsData: [
          LineChartBarData(
            spots: consumptionData,
            isCurved: true,
            color: isDarkMode ? Colors.white : Colors.black87,
            barWidth: 2,
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
          LineChartBarData(
            spots: chartData.map((spot) {
              final normalizedY = 18 + ((spot.y - 450) / 100 * 2);
              return FlSpot(spot.x, normalizedY.clamp(18.0, 20.0));
            }).toList(),
            isCurved: true,
            color: appColor,
            barWidth: 1.5,
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
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null;
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
      duration: Duration.zero,
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Container(
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
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 48,
              color: Theme.of(context).hintColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Nog geen gegevens',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySquare(BuildContext context, bool isDarkMode) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
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
        child: Center(
          child: Icon(
            Icons.route_outlined,
            size: 48,
            color: Theme.of(context).hintColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}