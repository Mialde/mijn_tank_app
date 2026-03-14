// DISTANCE & CONSUMPTION CARD
// XL: Bar chart per tankbeurt interval (fl_chart)
// M:  Totaal km / laatste rit selector

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'empty_state.dart';
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

    // Bereken intervallen
    final intervals = <_Interval>[];
    for (int i = 1; i < entries.length; i++) {
      final km = (entries[i].odometer - entries[i-1].odometer).abs().toDouble();
      final days = entries[i].date.difference(entries[i-1].date).inDays;
      if (km > 0) intervals.add(_Interval(km: km, days: days, date: entries[i].date));
    }

    if (intervals.isEmpty) return _buildEmptySquare(context, isDarkMode);

    final sparkPrices = intervals.map((e) => e.km).toList();
    final lastKm = intervals.last.km;
    final avgKm = sparkPrices.reduce((a, b) => a + b) / sparkPrices.length;
    final minKm = sparkPrices.reduce(math.min);
    final maxKm = sparkPrices.reduce(math.max);
    final diff = lastKm - avgKm;
    final isAbove = diff >= 0;
    final valueColor = isAbove ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (i) => setState(() => _showTotal = i == 0),
                children: [
                  _buildLastPage(context, lastKm, valueColor,
                      sparkPrices, avgKm, isDarkMode, appColor),
                  _buildTotaalPage(context, sparkPrices, avgKm,
                      isDarkMode, appColor, entries),
                ],
              ),
            ),
            _buildPageIndicator(appColor),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLastPage(BuildContext context, double lastKm, Color color,
      List<double> spark, double avgKm, bool isDarkMode, Color appColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel + label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AFSTAND',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: appColor, letterSpacing: 0.5)),
              Text('Laatste',
                  style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
            ],
          ),
          // Sparkline verticaal gecentreerd
          Expanded(
            child: Center(
              child: SizedBox(
                height: 44,
                child: CustomPaint(
                  painter: _KmSparklinePainter(
                    values: spark,
                    avgValue: avgKm,
                    color: color,
                    isDarkMode: isDarkMode,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Km rechts uitgelijnd, geen label eronder
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${lastKm.toStringAsFixed(0)} km',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                  color: color, height: 1.0),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTotaalPage(BuildContext context, List<double> spark, double avgKm,
      bool isDarkMode, Color appColor, List entries) {
    final totalKm = (entries.last.odometer - entries.first.odometer) as double;
    final minKm = spark.reduce(math.min);
    final maxKm = spark.reduce(math.max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AFSTAND',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: appColor, letterSpacing: 0.5)),
              Text('Totaal',
                  style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(context, 'Totaal', '${NumberFormat('#,###', 'nl_NL').format(totalKm.round())} km', appColor),
          const SizedBox(height: 10),
          _buildStatRow(context, 'Langste', '${maxKm.toStringAsFixed(0)} km', const Color(0xFF10B981)),
          const SizedBox(height: 10),
          _buildStatRow(context, 'Kortste', '${minKm.toStringAsFixed(0)} km', const Color(0xFFEF4444)),
          const SizedBox(height: 10),
          _buildStatRow(context, 'Gemiddeld', '${avgKm.toStringAsFixed(0)} km', const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        Text(value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPageIndicator(Color appColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(
                color: _showTotal ? appColor : appColor.withValues(alpha: 0.3),
                shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Container(width: 6, height: 6,
            decoration: BoxDecoration(
                color: !_showTotal ? appColor : appColor.withValues(alpha: 0.3),
                shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) =>
      EmptyCardXL(icon: Icons.route_outlined, title: 'Minimaal 2 tankbeurten nodig', isDarkMode: isDarkMode);

  Widget _buildEmptySquare(BuildContext context, bool isDarkMode) =>
      EmptyCardM(icon: Icons.route_outlined, title: 'Minimaal 2 tankbeurten nodig', isDarkMode: isDarkMode);
}

class _Interval {
  final double km;
  final int days;
  final DateTime date;
  const _Interval({required this.km, required this.days, required this.date});
}

// ── Km Sparkline painter ──────────────────────────────────────────
class _KmSparklinePainter extends CustomPainter {
  final List<double> values;
  final double avgValue;
  final Color color;
  final bool isDarkMode;

  const _KmSparklinePainter({
    required this.values,
    required this.avgValue,
    required this.color,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = math.max(maxV - minV, 1.0);
    final margin = range * 0.3;
    final yMin = minV - margin;
    final yMax = maxV + margin;

    double toX(int i) => i / (values.length - 1) * size.width;
    double toY(double v) => size.height - ((v - yMin) / (yMax - yMin)) * size.height;

    // Gemiddelde lijn gestippeld
    final avgY = toY(avgValue);
    final dashPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.15)
      ..strokeWidth = 1;
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, avgY), Offset(math.min(dx + 4, size.width), avgY), dashPaint);
      dx += 8;
    }

    // Lijn
    final linePath = Path()..moveTo(toX(0), toY(values[0]));
    for (int i = 1; i < values.length; i++) linePath.lineTo(toX(i), toY(values[i]));
    canvas.drawPath(linePath, Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Laatste punt
    final lx = toX(values.length - 1);
    final ly = toY(values.last);
    canvas.drawCircle(Offset(lx, ly), 4,
        Paint()..color = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);
    canvas.drawCircle(Offset(lx, ly), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_KmSparklinePainter old) =>
      old.values != values || old.color != color;
}