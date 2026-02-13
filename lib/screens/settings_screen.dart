import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../services/data_service.dart';
import '../models/car.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import 'developer_notes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  final List<String> _vehicleTypes = ['Auto', 'Motor', 'Vrachtwagen', 'Scooter', 'Bus', 'Camper', 'Tractor', 'Bestelwagen'];
  final String _version = "v1.0.6 (Beta)";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<DataProvider>().settings?.firstName);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final settings = provider.settings;
    final Color appColor = provider.themeColor;

    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        centerTitle: false,
        titleSpacing: 24, // Exact dezelfde linkerlijn als de kaarten
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. GEBRUIKER
                _buildAccordionCard(
                  title: 'Gebruikersprofiel',
                  icon: Icons.person_outline,
                  appColor: appColor,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Jouw Naam',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onChanged: (v) => provider.updateSettings(settings.copyWith(firstName: v)),
                      ),
                    ),
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: const Text('Begroeting tonen'),
                      trailing: Switch(
                        value: settings.useGreeting,
                        activeColor: appColor,
                        onChanged: (v) => provider.updateSettings(settings.copyWith(useGreeting: v)),
                      ),
                      onTap: () => provider.updateSettings(settings.copyWith(useGreeting: !settings.useGreeting)),
                    ),
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: const Text('Quotes tonen'),
                      trailing: Switch(
                        value: settings.showQuotes,
                        activeColor: appColor,
                        onChanged: (v) => provider.updateSettings(settings.copyWith(showQuotes: v)),
                      ),
                      onTap: () => provider.updateSettings(settings.copyWith(showQuotes: !settings.showQuotes)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. MIJN GARAGE
                _buildAccordionCard(
                  title: 'Mijn Garage',
                  icon: Icons.garage_outlined,
                  appColor: appColor,
                  children: [
                    ...provider.cars.map((car) => ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(_getVehicleIcon(car.type), color: appColor),
                      title: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(car.licensePlate),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange), onPressed: () => _showCarDialog(context, provider, appColor, car: car)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => provider.deleteCar(car.id!)),
                        ],
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => _showCarDialog(context, provider, appColor),
                        icon: const Icon(Icons.add),
                        label: const Text('Voertuig toevoegen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. WEERGAVE
                _buildAccordionCard(
                  title: 'Weergave-instellingen',
                  icon: Icons.palette_outlined,
                  appColor: appColor,
                  children: [
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(Icons.brush, color: appColor),
                      title: const Text('Accentkleur'),
                      trailing: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: appColor, shape: BoxShape.circle),
                      ),
                      onTap: () => _showColorPicker(context, provider, settings),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(Icons.contrast, color: appColor),
                      title: const Text('Thema'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(settings.themeMode, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showThemePicker(context, provider, settings, appColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. OPSLAG & DATA
                _buildAccordionCard(
                  title: 'Opslag & Data',
                  icon: Icons.cloud_upload_outlined,
                  appColor: appColor,
                  children: [
                    _sectionHeader('Data Management'),
                    _actionTile('Gegevens Exporteren', Icons.upload_file_outlined, () => _handleExport(context, provider)),
                    _actionTile('Gegevens Importeren', Icons.download_for_offline_outlined, () => _handleImport(context, provider), color: Colors.orange),
                    
                    const Divider(color: Colors.white10, height: 24),

                    _sectionHeader('Gevaarlijke Zone'),
                    _actionTile('Gegevens wissen', Icons.delete_forever, () => _showResetDialog(context, provider), color: Colors.red),

                    const Divider(color: Colors.white10, height: 24),

                    ListTile(
                      minTileHeight: 72,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.developer_mode, color: Colors.grey, size: 20),
                      ),
                      title: const Text('Developer Notities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DeveloperNotesScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 24),
                child: Text(
                  'TankAppie $_version',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXPORT MENU ---

  void _handleExport(BuildContext context, DataProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Kies export formaat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _exportOptionTile(context, 'PDF Rapport', Icons.picture_as_pdf, () => _showActionChoice(context, 'PDF Rapport', 
            onShare: () => DataService.exportToPDF(provider.cars, provider.entries, provider.maintenanceEntries),
            onSave: () => DataService.savePDFLocally(provider.cars, provider.entries, provider.maintenanceEntries)
          )),
          _exportOptionTile(context, 'Excel Lijst (.xlsx)', Icons.table_chart, () => _showActionChoice(context, 'Excel Lijst', 
            onShare: () => DataService.shareAsExcel(provider.cars, provider.entries, provider.maintenanceEntries),
            onSave: () => DataService.saveExcelLocally(provider.cars, provider.entries, provider.maintenanceEntries)
          )),
          _exportOptionTile(context, 'CSV Bestand', Icons.description, () => _showActionChoice(context, 'CSV Bestand', 
            onShare: () => DataService.shareAsCSV(provider.cars, provider.entries, provider.maintenanceEntries),
            onSave: () => DataService.saveCSVLocally(provider.cars, provider.entries, provider.maintenanceEntries)
          )),
          _exportOptionTile(context, 'Volledige Backup (JSON)', Icons.settings_backup_restore, () => _showActionChoice(context, 'JSON Backup', 
            onShare: () => DataService.shareBackupJSON({
              'cars': provider.cars.map((c)=>c.toMap()).toList(), 
              'entries': provider.entries.map((e)=>e.toMap()).toList(),
              'maintenance_entries': provider.maintenanceEntries.map((e)=>e.toMap()).toList()
            }),
            onSave: () => DataService.saveBackupJSON({
              'cars': provider.cars.map((c)=>c.toMap()).toList(), 
              'entries': provider.entries.map((e)=>e.toMap()).toList(),
              'maintenance_entries': provider.maintenanceEntries.map((e)=>e.toMap()).toList()
            })
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showActionChoice(BuildContext context, String title, {required VoidCallback onShare, required VoidCallback onSave}) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: const Text('Wat wil je doen met het bestand?'),
        actions: [
          TextButton.icon(
            onPressed: () { Navigator.pop(context); onShare(); },
            icon: const Icon(Icons.share), label: const Text('Delen')
          ),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); onSave(); },
            icon: const Icon(Icons.save_alt), label: const Text('Opslaan')
          ),
        ],
      ),
    );
  }

  // --- IMPORT LOGICA ---

  void _handleImport(BuildContext context, DataProvider provider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Kies bron voor import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.backup_outlined),
            title: const Text('TankAppie Backup (JSON)'),
            onTap: () async {
              Navigator.pop(context);
              final content = await DataService.pickFile(['json']);
              if (content != null) provider.importJsonBackup(content);
            },
          ),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('CSV Lijst (Slimme Import)'),
            onTap: () async {
              Navigator.pop(context);
              final rows = await DataService.pickAndParseCSV();
              if (rows != null && context.mounted) _showMappingDialog(context, rows, provider);
            },
          ),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.grid_on_outlined),
            title: const Text('Excel Lijst (.xlsx)'),
            onTap: () async {
              Navigator.pop(context);
              final rows = await DataService.pickAndParseExcel();
              if (rows != null && context.mounted) _showMappingDialog(context, rows, provider);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- MAPPING LOGICA ---

  void _showMappingDialog(BuildContext context, List<List<dynamic>> rows, DataProvider provider) {
    if (rows.isEmpty) return;
    List<dynamic> sampleRow = rows[0];
    Map<int, String?> mapping = {}; 
    final List<String> options = ['Datum', 'KM-stand', 'Liters', 'Totaal Bedrag', 'Negeren'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Kolommen koppelen'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Wijs per kolom aan wat de gegevens betekenen.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sampleRow.length,
                    itemBuilder: (context, index) {
                      String examples = rows.take(3).map((r) => r.length > index ? r[index].toString() : '').join('\n');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Voorbeelden uit bestand:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(examples, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: mapping[index],
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Kies type...'),
                              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setDialogState(() => mapping[index] = v),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
            ElevatedButton(
              onPressed: mapping.values.contains('Datum') && mapping.values.contains('Liters') 
                ? () {
                    _processMappedImport(context, rows, mapping, provider);
                    Navigator.pop(context);
                  }
                : null,
              child: const Text('Importeren'),
            ),
          ],
        ),
      ),
    );
  }

  void _processMappedImport(BuildContext context, List<List<dynamic>> rows, Map<int, String?> mapping, DataProvider provider) async {
    int count = 0;
    int errorCount = 0;
    for (var row in rows) {
      try {
        int dateIdx = mapping.keys.firstWhere((k) => mapping[k] == 'Datum', orElse: () => -1);
        int odoIdx = mapping.keys.firstWhere((k) => mapping[k] == 'KM-stand', orElse: () => -1);
        int literIdx = mapping.keys.firstWhere((k) => mapping[k] == 'Liters', orElse: () => -1);
        int priceIdx = mapping.keys.firstWhere((k) => mapping[k] == 'Totaal Bedrag', orElse: () => -1);
        if (dateIdx == -1 || literIdx == -1) continue;
        String rawDate = row[dateIdx].toString();
        DateTime parsedDate;
        try {
          parsedDate = DateTime.parse(rawDate);
        } catch (_) {
          parsedDate = DateFormat('dd-MM-yyyy').parse(rawDate.replaceAll('/', '-'));
        }
        await provider.addFuelEntry(FuelEntry(
          carId: provider.selectedCar!.id!,
          date: parsedDate,
          odometer: double.tryParse(row[odoIdx].toString().replaceAll(',', '.')) ?? 0,
          liters: double.tryParse(row[literIdx].toString().replaceAll(',', '.')) ?? 0,
          priceTotal: double.tryParse(row[priceIdx].toString().replaceAll(',', '.')) ?? 0,
          pricePerLiter: 0,
        ));
        count++;
      } catch (e) {
        errorCount++;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Succes: $count geïmporteerd. Fouten: $errorCount.')));
    }
  }

  // --- HELPERS ---

  void _showResetDialog(BuildContext context, DataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Wat wil je wissen?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 72,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Alleen historie'),
              subtitle: const Text('Wist alle tankbeurten van het huidige voertuig.'),
              onTap: () { Navigator.pop(context); provider.clearAllEntries(); },
            ),
            ListTile(
              minTileHeight: 72,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: const Text('Alles wissen'),
              subtitle: const Text('Reset de app volledig.'),
              onTap: () { Navigator.pop(context); _confirmFactoryReset(context, provider); },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmFactoryReset(BuildContext context, DataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weet je het zeker?'),
        content: const Text('Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
          TextButton(onPressed: () { Navigator.pop(context); provider.factoryReset(); }, 
            child: const Text('JA, WIS ALLES', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildAccordionCard({required String title, required IconData icon, required Color appColor, required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          minTileHeight: 72, // Vaste hoogte van de cel toegevoegd
          tilePadding: const EdgeInsets.symmetric(horizontal: 20), // Exact dezelfde padding
          shape: const Border(), collapsedShape: const Border(),
          leading: Icon(icon, color: appColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: children,
        ),
      ),
    );
  }

  Widget _actionTile(String t, IconData i, VoidCallback tap, {Color? color}) => ListTile(
    minTileHeight: 72,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    leading: Icon(i, color: color ?? Colors.grey), 
    title: Text(t, style: TextStyle(color: color, fontSize: 14)), 
    trailing: const Icon(Icons.chevron_right, size: 18), 
    onTap: tap
  );

  Widget _exportOptionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Motor': return Icons.motorcycle;
      case 'Vrachtwagen': return Icons.local_shipping;
      case 'Scooter': return Icons.moped;
      default: return Icons.directions_car;
    }
  }

  void _showCarDialog(BuildContext context, DataProvider provider, Color color, {Car? car}) {
    final name = TextEditingController(text: car?.name);
    final plate = TextEditingController(text: car?.licensePlate);
    final insurance = TextEditingController(text: car?.insurance.toString().replaceAll('.', ',') ?? '0');
    final tax = TextEditingController(text: car?.roadTax.toString().replaceAll('.', ',') ?? '0');
    String selectedType = _vehicleTypes.contains(car?.type) ? car!.type : 'Auto';
    DateTime? apk = car?.apkDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(car == null ? 'Nieuw Voertuig' : 'Wijzig Voertuig'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType, 
                  decoration: const InputDecoration(labelText: 'Type Voertuig'),
                  items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam')),
                TextField(controller: plate, decoration: const InputDecoration(labelText: 'Kenteken')),
                TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Verzekering p/m'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: tax, decoration: const InputDecoration(labelText: 'Wegenbelasting'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ListTile(
                  minTileHeight: 72,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('APK Datum'),
                  subtitle: Text(apk == null ? 'Kies datum' : DateFormat('dd-MM-yyyy').format(apk!)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100), locale: const Locale('nl', 'NL'));
                    if (d != null) setDialogState(() => apk = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
            ElevatedButton(
              onPressed: () {
                final newCar = Car(
                  id: car?.id, name: name.text, licensePlate: plate.text, type: selectedType,
                  apkDate: apk, insurance: double.tryParse(insurance.text.replaceAll(',', '.')) ?? 0,
                  roadTax: double.tryParse(tax.text.replaceAll(',', '.')) ?? 0, roadTaxFreq: 'Maandelijks',
                );
                car == null ? provider.addCar(newCar) : provider.updateCar(newCar);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, DataProvider provider, dynamic settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kies Accentkleur'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 3.0, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: DataProvider.colorOptions.length,
            itemBuilder: (context, index) {
              final entry = DataProvider.colorOptions.entries.elementAt(index);
              final isSelected = settings.accentColor == entry.key;
              return GestureDetector(
                onTap: () { provider.updateSettings(settings.copyWith(accentColor: entry.key)); Navigator.pop(context); },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border.all(color: isSelected ? entry.value : Colors.grey.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.key, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? entry.value : null), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sluiten'))],
      ),
    );
  }

  void _showThemePicker(BuildContext context, DataProvider provider, dynamic settings, Color appColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kies Thema'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThemeOption('Licht', 'Light', Icons.wb_sunny_outlined, settings, provider, appColor),
            _buildThemeOption('Donker', 'Dark', Icons.nights_stay_outlined, settings, provider, appColor),
            _buildThemeOption('Systeem', 'System', Icons.smartphone, settings, provider, appColor),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sluiten'))],
      ),
    );
  }

  Widget _buildThemeOption(String label, String value, IconData icon, dynamic settings, DataProvider provider, Color appColor) {
    final isSelected = settings.themeMode == value;
    return GestureDetector(
      onTap: () { provider.updateSettings(settings.copyWith(themeMode: value)); Navigator.pop(context); },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? appColor : Colors.transparent, width: 2)),
            child: Icon(icon, color: isSelected ? appColor : Colors.grey, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? appColor : Colors.grey)),
        ],
      ),
    );
  }
}