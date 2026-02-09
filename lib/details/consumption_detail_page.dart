import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data_provider.dart';
import '../models/fuel_entry.dart';

class ConsumptionDetailPage extends StatelessWidget {
  const ConsumptionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final car = provider.selectedCar;
    const Color mintGreen = Color(0xFF00D09E);
    
    // Beveiliging: als er geen auto is, toon een melding
    if (car == null) return const Scaffold(body: Center(child: Text('Geen voertuig geselecteerd')));

    final entries = provider.getEntriesForCar(car.id!);
    final avgConsumption = _calculateAverage(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Brandstofverbruik'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, avgConsumption),
            const SizedBox(height: 32),
            Text('Verbruik over tijd', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildChartCard(context, entries, mintGreen),
            const SizedBox(height: 32),
            _buildStatsList(context, entries),
          ],
        ),
      ),
    );
  }

  double _calculateAverage(List<FuelEntry> entries) {
    if (entries.length < 2) return 0.0;
    final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.odometer.compareTo(b.odometer));
    double totalKm = sorted.last.odometer - sorted.first.odometer;
    double totalLiters = sorted.skip(1).fold(0.0, (sum, e) => sum + e.liters);
    return totalKm == 0 ? 0.0 : (totalLiters / totalKm) * 100;
  }

  Widget _buildHeaderCard(BuildContext context, double avg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00D09E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gemiddeld verbruik', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(width: 8),
              const Text('L/100km', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<FuelEntry> entries, Color col) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.liters / (e.value.odometer / 1000))).toList(),
              isCurved: true,
              color: col,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: col.withAlpha(30)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsList(BuildContext context, List<FuelEntry> entries) {
    return Column(
      children: entries.take(5).map((e) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${(e.liters / (e.odometer / 1000)).toStringAsFixed(1)} L/100km'),
        subtitle: Text('KM-stand: ${e.odometer.toInt()}'),
        trailing: const Icon(Icons.chevron_right),
      )).toList(),
    );
  }
}