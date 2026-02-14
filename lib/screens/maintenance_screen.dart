import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data_provider.dart';
import '../models/maintenance_entry.dart';

class MaintenanceScreen extends StatefulWidget {
  final bool isModal; // NIEUW: Om te weten of hij in een popup zit
  const MaintenanceScreen({super.key, this.isModal = false});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _filter = 'Dit Jaar';

  double _parseInput(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

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
    final dateFormat = DateFormat('dd-MM-yy');

    List<MaintenanceEntry> filteredEntries = List.from(provider.maintenanceEntries);
    if (_filter == 'Dit Jaar') {
      final now = DateTime.now();
      filteredEntries = filteredEntries.where((e) => e.date.year == now.year).toList();
    }
    filteredEntries.sort((a, b) => b.date.compareTo(a.date));

    double totalCost = filteredEntries.fold(0, (sum, e) => sum + e.cost);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Onderhoud', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        automaticallyImplyLeading: !widget.isModal, // Geen back button als het een modal is
        actions: [
          if (widget.isModal)
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          // SUMMARY HEADER
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(children: [
                      const Text('Totaal Onderhoud', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('€ ${totalCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                    ]),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(child: Text('Geen onderhoud gevonden.'))
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
                              CustomSlidableAction(onPressed: (_) => _showMaintenanceDialog(context, provider, entry: entry), backgroundColor: Colors.transparent, child: _slideIcon(Colors.orange, Icons.edit)),
                              CustomSlidableAction(onPressed: (_) => provider.deleteMaintenance(entry.id!), backgroundColor: Colors.transparent, child: _slideIcon(Colors.red, Icons.delete)),
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
                                leading: Icon(Icons.build_circle_outlined, color: appColor),
                                title: Text(entry.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${dateFormat.format(entry.date)} • ${entry.description}'),
                                trailing: Text('€${entry.cost.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: appColor)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMaintenanceDialog(context, provider),
        backgroundColor: appColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _slideIcon(Color c, IconData i) => Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(i, color: c, size: 20));

  void _showMaintenanceDialog(BuildContext context, DataProvider provider, {MaintenanceEntry? entry}) {
    final desc = TextEditingController(text: entry?.description);
    final cost = TextEditingController(text: entry?.cost.toString().replaceAll('.', ','));
    final km = TextEditingController(text: entry?.odometer.toString().replaceAll('.', ','));
    String type = entry?.type ?? 'Beurt';
    DateTime date = entry?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(entry == null ? 'Onderhoud toevoegen' : 'Aanpassen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: ['Beurt', 'Reparatie', 'Banden', 'APK', 'Overig'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Beschrijving')),
                TextField(controller: km, decoration: const InputDecoration(labelText: 'KM-stand'), keyboardType: TextInputType.number),
                TextField(controller: cost, decoration: const InputDecoration(labelText: 'Kosten'), keyboardType: TextInputType.number),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Datum'),
                  subtitle: Text(DateFormat('dd-MM-yyyy').format(date)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d != null) setDialogState(() => date = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
            ElevatedButton(
              onPressed: () {
                final newEntry = MaintenanceEntry(
                  id: entry?.id, carId: provider.selectedCar!.id!, date: date, odometer: _parseInput(km.text), type: type, description: desc.text, cost: _parseInput(cost.text),
                );
                entry == null ? provider.addMaintenance(newEntry) : provider.updateMaintenance(newEntry);
                Navigator.pop(context);
              },
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );
  }
}