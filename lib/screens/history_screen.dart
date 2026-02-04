import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../services/database_helper.dart';

class HistoryPage extends StatelessWidget {
  final int? carId;
  const HistoryPage({super.key, this.carId});
  
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final entries = data.getEntriesForCar(carId);
    
    return Scaffold(
        appBar: AppBar(title: const Text("Geschiedenis")),
        body: entries.isEmpty
            ? const Center(child: Text("Geen tankbeurten gevonden."))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.local_gas_station, color: Colors.white, size: 20)),
                    title: Text("€${entries[i]['price_total']}  -  ${entries[i]['liters']} L"),
                    subtitle: Text("${entries[i]['date'].substring(0, 10)} | KM: ${entries[i]['odometer']}"),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => DatabaseHelper.instance.deleteEntry(entries[i]['id']).then((_) => data.loadData())))));
  }
}