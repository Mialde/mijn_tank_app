import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data_provider.dart';
import '../models/fuel_entry.dart';

class HistoryScreen extends StatefulWidget {
  final bool isModal;
  const HistoryScreen({super.key, this.isModal = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Dit Jaar';

  BoxBorder? _getBorder(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape;
    if (shape is RoundedRectangleBorder && shape.side != BorderSide.none) {
      return Border.fromBorderSide(shape.side);
    }
    return null;
  }

  double _parseInput(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final Color appColor = provider.themeColor; // Dynamische kleur
    final dateFormat = DateFormat('dd-MM-yy');

    List<FuelEntry> filteredEntries = List.from(provider.entries);
    if (_filter == 'Dit Jaar') {
      final now = DateTime.now();
      filteredEntries = filteredEntries.where((e) => e.date.year == now.year).toList();
    }
    filteredEntries.sort((a, b) => b.date.compareTo(a.date));

    double totalKm = 0, totalLiters = 0, totalCost = 0;
    if (filteredEntries.isNotEmpty) {
      double maxOdo = filteredEntries.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
      double minOdo = filteredEntries.map((e) => e.odometer).reduce((a, b) => a < b ? a : b);
      totalKm = maxOdo - minOdo;
      totalLiters = filteredEntries.fold(0, (sum, e) => sum + e.liters);
      totalCost = filteredEntries.fold(0, (sum, e) => sum + e.priceTotal);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historie', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                if (widget.isModal)
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: appColor, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overzicht', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        dropdownColor: appColor,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: ['Dit Jaar', 'Alles'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() => _filter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _headerItem('Afstand', '${totalKm.toInt()} km'),
                    _headerItem('Liters', '${totalLiters.toInt()} L'),
                    _headerItem('Kosten', '€${totalCost.toInt()}'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(child: Text('Geen tankbeurten gevonden.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Slidable(
                          key: ValueKey(entry.id),
                          endActionPane: ActionPane(
                            extentRatio: 0.45,
                            motion: const BehindMotion(),
                            children: [
                              CustomSlidableAction(onPressed: (_) => _showEditDialog(context, provider, entry), backgroundColor: Colors.transparent, child: _slideIcon(Colors.orange, Icons.edit)),
                              CustomSlidableAction(onPressed: (_) => provider.deleteFuelEntry(entry.id!), backgroundColor: Colors.transparent, child: _slideIcon(Colors.red, Icons.delete)),
                            ],
                          ),
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              border: _getBorder(context),
                            ),
                            child: Center(
                              child: ListTile(
                                visualDensity: VisualDensity.compact,
                                leading: Icon(Icons.local_gas_station, color: appColor),
                                title: Text(dateFormat.format(entry.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${entry.liters.toStringAsFixed(1)}L • €${entry.priceTotal.toStringAsFixed(1)}'),
                                trailing: Text('€${entry.priceTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: appColor)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerItem(String label, String value) => Column(children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]);
  Widget _slideIcon(Color c, IconData i) => Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withAlpha(50), shape: BoxShape.circle), child: Icon(i, color: c, size: 20));

  void _showEditDialog(BuildContext context, DataProvider provider, FuelEntry entry) {
    final odo = TextEditingController(text: entry.odometer.toString().replaceAll('.', ','));
    final liters = TextEditingController(text: entry.liters.toString().replaceAll('.', ','));
    final price = TextEditingController(text: entry.priceTotal.toString().replaceAll('.', ','));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aanpassen'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: odo, decoration: const InputDecoration(labelText: 'KM')),
          TextField(controller: liters, decoration: const InputDecoration(labelText: 'Liters')),
          TextField(controller: price, decoration: const InputDecoration(labelText: 'Totaal (€)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
          ElevatedButton(onPressed: () {
            provider.updateFuelEntry(FuelEntry(id: entry.id, carId: entry.carId, date: entry.date, odometer: _parseInput(odo.text), liters: _parseInput(liters.text), priceTotal: _parseInput(price.text), pricePerLiter: 0));
            Navigator.pop(context);
          }, child: const Text('Opslaan')),
        ],
      ),
    );
  }
}