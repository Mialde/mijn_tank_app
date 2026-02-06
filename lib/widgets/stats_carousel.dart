import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final bool isDark;

  const StatsCarousel({super.key, required this.entries, required this.isDark});

  @override
  State<StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<StatsCarousel> {
  bool _showLineChart = true;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.length < 2) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "Nog niet genoeg data.\nVoeg minimaal 2 tankbeurten toe.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    var sorted = List<Map<String, dynamic>>.from(widget.entries);
    sorted.sort((a, b) => a['date'].compareTo(b['date']));

    double totalDist = 0;
    double totalLiters = 0;
    for (int i = 1; i < sorted.length; i++) {
      double curOdo = (sorted[i]['odometer'] as num).toDouble();
      double prevOdo = (sorted[i - 1]['odometer'] as num).toDouble();
      totalDist += (curOdo - prevOdo);
      totalLiters += (sorted[i]['liters'] as num).toDouble();
    }
    double globalAvg = (totalLiters > 0) ? totalDist / totalLiters : 0;

    int takeCount = sorted.length > 12 ? 12 : sorted.length;
    var chartData = sorted.sublist(sorted.length - takeCount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.fromLTRB(25, 20, 5, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Verbruik Trend",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
                      const Text("1 op X (Hoger is beter)",
                          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.2)),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _showLineChart ? Icons.bar_chart_rounded : Icons.show_chart_rounded,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _showLineChart = !_showLineChart),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            SizedBox(
              height: 200,
              child: IgnorePointer(
                child: _buildUniversalChart(chartData, globalAvg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  List<Map<String, dynamic>> _calculateConsumptionPoints(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> points = [];
    for (int i = 1; i < data.length; i++) {
      double curOdo = (data[i]['odometer'] as num).toDouble();
      double prevOdo = (data[i - 1]['odometer'] as num).toDouble();
      double dist = curOdo - prevOdo;
      double liters = (data[i]['liters'] as num).toDouble();
      double cons = (liters > 0) ? dist / liters : 0;
      DateTime dt = DateTime.parse(data[i]['date']);
      points.add({'x': (i - 1).toDouble(), 'y': cons, 'label': DateFormat('d MMM').format(dt)});
    }
    return points;
  }

  _ChartScaling _calculateYAxisScaling(List<Map<String, dynamic>> points, double avg) {
    if (points.isEmpty) return _ChartScaling(minY: 0, maxY: 20, interval: 5);
    double maxData = avg;
    for (var p in points) { if (p['y'] > maxData) maxData = p['y']; }
    const double interval = 5.0;
    double finalMax = (maxData / interval).ceil() * interval + interval;
    if (finalMax < 20) finalMax = 20;
    return _ChartScaling(minY: 0, maxY: finalMax, interval: interval);
  }

  // --- DE CHART ---
  Widget _buildUniversalChart(List<Map<String, dynamic>> rawData, double globalAvg) {
    final points = _calculateConsumptionPoints(rawData);
    if (points.isEmpty) return const SizedBox();
    final scaling = _calculateYAxisScaling(points, globalAvg);
    
    return Stack(
      children: [
        Positioned.fill(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              maxY: scaling.maxY, 
              minY: scaling.minY,

              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false, 
                horizontalInterval: scaling.interval,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
              ),
              
              titlesData: _buildTitlesData(points, globalAvg, scaling, showTexts: true),
              borderData: FlBorderData(show: false),
              
              barTouchData: _buildFixedTooltipData(),
              
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: globalAvg, 
                  color: Colors.grey.withValues(alpha: 0.5), 
                  strokeWidth: 2, 
                  dashArray: [5, 5]
                )
              ]),
              
              barGroups: points.map((p) {
                double hoverHeight = p['y'] + (scaling.maxY - p['y']) * 0.5;
                final double width = _showLineChart ? 1.5 : 14.0;
                
                return BarChartGroupData(
                  x: p['x'].toInt(),
                  showingTooltipIndicators: [0], 
                  barRods: [
                    BarChartRodData(
                      toY: hoverHeight, 
                      width: width,
                      color: Colors.transparent, 
                      rodStackItems: _showLineChart 
                        ? [
                            BarChartRodStackItem(0, p['y'], widget.isDark ? Colors.white24 : Colors.black12),
                            BarChartRodStackItem(p['y'], hoverHeight, Colors.transparent),
                          ]
                        : [
                            BarChartRodStackItem(0, p['y'], Colors.blueAccent),
                            BarChartRodStackItem(p['y'], hoverHeight, Colors.transparent),
                          ],
                      borderRadius: _showLineChart ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(4)),
                    )
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        if (_showLineChart)
          Positioned.fill(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: scaling.minY, 
                maxY: scaling.maxY,
                
                gridData: FlGridData(show: false),
                titlesData: _buildTitlesData(points, globalAvg, scaling, showTexts: false),
                borderData: FlBorderData(show: false),
                
                extraLinesData: ExtraLinesData(horizontalLines: []),

                lineBarsData: [
                  LineChartBarData(
                    spots: points.map((p) => FlSpot(p['x'], p['y'])).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: widget.isDark ? Colors.black : Colors.white, 
                        strokeWidth: 2,
                        strokeColor: Colors.blueAccent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withValues(alpha: 0.3), Colors.blueAccent.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
                lineTouchData: LineTouchData(enabled: false), 
              ),
            ),
          ),
      ],
    );
  }

  FlTitlesData _buildTitlesData(List<Map<String, dynamic>> points, double globalAvg, _ChartScaling scaling, {required bool showTexts}) {
    Color textColor(Color c) => showTexts ? c : Colors.transparent;

    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50, 
          interval: 1,
          getTitlesWidget: (value, meta) => value.toInt() == globalAvg.round()
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Gem.", style: TextStyle(fontSize: 8, color: textColor(Colors.grey), fontWeight: FontWeight.bold)),
                      Text("1:${globalAvg.round()}",
                          style: TextStyle(fontSize: 8, color: textColor(Colors.grey), fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : const SizedBox(),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            if ((value - value.round()).abs() > 0.05) return const SizedBox();
            int index = value.round();
            if (index >= 0 && index < points.length) {
              if (points.length > 6 && index % 2 != 0) return const SizedBox();
              return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(points[index]['label'], style: TextStyle(color: textColor(Colors.grey[500]!), fontSize: 9)));
            }
            return const SizedBox();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: scaling.interval,
          reservedSize: 32,
          getTitlesWidget: (value, meta) => value == scaling.minY
              ? const SizedBox()
              : Text("1:${value.toInt()}",
                  style: TextStyle(color: textColor(Colors.grey[500]!), fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  BarTouchData _buildFixedTooltipData() {
    return BarTouchData(
      enabled: false, 
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: -14, 
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          double value = rod.rodStackItems.isNotEmpty ? rod.rodStackItems[0].toY : 0;
          return BarTooltipItem(
            '1:${value.round()}',
            TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }
}

class _ChartScaling {
  final double minY, maxY, interval;
  _ChartScaling({required this.minY, required this.maxY, required this.interval});
}