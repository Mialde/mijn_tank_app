// PRICE TRACKER CARD
// XL: Lollipop chart met groen/rood t.o.v. gemiddelde
// M: Huidig/Laagste selector

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class PriceTrackerCard extends StatefulWidget {
  final CardSize size;
  const PriceTrackerCard({super.key, this.size = CardSize.xl});

  @override
  State<PriceTrackerCard> createState() => _PriceTrackerCardState();
}

class _PriceTrackerCardState extends State<PriceTrackerCard> {
  bool _showCurrent = true;

  @override
  Widget build(BuildContext context) =>
      widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  // ── XL ───────────────────────────────────────────────────────────
  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;

    if (entries.isEmpty) return _buildEmptyState(context, isDarkMode);

    final valid = entries.where((e) => e.pricePerLiter > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (valid.isEmpty) return _buildEmptyState(context, isDarkMode);

    final prices = valid.map((e) => e.pricePerLiter).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

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
            Text('PRIJS TRACKER',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor, letterSpacing: 1.0)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _LollipopChart(
                entries: valid,
                avgPrice: avgPrice,
                minPrice: minPrice,
                maxPrice: maxPrice,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(height: 24),
            _buildStats(context, avgPrice, minPrice, maxPrice, valid.last.pricePerLiter, appColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, double avg, double min, double max, double last, Color appColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatItem(context, 'Laagste', '€${min.toStringAsFixed(3)}', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Gemiddeld', '€${avg.toStringAsFixed(3)}', const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Hoogste', '€${max.toStringAsFixed(3)}', const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildStatItem(context, 'Laatste', '€${last.toStringAsFixed(3)}', const Color(0xFF9CA3AF)),
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
            Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ── M ────────────────────────────────────────────────────────────
  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;

    if (entries.isEmpty) return _buildEmptySquare(context, isDarkMode);

    final valid = entries.where((e) => e.pricePerLiter > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (valid.isEmpty) return _buildEmptySquare(context, isDarkMode);

    final prices = valid.map((e) => e.pricePerLiter).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);
    final lastPrice = valid.last.pricePerLiter;
    final diff = lastPrice - avgPrice;
    final isBelow = diff <= 0;
    final valueColor = isBelow ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
            // Titel
            Text('PRIJS TRACKER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: appColor, letterSpacing: 0.5)),
            // Midden: laatste prijs gecentreerd
            Expanded(
              child: Center(
                child: Text('€${lastPrice.toStringAsFixed(3)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                        color: valueColor, height: 1.0)),
              ),
            ),
            // Onderste 3 stats met pijltjes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(context, 'Laagste', '€${minPrice.toStringAsFixed(2)}', const Color(0xFF10B981), lastPrice, minPrice),
                _buildMiniStat(context, 'Gemiddeld', '€${avgPrice.toStringAsFixed(2)}', const Color(0xFF3B82F6), lastPrice, avgPrice),
                _buildMiniStat(context, 'Hoogste', '€${maxPrice.toStringAsFixed(2)}', const Color(0xFFEF4444), lastPrice, maxPrice),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, Color color, double lastPrice, double comparePrice) {
    final isLower = lastPrice < comparePrice;
    final isEqual = lastPrice == comparePrice;
    final arrowColor = isLower ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final arrowIcon = isLower ? Icons.arrow_downward : Icons.arrow_upward;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            if (!isEqual) ...[
              const SizedBox(width: 2),
              Icon(arrowIcon, size: 10, color: arrowColor),
            ],
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor)),
      ],
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
              Icon(Icons.local_gas_station_outlined, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('Nog geen prijsgegevens',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.local_gas_station_outlined, size: 48,
            color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
      ),
    );
  }
}

// ── Lollipop chart widget ─────────────────────────────────────────
class _LollipopChart extends StatefulWidget {
  final List entries;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final bool isDarkMode;

  const _LollipopChart({
    required this.entries,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.isDarkMode,
  });

  @override
  State<_LollipopChart> createState() => _LollipopChartState();
}

class _LollipopChartState extends State<_LollipopChart> {
  int? _selectedIndex;

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const double _dotRadius = 6.0;
  static const double yLabelWidth = 30.0;
  static const double xLabelHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // chartW defined below via totalW - yLabelWidth
      final chartH = constraints.maxHeight - xLabelHeight;

      final prices = widget.entries.map((e) => e.pricePerLiter as double).toList();
      final margin = math.max((widget.maxPrice - widget.minPrice) * 0.35, 0.05);
      final yMin = widget.minPrice - margin;
      final yMax = widget.maxPrice + margin;

      // Totale breedte = yLabels + chart, zelfde als fl_chart reservedSize aanpak
      final totalW = constraints.maxWidth;

      return Stack(children: [
        // Y labels — links in de totale breedte
        Positioned(
          left: 0, top: 0, width: yLabelWidth, height: chartH,
          child: _buildYLabels(context, yMin, yMax, chartH),
        ),
        // Chart — vult de rest rechts van de y-labels
        Positioned(
          left: yLabelWidth, top: 0, width: totalW - yLabelWidth, height: chartH,
          child: CustomPaint(
            painter: _LollipopPainter(
              entries: widget.entries,
              prices: prices,
              yMin: yMin,
              yMax: yMax,
              avgPrice: widget.avgPrice,
              minPrice: widget.minPrice,
              maxPrice: widget.maxPrice,
              isDarkMode: widget.isDarkMode,
              selectedIndex: null,
              dotRadius: _dotRadius,
            ),
          ),
        ),
        // X labels
        Positioned(
          left: yLabelWidth, top: chartH, width: totalW - yLabelWidth, height: xLabelHeight,
          child: _buildXLabels(context, totalW - yLabelWidth, prices.length),
        ),
      ]);
    });
  }

  void _onTouch(Offset pos, double chartW, List<double> prices) {
    if (prices.isEmpty) return;
    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < prices.length; i++) {
      final px = _toX(i, prices.length, chartW);
      final dist = (pos.dx - px).abs();
      if (dist < minDist) { minDist = dist; closest = i; }
    }
    setState(() => _selectedIndex = closest);
  }

  double _toX(int i, int total, double w) =>
      total > 1 ? i / (total - 1) * w : w / 2;

  Widget _buildTooltip(BuildContext context, double chartW, double chartH,
      List<double> prices, double yMin, double yMax) {
    final i = _selectedIndex!;
    final entry = widget.entries[i];
    final price = prices[i];
    final isDark = widget.isDarkMode;
    final color = price <= widget.avgPrice ? _green : _red;
    final fmt = DateFormat('dd MMM yyyy', 'nl_NL');

    final px = _toX(i, prices.length, chartW);
    final py = chartH - ((price - yMin) / (yMax - yMin)) * chartH;
    final showLeft = px > chartW * 0.55;
    const tooltipW = 130.0;
    const tooltipH = 64.0;
    final tx = showLeft ? px - tooltipW - 10 : px + 14;
    final ty = (py - tooltipH / 2).clamp(4.0, chartH - tooltipH - 4);

    return Positioned(
      left: yLabelWidth + tx,
      top: ty,
      width: tooltipW,
      height: tooltipH,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(fmt.format(entry.date as DateTime),
                style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('€${price.toStringAsFixed(3)}/L',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            Text('${(entry.liters as double).toStringAsFixed(1)}L  •  €${(entry.priceTotal as double).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildYLabels(BuildContext context, double yMin, double yMax, double height) {
    const steps = 4;
    return Stack(
      children: List.generate(steps + 1, (i) {
        final fraction = i / steps;
        final price = yMax - fraction * (yMax - yMin);
        final y = fraction * height - 8;
        return Positioned(
          top: y, left: 0, right: 6,
          child: Text('€${price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor.withValues(alpha: 0.6)),
              textAlign: TextAlign.left),
        );
      }),
    );
  }

  Widget _buildXLabels(BuildContext context, double chartW, int count) {
    if (widget.entries.isEmpty) return const SizedBox();
    final fmt = DateFormat('dd/MM', 'nl_NL');
    // Max 5 labels, altijd eerste en laatste tonen
    final maxLabels = 5;
    final indices = <int>{0, count - 1};
    if (count > 2) {
      final step = (count / (maxLabels - 1)).ceil();
      for (int i = step; i < count - 1; i += step) indices.add(i);
    }
    final labelW = (chartW / math.max(indices.length, 1)).clamp(30.0, 50.0);
    return Stack(
      children: indices.map((idx) {
        final x = _toX(idx, count, chartW);
        return Positioned(
          left: (x - labelW / 2).clamp(0.0, chartW - labelW),
          top: 2,
          width: labelW,
          child: Text(fmt.format(widget.entries[idx].date as DateTime),
              style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor.withValues(alpha: 0.6)),
              textAlign: TextAlign.center),
        );
      }).toList(),
    );
  }
}

// ── Lollipop painter ──────────────────────────────────────────────
class _LollipopPainter extends CustomPainter {
  final List entries;
  final List<double> prices;
  final double yMin;
  final double yMax;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final bool isDarkMode;
  final int? selectedIndex;
  final double dotRadius;

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _blue  = Color(0xFF3B82F6);

  const _LollipopPainter({
    required this.entries,
    required this.prices,
    required this.yMin,
    required this.yMax,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.isDarkMode,
    required this.dotRadius,
    this.selectedIndex,
  });

  double _toY(double price, double h) =>
      h - ((price - yMin) / (yMax - yMin)) * h;

  double _toX(int i, double w) {
    const pad = 16.0;
    return prices.length > 1
        ? pad + i / (prices.length - 1) * (w - pad * 2)
        : w / 2;
  }

  // Top 3 duurste = rood, top 3 goedkoopste = groen, rest = blauw
  Color _colorForIndex(int i) {
    final sorted = [...prices]..sort();
    final n = math.min(3, (prices.length / 2).floor());
    if (prices.length <= 3) {
      // Als weinig data: goedkoopste groen, duurste rood
      final rank = sorted.indexOf(prices[i]);
      if (rank == 0) return _green;
      if (rank == sorted.length - 1) return _red;
      return _blue;
    }
    final cheapThreshold = sorted[n - 1];
    final expThreshold = sorted[sorted.length - n];
    if (prices[i] <= cheapThreshold) return _green;
    if (prices[i] >= expThreshold) return _red;
    return _blue;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    // ── Subtiele grid ──
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        gridPaint,
      );
    }

    // ── Gemiddelde lijn gestippeld ──
    final avgY = _toY(avgPrice, size.height);
    final avgPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.25)
      ..strokeWidth = 1.2;
    const dash = 5.0;
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(
        Offset(dx, avgY),
        Offset(math.min(dx + dash, size.width), avgY),
        avgPaint,
      );
      dx += dash * 2;
    }
    // gem label links van de lijn (niet over de bolletjes)
    final avgTp = TextPainter(
      text: TextSpan(
        text: 'gem.',
        style: TextStyle(fontSize: 8, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.3)),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    avgTp.paint(canvas, Offset(2, avgY - avgTp.height - 2));

    // ── Lollipops ──
    final minIdx = prices.indexOf(prices.reduce(math.min));
    final maxIdx = prices.indexOf(prices.reduce(math.max));
    final lastIdx = prices.length - 1;

    for (int i = 0; i < prices.length; i++) {
      final x = _toX(i, size.width);
      final y = _toY(prices[i], size.height);
      final isSelected = selectedIndex == i;
      final color = _colorForIndex(i);
      final r = isSelected ? dotRadius * 1.25 : dotRadius;

      // Stok: van onderkant chart tot dot
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, y + r),
        Paint()
          ..color = color.withOpacity(0.35)
          ..strokeWidth = isSelected ? 2.0 : 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Glow bij geselecteerd
      if (isSelected) {
        canvas.drawCircle(Offset(x, y), r + 5, Paint()..color = color.withOpacity(0.18));
      }

      // Witte ring
      canvas.drawCircle(Offset(x, y), r + 1.5,
          Paint()..color = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);

      // Dot
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);

      // Prijslabel — alleen bij laagste, hoogste en laatste
      if (i == minIdx || i == maxIdx || i == lastIdx) {
        final labelTp = TextPainter(
          text: TextSpan(
            text: '€${prices[i].toStringAsFixed(2)}',
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: color),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        labelTp.paint(
          canvas,
          Offset(
            (x - labelTp.width / 2).clamp(0.0, size.width - labelTp.width),
            y - r - labelTp.height - 2,
          ),
        );
      }
    }

    // ── Rand ──
    final border = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), border);
    canvas.drawLine(Offset.zero, Offset(0, size.height), border);
  }

  @override
  bool shouldRepaint(_LollipopPainter old) =>
      old.prices != prices || old.selectedIndex != selectedIndex;
}

