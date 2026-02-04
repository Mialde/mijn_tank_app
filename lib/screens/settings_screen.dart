import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onEasterEgg;
  const SettingsScreen({super.key, required this.onEasterEgg});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _clicks = 0;
  
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final user = data.user;
    
    Widget buildToggle(int value, Function(int) onChanged) {
      return SizedBox(
        width: 100, 
        child: SegmentedButton<int>(
          showSelectedIcon: false, 
          style: ButtonStyle(
            visualDensity: VisualDensity.compact, 
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
            padding: WidgetStateProperty.all(EdgeInsets.zero)
          ), 
          segments: const [
            ButtonSegment(value: 0, label: Text("O", style: TextStyle(fontWeight: FontWeight.bold))), 
            ButtonSegment(value: 1, label: Text("I", style: TextStyle(fontWeight: FontWeight.bold)))
          ], 
          selected: {value}, 
          onSelectionChanged: (Set<int> newSelection) => onChanged(newSelection.first)
        )
      );
    }

    return SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 20), 
                      _section("Personalisatie"),
                      ListTile(title: const Text("Naam aanpassen"), subtitle: Text(user['first_name'] ?? "Bestuurder"), leading: const Icon(Icons.person_outline, color: Colors.blueAccent), onTap: () => _nameDlg(context, data)),
                      ListTile(title: const Text("Begroeting"), leading: const Icon(Icons.waving_hand_outlined, color: Colors.blueAccent), trailing: buildToggle(user['use_greeting'] ?? 1, (v) => data.updateUserSettings({'use_greeting': v}))),
                      ListTile(title: const Text("Quotes"), leading: const Icon(Icons.format_quote_outlined, color: Colors.blueAccent), trailing: buildToggle(user['show_quotes'] ?? 1, (v) => data.updateUserSettings({'show_quotes': v}))),
                      ListTile(title: const Text("Thema"), leading: const Icon(Icons.palette_outlined, color: Colors.blueAccent), trailing: SizedBox(width: 150, child: SegmentedButton<String>(showSelectedIcon: false, style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: WidgetStateProperty.all(EdgeInsets.zero)), segments: const [ButtonSegment(value: 'light', icon: Icon(Icons.wb_sunny_outlined, size: 20)), ButtonSegment(value: 'dark', icon: Icon(Icons.nightlight_round_outlined, size: 20)), ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto, size: 20))], selected: {user['theme_mode'] ?? 'system'}, onSelectionChanged: (Set<String> newSelection) => data.updateUserSettings({'theme_mode': newSelection.first})))) ,
                      const SizedBox(height: 24),
                      _section("Garage"),
                      ListTile(title: const Text("Voertuig beheer"), subtitle: const Text("Toevoegen, wijzigen en verwijderen"), leading: const Icon(Icons.directions_car_outlined, color: Colors.blueAccent), trailing: const Icon(Icons.chevron_right), onTap: () => _manageCars(context, data)),
                      const SizedBox(height: 24),
                      _section("Systeem"),
                      ListTile(title: const Text("Backup maken"), subtitle: const Text("Lokaal of Delen"), leading: const Icon(Icons.upload_file, color: Colors.blueAccent), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.save, color: Colors.blueAccent), tooltip: "Lokaal opslaan", onPressed: () async { await data.saveLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup lokaal opgeslagen!"))); } }), IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Delen / Exporteren", onPressed: () => data.exportDataShare())])),
                      ListTile(title: const Text("Backup herstellen"), subtitle: const Text("Lokaal of Bestand"), leading: const Icon(Icons.download_rounded, color: Colors.blueAccent), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.restore, color: Colors.blueAccent), tooltip: "Lokaal herstellen", onPressed: () async { bool success = await data.importLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Lokale backup hersteld!" : "Geen lokale backup gevonden."))); } }), IconButton(icon: const Icon(Icons.folder_open, color: Colors.blueAccent), tooltip: "Bestand kiezen", onPressed: () async { bool success = await data.importDataPicker(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Backup hersteld!" : "Geen bestand gekozen."))); } })])),
                      ListTile(title: const Text("Excel Export"), subtitle: const Text("Opslaan als CSV"), leading: const Icon(Icons.table_view, color: Colors.blueAccent), trailing: IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Excel/CSV delen", onPressed: () => data.exportCSV())),
                      const SizedBox(height: 20),
                      ListTile(title: const Text("Alle data wissen", style: TextStyle(color: Colors.red)), leading: const Icon(Icons.delete_forever_outlined, color: Colors.red), onTap: () => _clearDlg(context, data)),
                ])),
                Padding(padding: const EdgeInsets.all(20), child: GestureDetector(onTap: () { if (++_clicks >= 7) { _clicks = 0; bool isDeLorean = data.cars.any((c) => c.licensePlate?.toUpperCase() == 'OUTATIME'); widget.onEasterEgg(isDeLorean); } }, child: const Text("TankBuddy v1.1.02", style: TextStyle(color: Colors.grey)))),
              ],
            )));
      },
    ));
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.w600)));
  
  void _nameDlg(BuildContext context, DataProvider data) {
    final c = TextEditingController(text: data.user['first_name']);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Naam wijzigen"), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), TextButton(onPressed: () { data.updateUserSettings({'first_name': c.text}); Navigator.pop(ctx); }, child: const Text("Opslaan"))]));
  }
  
  void _manageCars(BuildContext context, DataProvider data) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (ctx) => DraggableScrollableSheet(expand: false, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9, builder: (_, scrollCtrl) => Container(padding: const EdgeInsets.all(20), child: Column(children: [const Text("Mijn Garage", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text("Klik op een voertuig om te wijzigen.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 20), Expanded(child: data.cars.isEmpty ? const Center(child: Text("Nog geen voertuigen.")) : ListView.separated(controller: scrollCtrl, itemCount: data.cars.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) { final car = data.cars[index]; return ListTile(leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(data.getVehicleIcon(car.type), color: Colors.white, size: 20)), title: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${car.type.toUpperCase()} - ${car.licensePlate ?? ''}"), onTap: () => _carDlg(context, data, car), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteCar(context, data, car))); })), const SizedBox(height: 20), SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => _carDlg(context, data, null), icon: const Icon(Icons.add), label: const Text("Nieuw Voertuig Toevoegen"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white))) ]))));
  }
  
  void _confirmDeleteCar(BuildContext context, DataProvider data, Car car) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Voertuig verwijderen?"), content: Text("Weet je zeker dat je '${car.name}' wilt verwijderen?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), TextButton(onPressed: () { data.deleteCar(car.id!); Navigator.pop(ctx); }, child: const Text("Verwijderen", style: TextStyle(color: Colors.red)))]));
  }
  
  void _clearDlg(BuildContext context, DataProvider data) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Alles wissen?"), content: const Text("Dit wist ALLE data."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), TextButton(onPressed: () { DatabaseHelper.instance.clearAllData(); data.loadData(); Navigator.pop(ctx); }, child: const Text("WIS", style: TextStyle(color: Colors.red)))]));
  }

  void _carDlg(BuildContext context, DataProvider data, Car? car) {
    final n = TextEditingController(text: car?.name); 
    final k = TextEditingController(text: car?.licensePlate);
    final insCtrl = TextEditingController(text: car?.insurance?.toString() ?? "");
    final taxCtrl = TextEditingController(text: car?.roadTax?.toString() ?? "");
    
    String type = car?.type ?? 'auto'; 
    String taxFreq = car?.roadTaxFreq ?? 'month'; 

    DateTime? apk = car?.apkDate != null ? DateTime.parse(car!.apkDate!) : null;
    final dCtrl = TextEditingController(text: apk != null ? DateFormat('dd-MM-yyyy').format(apk) : "");
    final types = ['auto', 'motor', 'scooter', 'vrachtwagen', 'trekker', 'bus', 'camper'];
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(car == null ? "Nieuw Voertuig" : "Voertuig Wijzigen"), 
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: type, 
            decoration: const InputDecoration(labelText: "Soort Voertuig", border: OutlineInputBorder()), 
            items: types.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(data.getVehicleIcon(t), color: Colors.grey), const SizedBox(width: 10), Text(t[0].toUpperCase() + t.substring(1))]))).toList(), 
            onChanged: (v) => setS(() => type = v!)
          ), 
          const SizedBox(height: 16), 
          TextField(controller: n, decoration: const InputDecoration(labelText: "Naam", border: OutlineInputBorder())), 
          const SizedBox(height: 16), 
          TextField(controller: k, decoration: const InputDecoration(labelText: "Kenteken", border: OutlineInputBorder())), 
          const SizedBox(height: 16), 
          TextField(controller: insCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Verzekering (p/mnd)", border: OutlineInputBorder(), prefixText: "€ ")),
          const SizedBox(height: 16), 
          Row(
            children: [
              Expanded(child: TextField(controller: taxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Wegenbelasting", border: OutlineInputBorder(), prefixText: "€ "))),
              const SizedBox(width: 8),
              SizedBox(width: 110, child: DropdownButtonFormField<String>(
                value: taxFreq,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                items: const [DropdownMenuItem(value: 'month', child: Text("p/mnd")), DropdownMenuItem(value: 'quarter', child: Text("p/kwrt"))],
                onChanged: (v) => setS(() => taxFreq = v!),
              ))
            ],
          ),
          const SizedBox(height: 16), 
          TextField(controller: dCtrl, readOnly: true, decoration: const InputDecoration(labelText: "APK Vervaldatum", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month, color: Colors.blueAccent)), onTap: () async { 
                        final d = await showDatePicker(context: context, initialDate: apk ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); 
                        if (d != null) { setS(() => apk = d); dCtrl.text = DateFormat('dd-MM-yyyy').format(d); }})
        ])), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), 
        ElevatedButton(
          onPressed: () { 
            if (n.text.isEmpty) { return; } 
            double? ins = double.tryParse(insCtrl.text.replaceAll(',', '.'));
            double? tax = double.tryParse(taxCtrl.text.replaceAll(',', '.'));

            data.updateCar(Car(
              id: car?.id, 
              name: n.text, 
              licensePlate: k.text, 
              apkDate: apk?.toIso8601String(), 
              type: type,
              insurance: ins,
              roadTax: tax,
              roadTaxFreq: taxFreq
            )); 
            Navigator.pop(ctx); 
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), 
          child: const Text("Opslaan")
        )
      ]
    )));
  }
}