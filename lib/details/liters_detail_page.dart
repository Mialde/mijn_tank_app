import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data_provider.dart';

class LitersDetailPage extends StatelessWidget {
  const LitersDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final car = provider.selectedCar;
    const Color mintGreen = Color(0xFF00D09E);

    if (car == null) return const Scaffold(body: Center(child: Text('Geen voertuig geselecteerd')));
    final entries = provider.getEntriesForCar(car.id!);
    final totalLiters = entries.fold(0.0, (sum, e) => sum + e.liters);

    return Scaffold(
      appBar: AppBar(title: const Text('Getankte Liters'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, totalLiters),
            const SizedBox(height: 32),
            Text('Liter historie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildBarChart(context, entries, mintGreen),
            const SizedBox(height: 32),
            _buildSimpleList(entries),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Totaal getankt (all-time)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${total.toStringAsFixed(1)} Liter', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<dynamic> entries, Color col) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(toY: e.value.liters, color: col, width: 16, borderRadius: BorderRadius.circular(4))],
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSimpleList(List<dynamic> entries) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final e = entries[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${e.liters.toStringAsFixed(2)} Liter'),
          subtitle: Text('Prijs: €${e.priceTotal.toStringAsFixed(2)}'),
          trailing: const Icon(Icons.local_gas_station, color: Color(0xFF00D09E)),
        );
      },
    );
  }
}