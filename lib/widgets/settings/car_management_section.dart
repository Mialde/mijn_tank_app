// lib/widgets/settings/car_management_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../data_provider.dart';
import '../../services/rdw_service.dart';
import '../recurring_costs_dialog.dart';
import 'accordion_card.dart';

class CarManagementSection extends StatelessWidget {
  final Color appColor;
  final DataProvider provider;
  final List<String> vehicleTypes;

  const CarManagementSection({
    super.key,
    required this.appColor,
    required this.provider,
    required this.vehicleTypes,
  });

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Motor':
        return Icons.motorcycle;
      case 'Vrachtwagen':
        return Icons.local_shipping;
      case 'Scooter':
        return Icons.moped;
      default:
        return Icons.directions_car;
    }
  }

  void _showCarDialog(BuildContext context, {Car? car}) {
    final plate = TextEditingController(text: car?.licensePlate);
    final name = TextEditingController(text: car?.name);
    final insurance = TextEditingController(
      text: car?.insurance.toString().replaceAll('.', ',') ?? '0',
    );
    final tax = TextEditingController(
      text: car?.roadTax.toString().replaceAll('.', ',') ?? '0',
    );
    String selectedType = vehicleTypes.contains(car?.type) ? car!.type : 'Auto';
    DateTime? apk = car?.apkDate;
    String? fuelType = car?.fuelType;
    String? owner = car?.owner;
    bool isLoadingRdw = false;
    bool manualMode = car != null;

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
                // Kenteken met RDW lookup
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plate,
                        decoration: const InputDecoration(
                          labelText: 'Kenteken',
                          hintText: 'Bijv: KT-915-G',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: isLoadingRdw
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      tooltip: 'Gegevens ophalen van RDW',
                      onPressed: isLoadingRdw
                          ? null
                          : () async {
                              if (plate.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voer eerst een kenteken in')),
                                );
                                return;
                              }

                              setDialogState(() => isLoadingRdw = true);

                              try {
                                final rdwData = await RdwService.getVehicleData(plate.text);

                                if (rdwData == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Kenteken niet gevonden in RDW database'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  plate.text = RdwService.normalizeLicensePlate(plate.text);
                                  setDialogState(() {
                                    name.text = rdwData.getVehicleName();
                                    selectedType = rdwData.getVehicleType();
                                    apk = rdwData.apkVervaldatum;
                                    fuelType = rdwData.brandstof;
                                    owner = rdwData.eigenaar;
                                    manualMode = true;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ RDW gegevens opgehaald!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fout: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setDialogState(() => isLoadingRdw = false);
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Manual mode toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Handmatig gegevens invoeren'),
                  value: manualMode,
                  activeTrackColor: appColor,
                  onChanged: (value) => setDialogState(() => manualMode = value),
                ),
                
                // Manual fields
                if (manualMode) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type Voertuig'),
                    items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Naam'),
                  ),
                  
                  // APK Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('APK Datum'),
                    subtitle: Text(apk == null ? 'Kies datum' : DateFormat('dd-MM-yyyy').format(apk!)),
                    trailing: apk != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setDialogState(() => apk = null),
                          )
                        : null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: apk ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('nl', 'NL'),
                      );
                      if (d != null) setDialogState(() => apk = d);
                    },
                  ),
                  
                  TextField(
                    controller: insurance,
                    decoration: const InputDecoration(labelText: 'Verzekering p/m (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: tax,
                    decoration: const InputDecoration(labelText: 'Wegenbelasting p/m (€)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  // Recurring costs button
                  if (car != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.subscriptions),
                      label: const Text('Abonnementen Beheren'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: BorderSide(color: appColor),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => RecurringCostsDialog(
                            carId: car.id!,
                            appColor: appColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // RDW info (read-only)
                  if (fuelType != null) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.local_gas_station, size: 20),
                      title: Text(
                        'Brandstof: $fuelType',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                  if (owner != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.person, size: 20),
                      title: Text(
                        'Eigenaar: $owner',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleer'),
            ),
            ElevatedButton(
              onPressed: () {
                if (plate.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kenteken is verplicht')),
                  );
                  return;
                }
                
                if (manualMode && name.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naam is verplicht')),
                  );
                  return;
                }
                
                final newCar = Car(
                  id: car?.id,
                  name: manualMode ? name.text : (name.text.isNotEmpty ? name.text : 'Auto'),
                  licensePlate: RdwService.normalizeLicensePlate(plate.text),
                  type: selectedType,
                  apkDate: apk,
                  insurance: double.tryParse(insurance.text.replaceAll(',', '.')) ?? 0,
                  roadTax: double.tryParse(tax.text.replaceAll(',', '.')) ?? 0,
                  roadTaxFreq: 'Maandelijks',
                  fuelType: fuelType,
                  owner: owner,
                );
                
                car == null ? provider.addCar(newCar) : provider.updateCar(newCar);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccordionCard(
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
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange),
                onPressed: () => _showCarDialog(context, car: car),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => provider.deleteCar(car.id!),
              ),
            ],
          ),
        )),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showCarDialog(context),
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
    );
  }
}