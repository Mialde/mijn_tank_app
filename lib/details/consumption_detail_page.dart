import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../data_provider.dart';

class ConsumptionDetailPage extends StatefulWidget {
  final int? carId;
  const ConsumptionDetailPage({super.key, this.carId});
  @override
  State<ConsumptionDetailPage> createState() => _ConsumptionDetailPageState();
}

class _ConsumptionDetailPageState extends State<ConsumptionDetailPage> {
  bool isBarChart = true;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    
    List<Map<String, dynamic>> rawEntries = data.getEntriesForCar(widget.carId);
    rawEntries.sort((a, b) => b['date'].compareTo(a['date'])); 

    List<Map<String, dynamic>> calculatedData = [];
    
    double bestRun = 0;
    int bestRunDays = 0;
    
    double worstRun = 0; 
    int worstRunDays = 0;

    int totalDays = 0; 
    
    bool firstValidRunFound = false;

    if (rawEntries.length > 1) {
      for (int i = 0; i < rawEntries.length - 1; i++) {
        double dist = (rawEntries[i]['odometer'] as num).toDouble() - (rawEntries[i+1]['odometer'] as num).toDouble();
        double liters = (rawEntries[i]['liters'] as num).toDouble();
        
        DateTime currDate = DateTime.parse(rawEntries[i]['date']);
        DateTime prevDate = DateTime.parse(rawEntries[i+1]['date']);
        int days = currDate.difference(prevDate).inDays;
        if (days == 0) days = 1; 

        if (dist > 0 && liters > 0) {
          double cons = dist / liters;
          totalDays += days;

          if (!firstValidRunFound) {
            worstRun = cons; 
            worstRunDays = days;
            
            bestRun = cons;
            bestRunDays = days;
            
            firstValidRunFound = true;
          }

          if (cons > bestRun) {
            bestRun = cons;
            bestRunDays = days;
          }
          if (cons < worstRun) {
            worstRun = cons;
            worstRunDays = days;
          }

          calculatedData.add({
            'val': cons,
            'date': rawEntries[i]['date']
          });
        }
      }
    }
    
    final chartData = calculatedData.reversed.toList();

    double averageVal = 0;
    if (chartData.isNotEmpty) {
      averageVal = chartData.map((e) => e['val'] as double).reduce((a, b) => a + b) / chartData.length;
    }

    double totalPadding = 88; 
    double screenAvailableWidth = MediaQuery.of(context).size.width - totalPadding;
    int minItemsOnScreen = 10;
    double slotWidth = screenAvailableWidth / minItemsOnScreen;
    double barWidth = slotWidth * 0.5; 

    int totalSlots = max(chartData.length, minItemsOnScreen);
    double totalChartWidth = slotWidth * totalSlots;

    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    double maxY = _calculateMaxY(chartData);

    double xMin = -0.5;
    double xMax = totalSlots - 0.5;

