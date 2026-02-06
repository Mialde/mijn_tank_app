import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../widgets/stats_carousel.dart';
import '../widgets/tco_stacked_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selCarId;

  void _showCarPicker(BuildContext context, DataProvider data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
            ),
            const SizedBox(height: 20),
            const Text("Selecteer Voertuig", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // FIX: .toList() verwijderd voor betere performance in spreads
            ...data.cars.map((carItem) {
              bool isSelected = carItem.id == _selCarId;
              return ListTile(
                leading: Icon(Icons.directions_car_filled, color: isSelected ? Colors.blueAccent : Colors.grey),
                title: Text(carItem.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                onTap: () {
                  setState(() => _selCarId = carItem.id);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selCarId == null && data.cars.isNotEmpty) {
      _selCarId = data.cars.first.id;
    }

    final entries = data.getEntriesForCar(_selCarId);
    // FIX: Variabele naam 'car' gedefinieerd voor gebruik in widgets hieronder
    final car = data.cars.firstWhere((c) => c.id == _selCarId, orElse: () => Car(name: "Geen auto"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              avatar: const Icon(Icons.directions_car_filled, size: 16, color: Colors.blueAccent),
              label: Text(car.name),
              onPressed: () => _showCarPicker(context, data),
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          StatsCarousel(entries: entries, isDark: isDark),
          TcoStackedChart(
            entries: entries,
            car: car,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}