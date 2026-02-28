// FLAT MAINTENANCE LINE - Based on latest tankbeurt
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
  
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  double _getMaintenanceOdometer(dynamic maintenance, List<dynamic> sortedEntries) {
    if (maintenance.odometer > 0) {
      return maintenance.odometer.toDouble();
    }
    
    final maintenanceDate = maintenance.date;
    final entriesBefore = sortedEntries.where((e) => e.date.isBefore(maintenanceDate)).toList();
    final entriesAfter = sortedEntries.where((e) => e.date.isAfter(maintenanceDate)).toList();
    
    if (entriesBefore.isEmpty) {
      return sortedEntries.first.odometer.toDouble();
    }
    
    if (entriesAfter.isEmpty) {
      return sortedEntries.last.odometer.toDouble();
    }
    
    final before = entriesBefore.last;
    final after = entriesAfter.first;
    
    final totalDays = after.date.difference(before.date).inDays;
    final daysFromBefore = maintenanceDate.difference(before.date).inDays;
    
    if (totalDays <= 0) {
      return before.odometer.toDouble();
    }
    
    final percentage = daysFromBefore / totalDays;
    final kmDiff = after.odometer - before.odometer;
    final estimatedOdo = before.odometer + (kmDiff * percentage);
    
    return estimatedOdo.toDouble();
  }

  Map<String, double> _calculateAllCosts(DataProvider provider, int entryIndex) {
    final entries = provider.entries;
    if (entryIndex >= entries.length - 1) {
      return {'fuel': 0, 'insurance': 0, 'roadTax': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final current = sorted[entryIndex];
    final next = sorted[entryIndex + 1];
    final km = (next.odometer - current.odometer).abs();
    
    if (km <= 0) {
      return {'fuel': 0, 'insurance': 0, 'roadTax': 0, 'maintenance': 0, 'subscriptions': 0};
    }
    
    final car = provider.selectedCar;
    final monthsInPeriod = (next.date.difference(current.date).inDays / 30).clamp(0.1, 999).toDouble();
    
    final fuelCost = current.priceTotal / km;
    final insuranceCost = car != null ? (car.insurance * monthsInPeriod) / km : 0.0;
    
    double roadTaxMonthly = 0;
    if (car != null) {
      switch (car.roadTaxFreq.toLowerCase()) {
        case 'yearly':
        case 'jaarlijks':
          roadTaxMonthly = car.roadTax / 12;
          break;
        case 'quarterly':
        case 'per kwartaal':
        case 'kwartaal':
          roadTaxMonthly = car.roadTax / 3;
          break;
        default:
          roadTaxMonthly = car.roadTax;
      }
    }
    final roadTaxCost = (roadTaxMonthly * monthsInPeriod) / km;
    
    // Calculate maintenance based on LAST entry
    final lastEntry = sorted.last;
    final maintenanceBeforeLast = provider.maintenanceEntries.where((m) => 
      m.date.isBefore(lastEntry.date) || m.date.isAtSameMomentAs(lastEntry.date)
    ).toList();

    double maintenanceCost = 0;
    if (maintenanceBeforeLast.isNotEmpty) {
      final totalMaintenanceCost = maintenanceBeforeLast.fold<double>(0, (sum, m) => sum + m.cost);
      final firstMaintenance = maintenanceBeforeLast.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      final startOdometer = _getMaintenanceOdometer(firstMaintenance, sorted);
      final kmSinceMaintenance = lastEntry.odometer - startOdometer;
      
      if (kmSinceMaintenance > 0) {
        final globalMaintenanceCost = totalMaintenanceCost / kmSinceMaintenance;
        
        // Check if maintenance happened before THIS trip
        final hasMaintenanceBeforeThis = provider.maintenanceEntries.any((m) => 
          m.date.isBefore(current.date) || m.date.isAtSameMomentAs(current.date)
        );
        
        maintenanceCost = hasMaintenanceBeforeThis ? globalMaintenanceCost : 0.0;
      }
    }
    
    // Calculate subscriptions - FLAT rate over entire period
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
      'insurance': insuranceCost,
      'roadTax': roadTaxCost,
      'maintenance': maintenanceCost,
      'subscriptions': subscriptionCost,
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
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    final costData = <FlSpot>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];
      final km = (next.odometer - current.odometer).abs();
      final cost = current.liters * current.pricePerLiter;
      final costPerKm = km > 0 ? (cost / km).toDouble() : 0.0;
      costData.add(FlSpot(i.toDouble(), costPerKm));
    }
    
    if (costData.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final allCosts = _calculateAllCosts(provider, sorted.length - 2);
    final totalCostPerKm = allCosts.values.fold<double>(0, (sum, v) => sum + v);
    
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: appColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Totaal: €${totalCostPerKm.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildChart(context, costData, appColor, isDarkMode),
            ),
            const SizedBox(height: 16),
            _buildBreakdown(context, allCosts),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(BuildContext context, Map<String, double> costs) {
    final items = <Widget>[];
    
    if (costs['fuel']! > 0) {
      items.add(_buildBreakdownRow('Brandstof', costs['fuel']!, const Color(0xFFEF4444)));
    }
    if (costs['insurance']! > 0) {
      items.add(_buildBreakdownRow('Verzekering', costs['insurance']!, const Color(0xFF3B82F6)));
    }
    if (costs['roadTax']! > 0) {
      items.add(_buildBreakdownRow('Wegenbelasting', costs['roadTax']!, const Color(0xFF10B981)));
    }
    if (costs['maintenance']! > 0) {
      items.add(_buildBreakdownRow('Onderhoud', costs['maintenance']!, const Color(0xFFF59E0B)));
    }
    if (costs['subscriptions']! > 0) {
      items.add(_buildBreakdownRow('Abonnementen', costs['subscriptions']!, const Color(0xFF8B5CF6)));
    }
    
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
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

  Widget _buildChart(BuildContext context, List<FlSpot> data, Color appColor, bool isDarkMode) {
    final provider = context.watch<DataProvider>();
    final entries = provider.entries;
    
    if (entries.isEmpty) return const SizedBox();
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final car = provider.selectedCar;
    
    // PRE-CALCULATE flat costs based on LAST entry
    double globalMaintenanceCost = 0;
    double globalSubscriptionCost = 0;
    
    final lastEntry = sorted.last;
    
    // Maintenance calculation
    final maintenanceBeforeLast = provider.maintenanceEntries.where((m) => 
      m.date.isBefore(lastEntry.date) || m.date.isAtSameMomentAs(lastEntry.date)
    ).toList();

    if (maintenanceBeforeLast.isNotEmpty) {
      final totalMaintenanceCost = maintenanceBeforeLast.fold<double>(0, (sum, m) => sum + m.cost);
      final firstMaintenance = maintenanceBeforeLast.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
      final startOdometer = _getMaintenanceOdometer(firstMaintenance, sorted);
      final kmSinceMaintenance = lastEntry.odometer - startOdometer;
      
      if (kmSinceMaintenance > 0) {
        globalMaintenanceCost = totalMaintenanceCost / kmSinceMaintenance;
      }
    }
    
    // Subscriptions calculation - flat rate over entire period
    if (provider.recurringCosts.isNotEmpty && sorted.length >= 2) {
      final totalMonthlySubscriptions = provider.recurringCosts.fold<double>(0, (sum, s) => sum + s.monthlyCost);
      final firstEntry = sorted.first;
      final totalDays = lastEntry.date.difference(firstEntry.date).inDays;
      final totalMonths = totalDays / 30;
      final totalKm = lastEntry.odometer - firstEntry.odometer;
      
      if (totalKm > 0 && totalMonths > 0) {
        globalSubscriptionCost = (totalMonthlySubscriptions * totalMonths) / totalKm;
      }
    }
    
    final List<FlSpot> fuelSpots = [];
    final List<FlSpot> insuranceSpots = [];
    final List<FlSpot> taxSpots = [];
    final List<FlSpot> maintenanceSpots = [];
    final List<FlSpot> subscriptionSpots = [];
    
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];
      final km = (next.odometer - current.odometer).abs();
      
      if (km > 0) {
        final x = i.toDouble();
        final monthsInPeriod = (next.date.difference(current.date).inDays / 30).clamp(0.1, 999).toDouble();
        
        final fuelCost = current.priceTotal / km;
        final insuranceCost = car != null ? (car.insurance * monthsInPeriod) / km : 0.0;
        
        double roadTaxMonthly = 0;
        if (car != null) {
          switch (car.roadTaxFreq.toLowerCase()) {
            case 'yearly':
            case 'jaarlijks':
              roadTaxMonthly = car.roadTax / 12;
              break;
            case 'quarterly':
            case 'per kwartaal':
            case 'kwartaal':
              roadTaxMonthly = car.roadTax / 3;
              break;
            default:
              roadTaxMonthly = car.roadTax;
          }
        }
        final taxCost = (roadTaxMonthly * monthsInPeriod) / km;
        
        // Use FLAT maintenance cost
        final hasMaintenanceBeforeThis = provider.maintenanceEntries.any((m) => 
          m.date.isBefore(current.date) || m.date.isAtSameMomentAs(current.date)
        );
        final maintenanceCost = hasMaintenanceBeforeThis ? globalMaintenanceCost : 0.0;
        
        // Use FLAT subscription cost (always on)
        final subscriptionCost = globalSubscriptionCost;
        
        fuelSpots.add(FlSpot(x, fuelCost));
        insuranceSpots.add(FlSpot(x, fuelCost + insuranceCost));
        taxSpots.add(FlSpot(x, fuelCost + insuranceCost + taxCost));
        maintenanceSpots.add(FlSpot(x, fuelCost + insuranceCost + taxCost + maintenanceCost));
        subscriptionSpots.add(FlSpot(x, fuelCost + insuranceCost + taxCost + maintenanceCost + subscriptionCost));
      }
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.02,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '€${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            left: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          // Layer 5: Subscriptions (purple - top)
          LineChartBarData(
            spots: subscriptionSpots,
            isCurved: true,
            color: const Color(0xFF8B5CF6),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            ),
          ),
          // Layer 4: Maintenance (orange)
          LineChartBarData(
            spots: maintenanceSpots,
            isCurved: true,
            color: const Color(0xFFF59E0B),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            ),
          ),
          // Layer 3: Road Tax (green)
          LineChartBarData(
            spots: taxSpots,
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
            ),
          ),
          // Layer 2: Insurance (blue)
          LineChartBarData(
            spots: insuranceSpots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            ),
          ),
          // Layer 1: Fuel (red - bottom)
          LineChartBarData(
            spots: fuelSpots,
            isCurved: true,
            color: const Color(0xFFEF4444),
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            ),
          ),
        ],
        minY: 0,
      ),
      duration: Duration.zero,
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
    double latest = 0, avg = 0;
    if (sorted.length >= 2) {
      final last = sorted.last;
      final prev = sorted[sorted.length - 2];
      final km = (last.odometer - prev.odometer).abs();
      final cost = prev.liters * prev.pricePerLiter;
      latest = km > 0 ? (cost / km) : 0;
    }
    final totalKm = sorted.last.odometer - sorted.first.odometer;
    final totalCost = entries.fold<double>(0, (s, e) => s + (e.liters * e.pricePerLiter));
    avg = totalKm > 0 ? (totalCost / totalKm) : 0;
    
    final val = _showLatest ? latest : avg;
    final lbl = _showLatest ? 'laatste rit' : 'gemiddeld';

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, color: appColor, size: 40),
            const SizedBox(height: 12),
            Text('€${val.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: appColor, height: 1.0)),
            const SizedBox(height: 2),
            Text('per km $lbl', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
            const Spacer(),
            _buildSelector(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(context, Icons.refresh, 'Laatste', _showLatest, isDarkMode, () => setState(() => _showLatest = true)),
          _buildBtn(context, Icons.show_chart, 'Gem.', !_showLatest, isDarkMode, () => setState(() => _showLatest = false)),
        ],
      ),
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