    return Scaffold(
      appBar: AppBar(title: const Text("Verbruik Details")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.end, 
                  children: [
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(value: true, icon: Icon(Icons.bar_chart)),
                        ButtonSegment(value: false, icon: Icon(Icons.show_chart)),
                      ],
                      selected: {isBarChart},
                      onSelectionChanged: (val) => setState(() => isBarChart = val.first),
                    ),
                  ],
                ),
                const SizedBox(height: 4), 
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalChartWidth,
                    height: 220, 
                    padding: const EdgeInsets.only(top: 30, bottom: 0),
                    child: chartData.isEmpty 
                      ? const Center(child: Text("Nog niet genoeg data (minimaal 2 tankbeurten)"))
                      : isBarChart 
                        ? _buildBarChart(chartData, totalSlots, averageVal, barWidth, textColor, maxY, bestRun, worstRun) 
                        : _buildLineChart(chartData, averageVal, textColor, maxY, xMin, xMax, bestRun, worstRun),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), 
          
          if (chartData.isNotEmpty)
            Column(
              children: [
                _detailedStatCard(
                  title: "Zuinigste verbruik",
                  val: bestRun,
                  days: bestRunDays,
                  color: Colors.green,
                  icon: Icons.eco_rounded,
                  compareText: "Dit was ${worstRun > 0 ? ((bestRun - worstRun) / worstRun * 100).toStringAsFixed(0) : '0'}% zuiniger dan je slechtste rit en ${averageVal > 0 ? ((bestRun - averageVal) / averageVal * 100).toStringAsFixed(0) : '0'}% beter dan gemiddeld.",
                  iconCompare: Icons.trending_up,
                ),
                const SizedBox(height: 16),
                _detailedStatCard(
                  title: "Minst zuinige verbruik",
                  val: worstRun,
                  days: worstRunDays,
                  color: Colors.orange,
                  icon: Icons.warning_amber_rounded,
                  compareText: "Dit was ${averageVal > 0 ? ((averageVal - worstRun) / averageVal * 100).abs().toStringAsFixed(0) : '0'}% minder zuinig dan je gemiddelde verbruik.",
                  iconCompare: Icons.trending_down,
                ),
                const SizedBox(height: 16),
                _detailedStatCard(
                  title: "Gemiddeld verbruik",
                  val: averageVal,
                  days: totalDays,
                  color: Colors.blueAccent,
                  icon: Icons.functions_rounded, 
                  compareText: null, 
                  iconCompare: null, 
                ),
              ],
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _detailedStatCard({
    required String title,
    required double val,
    required int days,
    required Color color,
    required IconData icon,
    String? compareText, 
    IconData? iconCompare, 
  }) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("1 op", style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 2.5)),
              const SizedBox(width: 6),
              Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          _infoLine(Icons.calendar_today_outlined, "Gemeten over totaal $days ${days == 1 ? 'dag' : 'dagen'}.", bodyColor),
          
          if (compareText != null && iconCompare != null) ...[
             const SizedBox(height: 8),
            _infoLine(iconCompare, compareText, bodyColor),
          ]
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text, Color? color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 10),
          child: Icon(icon, size: 16, color: color?.withValues(alpha: 0.7) ?? Colors.grey),
        ),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color?.withValues(alpha: 0.8), height: 1.3)),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate);
      return DateFormat('dd-MM').format(dt);
    } catch (e) {
      return "";
    }
  }

  double _calculateMaxY(List<Map<String, dynamic>> data) {
    double maxVal = 0;
    if (data.isNotEmpty) {
      maxVal = data.map((e) => e['val'] as double).reduce(max);
    }
    double target = maxVal + 5;
    return (target / 5).ceil() * 5.0;
  }

  FlBorderData _getBorderData() {
    return FlBorderData(
      show: true,
      border: const Border(
        bottom: BorderSide(color: Colors.grey, width: 1.5), 
        left: BorderSide(color: Colors.grey, width: 1.5),   
        top: BorderSide.none,
        right: BorderSide.none,
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, int totalSlots, double avg, double barW, Color textColor, double sharedMaxY, double bestRun, double worstRun) {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < totalSlots; i++) {
      if (i < data.length) {
        
        double val = data[i]['val'];
        Color barColor = Colors.blueAccent;
        if (val == bestRun) { barColor = Colors.green; }
        else if (val == worstRun) { barColor = Colors.orange;}

        groups.add(BarChartGroupData(
          x: i, 
          showingTooltipIndicators: [0],
          barRods: [BarChartRodData(
            toY: val, 
            color: barColor, 
            width: barW, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          )] 
        ));
      } else {
        groups.add(BarChartGroupData(
          x: i, 
          showingTooltipIndicators: [], 
          barRods: [BarChartRodData(
            toY: 0, 
            color: Colors.transparent, 
            width: barW, 
          )] 
        ));
      }
    }

    return BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, 
        maxY: sharedMaxY,
        minY: 0,
        barGroups: groups,
        
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, 
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: avg, color: Colors.grey, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, labelResolver: (l) => "Gem", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), alignment: Alignment.topRight))
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30,
            interval: 5, 
            getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          )), 
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            interval: 1, 
            reservedSize: 30,
            getTitlesWidget: (val, meta) {
              if (val % 1 != 0) return const SizedBox();
              int idx = val.toInt();
              if (idx >= 0 && idx < data.length) {
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_formatDate(data[idx]['date']), style: const TextStyle(fontSize: 10)));
              }
              return const SizedBox();
            }
          )), 
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
        ),
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4, 
            getTooltipColor: (group) => Colors.transparent, 
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rod.toY == 0) return null;
              return BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11),
              );
            },
          ),
        ),
        borderData: _getBorderData(), 
      ));
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, double avg, Color textColor, double sharedMaxY, double xMin, double xMax, double bestRun, double worstRun) {
    final lineChartBarData = LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['val'])).toList(), 
      isCurved: true, 
      color: Colors.blueAccent, 
      barWidth: 3, 
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          Color dotColor = Colors.blueAccent;
          if (spot.y == bestRun) {
            dotColor = Colors.green;
          } else if (spot.y == worstRun) {
            dotColor = Colors.orange;
          }

          return FlDotCirclePainter(
            radius: 4,
            color: dotColor,
            strokeWidth: 0, 
          );
        }
      ),
    );

    return LineChart(LineChartData(
        minY: 0,
        maxY: sharedMaxY, 
        minX: xMin, 
        maxX: xMax, 
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: true, 
          horizontalInterval: 5,
          verticalInterval: 1, 
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: avg, color: Colors.grey, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, labelResolver: (l) => "Gem", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), alignment: Alignment.topRight))
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30,
            interval: 5, 
            getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          )), 
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            interval: 1, 
            reservedSize: 30,
            getTitlesWidget: (val, meta) {
              if (val % 1 != 0) return const SizedBox();
              int idx = val.toInt();
              if (idx >= 0 && idx < data.length) {
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_formatDate(data[idx]['date']), style: const TextStyle(fontSize: 10)));
              }
              return const SizedBox();
            }
          )), 
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
        ),
        
        borderData: _getBorderData(), 

        showingTooltipIndicators: data.asMap().entries.map((entry) {
          return ShowingTooltipIndicators([
            LineBarSpot(
              lineChartBarData,
              0, 
              lineChartBarData.spots[entry.key],
            ),
          ]);
        }).toList(),
        
        lineBarsData: [lineChartBarData],
        
        lineTouchData: LineTouchData(
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.transparent, 
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 10, 
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900),
                );
              }).toList();
            },
          ),
        ),
      ));
  }
}