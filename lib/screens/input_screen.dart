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
  final _odoController = TextEditingController();
  final _literController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _odoController.dispose();
    _literController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Nieuwe Tankbeurt')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                  // Kalender cel
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
          ),
          // Opslaan knop gefixeerd onderaan
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
              // We gebruiken een suffix widget voor betere controle over uitlijning en grootte
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 20, top: 14), // top padding om het uit te lijnen met vette tekst
                child: Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 18, 
                    color: Colors.grey, 
                    fontWeight: FontWeight.normal
                  ),
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
}