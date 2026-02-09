import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data_provider.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  BoxBorder? _getBorder(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape;
    if (shape is RoundedRectangleBorder && shape.side != BorderSide.none) {
      return Border.fromBorderSide(shape.side);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final Color appColor = provider.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 24), 
            onPressed: () => _showHistoryModal(context),
          ),
          if (provider.cars.length > 1)
            IconButton(
              icon: Icon(Icons.directions_car, color: appColor), 
              onPressed: () => _showVehicleSelector(context, provider)
            ),
          const SizedBox(width: 24),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Begroeting is hier weggehaald
            _buildDonutCard(context, provider, appColor),
            const SizedBox(height: 32),
            const Text('Verbruikstrend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLineChart(context, provider, appColor),
          ],
        ),
      ),
    );
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            child: HistoryScreen(isModal: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutCard(BuildContext context, DataProvider provider, Color mainColor) {
    final fuel = provider.monthlyFuelCost;
    final tax = provider.monthlyRoadTax;
    final insurance = provider.monthlyInsurance;
    final total = fuel + tax + insurance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: _getBorder(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 120, width: 120,
                child: PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 35, sections: [
                  PieChartSectionData(value: fuel > 0 ? fuel : 0.1, color: mainColor, radius: 15, showTitle: false),
                  PieChartSectionData(value: tax > 0 ? tax : 0.1, color: Colors.blueAccent, radius: 15, showTitle: false),
                  PieChartSectionData(value: insurance > 0 ? insurance : 0.1, color: Colors.orangeAccent, radius: 15, showTitle: false),
                ])),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAAL PER MAAND', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text('€${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 16),
          _indicator('Brandstof', '€${fuel.toStringAsFixed(0)}', mainColor),
          _indicator('Wegenbelasting', '€${tax.toStringAsFixed(0)}', Colors.blueAccent),
          _indicator('Verzekering', '€${insurance.toStringAsFixed(0)}', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _indicator(String label, String val, Color col) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildLineChart(BuildContext context, DataProvider p, Color col) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: _getBorder(context),
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: p.entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.liters)).toList(),
            isCurved: true, color: col, barWidth: 4, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: col.withAlpha(30)),
          )
        ],
      )),
    );
  }

  void _showVehicleSelector(BuildContext context, DataProvider provider) {
    final Color appColor = provider.themeColor;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => ListView(
        padding: const EdgeInsets.all(24),
        children: provider.cars.map((c) => ListTile(
          leading: Icon(Icons.directions_car, color: appColor),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () { provider.selectCar(c); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }
}