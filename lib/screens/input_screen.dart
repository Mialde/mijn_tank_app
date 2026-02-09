import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../models/fuel_entry.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final FocusNode _focusKm = FocusNode();
  final FocusNode _focusLiters = FocusNode();
  final FocusNode _focusPrice = FocusNode();

  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _focusKm.dispose();
    _focusLiters.dispose();
    _focusPrice.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double _parseInput(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

  // NIEUW: Bepaalt de begroeting op basis van de tijd
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Goedemorgen';
    if (hour >= 12 && hour < 18) return 'Goedemiddag';
    if (hour >= 18 && hour < 23) return 'Goedenavond';
    return 'Goedenacht';
  }

  void _saveEntry() {
    final provider = context.read<DataProvider>();
    if (provider.selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecteer eerst een voertuig')));
      return;
    }
    final odometer = _parseInput(_odometerController.text);
    final liters = _parseInput(_litersController.text);
    final priceTotal = _parseInput(_priceController.text);

    if (odometer > 0 && liters > 0 && priceTotal > 0) {
      final newEntry = FuelEntry(
        carId: provider.selectedCar!.id!,
        date: _selectedDate,
        odometer: odometer, liters: liters, priceTotal: priceTotal,
        pricePerLiter: priceTotal / liters,
      );
      provider.addFuelEntry(newEntry);
      
      _odometerController.clear(); _litersController.clear(); _priceController.clear();
      setState(() => _selectedDate = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tankbeurt opgeslagen!')));
      _focusKm.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final settings = provider.settings;
    final Color appColor = provider.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe Tankbeurt'),
        actions: [
          if (provider.cars.length > 1)
            IconButton(
              icon: Icon(Icons.directions_car, color: appColor), 
              onPressed: () => _showVehicleSelector(context, provider)
            ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                // --- TIJDSGEBONDEN BEGROETING ---
                if (settings?.useGreeting ?? true) ...[
                  Text(
                    '${_getGreeting()} ${settings?.firstName ?? 'Gebruiker'}!',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (settings?.showQuotes ?? true) ...[
                  Text(
                    '"${provider.currentQuote}"',
                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                ],
                // -------------------------------------

                _buildInputCard('Kilometerstand', Icons.speed, _odometerController, _focusKm, _focusLiters, appColor),
                const SizedBox(height: 16),
                _buildInputCard('Aantal Liters', Icons.local_gas_station, _litersController, _focusLiters, _focusPrice, appColor),
                const SizedBox(height: 16),
                _buildInputCard('Totaalbedrag (€)', Icons.euro, _priceController, _focusPrice, null, appColor, isLast: true),
                const SizedBox(height: 16),
                _buildDateCard(appColor),
              ],
            ),
          ),
          _buildBottomSaveButton(appColor),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, IconData icon, TextEditingController controller, FocusNode currentFocus, FocusNode? nextFocus, Color color, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: _getBorder(context),
      ),
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) {
          if (nextFocus != null) nextFocus.requestFocus(); else FocusScope.of(context).unfocus();
        },
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          icon: Icon(icon, color: color),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDateCard(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: _getBorder(context),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now(),
            locale: const Locale('nl', 'NL'),
            builder: (context, child) {
              return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: color)), child: child!);
            },
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Datum',
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
            border: InputBorder.none,
            icon: Icon(Icons.calendar_today, color: color),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
          child: Text(DateFormat('dd-MM-yyyy').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBottomSaveButton(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: SizedBox(
        height: 60, width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Opslaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
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

  BoxBorder? _getBorder(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape;
    if (shape is RoundedRectangleBorder && shape.side != BorderSide.none) {
      return Border.fromBorderSide(shape.side);
    }
    return null;
  }
}