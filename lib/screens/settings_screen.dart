import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../services/data_service.dart';
import '../models/car.dart';
import 'developer_notes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  final List<String> _vehicleTypes = ['Auto', 'Motor', 'Vrachtwagen', 'Scooter', 'Bus', 'Camper', 'Tractor', 'Bestelwagen'];
  final String _version = "v1.0.4 (Beta)";

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
      appBar: AppBar(title: const Text('Instellingen')),
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
                          fillColor: Theme.of(context).scaffoldBackgroundColor, // Subtiel contrast
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onChanged: (v) => provider.updateSettings(settings.copyWith(firstName: v)),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Begroeting tonen'), 
                      value: settings.useGreeting, 
                      activeColor: appColor, 
                      onChanged: (v) => provider.updateSettings(settings.copyWith(useGreeting: v))
                    ),
                    SwitchListTile(
                      title: const Text('Quotes tonen'), 
                      value: settings.showQuotes, 
                      activeColor: appColor, 
                      onChanged: (v) => provider.updateSettings(settings.copyWith(showQuotes: v))
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

                // 3. WEERGAVE-INSTELLINGEN (MET ICONEN)
                _buildAccordionCard(
                  title: 'Weergave-instellingen',
                  icon: Icons.palette_outlined,
                  appColor: appColor,
                  children: [
                    ListTile(
                      leading: Icon(Icons.brush, color: appColor), // Icoon toegevoegd
                      title: const Text('Accentkleur'),
                      trailing: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: appColor, shape: BoxShape.circle),
                      ),
                      onTap: () => _showColorPicker(context, provider, settings),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: Icon(Icons.contrast, color: appColor), // Icoon toegevoegd
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

                // 4. OPSLAG & DATA (GEGROEPEERD)
                _buildAccordionCard(
                  title: 'Opslag & Data',
                  icon: Icons.cloud_upload_outlined,
                  appColor: appColor,
                  children: [
                    // Groep 1: Rapportage
                    _sectionHeader('Rapportage'),
                    _actionTile('PDF Rapport', Icons.picture_as_pdf, () => DataService.exportToPDF(provider.selectedCar!, provider.entries)),
                    _actionTile('Excel (.xlsx)', Icons.table_chart, () => DataService.shareAsExcel(provider.entries)),
                    
                    const Divider(color: Colors.white10, height: 24),
                    
                    // Groep 2: Data Beheer
                    _sectionHeader('Data Beheer'),
                    _actionTile('Backup Maken (JSON)', Icons.save_alt, () => DataService.saveBackupJSON({'cars': provider.cars.map((c)=>c.toMap()).toList(), 'entries': provider.entries.map((e)=>e.toMap()).toList()})),
                    _actionTile('Data Importeren', Icons.file_download, () => _handleImport(context, provider), color: Colors.orange),
                    _actionTile('CSV Export', Icons.description, () => DataService.shareAsCSV(provider.entries)), // Verplaatst naar beheer
                    
                    const Divider(color: Colors.white10, height: 24),

                    // Groep 3: Dev
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                  'TankBuddy $_version',
                  style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  // --- POP-UPS ---

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
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: DataProvider.colorOptions.length,
            itemBuilder: (context, index) {
              final entry = DataProvider.colorOptions.entries.elementAt(index);
              final isSelected = settings.accentColor == entry.key;
              return GestureDetector(
                onTap: () {
                  provider.updateSettings(settings.copyWith(accentColor: entry.key));
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border.all(
                      color: isSelected ? entry.value : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(entry.key, style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? entry.value : null
                        ), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sluiten')),
        ],
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sluiten')),
        ],
      ),
    );
  }

  // AANGEPAST: Geen gekleurde achtergrond meer, alleen border + icon color
  Widget _buildThemeOption(String label, String value, IconData icon, dynamic settings, DataProvider provider, Color appColor) {
    final isSelected = settings.themeMode == value;
    return GestureDetector(
      onTap: () {
        provider.updateSettings(settings.copyWith(themeMode: value));
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, // Gewoon kaartkleur
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? appColor : Colors.transparent, width: 2), // Alleen rand bij selectie
              // Geen shadow meer
            ),
            child: Icon(icon, color: isSelected ? appColor : Colors.grey, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(
            fontSize: 12, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? appColor : Colors.grey
          )),
        ],
      ),
    );
  }

  // --- HELPERS ---

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
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type Voertuig'),
                  items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam')),
                TextField(controller: plate, decoration: const InputDecoration(labelText: 'Kenteken')),
                TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Verzekering p/m'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: tax, decoration: const InputDecoration(labelText: 'Wegenbelasting'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ListTile(
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

  void _handleImport(BuildContext context, DataProvider provider) async {
    final content = await DataService.pickFile(['json']);
    if (content != null && context.mounted) {
      await provider.importJsonBackup(content);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import geslaagd!')));
    }
  }

  Widget _buildAccordionCard({required String title, required IconData icon, required Color appColor, required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(), collapsedShape: const Border(),
          leading: Icon(icon, color: appColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: children,
        ),
      ),
    );
  }

  Widget _actionTile(String t, IconData i, VoidCallback tap, {Color? color}) => ListTile(leading: Icon(i, color: color ?? Colors.grey), title: Text(t, style: TextStyle(color: color, fontSize: 14)), trailing: const Icon(Icons.chevron_right, size: 18), onTap: tap);
}