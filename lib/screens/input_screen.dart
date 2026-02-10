import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';
import '../models/fuel_entry.dart';
import '../widgets/apk_warning_banner.dart';
import 'maintenance_screen.dart'; // Import nodig voor de modal

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
    _focusKm.dispose(); _focusLiters.dispose(); _focusPrice.dispose();
    _odometerController.dispose(); _litersController.dispose(); _priceController.dispose();
    super.dispose();
  }

  double _parseInput(String value) => double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Goedemorgen';
    if (hour >= 12 && hour < 18) return 'Goedemiddag';
    if (hour >= 18 && hour < 23) return 'Goedenavond';
    return 'Goedenacht';
  }

  void _saveEntry() {
    final provider = context.read<DataProvider>();
    if (provider.selectedCar == null) return;
    final odo = _parseInput(_odometerController.text);
    final l = _parseInput(_litersController.text);
    final p = _parseInput(_priceController.text);
    if (odo > 0 && l > 0 && p > 0) {
      provider.addFuelEntry(FuelEntry(carId: provider.selectedCar!.id!, date: _selectedDate, odometer: odo, liters: l, priceTotal: p, pricePerLiter: p / l));
      _odometerController.clear(); _litersController.clear(); _priceController.clear();
      setState(() => _selectedDate = DateTime.now());
      _focusKm.requestFocus();
    }
  }

  // Auto selectie modal
  void _showVehicleSelector(BuildContext context, DataProvider provider) {
    showModalBottomSheet(
      context: context, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), 
      builder: (context) => ListView(
        padding: const EdgeInsets.all(24), 
        children: provider.cars.map((c) => ListTile(
          leading: Icon(Icons.directions_car, color: provider.themeColor), 
          title: Text(c.name), 
          onTap: () { 
            provider.selectCar(c); 
            Navigator.pop(context); 
          }
        )).toList()
      )
    );
  }

  // NIEUW: Onderhoud modal
  void _showMaintenanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9, 
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), 
          child: const MaintenanceScreen(isModal: true)
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final settings = provider.settings;
    final apk = provider.apkStatus;
    final bool showBanner = apk['show'] == true;
    final Color appColor = provider.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe Tankbeurt'),
        actions: [
          // AANGEPAST: Onderhouds knop hier toegevoegd
          IconButton(
            icon: Icon(Icons.build_circle_outlined, color: apk['urgent'] == true ? Colors.red : appColor), 
            onPressed: () => _showMaintenanceModal(context),
          ),
          if (provider.cars.length > 1)
             IconButton(
               icon: Icon(Icons.directions_car, color: appColor), 
               onPressed: () => _showVehicleSelector(context, provider)
             ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const ApkWarningBanner(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, showBanner ? 16 : 24, 24, 24),
              children: [
                if (settings?.useGreeting ?? true) ...[
                  Text('${_getGreeting()} ${settings?.firstName ?? 'Gebruiker'}!', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                ],
                if (settings?.showQuotes ?? true) ...[
                  Text('"${provider.currentQuote}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 14)),
                  const SizedBox(height: 24),
                ],
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

  Widget _buildInputCard(String l, IconData i, TextEditingController c, FocusNode f, FocusNode? n, Color col, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: _getBorder(context)),
      child: TextField(
        controller: c, focusNode: f, 
        keyboardType: const TextInputType.numberWithOptions(decimal: true), 
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next, 
        onSubmitted: (_) { if (n != null) n.requestFocus(); }, 
        decoration: InputDecoration(labelText: l, border: InputBorder.none, icon: Icon(i, color: col), isDense: true)
      ),
    );
  }

  Widget _buildDateCard(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), border: _getBorder(context)),
      child: InkWell(
        onTap: () async {
          final p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
          if (p != null) setState(() => _selectedDate = p);
        },
        child: InputDecorator(decoration: InputDecoration(labelText: 'Datum', border: InputBorder.none, icon: Icon(Icons.calendar_today, color: color), isDense: true), child: Text(DateFormat('dd-MM-yyyy').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildBottomSaveButton(Color color) {
    return Container(padding: const EdgeInsets.all(24), child: SizedBox(height: 60, width: double.infinity, child: ElevatedButton(onPressed: _saveEntry, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Opslaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))));
  }

  BoxBorder? _getBorder(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape;
    if (shape is RoundedRectangleBorder && shape.side != BorderSide.none) return Border.fromBorderSide(shape.side);
    return null;
  }
}