// DISTANCE & CONSUMPTION CARD
// XL: Bar chart per tankbeurt interval (fl_chart)
// M:  Totaal km / laatste rit selector

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class DistanceConsumptionCard extends StatefulWidget {
  final CardSize size;
  const DistanceConsumptionCard({super.key, this.size = CardSize.xl});

  @override
  State<DistanceConsumptionCard> createState() => _DistanceConsumptionCardState();
}

class _DistanceConsumptionCardState extends State<DistanceConsumptionCard> {
  bool _showTotal = true;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) =>
      widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  // ── XL ────────────────────────────────────────────────────────────
  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.length < 2) return _buildEmptyState(context, isDarkMode);

    // Bereken km per interval
    final intervals = <_Interval>[];
    for (int i = 1; i < entries.length; i++) {
      final prev = entries[i - 1];
      final curr = entries[i];
      final km = (curr.odometer - prev.odometer).abs().toDouble();
      final days = curr.date.difference(prev.date).inDays;
      if (km <= 0) continue;
      intervals.add(_Interval(km: km, days: days, date: curr.date));
    }

    if (intervals.isEmpty) return _buildEmptyState(context, isDarkMode);

    final display = intervals.length > 10
        ? intervals.sublist(intervals.length - 10)
        : intervals;

    final avgKm = display.map((e) => e.km).reduce((a, b) => a + b) / display.length;
    final maxKm = display.map((e) => e.km).reduce(math.max);
    final minKm = display.map((e) => e.km).reduce(math.min);

    // Kleur per staaf: top3 groen, laagste3 rood, rest blauw
    final sorted = display.map((e) => e.km).toList()..sort();
    final n = math.min(3, (display.length / 2).floor());

    Color colorFor(double km) {
      if (display.length <= 3) {
        if (km == sorted.first) return const Color(0xFFEF4444);
        if (km == sorted.last) return const Color(0xFF10B981);
        return const Color(0xFF3B82F6);
      }
      if (km >= sorted[sorted.length - n]) return const Color(0xFF10B981);
      if (km <= sorted[n - 1]) return const Color(0xFFEF4444);
      return const Color(0xFF3B82F6);
    }

    final bars = display.asMap().entries.map((e) {
      final isTouched = _touchedIndex == e.key;
      final color = colorFor(e.value.km);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.km,
            color: color,
            width: isTouched ? 14 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxKm * 1.2,
              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.04),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
          blurRadius: 20, offset: const Offset(0, 5),
        )],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AFSTAND PER BEURT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxKm * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final interval = display[group.x];
                      final fmt = DateFormat('d MMM', 'nl_NL');
                      final date = fmt.format(interval.date);
                      final km = interval.km.toStringAsFixed(0);
                      final days = interval.days;
                      return BarTooltipItem(
                        '$date\n$km km\n$days dagen',
                        const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null || response.spot == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == meta.max) return const SizedBox.shrink();
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= display.length) return const SizedBox.shrink();
                        // Toon alleen eerste, middelste en laatste datum
                        final show = i == 0 || i == display.length - 1 || i == display.length ~/ 2;
                        if (!show) return const SizedBox.shrink();
                        return Text(
                          DateFormat('d/M', 'nl_NL').format(display[i].date),
                          style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxKm / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                    left: BorderSide(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                  ),
                ),
                barGroups: bars,
              ),
              duration: Duration.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(context, 'Gemiddeld', '${avgKm.toStringAsFixed(0)} km', appColor),
              _buildMiniStat(context, 'Langste', '${maxKm.toStringAsFixed(0)} km', const Color(0xFF10B981)),
              _buildMiniStat(context, 'Kortste', '${minKm.toStringAsFixed(0)} km', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor)),
      ],
    );
  }

  // ── M card ────────────────────────────────────────────────────────
  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries.toList()..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) return _buildEmptySquare(context, isDarkMode);

    final totalDistance = entries.last.odometer - entries.first.odometer;
    double lastTripKm = 0;
    if (entries.length >= 2) {
      lastTripKm = (entries.last.odometer - entries[entries.length - 2].odometer).abs();
    }

    final displayValue = _showTotal ? totalDistance : lastTripKm;
    final displayLabel = _showTotal ? 'km totaal' : 'km laatste rit';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20, offset: const Offset(0, 5),
          )],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AFSTAND PER BEURT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: appColor, letterSpacing: 0.5)),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat('#,###', 'nl_NL').format(displayValue.round()),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                          color: appColor, height: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(displayLabel,
                        style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ),
            _buildModeSelector(context, isDarkMode, appColor),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, bool isDarkMode, Color appColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildSelectorBtn(context, 'Totaal', _showTotal, appColor,
              () => setState(() => _showTotal = true)),
          _buildSelectorBtn(context, 'Laatste', !_showTotal, appColor,
              () => setState(() => _showTotal = false)),
        ],
      ),
    );
  }

  Widget _buildSelectorBtn(BuildContext context, String label, bool sel,
      Color appColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? appColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: sel ? Colors.white : Theme.of(context).hintColor),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
          blurRadius: 20, offset: const Offset(0, 5),
        )],
      ),
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Minimaal 2 tankbeurten nodig',
                style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
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
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20, offset: const Offset(0, 5),
          )],
        ),
        child: Center(
          child: Icon(Icons.route_outlined, size: 48,
              color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _Interval {
  final double km;
  final int days;
  final DateTime date;
  const _Interval({required this.km, required this.days, required this.date});
}