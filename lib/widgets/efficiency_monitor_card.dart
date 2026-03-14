// EFFICIENCY MONITOR CARD - M: [Laatste] [Gemiddeld]
import 'package:flutter/material.dart';
import 'empty_state.dart';
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
    final provider = context.read<DataProvider>();
    final goalLine = provider.goalEfficiency;
    return LineChart(
      LineChartData(
        extraLinesData: goalLine != null ? ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: goalLine,
            color: appColor.withValues(alpha: 0.6),
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              style: TextStyle(fontSize: 9, color: appColor, fontWeight: FontWeight.w600),
              labelResolver: (_) => 'doel ${goalLine.toStringAsFixed(1)}',
            ),
          ),
        ]) : null,
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
    final provider = context.read<DataProvider>();
    final goalEff = provider.goalEfficiency;
    return Row(
      children: [
        _buildStatItem(context, 'Gemiddeld', '${avg.toStringAsFixed(1)} km/L', appColor),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Best', '${best.toStringAsFixed(1)} km/L', Colors.green),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Slechtst', '${worst.toStringAsFixed(1)} km/L', Colors.red),
        const SizedBox(width: 12),
        if (goalEff != null) ...[
          _buildStatItem(
            context, 'Doel',
            '${goalEff.toStringAsFixed(1)} km/L',
            latest >= goalEff ? Colors.green : Colors.orange,
            icon: latest >= goalEff ? Icons.check_circle_outline : Icons.flag_outlined,
          ),
        ] else
          _buildStatItem(context, 'Laatste', '${latest.toStringAsFixed(1)} km/L', Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color, {IconData? icon}) {
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
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
              ],
              Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
            ]),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) =>
      EmptyCardXL(icon: Icons.speed_outlined, title: 'Geen verbruiksdata', isDarkMode: isDarkMode);

  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    if (entries.isEmpty) return _buildEmpty(context, isDarkMode);

    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));

    // Zelfde berekening als XL card
    final effData = <double>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final km = (sorted[i + 1].odometer - sorted[i].odometer).abs();
      final eff = sorted[i].liters > 0 ? km / sorted[i].liters : 0.0;
      if (eff > 0) effData.add(eff);
    }
    if (effData.isEmpty) return _buildEmpty(context, isDarkMode);

    final latest = effData.last;
    final avg    = effData.reduce((a, b) => a + b) / effData.length;
    final best   = effData.reduce((a, b) => a > b ? a : b);
    final worst  = effData.reduce((a, b) => a < b ? a : b);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (i) => setState(() => _showLatest = i == 0),
                children: [
                  _buildMPage(context, appColor, latest, avg, best, worst, 'Laatste', true),
                  _buildMPage(context, appColor, avg, avg, best, worst, 'Gemiddeld', false),
                ],
              ),
            ),
            _buildPageDots(appColor),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMPage(BuildContext context, Color appColor, double value, double avg,
      double best, double worst, String label, bool showTrend) {
    final provider = context.read<DataProvider>();
    final goalEff = provider.goalEfficiency;
    final pct = avg > 0 ? ((value - avg) / avg * 100) : 0.0;
    final isUp = pct >= 0;
    final trendColor = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final range = best - worst;
    final pos = range > 0 ? ((value - worst) / range).clamp(0.0, 1.0) : 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VERBRUIK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appColor, letterSpacing: 0.5)),
              Text(label, style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
            ],
          ),
          const SizedBox(height: 8),
          // Grote waarde + pijl
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: appColor, height: 1.0),
                    ),
                    Text('km/L', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  ],
                ),
                if (showTrend) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: trendColor, size: 28),
                      const SizedBox(height: 2),
                      Text(
                        '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: trendColor),
                      ),
                      const SizedBox(height: 1),
                      Text('vs gem.', style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Positiebalk
          LayoutBuilder(builder: (context, constraints) {
            final dotX = pos * constraints.maxWidth;
            final goalPos = (goalEff != null && (best - worst) > 0)
                ? ((goalEff - worst) / (best - worst)).clamp(0.0, 1.0) * constraints.maxWidth
                : null;
            return Column(
              children: [
                SizedBox(
                  height: 18,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0, right: 0, top: 6.5,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF10B981)]),
                          ),
                        ),
                      ),
                      // Doelmarkering (driehoekje)
                      if (goalPos != null)
                        Positioned(
                          left: goalPos - 4,
                          top: 0,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: appColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      Positioned(
                        left: dotX - 7,
                        top: 2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appColor,
                            border: Border.all(color: Theme.of(context).cardTheme.color ?? Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(worst.toStringAsFixed(1), style: const TextStyle(fontSize: 8, color: Color(0xFFEF4444))),
                    Text('gem. ${avg.toStringAsFixed(1)}', style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
                    Text(best.toStringAsFixed(1), style: const TextStyle(fontSize: 8, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPageDots(Color appColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _showLatest ? appColor : appColor.withValues(alpha: 0.3))),
        const SizedBox(width: 6),
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: !_showLatest ? appColor : appColor.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) =>
      EmptyCardM(icon: Icons.speed_outlined, title: 'Geen verbruiksdata', isDarkMode: isDarkMode);

}