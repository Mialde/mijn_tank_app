// PRICE TRACKER CARD
// M-size: Square with Huidig/Laagste selector

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class PriceTrackerCard extends StatefulWidget {
  final CardSize size;
  
  const PriceTrackerCard({
    super.key,
    this.size = CardSize.xl,
  });

  @override
  State<PriceTrackerCard> createState() => _PriceTrackerCardState();
}

class _PriceTrackerCardState extends State<PriceTrackerCard> {
  bool _showCurrent = true; // true = Huidig, false = Laagste

  @override
  Widget build(BuildContext context) {
    return widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);
  }

  // XL: Full version (keep existing)
  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final validEntries = entries.where((e) => e.pricePerLiter > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (validEntries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final avgPrice = validEntries.map((e) => e.pricePerLiter).reduce((a, b) => a + b) / validEntries.length;
    final maxPrice = validEntries.map((e) => e.pricePerLiter).reduce((a, b) => a > b ? a : b);
    final minPrice = validEntries.map((e) => e.pricePerLiter).reduce((a, b) => a < b ? a : b);
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
            SizedBox(
              height: 200,
              child: _buildChart(context, validEntries, appColor, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildStats(context, avgPrice, minPrice, maxPrice, savings, appColor),
          ],
        ),
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
    
    final validEntries = entries.where((e) => e.pricePerLiter > 0).toList();
    
    if (validEntries.isEmpty) {
      return _buildEmptySquare(context, isDarkMode);
    }
    
    final avgPrice = validEntries.map((e) => e.pricePerLiter).reduce((a, b) => a + b) / validEntries.length;
    final minPrice = validEntries.map((e) => e.pricePerLiter).reduce((a, b) => a < b ? a : b);
    
    final displayValue = _showCurrent ? avgPrice : minPrice;
    final displayLabel = _showCurrent ? 'gemiddelde prijs' : 'laagste prijs';

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
            Icon(Icons.local_gas_station, color: appColor, size: 40),
            const SizedBox(height: 12),
            Text(
              '€${displayValue.toStringAsFixed(2)}',
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
              textAlign: TextAlign.center,
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
            label: 'Huidig',
            isSelected: _showCurrent,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showCurrent = true),
          ),
          _buildSelectorButton(
            context,
            icon: Icons.trending_down,
            label: 'Laagste',
            isSelected: !_showCurrent,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showCurrent = false),
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

  Widget _buildChart(BuildContext context, List entries, Color appColor, bool isDarkMode) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.pricePerLiter);
    }).toList();

    return LineChart(
      LineChartData(
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
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            left: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: appColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: appColor,
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
    );
  }

  Widget _buildStats(BuildContext context, double avg, double min, double max, double savings, Color appColor) {
    return Row(
      children: [
        _buildStatItem(context, 'Gemiddeld', '€${avg.toStringAsFixed(2)}', appColor),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Min', '€${min.toStringAsFixed(2)}', Colors.green),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Max', '€${max.toStringAsFixed(2)}', Colors.red),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Bespaard', '€${savings.toStringAsFixed(0)}', Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station_outlined,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Nog geen prijsgegevens',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
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
            Icons.local_gas_station_outlined,
            size: 48,
            color: Theme.of(context).hintColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}