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

    const double holeRadius = 115;
    const double mainThickness = 26;
    const double gapWidth = 8; // verder van de buitenrand
    const double ringThickness = 5;

    // Auto-selecteer grootste segment als nog niets geselecteerd
    if (statItems.isNotEmpty && selectedIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setSelectedIndex(0); // statItems zijn al gesorteerd op waarde desc
      });
    }

    final fmt = NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 0);
    final fmtDec = NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 2);

    // Geselecteerd item info
    final hasSelection = selectedIndex != -1 && selectedIndex < statItems.length;
    final sel = hasSelection ? statItems[selectedIndex] : null;
    final selTitle = sel != null ? _getLegendTitle(sel, provider.selectedPeriod) : '';
    final selAmount = sel != null ? fmtDec.format(sel.value) : '';
    final selPct = sel != null ? '${sel.percentage.toStringAsFixed(1)}%' : '';
    final selColor = sel?.color ?? appColor;

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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: statItems.isEmpty
                ? const Center(child: Text("Geen data."))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Indicator ring
                      if (hasSelection)
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
                      // Hoofd donut — aanklikbaar
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: holeRadius,
                          startDegreeOffset: -90,
                          sections: _buildChartSections(statItems, mainThickness, selectedIndex),
                          pieTouchData: PieTouchData(
                            enabled: true,
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              if (event is FlTapUpEvent) {
                                final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex ?? -1;
                                if (idx != -1) provider.setSelectedIndex(idx);
                              }
                            },
                          ),
                        ),
                        duration: Duration.zero,
                      ),
                      // Midden tekst
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titel boven
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                hasSelection ? selTitle : 'Totaal',
                                key: ValueKey(selTitle),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasSelection ? selColor : Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Groot bedrag
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                hasSelection ? selAmount : fmt.format(totalAmount),
                                key: ValueKey(hasSelection ? sel!.value : totalAmount),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: hasSelection ? selColor : Theme.of(context).textTheme.bodyLarge?.color,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Percentage + totaal onder
                            if (hasSelection) ...[
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  '$selPct van ${fmt.format(totalAmount)}',
                                  key: ValueKey(selPct),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _showThisMonth = true;

  // M: Square with swipeable pages
  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (i) => setState(() => _showThisMonth = i == 0),
                children: [
                  _buildMPage(context, appColor, isDarkMode, provider, TimePeriod.oneMonth, 'Deze maand'),
                  _buildMPage(context, appColor, isDarkMode, provider, TimePeriod.allTime, 'Totaal'),
                ],
              ),
            ),
            _buildMPageIndicator(appColor),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMPage(BuildContext context, Color appColor, bool isDarkMode,
      DataProvider provider, TimePeriod period, String label) {
    final rawItems = provider.getStatsForSpecificPeriod(period);

    // Brandstof samenvoegen tot 1 item
    final fuelTotal = rawItems.where((s) => s.isFuelGroup).fold<double>(0, (s, i) => s + i.value);
    final nonFuel   = rawItems.where((s) => !s.isFuelGroup).toList();
    final statItems = [
      if (fuelTotal > 0)
        StatItem(title: 'Brandstof', value: fuelTotal, color: const Color(0xFFEF4444), percentage: 0, sortOrder: 0),
      ...nonFuel,
    ];

    final totalAmount = statItems.fold<double>(0, (s, i) => s + i.value);
    final fmt = NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 0);
    final maxVal = statItems.isEmpty ? 1.0 : statItems.map((s) => s.value).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — zelfde stijl als andere M cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KOSTEN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: appColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Kolommen
          Expanded(
            child: statItems.isEmpty
                ? Center(child: Icon(Icons.bar_chart, color: Theme.of(context).hintColor.withValues(alpha: 0.3), size: 32))
                : LayoutBuilder(builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: statItems.take(6).toList().asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        final frac = (maxVal > 0) ? (item.value / maxVal).clamp(0.0, 1.0) : 0.0;
                        final barH = (constraints.maxHeight * frac).clamp(4.0, constraints.maxHeight);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
          ),
          const SizedBox(height: 6),
          // Legenda gecentreerd
          if (statItems.isNotEmpty)
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: statItems.take(6).map((item) {
                  final name = item.title;
                  final short = name.length > 9 ? '${name.substring(0, 8)}.' : name;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Text(short, style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor)),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 6),
          // Totaal rechts uitgelijnd
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'totaal',
                style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor),
              ),
              const SizedBox(width: 4),
              Text(
                fmt.format(totalAmount),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appColor, height: 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMPageIndicator(Color appColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: _showThisMonth ? appColor : appColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Container(width: 6, height: 6, decoration: BoxDecoration(color: !_showThisMonth ? appColor : appColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
      ],
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

  List<PieChartSectionData> _buildChartSections(List<StatItem> items, double thickness, int selectedIndex) {
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