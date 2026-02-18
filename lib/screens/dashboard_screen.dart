// LAATST BIJGEWERKT: 2026-02-18 23:00 UTC
// WIJZIGING: Added all 5 cards with visibility toggle + debug logging
// REDEN: Complete dashboard with card management

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../models/time_period.dart';
import '../models/stat_item.dart';
import '../models/card_config.dart';
import '../widgets/apk_warning_banner.dart';
import '../widgets/distance_consumption_card.dart';
import '../widgets/swipeable_stats_cards.dart';
import '../widgets/price_tracker_card.dart';
import '../widgets/efficiency_monitor_card.dart';
import '../widgets/cost_per_km_card.dart';
import '../widgets/timeline_heatmap_card.dart';
import '../widgets/card_visibility_selector.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final selectedCar = provider.selectedCar;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // DEBUG LOGGING
    debugPrint('🔍 DASHBOARD DEBUG:');
    debugPrint('   📊 Entries: ${provider.entries.length}');
    debugPrint('   🚗 Selected car: ${selectedCar?.name ?? "NONE"}');
    debugPrint('   🔧 Maintenance: ${provider.maintenanceEntries.length}');
    debugPrint('   🎴 Visible cards: ${provider.visibleCards.where((c) => c.isVisible).length}');
    if (provider.entries.isNotEmpty) {
      debugPrint('   ⛽ First entry: ${provider.entries.first.pricePerLiter} €/L on ${provider.entries.first.date}');
      debugPrint('   ⛽ Last entry: ${provider.entries.last.pricePerLiter} €/L on ${provider.entries.last.date}');
    }

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
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 24), 
            onPressed: () => _showHistoryModal(context)
          ),
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
            const DistanceConsumptionCard(),
            const SizedBox(height: 16),
            
            // Swipeable stats cards with long-press to configure
            SwipeableStatsCards(
              cards: _buildVisibleCards(context, provider, appColor, isDarkMode, statItems, totalAmount, selectedIndex, holeRadius, mainThickness, gapWidth, ringThickness),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildVisibleCards(
    BuildContext context,
    DataProvider provider,
    Color appColor,
    bool isDarkMode,
    List<StatItem> statItems,
    double totalAmount,
    int selectedIndex,
    double holeRadius,
    double mainThickness,
    double gapWidth,
    double ringThickness,
  ) {
    final cards = <Widget>[];
    
    debugPrint('🎴 Building cards...');
    for (final config in provider.visibleCards) {
      debugPrint('   - ${config.title}: ${config.isVisible ? "✅" : "❌"}');
      
      if (!config.isVisible) continue;
      
      Widget card;
      switch (config.id) {
        case 'costs_overview':
          card = _buildCostsCard(context, provider, appColor, isDarkMode, statItems, totalAmount, selectedIndex, holeRadius, mainThickness, gapWidth, ringThickness);
          break;
        case 'price_tracker':
          card = PriceTrackerCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
        case 'efficiency_monitor':
          card = EfficiencyMonitorCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
        case 'cost_per_km':
          card = CostPerKmCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
        case 'timeline_heatmap':
          card = TimelineHeatmapCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
        default:
          continue;
      }
      
      cards.add(
        GestureDetector(
          onLongPress: () => _showCardVisibilitySelector(context, provider),
          child: card,
        ),
      );
    }
    
    debugPrint('   📦 Total visible cards: ${cards.length}');
    return cards;
  }

  Widget _buildCostsCard(
    BuildContext context, 
    DataProvider provider, 
    Color appColor, 
    bool isDarkMode,
    List<StatItem> statItems,
    double totalAmount,
    int selectedIndex,
    double holeRadius,
    double mainThickness,
    double gapWidth,
    double ringThickness,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: SizedBox(
        height: 649,
        child: Material(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),

            SizedBox(
              height: 280,
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

                      RepaintBoundary(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 0).format(totalAmount),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  selectedIndex != -1 && selectedIndex < statItems.length
                                      ? _getLegendTitle(statItems[selectedIndex], provider.selectedPeriod)
                                      : '',
                                  key: ValueKey('subtitle_${selectedIndex}_${provider.selectedPeriod}'),
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 4),

            if (statItems.isNotEmpty) ...[
              ClipRRect(
                child: SizedBox(
                  height: 277,
                  child: _buildLegendGrid(context, provider, statItems, selectedIndex),
                ),
              ),
            ],
          ],
        ),
      ),
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

  Widget _buildLegendGrid(BuildContext context, DataProvider provider, List<StatItem> items, int selectedIndex) {
    final leftItems = <MapEntry<int, StatItem>>[];
    final rightItems = <MapEntry<int, StatItem>>[];
    
    for (int i = 0; i < items.length && i < 16; i++) {
      if (i % 2 == 0) {
        leftItems.add(MapEntry(i, items[i]));
      } else {
        rightItems.add(MapEntry(i, items[i]));
      }
    }

    Widget buildItem(int i, StatItem item) {
      final isSelected = i == selectedIndex;
      final String displayTitle = _getLegendTitle(item, provider.selectedPeriod);
      return SizedBox(
        height: 30,
        child: InkWell(
          onTap: () => provider.setSelectedIndex(i),
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? item.color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 5, 
                  decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3))
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayTitle, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Expanded(
          child: Column(
            children: leftItems.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: buildItem(e.key, e.value),
            )).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: rightItems.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: buildItem(e.key, e.value),
            )).toList(),
          ),
        ),
      ],
    ),
    );
  }

  void _showCardVisibilitySelector(BuildContext context, DataProvider provider) {
    showCardVisibilitySelector(
      context: context,
      cards: provider.visibleCards,
      onSave: (cards) {
        provider.updateCardVisibility(cards);
      },
    );
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9, 
        child: Container(
          clipBehavior: Clip.antiAlias,
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