import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../models/fuel_entry.dart';
import '../widgets/apk_warning_banner.dart';
import 'maintenance_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _odoController = TextEditingController();
  final _literController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<String> _quotes = [
    "Tijd om de tank weer te vullen!",
    "Klaar voor de volgende rit?",
    "Op naar de volgende bestemming!",
    "Elke liter brengt je verder.",
    "Tijd voor een pitstop!",
    "Weer wat kilometers voor de boeg?",
    "Brandstof erin, zorgen eruit."
  ];
  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  @override
  void dispose() {
    _odoController.dispose();
    _literController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _getGreeting(String? name) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 6 && hour < 12) {
      greeting = 'Goedemorgen';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Goedemiddag';
    } else if (hour >= 18 && hour < 24) {
      greeting = 'Goedenavond';
    } else {
      greeting = 'Goedenacht';
    }
    
    if (name != null && name.trim().isNotEmpty) {
      return '$greeting, $name!';
    }
    return '$greeting!';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final settings = provider.settings;
    
    final bool showBanner = provider.apkStatus['show'] == true;
    final bool showGreeting = settings?.useGreeting == true;
    final bool showQuotes = settings?.showQuotes == true;
    final bool hasHeader = showGreeting || showQuotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe Tankbeurt'),
        centerTitle: false,
        titleSpacing: 24,
        actions: [
          // Onderhoud: Neutraal thema
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: const [
                Icon(Icons.circle_outlined, size: 24),
                Icon(Icons.build, size: 12),
              ],
            ),
            onPressed: () => _showMaintenanceModal(context),
          ),
          // Autoselectie: Accentkleur (appColor)
          if (provider.cars.length > 1)
            IconButton(
              icon: Icon(Icons.directions_car, size: 24, color: appColor), 
              onPressed: () => _showVehicleSelector(context, provider),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ApkWarningBanner(),
                  
                  if (hasHeader)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, showBanner ? 16 : 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showGreeting)
                            Text(
                              _getGreeting(settings?.firstName),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          if (showGreeting && showQuotes) const SizedBox(height: 6),
                          if (showQuotes)
                            Text(
                              _randomQuote,
                              style: TextStyle(
                                fontSize: 15, 
                                color: Theme.of(context).hintColor, 
                                fontStyle: FontStyle.italic
                              ),
                            ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(24, hasHeader ? 24 : (showBanner ? 16 : 24), 24, 24),
                    child: Column(
                      children: [
                        _buildInputCard(
                          icon: Icons.speed,
                          label: 'Kilometerstand',
                          controller: _odoController,
                          suffix: 'km',
                          color: appColor,
                        ),
                        const SizedBox(height: 16),
                        _buildInputCard(
                          icon: Icons.local_gas_station,
                          label: 'Aantal liters',
                          controller: _literController,
                          suffix: 'L',
                          color: appColor,
                        ),
                        const SizedBox(height: 16),
                        _buildInputCard(
                          icon: Icons.euro,
                          label: 'Totaalbedrag',
                          controller: _priceController,
                          suffix: '€',
                          color: appColor,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Card(
                            child: SizedBox(
                              height: 72,
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Icon(Icons.calendar_today, color: appColor),
                                  const SizedBox(width: 16),
                                  Text(
                                    DateFormat('dd MMMM yyyy', 'nl_NL').format(_selectedDate),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => _saveEntry(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Opslaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String suffix,
    required Color color,
  }) {
    return Card(
      child: SizedBox(
        height: 72,
        child: Center(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              prefixIcon: Icon(icon, color: color),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 20, top: 14), 
                child: Text(suffix, 
                  style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.normal)
                ),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  void _saveEntry(DataProvider provider) {
    if (provider.selectedCar == null) return;
    final entry = FuelEntry(
      carId: provider.selectedCar!.id!,
      date: _selectedDate,
      odometer: double.tryParse(_odoController.text.replaceAll(',', '.')) ?? 0,
      liters: double.tryParse(_literController.text.replaceAll(',', '.')) ?? 0,
      priceTotal: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0,
      pricePerLiter: 0,
    );
    provider.addFuelEntry(entry);
    _odoController.clear();
    _literController.clear();
    _priceController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tankbeurt opgeslagen!')));
  }

  void _showMaintenanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias, // Clipping geforceerd
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          clipBehavior: Clip.antiAlias, // Ook clipping op de container zelf
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const MaintenanceScreen(isModal: true),
        ),
      ),
    );
  }

  void _showVehicleSelector(BuildContext context, DataProvider provider) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), 
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView(
            shrinkWrap: true,
            children: provider.cars.map((c) {
              final isSelected = provider.selectedCar?.id == c.id;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Icon(Icons.directions_car, color: isSelected ? provider.themeColor : Colors.grey), 
                title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), 
                trailing: isSelected ? Icon(Icons.check, color: provider.themeColor) : null,
                onTap: () { provider.selectCar(c); Navigator.pop(context); }
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}