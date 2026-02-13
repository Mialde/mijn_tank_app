import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../models/time_period.dart';
import '../models/stat_item.dart';
import '../widgets/apk_warning_banner.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final selectedCar = provider.selectedCar;
    final apk = provider.apkStatus;
    
    final bool showBanner = apk['show'] == true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (selectedCar == null) return const Scaffold(body: Center(child: Text("Selecteer eerst een voertuig.")));

    final statItems = provider.getStatsForPeriod();
    final totalAmount = provider.getTotalForPeriod();
    final selectedIndex = provider.selectedIndex;

    const double holeRadius = 95;      
    const double mainThickness = 20;   
    const double gapWidth = 8;         
    const double ringThickness = 6;    

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCar.name),
        centerTitle: false,
        titleSpacing: 24,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Geschiedenis: Neutraal thema
          IconButton(
            icon: const Icon(Icons.history, size: 24), 
            onPressed: () => _showHistoryModal(context)
          ),
          // Autoselectie: Accentkleur
          if (provider.cars.length > 1)
            IconButton(
              icon: Icon(Icons.directions_car, color: appColor, size: 24), 
              onPressed: () => _showVehicleSelector(context, provider)
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ApkWarningBanner(),
            Padding(
              padding: EdgeInsets.fromLTRB(24, showBanner ? 16 : 24, 24, 24), 
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), 
                      blurRadius: 20, 
                      offset: const Offset(0, 5)
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("KOSTENOVERZICHT", 
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).hintColor, 
                            letterSpacing: 1.0
                          )
                        ),
                        _buildCompactSelector(context, provider, appColor),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 320,
                      child: statItems.isEmpty 
                        ? const Center(child: Text("Geen data."))
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              if (selectedIndex != -1 && selectedIndex < statItems.length)
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: holeRadius + mainThickness + gapWidth, 
                                    startDegreeOffset: -90,
                                    pieTouchData: PieTouchData(enabled: false),
                                    sections: _buildIndicatorSections(statItems, selectedIndex, ringThickness),
                                  ),
                                  duration: Duration.zero, 
                                ),
                              
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 0,
                                  centerSpaceRadius: holeRadius, 
                                  startDegreeOffset: -90,
                                  sections: _buildChartSections(statItems, mainThickness),
                                ),
                                duration: Duration.zero,
                              ),

                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 0).format(totalAmount), 
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)
                                    ),
                                    if (selectedIndex != -1 && selectedIndex < statItems.length)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _getLegendTitle(statItems[selectedIndex], provider.selectedPeriod),
                                          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13, height: 1.2),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (statItems.isNotEmpty) ..._buildLegend(context, provider, statItems, selectedIndex),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLegendTitle(StatItem item, TimePeriod period) {
    if (!item.isFuelGroup) return item.title;
    if (period == TimePeriod.oneMonth) return 'Getankt op ${item.title}';
    return 'Getankt in ${item.title}';
  }

  Widget _buildCompactSelector(BuildContext context, DataProvider provider, Color appColor) {
    final Map<TimePeriod, String> labels = {
      TimePeriod.oneMonth: '1M', 
      TimePeriod.sixMonths: '6M', 
      TimePeriod.oneYear: '1J', 
      TimePeriod.allTime: 'All'
    };
    return Row(
      children: TimePeriod.values.map((p) => GestureDetector(
        onTap: () => provider.setTimePeriod(p),
        child: Container(
          margin: const EdgeInsets.only(left: 8), 
          width: 32, height: 32, 
          alignment: Alignment.center, 
          decoration: BoxDecoration(
            color: provider.selectedPeriod == p ? appColor : Colors.transparent, 
            shape: BoxShape.circle, 
            border: provider.selectedPeriod == p ? null : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3))
          ), 
          child: Text(labels[p]!, 
            style: TextStyle(
              color: provider.selectedPeriod == p ? Colors.white : Colors.grey, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            )
          )
        ),
      )).toList()
    );
  }

  List<PieChartSectionData> _buildChartSections(List<StatItem> items, double thickness) {
    return List.generate(items.length, (i) => PieChartSectionData(
      color: items[i].color, 
      value: items[i].value, 
      title: '', 
      radius: thickness, 
      showTitle: false
    ));
  }

  List<PieChartSectionData> _buildIndicatorSections(List<StatItem> items, int selectedIndex, double thickness) {
    return List.generate(items.length, (i) => PieChartSectionData(
      color: i == selectedIndex ? items[i].color : Colors.transparent, 
      value: items[i].value, 
      title: '', 
      radius: thickness, 
      showTitle: false
    ));
  }

  List<Widget> _buildLegend(BuildContext context, DataProvider provider, List<StatItem> items, int selectedIndex) {
    return List.generate(items.length, (i) {
      final item = items[i];
      final isSelected = i == selectedIndex;
      final String displayTitle = _getLegendTitle(item, provider.selectedPeriod);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: () => provider.setSelectedIndex(i),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 16, height: 8, 
                  decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(4))
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                Text('${item.percentage.toStringAsFixed(1)} %', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Text('(${NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 2).format(item.value)})', 
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias, // Clipping toegevoegd
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9, 
        child: Container(
          clipBehavior: Clip.antiAlias, // Clipping toegevoegd
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
          ), 
          child: const HistoryScreen(isModal: true)
        )
      )
    );
  }

  void _showVehicleSelector(BuildContext context, DataProvider provider) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), 
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView(
            shrinkWrap: true,
            children: provider.cars.map((c) {
              final isSelected = provider.selectedCar?.id == c.id;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Icon(Icons.directions_car, color: isSelected ? provider.themeColor : Colors.grey), 
                title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), 
                trailing: isSelected ? Icon(Icons.check, color: provider.themeColor) : null,
                onTap: () { 
                  provider.selectCar(c); 
                  Navigator.pop(context); 
                }
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}