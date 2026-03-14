// 5 LAYERS + PERIOD SELECTOR - Complete working version
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class CostPerKmCard extends StatefulWidget {
  final CardSize size;
  const CostPerKmCard({super.key, this.size = CardSize.xl});
  @override
  State<CostPerKmCard> createState() => _CostPerKmCardState();
}

class _CostPerKmCardState extends State<CostPerKmCard> {
  bool _showLatest = true;
  String _selectedPeriod = 'ALL';
  int _touchedIndex = -1; // For M-card donut touch
  
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  List<dynamic> _filterEntriesByPeriod(List<dynamic> sorted) {
    if (_selectedPeriod == 'ALL' || sorted.isEmpty) return sorted;
    
    final now = DateTime.now();
    final cutoffDate = switch (_selectedPeriod) {
      '1M' => DateTime(now.year, now.month - 1, now.day),
      '6M' => DateTime(now.year, now.month - 6, now.day),
      '1J' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(2000, 1, 1),
    };
    
    return sorted.where((e) => e.date.isAfter(cutoffDate)).toList();
  }

  double _getMaintenanceOdometer(dynamic maintenance, List<dynamic> sortedEntries) {
    if (maintenance.odometer > 0) {
      return maintenance.odometer.toDouble();
    }
    
    final maintenanceDate = maintenance.date;
    final entriesBefore = sortedEntries.where((e) => e.date.isBefore(maintenanceDate)).toList();
    final entriesAfter = sortedEntries.where((e) => e.date.isAfter(maintenanceDate)).toList();
    
    if (entriesBefore.isEmpty) return sortedEntries.first.odometer.toDouble();
    if (entriesAfter.isEmpty) return sortedEntries.last.odometer.toDouble();
    
    final before = entriesBefore.last;
    final after = entriesAfter.first;
    final totalDays = after.date.difference(before.date).inDays;
    final daysFromBefore = maintenanceDate.difference(before.date).inDays;
    
    if (totalDays <= 0) return before.odometer.toDouble();
    
    final percentage = daysFromBefore / totalDays;
    final kmDiff = after.odometer - before.odometer;
    final estimatedOdo = before.odometer + (kmDiff * percentage);
    
    return estimatedOdo.toDouble();
  }

