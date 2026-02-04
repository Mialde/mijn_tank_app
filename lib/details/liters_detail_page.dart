import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../data_provider.dart';

class LitersDetailPage extends StatelessWidget {
  final int? carId;
  const LitersDetailPage({super.key, this.carId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final entries = data.getEntriesForCar(carId);
    entries.sort((a, b) => a['date'].compareTo(b['date'])); 

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in entries) {
      DateTime dt = DateTime.parse(e['date']);
      String key = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(e);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    final reversedKeys = sortedKeys.reversed.toList();

    double totalLiters = 0;
    if (entries.isNotEmpty) {
      totalLiters = entries.map((e) => (e['liters'] as num).toDouble()).reduce((a, b) => a + b);
    }
    double avgLiters = entries.isNotEmpty ? totalLiters / entries.length : 0;

    final List<Color> stackColors = [
      Colors.teal, Colors.blueAccent, Colors.orange, Colors.purpleAccent, 
      Colors.redAccent, Colors.green, Colors.amber, Colors.indigo, Colors.pink
    ];

    List<BarChartGroupData> bars = [];
    double maxTotal = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      String key = sortedKeys[i];
      List<Map<String, dynamic>> monthEntries = grouped[key]!;
      
      double currentY = 0;
      List<BarChartRodStackItem> stacks = [];
      
      for (int j = 0; j < monthEntries.length; j++) {
        double val = (monthEntries[j]['liters'] as num).toDouble();
        Color color = stackColors[j % stackColors.length];
        
        stacks.add(BarChartRodStackItem(currentY, currentY + val, color));
        currentY += val;
      }

      if (currentY > maxTotal) maxTotal = currentY;

      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: currentY,
            width: 24, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            rodStackItems: stacks,
          )
        ],
        showingTooltipIndicators: [], 
      ));
    }

    double maxY = ((maxTotal / 10).ceil() * 10.0) + 10;
    if (maxY == maxTotal + 10) { maxY = maxTotal; } 

    return Scaffold(
      appBar: AppBar(title: const Text("Getankte Liters")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double widthPerBarSlot = screenWidth / 6; 
              
              double finalChartWidth = max(screenWidth, sortedKeys.length * widthPerBarSlot);

              double spacing = widthPerBarSlot - 24; 

              return Container(
                height: 220, 
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 10), 
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: finalChartWidth,
                    padding: const EdgeInsets.only(left: 10, right: 10), 
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.start, 
                        groupsSpace: spacing, 
                        barGroups: bars,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40, 
                              interval: 10,
                              getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            )
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (val, meta) {
                                int idx = val.toInt();
                                if (idx >= 0 && idx < sortedKeys.length) {
                                  List<String> parts = sortedKeys[idx].split('-');
                                  int m = int.parse(parts[1]);
                                  const mNames = ["", "Jan", "Feb", "Mrt", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"];
                                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(mNames[m], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
                                }
                                return const SizedBox();
                              },
                            )
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.grey, width: 1),
                            left: BorderSide(color: Colors.grey, width: 1),
                            top: BorderSide.none,
                            right: BorderSide.none,
                          )
                        ),
                        barTouchData: BarTouchData(enabled: false), 
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statCard(context, "Totaal Getankt", "${totalLiters.toStringAsFixed(0)} L", Icons.water_drop, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _statCard(context, "Gemiddeld p/beurt", "${avgLiters.toStringAsFixed(2)} L", Icons.functions, Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 24),
          
          ...reversedKeys.map((key) {
             List<Map<String, dynamic>> monthEntries = grouped[key]!;
             double monthTotal = monthEntries.map((e) => (e['liters'] as num).toDouble()).reduce((a, b) => a + b);
             
             List<String> parts = key.split('-');
             int m = int.parse(parts[1]);
             int y = int.parse(parts[0]);
             const mNames = ["", "Januari", "Februari", "Maart", "April", "Mei", "Juni", "Juli", "Augustus", "September", "Oktober", "November", "December"];
             String monthName = "${mNames[m]} $y";

             return Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Theme.of(context).cardColor,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(monthName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       Text("${monthTotal.toStringAsFixed(1).replaceAll('.', ',')} L", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                     ],
                   ),
                   const Divider(),
                   ...monthEntries.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var e = entry.value;
                      double l = (e['liters'] as num).toDouble();
                      DateTime d = DateTime.parse(e['date']);
                      Color dotColor = stackColors[idx % stackColors.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Text("${l.toStringAsFixed(1).replaceAll('.', ',')} L", style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text("op ${d.day} ${mNames[d.month].toLowerCase()}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      );
                   }),
                 ],
               ),
             );
          }),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}