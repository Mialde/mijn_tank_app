// COSTS OVERVIEW CARD
// M-size: Square with Totaal/Gemiddeld selector

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/time_period.dart';
import '../models/stat_item.dart';
import '../models/card_config.dart';

class CostsOverviewCard extends StatefulWidget {
  final CardSize size;
  
  const CostsOverviewCard({
    super.key,
    this.size = CardSize.xl,
  });

  @override
  State<CostsOverviewCard> createState() => _CostsOverviewCardState();
}

class _CostsOverviewCardState extends State<CostsOverviewCard> {
  bool _showTotal = true; // true = Totaal, false = Gemiddeld

  @override
  Widget build(BuildContext context) {
    return widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);
  }

  // XL: Full version
  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statItems = provider.getStatsForPeriod();
    final totalAmount = provider.getTotalForPeriod();
    final selectedIndex = provider.selectedIndex;
    
    const double holeRadius = 95;
    const double mainThickness = 20;
    const double gapWidth = 8;
    const double ringThickness = 6;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "KOSTENOVERZICHT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                  letterSpacing: 1.0,
                ),
              ),
              _buildCompactSelector(context, provider, appColor),
            ],
          ),
          const SizedBox(height: 24),
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
                      Center(
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
                    ],
                  ),
          ),
          const SizedBox(height: 4),
          if (statItems.isNotEmpty) ...[
            SizedBox(
              height: 277,
              child: _buildLegendGrid(context, provider, statItems, selectedIndex),
            ),
          ],
        ],
      ),
    );
  }

  // M: Square with selector
  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = provider.getTotalForPeriod();
    
    // Calculate average per fill
    final entries = provider.entries;
    final avgPerFill = entries.isNotEmpty ? totalAmount / entries.length : 0;
    
    final displayValue = _showTotal ? totalAmount : avgPerFill;
    final displayLabel = _showTotal ? 'totaal' : 'gemiddeld per tank';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.euro, color: appColor, size: 48),
            const SizedBox(height: 16),
            Text(
              NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 0).format(displayValue),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: appColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            _buildModeSelector(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectorButton(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Totaal',
            isSelected: _showTotal,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showTotal = true),
          ),
          _buildSelectorButton(
            context,
            icon: Icons.show_chart,
            label: 'Gem.',
            isSelected: !_showTotal,
            isDarkMode: isDarkMode,
            onTap: () => setState(() => _showTotal = false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (isDarkMode ? Colors.black : Colors.white)
                    : Theme.of(context).hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Theme.of(context).hintColor,
                ),
              ),
            ],
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
      TimePeriod.allTime: 'All',
    };
    
    return Row(
      children: TimePeriod.values.map((p) {
        final isSelected = provider.selectedPeriod == p;
        return GestureDetector(
          onTap: () => provider.setTimePeriod(p),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? appColor : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              labels[p]!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildChartSections(List<StatItem> items, double thickness) {
    return List.generate(
      items.length,
      (i) => PieChartSectionData(
        color: items[i].color,
        value: items[i].value,
        title: '',
        radius: thickness,
        showTitle: false,
      ),
    );
  }

  List<PieChartSectionData> _buildIndicatorSections(List<StatItem> items, int selectedIndex, double thickness) {
    return List.generate(
      items.length,
      (i) => PieChartSectionData(
        color: i == selectedIndex ? items[i].color : Colors.transparent,
        value: items[i].value,
        title: '',
        radius: thickness,
        showTitle: false,
      ),
    );
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
                  width: 10,
                  height: 5,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftItems
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: buildItem(e.key, e.value),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: rightItems
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: buildItem(e.key, e.value),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
} 