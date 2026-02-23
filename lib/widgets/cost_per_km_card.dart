// KOSTEN PER KM CARD
// Shows stacked cost per kilometer with all expense categories

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class CostPerKmCard extends StatelessWidget {
  final Color appColor;
  final bool isDarkMode;
  
  const CostPerKmCard({
    super.key,
    required this.appColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final entries = provider.entries;
    final maintenanceEntries = provider.maintenanceEntries;
    final car = provider.selectedCar;
    
    if (entries.length < 2 || car == null) {
      return _buildEmptyState(context);
    }
    
    final sortedEntries = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    final firstEntry = sortedEntries.first;
    final lastEntry = sortedEntries.last;
    final totalKm = (lastEntry.odometer - firstEntry.odometer).abs();
    
    if (totalKm == 0) {
      return _buildEmptyState(context);
    }
    
    // Calculate days driven
    final daysDriven = lastEntry.date.difference(firstEntry.date).inDays;
    if (daysDriven == 0) {
      return _buildEmptyState(context);
    }
    
    // Total costs
    final totalFuelCost = sortedEntries.map((e) => e.priceTotal).reduce((a, b) => a + b);
    final totalMaintenanceCost = maintenanceEntries.map((e) => e.cost).fold(0.0, (a, b) => a + b);
    
    // Yearly costs to per-km (prorated)
    final yearsElapsed = daysDriven / 365.0;
    final insuranceCostTotal = car.insurance * yearsElapsed;
    final roadTaxCostTotal = _calculateRoadTaxTotal(car.roadTax, car.roadTaxFreq, yearsElapsed);
    
    final totalCost = totalFuelCost + totalMaintenanceCost + insuranceCostTotal + roadTaxCostTotal;
    
    // Per km breakdown
    final fuelCostPerKm = totalFuelCost / totalKm;
    final maintenanceCostPerKm = totalMaintenanceCost / totalKm;
    final insuranceCostPerKm = insuranceCostTotal / totalKm;
    final roadTaxCostPerKm = roadTaxCostTotal / totalKm;
    final totalCostPerKm = totalCost / totalKm;
    
    // Build stacked line data
    final trendData = _buildTrendData(sortedEntries, maintenanceEntries, car, yearsElapsed, totalKm);
    
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
              Text(
                "KOSTEN PER KM",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: Column(
                  children: [
                    Text(
                      '€${totalCostPerKm.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: appColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per kilometer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stacked line chart
              if (trendData.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
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
                                  fontSize: 9,
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
                      lineBarsData: [
                        // Line 1: Fuel only
                        LineChartBarData(
                          spots: trendData.map((d) => FlSpot(d.x, d.fuel)).toList(),
                          isCurved: true,
                          color: appColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: appColor.withValues(alpha: 0.3),
                          ),
                        ),
                        // Line 2: Fuel + Maintenance
                        if (maintenanceCostPerKm > 0)
                          LineChartBarData(
                            spots: trendData.map((d) => FlSpot(d.x, d.fuelPlusMaintenance)).toList(),
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.orange.withValues(alpha: 0.2),
                            ),
                          ),
                        // Line 3: + Insurance
                        if (insuranceCostPerKm > 0)
                          LineChartBarData(
                            spots: trendData.map((d) => FlSpot(d.x, d.fuelPlusMaintenancePlusInsurance)).toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withValues(alpha: 0.15),
                            ),
                          ),
                        // Line 4: Total (+ Road Tax)
                        if (roadTaxCostPerKm > 0)
                          LineChartBarData(
                            spots: trendData.map((d) => FlSpot(d.x, d.total)).toList(),
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.purple.withValues(alpha: 0.1),
                            ),
                          ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendItem(appColor, 'Brandstof'),
                  if (maintenanceCostPerKm > 0) _buildLegendItem(Colors.orange, 'Onderhoud'),
                  if (insuranceCostPerKm > 0) _buildLegendItem(Colors.blue, 'Verzekering'),
                  if (roadTaxCostPerKm > 0) _buildLegendItem(Colors.purple, 'Wegenbelasting'),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Info summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🚗 Totaal Gereden',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                        Text(
                          '${NumberFormat('#,###', 'nl_NL').format(totalKm.round())} km',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💰 Totaal Uitgegeven',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                        Text(
                          '€${NumberFormat('#,###', 'nl_NL').format(totalCost.round())}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📅 Vanaf',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(firstEntry.date),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Breakdown
              Column(
                children: [
                  _buildBreakdownItem(context, '⛽ Brandstof', '€${fuelCostPerKm.toStringAsFixed(3)}/km', appColor),
                  if (maintenanceCostPerKm > 0) ...[
                    const SizedBox(height: 8),
                    _buildBreakdownItem(context, '🔧 Onderhoud', '€${maintenanceCostPerKm.toStringAsFixed(3)}/km', Colors.orange),
                  ],
                  if (insuranceCostPerKm > 0) ...[
                    const SizedBox(height: 8),
                    _buildBreakdownItem(context, '🛡️ Verzekering', '€${insuranceCostPerKm.toStringAsFixed(3)}/km', Colors.blue),
                  ],
                  if (roadTaxCostPerKm > 0) ...[
                    const SizedBox(height: 8),
                    _buildBreakdownItem(context, '🚦 Wegenbelasting', '€${roadTaxCostPerKm.toStringAsFixed(3)}/km', Colors.purple),
                  ],
                ],
              ),
            ],
          ),
      ),
    );
  }
  
  double _calculateRoadTaxTotal(double amount, String freq, double yearsElapsed) {
    switch (freq.toLowerCase()) {
      case 'yearly':
        return amount * yearsElapsed;
      case 'quarterly':
        return amount * 4 * yearsElapsed;
      case 'monthly':
        return amount * 12 * yearsElapsed;
      default:
        return 0;
    }
  }
  
  List<_TrendDataPoint> _buildTrendData(List entries, List maintenanceEntries, car, double yearsElapsed, double totalKm) {
    final data = <_TrendDataPoint>[];
    double cumulativeFuelCost = 0;
    double cumulativeMaintCost = 0;
    double cumulativeDistance = 0;
    
    for (int i = 0; i < entries.length; i++) {
      cumulativeFuelCost += entries[i].priceTotal;
      
      if (i > 0) {
        final distance = (entries[i].odometer - entries[i - 1].odometer).abs();
        cumulativeDistance += distance;
        
        if (cumulativeDistance > 0) {
          // Calculate cumulative maintenance up to this point
          cumulativeMaintCost = maintenanceEntries
              .where((m) => m.date.isBefore(entries[i].date) || m.date.isAtSameMomentAs(entries[i].date))
              .fold(0.0, (sum, m) => sum + m.cost);
          
          final fuelPerKm = cumulativeFuelCost / cumulativeDistance;
          final maintPerKm = cumulativeMaintCost / cumulativeDistance;
          final insurancePerKm = (car.insurance * yearsElapsed) / totalKm;
          final taxPerKm = _calculateRoadTaxTotal(car.roadTax, car.roadTaxFreq, yearsElapsed) / totalKm;
          
          data.add(_TrendDataPoint(
            x: i.toDouble(),
            fuel: fuelPerKm,
            fuelPlusMaintenance: fuelPerKm + maintPerKm,
            fuelPlusMaintenancePlusInsurance: fuelPerKm + maintPerKm + insurancePerKm,
            total: fuelPerKm + maintPerKm + insurancePerKm + taxPerKm,
          ));
        }
      }
    }
    
    return data;
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Minimaal 2 tankbeurten nodig',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voeg meer tankbeurten toe om kosten te berekenen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
    );
  }
  
  Widget _buildBreakdownItem(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _TrendDataPoint {
  final double x;
  final double fuel;
  final double fuelPlusMaintenance;
  final double fuelPlusMaintenancePlusInsurance;
  final double total;
  
  _TrendDataPoint({
    required this.x,
    required this.fuel,
    required this.fuelPlusMaintenance,
    required this.fuelPlusMaintenancePlusInsurance,
    required this.total,
  });
}