// ── Sparkline painter ─────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final double avgPrice;
  final Color color;
  final bool isDarkMode;

  const _SparklinePainter({
    required this.prices,
    required this.avgPrice,
    required this.color,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final minP = prices.reduce(math.min);
    final maxP = prices.reduce(math.max);
    final range = math.max(maxP - minP, 0.01);
    final margin = range * 0.3;
    final yMin = minP - margin;
    final yMax = maxP + margin;

    double toX(int i) => i / (prices.length - 1) * size.width;
    double toY(double p) => size.height - ((p - yMin) / (yMax - yMin)) * size.height;

    // Gemiddelde lijn gestippeld
    final avgY = toY(avgPrice);
    final dashPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.15)
      ..strokeWidth = 1;
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, avgY), Offset(math.min(dx + 4, size.width), avgY), dashPaint);
      dx += 8;
    }

    // Schaduw vlak onder de lijn (niet tot bodem, alleen ~12px)
    const shadowDepth = 12.0;
    final areaPath = Path()..moveTo(toX(0), toY(prices[0]));
    for (int i = 1; i < prices.length; i++) areaPath.lineTo(toX(i), toY(prices[i]));
    areaPath.lineTo(toX(prices.length - 1), toY(prices.last) + shadowDepth);
    areaPath.lineTo(0, toY(prices[0]) + shadowDepth);
    areaPath.close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, toY(prices.reduce(math.min))),
          Offset(0, toY(prices.reduce(math.min)) + shadowDepth),
          [color.withOpacity(0.4), color.withOpacity(0.0)],
        )
        ..style = PaintingStyle.fill,
    );

    // Lijn
    final linePath = Path()..moveTo(toX(0), toY(prices[0]));
    for (int i = 1; i < prices.length; i++) linePath.lineTo(toX(i), toY(prices[i]));
    canvas.drawPath(linePath, Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Laatste punt highlight
    final lastX = toX(prices.length - 1);
    final lastY = toY(prices.last);
    canvas.drawCircle(Offset(lastX, lastY), 4,
        Paint()..color = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.prices != prices || old.color != color;
}