  Map<String, double> _calculateAllCosts(DataProvider provider, int entryIndex, List<dynamic> sorted) {
    if (entryIndex >= sorted.length - 1) {
      return {'fuel': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    final current = sorted[entryIndex];
    final next = sorted[entryIndex + 1];
    final km = (next.odometer - current.odometer).abs();
    
    if (km <= 0) {
      return {'fuel': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    final car = provider.selectedCar;
    final monthsInPeriod = (next.date.difference(current.date).inDays / 30).clamp(0.1, 999).toDouble();
    
    final fuelCost = current.priceTotal / km;

    
    final lastEntry = sorted.last;
    final maintenanceBeforeLast = provider.maintenanceEntries.where((m) => 
      m.date.isBefore(lastEntry.date) || m.date.isAtSameMomentAs(lastEntry.date)
    ).toList();

    double maintenanceCost = 0;
    if (maintenanceBeforeLast.isNotEmpty) {
      final totalMaintenanceCost = maintenanceBeforeLast.fold<double>(0, (sum, m) => sum + m.cost);
      final firstMaintenance = maintenanceBeforeLast.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      
      final allEntries = provider.entries.toList()..sort((a, b) => a.date.compareTo(b.date));
      final startOdometer = _getMaintenanceOdometer(firstMaintenance, allEntries);
      final kmSinceMaintenance = lastEntry.odometer - startOdometer;
      
      if (kmSinceMaintenance > 0) {
        final globalMaintenanceCost = totalMaintenanceCost / kmSinceMaintenance;
        
        final hasMaintenanceBeforeThis = provider.maintenanceEntries.any((m) => 
          m.date.isBefore(current.date) || m.date.isAtSameMomentAs(current.date)
        );
        
        maintenanceCost = hasMaintenanceBeforeThis ? globalMaintenanceCost : 0.0;
      }
    }
    
    double subscriptionCost = 0;
    if (provider.recurringCosts.isNotEmpty && sorted.length >= 2) {
      final totalMonthlySubscriptions = provider.recurringCosts.fold<double>(0, (sum, s) => sum + s.monthlyCost);
      final firstEntry = sorted.first;
      final totalDays = lastEntry.date.difference(firstEntry.date).inDays;
      final totalMonths = totalDays / 30;
      final totalKm = lastEntry.odometer - firstEntry.odometer;
      
      if (totalKm > 0 && totalMonths > 0) {
        subscriptionCost = (totalMonthlySubscriptions * totalMonths) / totalKm;
      }
    }
    
    return {
      'fuel': fuelCost,
      'maintenance': maintenanceCost,
      'subscriptions': 0,
      '_km': km,
      '_months': monthsInPeriod,
    };
  }

  // NEW: Calculate average costs over entire filtered period
  Map<String, double> _calculatePeriodAverageCosts(DataProvider provider, List<dynamic> sorted) {
    if (sorted.length < 2) {
      return {'fuel': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    final car = provider.selectedCar;
    final firstEntry = sorted.first;
    final lastEntry = sorted.last;
    
    // Total km in period
    final totalKm = lastEntry.odometer - firstEntry.odometer;
    if (totalKm <= 0) {
      return {'fuel': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    // Total days and months
    final totalDays = lastEntry.date.difference(firstEntry.date).inDays;
    final totalMonths = (totalDays / 30).clamp(0.1, 999);
    
    // 1. Average Fuel cost
    final totalFuelCost = sorted.fold<double>(0, (sum, e) => sum + e.priceTotal);
    final avgFuelCost = totalFuelCost / totalKm;
    

    
    // 4. Maintenance - all maintenance BEFORE end of period (same as chart)
    final maintenanceBeforePeriod = provider.maintenanceEntries.where((m) => 
      m.date.isBefore(lastEntry.date) || m.date.isAtSameMomentAs(lastEntry.date)
    ).toList();
    
    double maintenanceCost = 0;
    if (maintenanceBeforePeriod.isNotEmpty) {
      final totalMaintenanceCost = maintenanceBeforePeriod.fold<double>(0, (sum, m) => sum + m.cost);
      final firstMaintenance = maintenanceBeforePeriod.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      
      final allEntries = provider.entries.toList()..sort((a, b) => a.date.compareTo(b.date));
      final startOdometer = _getMaintenanceOdometer(firstMaintenance, allEntries);
      final kmSinceMaintenance = lastEntry.odometer - startOdometer;
      
      if (kmSinceMaintenance > 0) {
        maintenanceCost = totalMaintenanceCost / kmSinceMaintenance;
      }
    }
    
    // 5. Subscriptions
    final totalMonthlySubscriptions = provider.recurringCosts.fold<double>(0, (sum, s) => sum + s.monthlyCost);
    final subscriptionCost = (totalMonthlySubscriptions * totalMonths) / totalKm;
    
    return {
      'fuel': avgFuelCost,
      'maintenance': maintenanceCost,
      'subscriptions': 0,
      '_km': totalKm,
      '_months': totalMonths,
    };
  }

  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final allSorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final sorted = _filterEntriesByPeriod(allSorted);
    
    if (sorted.length < 2) {
      return _buildEmptyState(context, isDarkMode);
    }
    
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    "KOSTEN PER KILOMETER",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).hintColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _buildPeriodSelector(context, isDarkMode, appColor),
              ],
            ),
            const SizedBox(height: 24),
            _buildChart(context, appColor, isDarkMode, provider, sorted),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, bool isDarkMode, Color appColor) {
    final Map<String, String> labels = {
      '1M': '1M',
      '6M': '6M',
      '1J': '1J',
      'ALL': 'All',
    };
    
    return Row(
      children: labels.entries.map((entry) {
        final isSelected = _selectedPeriod == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedPeriod = entry.key),
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
              entry.value,
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

  Widget _buildBreakdown(BuildContext context, Map<String, double> costs) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    // Tel recurring costs mee in totaal (subscriptions staat op 0, posts worden apart opgeteld)
    final km = costs['_km'] ?? 1.0;
    final months = costs['_months'] ?? 1.0;
    double recurringTotal = 0;
    if (km > 0 && months > 0) {
      recurringTotal = provider.recurringCosts.fold<double>(0, (s, c) => s + (c.monthlyCost * months) / km);
    }
    final total = costs.entries
        .where((e) => !e.key.startsWith('_'))
        .fold<double>(0, (sum, e) => sum + e.value) + recurringTotal;
    
    final items = <Widget>[];
    
    // Vaste kleuren palette voor recurring cost posts
    const fixedPalette = [
      Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF6366F1),
    ];

    if (costs['fuel']! > 0) {
      items.add(_buildBreakdownRow('Brandstof', costs['fuel']!, const Color(0xFFEF4444)));
    }
    if (costs['maintenance']! > 0) {
      items.add(_buildBreakdownRow('Onderhoud', costs['maintenance']!, const Color(0xFFF59E0B)));
    }
    // Recurring cost posts elk met eigen kleur
    int paletteIdx = 0;
    for (final cost in provider.recurringCosts) {
      final val = km > 0 && months > 0 ? (cost.monthlyCost * months) / km : 0.0;
      if (val > 0) {
        items.add(_buildBreakdownRow(cost.name, val, fixedPalette[paletteIdx % fixedPalette.length]));
        paletteIdx++;
      }
    }
    
    // Add Gemiddeld Totaal as 6th item
    items.add(_buildTotalRow(context, total, appColor));
    
    if (items.isEmpty) return const SizedBox.shrink();
    
    // Split into 2 columns
    final leftItems = <Widget>[];
    final rightItems = <Widget>[];
    
    for (int i = 0; i < items.length; i++) {
      if (i % 2 == 0) {
        leftItems.add(items[i]);
      } else {
        rightItems.add(items[i]);
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftItems,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightItems,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, double total, Color appColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: appColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gemiddeld Totaal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: appColor,
              ),
            ),
          ),
          Text(
            '€${total.toStringAsFixed(3)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: appColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double cost, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          Text(
            '€${cost.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Color appColor, bool isDarkMode, DataProvider provider, List<dynamic> sorted) {
    // Bouw kostenposten op — zelfde volgorde/kleuren als breakdown
    const fixedPalette = [
      Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF6366F1),
    ];

    final allCosts = _calculatePeriodAverageCosts(provider, sorted);
    final km     = allCosts['_km']     ?? 1.0;
    final months = allCosts['_months'] ?? 1.0;

    final bars = <_BarItem>[];

    if ((allCosts['fuel'] ?? 0) > 0)
      bars.add(_BarItem('Brandstof', allCosts['fuel']!, const Color(0xFFEF4444)));
    if ((allCosts['maintenance'] ?? 0) > 0)
      bars.add(_BarItem('Onderhoud', allCosts['maintenance']!, const Color(0xFFF59E0B)));

    for (int r = 0; r < provider.recurringCosts.length; r++) {
      final c = provider.recurringCosts[r];
      final val = (km > 0 && months > 0) ? (c.monthlyCost * months) / km : 0.0;
      if (val > 0) bars.add(_BarItem(c.name, val, fixedPalette[r % fixedPalette.length]));
    }

    if (bars.isEmpty) return const SizedBox();

    final total = bars.fold<double>(0, (s, b) => s + b.value);
    final maxVal = total; // schaal op totaal zodat totaalbalk 100% breed is

    return LayoutBuilder(builder: (context, constraints) {
      const barHeight = 20.0;
      const labelW    = 110.0;
      const valueW    = 56.0;
      const spacing   = 10.0;
      final appColor  = provider.themeColor;

      // Alle bars + scheidingslijn + totaalbalk
      final allRows = <Widget>[];

      for (int i = 0; i < bars.length; i++) {
        final bar = bars[i];
        final frac = (maxVal > 0) ? (bar.value / maxVal).clamp(0.0, 1.0) : 0.0;
        allRows.add(Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: _buildBar(context, bar.name, bar.value, frac, barHeight, labelW, valueW, bar.color),
        ));
      }

      // Scheidingslijn
      allRows.add(Padding(
        padding: const EdgeInsets.only(bottom: spacing),
        child: Row(children: [
          const SizedBox(width: labelW),
          Expanded(child: Divider(color: Theme.of(context).hintColor.withValues(alpha: 0.2), height: 1)),
          const SizedBox(width: valueW),
        ]),
      ));

      // Totaalbalk
      allRows.add(_buildBar(context, 'Totaal', total, 1.0, barHeight, labelW, valueW, appColor, bold: true));

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: allRows);
    });
  }

  Widget _buildBar(BuildContext context, String name, double value, double frac,
      double barHeight, double labelW, double valueW, Color color, {bool bold = false}) {
    return SizedBox(
      height: barHeight,
      child: Row(children: [
        SizedBox(
          width: labelW,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: bold ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Stack(alignment: Alignment.centerLeft, children: [
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: frac,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: bold ? 1.0 : 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(
          width: valueW,
          child: Text(
            '€${value.toStringAsFixed(3)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ]),
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
              Icon(
                Icons.payments_outlined,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Nog geen kosten gegevens',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
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
    
    // Get costs for both pages
    final latestCosts = sorted.length >= 2 
        ? _calculateAllCosts(provider, sorted.length - 2, sorted)
        : {'fuel': 0.0, 'maintenance': 0.0, 'subscriptions': 0.0};
    final allTimeCosts = _calculatePeriodAverageCosts(provider, sorted);

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
                onPageChanged: (index) => setState(() => _showLatest = index == 0),
                children: [
                  _buildMPage(context, latestCosts, 'Laatste', appColor, isDarkMode),
                  _buildMPage(context, allTimeCosts, 'Gemiddeld', appColor, isDarkMode),
                ],
              ),
            ),
            _buildPageIndicator(appColor),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMPage(BuildContext context, Map<String, double> costs, String label, Color appColor, bool isDarkMode) {
    final provider = context.read<DataProvider>();
    final km = costs['_km'] ?? 1.0;
    final months = costs['_months'] ?? 1.0;

    // Bereken per recurring cost de kosten per km
    final recurringCosts = provider.recurringCosts;
    final recurringPerKm = <String, double>{};
    double recurringTotal = 0;
    if (km > 0 && months > 0) {
      for (final c in recurringCosts) {
        final val = (c.monthlyCost * months) / km;
        recurringPerKm[c.name] = val;
        recurringTotal += val;
      }
    }

    final total = costs.entries
        .where((e) => !e.key.startsWith('_'))
        .fold<double>(0, (sum, e) => sum + e.value) + recurringTotal;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KOSTEN PER KM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: appColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chart with tooltip overlay
          Expanded(
            child: Stack(
              children: [
                // Centered donut
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            startDegreeOffset: -180, // 240 degrees = -180 (90 degrees counter-clockwise from -90)
                            sections: _buildMiniChartSections(costs, recurringCosts, recurringPerKm),
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                          ),
                          duration: Duration.zero,
                        ),
                        // Center total
                        Text(
                          '€${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appColor,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tooltip overlay at top-right (aligned with label)
                if (_touchedIndex != -1)
                  _buildTooltipOverlay(costs, recurringCosts, recurringPerKm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildMiniChartSections(Map<String, double> costs, List<dynamic> recurringCosts, Map<String, double> recurringPerKm) {
    const fixedPalette = [
      Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF6366F1),
    ];
    final sections = <PieChartSectionData>[];
    int currentIndex = 0;

    void add(Color color, double value) {
      if (value <= 0) return;
      final isTouched = currentIndex == _touchedIndex;
      sections.add(PieChartSectionData(
        color: color, value: value, title: '',
        radius: isTouched ? 17 : 15, showTitle: false,
      ));
      currentIndex++;
    }

    add(const Color(0xFFEF4444), costs['fuel'] ?? 0);
    add(const Color(0xFFF59E0B), costs['maintenance'] ?? 0);
    for (int r = 0; r < recurringCosts.length; r++) {
      add(fixedPalette[r % fixedPalette.length], recurringPerKm[recurringCosts[r].name] ?? 0);
    }

    return sections;
  }

  List<Map<String, dynamic>> _getMiniChartLabels(Map<String, double> costs, List<dynamic> recurringCosts, Map<String, double> recurringPerKm) {
    const fixedPalette = [
      Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF6366F1),
    ];
    final labels = <Map<String, dynamic>>[];

    if ((costs['fuel'] ?? 0) > 0)        labels.add({'name': 'Brandstof', 'value': costs['fuel']!,        'color': const Color(0xFFEF4444)});
    if ((costs['maintenance'] ?? 0) > 0) labels.add({'name': 'Onderhoud', 'value': costs['maintenance']!, 'color': const Color(0xFFF59E0B)});
    for (int r = 0; r < recurringCosts.length; r++) {
      final val = recurringPerKm[recurringCosts[r].name] ?? 0;
      if (val > 0) labels.add({'name': recurringCosts[r].name, 'value': val, 'color': fixedPalette[r % fixedPalette.length]});
    }

    return labels;
  }

  Widget _buildTooltipOverlay(Map<String, double> costs, List<dynamic> recurringCosts, Map<String, double> recurringPerKm) {
    final labels = _getMiniChartLabels(costs, recurringCosts, recurringPerKm);
    if (_touchedIndex < 0 || _touchedIndex >= labels.length) {
      return const SizedBox.shrink();
    }
    
    final label = labels[_touchedIndex];
    
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: label['color'],
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label['name'],
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '€${label['value']!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(Color appColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _showLatest ? appColor : appColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: !_showLatest ? appColor : appColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleSelector(BuildContext context, bool isDarkMode, Color appColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showLatest = true),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _showLatest ? appColor : Colors.transparent,
              shape: BoxShape.circle,
              border: _showLatest
                  ? null
                  : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '1',
              style: TextStyle(
                color: _showLatest ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _showLatest = false),
          child: Container(
            margin: const EdgeInsets.only(left: 0),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: !_showLatest ? appColor : Colors.transparent,
              shape: BoxShape.circle,
              border: !_showLatest
                  ? null
                  : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'All',
              style: TextStyle(
                color: !_showLatest ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(BuildContext context, IconData icon, String label, bool sel, bool dark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? (dark ? Colors.white : Colors.black) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor),
              const SizedBox(width: 3),
              Flexible(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.payments_outlined, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
      ),
    );
  }
}

class _BarItem {
  final String name;
  final double value;
  final Color color;
  const _BarItem(this.name, this.value, this.color);
}