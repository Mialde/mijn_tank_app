import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum TimeFilter { last, month, year }

class DistributionCharts extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final bool isDark;

  const DistributionCharts({super.key, required this.entries, required this.isDark});

  @override
  State<DistributionCharts> createState() => _DistributionChartsState();
}

class _DistributionChartsState extends State<DistributionCharts> {
  final PageController _pageCtrl = PageController(viewportFraction: 1.0);
  TimeFilter _activeFilter = TimeFilter.month;
  int _touchedIndex = -1;
  int _currentView = 0; // 0 = Kosten, 1 = Liters

  final List<Color> chartColors = [
    const Color(0xFF26E5FF),
    const Color(0xFF845BEF),
    const Color(0xFFFFCF26),
    const Color(0xFFEE2727),
    const Color(0xFF26FF31),
    const Color(0xFFFF6200),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 440, // Iets hoger om ruimte te bieden aan filters binnenin
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() {
              _currentView = i;
              _touchedIndex = -1;
            }),
            children: [
              _buildChartCard("Kosten Verdeling", "€", true),
              _buildChartCard("Brandstof Verdeling", "L", false),
            ],
          ),
        ),
        // Indicator bolletjes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: _currentView == index ? 18 : 6,
            decoration: BoxDecoration(
              color: _currentView == index ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChartCard(String title, String unit, bool isCost) {
    final data = _getFilteredData(isCost);
    final total = data.fold<double>(0, (sum, item) => sum + item['value']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          // --- FILTERS BINNEN HET KADER ---
          _buildInternalFilterBar(),
          
          const SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    sections: _buildSections(data),
                  ),
                ),
                _buildCenterText(total, isCost, data),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: data.length,
              itemBuilder: (context, i) => _buildLegendItem(data[i], i, total, unit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalFilterBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _internalFilterBtn("Laatste", TimeFilter.last),
          _internalFilterBtn("Maand", TimeFilter.month),
          _internalFilterBtn("Jaar", TimeFilter.year),
        ],
      ),
    );
  }

  Widget _internalFilterBtn(String label, TimeFilter filter) {
    bool active = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeFilter = filter;
          _touchedIndex = -1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.blueAccent : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterText(double total, bool isCost, List<Map<String, dynamic>> data) {
    String valueText = isCost ? "€${total.toStringAsFixed(2)}" : "${total.toStringAsFixed(1)}L";
    String labelText = "Totaal";

    if (_touchedIndex != -1 && _touchedIndex < data.length) {
      valueText = isCost ? "€${data[_touchedIndex]['value'].toStringAsFixed(2)}" : "${data[_touchedIndex]['value'].toStringAsFixed(1)}L";
      labelText = data[_touchedIndex]['label'];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(valueText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(labelText, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (i) {
      final isTouched = i == _touchedIndex;
      final color = chartColors[i % chartColors.length];
      
      return PieChartSectionData(
        color: color,
        value: data[i]['value'],
        radius: isTouched ? 22 : 18,
        showTitle: false,
        borderSide: isTouched 
          ? BorderSide(color: color.withValues(alpha: 0.4), width: 8)
          : const BorderSide(color: Colors.transparent),
      );
    });
  }

  Widget _buildLegendItem(Map<String, dynamic> item, int index, double total, String unit) {
    bool isTouched = index == _touchedIndex;
    double percentage = (item['value'] / (total == 0 ? 1 : total)) * 100;

    return InkWell(
      onTap: () => setState(() => _touchedIndex = isTouched ? -1 : index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isTouched ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: chartColors[index % chartColors.length], shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(item['label'], style: TextStyle(fontSize: 13, fontWeight: isTouched ? FontWeight.bold : FontWeight.normal))),
            Text("${percentage.toStringAsFixed(1)}% ($unit${item['value'].toStringAsFixed(0)})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredData(bool isCost) {
    List<Map<String, dynamic>> result = [];
    DateTime now = DateTime.now();
    var sorted = List<Map<String, dynamic>>.from(widget.entries);
    sorted.sort((a, b) => b['date'].compareTo(a['date']));
    final String key = isCost ? 'price_total' : 'liters';

    if (_activeFilter == TimeFilter.last) {
      if (sorted.isNotEmpty) {
        result.add({'label': 'Laatste tankbeurt', 'value': (sorted.first[key] as num).toDouble()});
      }
    } else if (_activeFilter == TimeFilter.month) {
      var thisMonth = sorted.where((e) {
        DateTime dt = DateTime.parse(e['date']);
        return dt.month == now.month && dt.year == now.year;
      }).toList();
      for (var i = 0; i < thisMonth.length; i++) {
        DateTime dt = DateTime.parse(thisMonth[i]['date']);
        result.add({'label': '${dt.day} ${DateFormat('MMM').format(dt)}', 'value': (thisMonth[i][key] as num).toDouble()});
      }
    } else if (_activeFilter == TimeFilter.year) {
      for (int i = 0; i < 12; i++) {
        DateTime targetDate = DateTime(now.year, now.month - i, 1);
        var monthEntries = sorted.where((e) {
          DateTime dt = DateTime.parse(e['date']);
          return dt.month == targetDate.month && dt.year == targetDate.year;
        });
        if (monthEntries.isNotEmpty) {
          double sum = monthEntries.fold(0, (prev, e) => prev + (e[key] as num).toDouble());
          result.add({'label': DateFormat('MMMM').format(targetDate), 'value': sum});
        }
      }
    }
    return result;
  }
}