// TIMELINE HEATMAP CARD
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'empty_state.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class TimelineHeatmapCard extends StatefulWidget {
  final CardSize size;
  const TimelineHeatmapCard({super.key, this.size = CardSize.xl});
  @override
  State<TimelineHeatmapCard> createState() => _TimelineHeatmapCardState();
}

class _TimelineHeatmapCardState extends State<TimelineHeatmapCard> {
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;

    if (entries.isEmpty) return _buildEmptyState(context, isDarkMode);

    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final daysSinceLast = now.difference(sorted.last.date).inDays;
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
    }
    final avgInterval = intervals.isNotEmpty ? (intervals.reduce((a, b) => a + b) / intervals.length).round() : 0;
    final minInterval = intervals.isNotEmpty ? intervals.reduce((a, b) => a < b ? a : b) : 0;
    final maxInterval = intervals.isNotEmpty ? intervals.reduce((a, b) => a > b ? a : b) : 0;

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
              "TANK KALENDER",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            _buildCalendarHeatmap(context, sorted, appColor, isDarkMode),
            const SizedBox(height: 24),
            _buildStats(context, daysSinceLast, avgInterval, minInterval, maxInterval, appColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeatmap(BuildContext context, List entries, Color appColor, bool isDarkMode) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final endOfThisWeek = now.add(Duration(days: 7 - todayWeekday));
    final startDate = endOfThisWeek.subtract(const Duration(days: 12 * 7 - 1));

    final entryDates = <String, int>{};
    for (var entry in entries) {
      if (entry.date.isAfter(startDate.subtract(const Duration(days: 1)))) {
        final dateKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
        entryDates[dateKey] = (entryDates[dateKey] ?? 0) + 1;
      }
    }

    const dayLabels = ['M', 'D', 'W', 'D', 'V', 'Z', 'Z'];
    final weekLabels = List.generate(12, (col) {
      final weekStart = startDate.add(Duration(days: col * 7));
      return 'W${_isoWeekNumber(weekStart)}';
    });

    const int numWeeks = 12;
    const double cellGap = 4;
    const double labelWidth = 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - labelWidth - cellGap - (cellGap * (numWeeks - 1));
        final cellSize = (availableWidth / numWeeks).floorToDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // X-axis: week numbers
            Row(
              children: [
                SizedBox(width: labelWidth + cellGap),
                ...List.generate(numWeeks, (col) => SizedBox(
                  width: cellSize + cellGap,
                  child: Text(
                    weekLabels[col],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 4),
            // Grid: 7 rows x numWeeks cols
            ...List.generate(7, (row) => Padding(
              padding: const EdgeInsets.only(bottom: cellGap),
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    height: cellSize,
                    child: Center(
                      child: Text(
                        dayLabels[row],
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: cellGap),
                  ...List.generate(numWeeks, (col) {
                    final date = startDate.add(Duration(days: col * 7 + row));
                    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final count = entryDates[dateKey] ?? 0;
                    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                    final emptyColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

                    return Padding(
                      padding: const EdgeInsets.only(right: cellGap),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: count > 0 ? appColor : emptyColor,
                          borderRadius: BorderRadius.circular(4),
                          border: isToday ? Border.all(color: appColor, width: 2) : null,
                        ),
                        child: count > 1
                            ? Center(
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    if (woy > 52) {
      final firstDay = DateTime(date.year, 1, 1).weekday;
      if (firstDay == 4 || (firstDay == 3 && _isLeapYear(date.year))) return 53;
      return 1;
    }
    return woy;
  }

  bool _isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  Widget _buildStats(BuildContext context, int daysSince, int avg, int min, int max, Color appColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatItem(context, 'Sinds laatst', '$daysSince dagen', appColor),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Gemiddeld', '$avg dagen', const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Kortste', '$min dagen', const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Langste', '$max dagen', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
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
    final now = DateTime.now();
    final daysSince = now.difference(sorted.last.date).inDays;

    int avgInterval = 0;
    int minInterval = 0;
    int maxInterval = 0;

    if (sorted.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < sorted.length; i++) {
        intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
      }
      avgInterval = (intervals.reduce((a, b) => a + b) / intervals.length).round();
      minInterval = intervals.reduce((a, b) => a < b ? a : b);
      maxInterval = intervals.reduce((a, b) => a > b ? a : b);
    }

    final scaleMax = (daysSince > maxInterval ? daysSince : maxInterval) + 3;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TANK KALENDER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: appColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CustomPaint(
                painter: _GaugePainter(
                  daysSince: daysSince,
                  minInterval: minInterval,
                  avgInterval: avgInterval,
                  maxInterval: maxInterval,
                  scaleMax: scaleMax,
                  appColor: appColor,
                  isDarkMode: isDarkMode,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(context, 'Kortste', '$minInterval d', const Color(0xFFEF4444)),
                _buildMiniStat(context, 'Gemiddeld', '$avgInterval d', const Color(0xFF3B82F6)),
                _buildMiniStat(context, 'Langste', '$maxInterval d', const Color(0xFF10B981)),
              ],
            ),
          ],
        ),
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

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) =>
      EmptyCardXL(icon: Icons.calendar_today_outlined, title: 'Geen tankbeurten', isDarkMode: isDarkMode);

  Widget _buildEmpty(BuildContext context, bool isDarkMode) =>
      EmptyCardM(icon: Icons.calendar_today_outlined, title: 'Geen tankbeurten', isDarkMode: isDarkMode);

}

// ── GaugePainter is een top-level class, BUITEN de widget class ──
class _GaugePainter extends CustomPainter {
  final int daysSince;
  final int minInterval;
  final int avgInterval;
  final int maxInterval;
  final int scaleMax;
  final Color appColor;
  final bool isDarkMode;

  const _GaugePainter({
    required this.daysSince,
    required this.minInterval,
    required this.avgInterval,
    required this.maxInterval,
    required this.scaleMax,
    required this.appColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.80;
    final radius = size.width * 0.40;
    final strokeWidth = size.width * 0.13;

    const startAngle = math.pi;       // 180° = links
    const sweepAngle = math.pi;       // 180° sweep = halve cirkel

    final redEnd  = scaleMax > 0 ? (minInterval / scaleMax).clamp(0.0, 1.0) : 0.0;
    final blueEnd = scaleMax > 0 ? (avgInterval / scaleMax).clamp(0.0, 1.0) : 0.5;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Rood zone: 0 → kortste
    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(rect, startAngle, sweepAngle * redEnd, false, paint);

    // Blauw zone: kortste → gemiddelde
    paint.color = const Color(0xFF3B82F6);
    canvas.drawArc(rect, startAngle + sweepAngle * redEnd, sweepAngle * (blueEnd - redEnd), false, paint);

    // Groen zone: gemiddelde → einde
    paint.color = const Color(0xFF10B981);
    canvas.drawArc(rect, startAngle + sweepAngle * blueEnd, sweepAngle * (1.0 - blueEnd), false, paint);

    // Verwacht-streepje op langste interval (wit)
    final maxFraction = scaleMax > 0 ? (maxInterval / scaleMax).clamp(0.0, 1.0) : 1.0;
    final maxAngle = startAngle + sweepAngle * maxFraction;
    final markerInner = radius - strokeWidth * 0.6;
    final markerOuter = radius + strokeWidth * 0.6;
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + markerInner * math.cos(maxAngle), cy + markerInner * math.sin(maxAngle)),
      Offset(cx + markerOuter * math.cos(maxAngle), cy + markerOuter * math.sin(maxAngle)),
      markerPaint,
    );

    // Naald
    final needleFraction = (daysSince / scaleMax).clamp(0.0, 1.0);
    final needleAngle = startAngle + sweepAngle * needleFraction;
    final needlePaint = Paint()
      ..color = isDarkMode ? Colors.white : Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + radius * math.cos(needleAngle), cy + radius * math.sin(needleAngle)),
      needlePaint,
    );

    // Middelpunt dot
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = isDarkMode ? Colors.white : Colors.black87,
    );

    // Dag getal boven de as
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$daysSince',
        style: TextStyle(
          fontSize: size.width * 0.11,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height - 10));

    // Schaal labels: 0 links, max rechts
    _drawLabel(canvas, '0', cx - radius - strokeWidth * 0.5, cy + 10, size, leftAlign: true);
    _drawLabel(canvas, '$scaleMax', cx + radius + strokeWidth * 0.5, cy + 10, size, leftAlign: false);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Size size, {required bool leftAlign}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size.width * 0.07,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(leftAlign ? x : x - tp.width, y));
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.daysSince != daysSince ||
      old.scaleMax != scaleMax ||
      old.avgInterval != avgInterval;
}