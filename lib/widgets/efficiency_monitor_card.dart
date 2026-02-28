// EFFICIENCY MONITOR CARD - M: [Laatste] [Gemiddeld]
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class EfficiencyMonitorCard extends StatefulWidget {
  final CardSize size;
  const EfficiencyMonitorCard({super.key, this.size = CardSize.xl});
  @override
  State<EfficiencyMonitorCard> createState() => _EfficiencyMonitorCardState();
}

class _EfficiencyMonitorCardState extends State<EfficiencyMonitorCard> {
  bool _showLatest = true;
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate efficiency data
    final efficiencyData = <FlSpot>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];
      final km = (next.odometer - current.odometer).abs();
      final efficiency = current.liters > 0 ? (km / current.liters).toDouble() : 0.0;
      efficiencyData.add(FlSpot(i.toDouble(), efficiency));
    }
    
    if (efficiencyData.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final avgEfficiency = efficiencyData.map((e) => e.y).reduce((a, b) => a + b) / efficiencyData.length;
    final bestEfficiency = efficiencyData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final worstEfficiency = efficiencyData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final latestEfficiency = efficiencyData.last.y;
    
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
              "EFFICIENCY MONITOR",
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
              child: _buildChart(context, efficiencyData, appColor, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildStats(context, avgEfficiency, bestEfficiency, worstEfficiency, latestEfficiency, appColor),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<FlSpot> data, Color appColor, bool isDarkMode) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
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
                  '${value.toInt()} km/L',
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
            spots: data,
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

  Widget _buildStats(BuildContext context, double avg, double best, double worst, double latest, Color appColor) {
    return Row(
      children: [
        _buildStatItem(context, 'Gemiddeld', '${avg.toStringAsFixed(1)} km/L', appColor),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Best', '${best.toStringAsFixed(1)} km/L', Colors.green),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Slechtst', '${worst.toStringAsFixed(1)} km/L', Colors.red),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Laatste', '${latest.toStringAsFixed(1)} km/L', Colors.blue),
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
                Icons.speed_outlined,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Nog geen efficiency gegevens',
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

  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    if (entries.isEmpty) return _buildEmpty(context, isDarkMode);
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    double latest = 0, avg = 0;
    if (sorted.length >= 2) {
      final last = sorted.last;
      final prev = sorted[sorted.length - 2];
      final km = (last.odometer - prev.odometer).abs();
      latest = prev.liters > 0 ? (km / prev.liters) : 0;
    }
    final totalKm = sorted.last.odometer - sorted.first.odometer;
    final totalL = entries.fold<double>(0, (s, e) => s + e.liters);
    avg = totalL > 0 ? (totalKm / totalL) : 0;
    
    final val = _showLatest ? latest : avg;
    final lbl = _showLatest ? 'laatste rit' : 'gemiddeld';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: Offset(0, 5))],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, color: appColor, size: 40),
            SizedBox(height: 12),
            Text('${val.toStringAsFixed(1)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: appColor, height: 1.0)),
            SizedBox(height: 2),
            Text('km/L $lbl', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
            Spacer(),
            _buildSelector(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(context, Icons.refresh, 'Laatste', _showLatest, isDarkMode, () => setState(() => _showLatest = true)),
          _buildBtn(context, Icons.show_chart, 'Gem.', !_showLatest, isDarkMode, () => setState(() => _showLatest = false)),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, IconData icon, String label, bool sel, bool dark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? (dark ? Colors.white : Colors.black) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor),
              SizedBox(width: 3),
              Flexible(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.speed_outlined, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
      ),
    );
  }
}