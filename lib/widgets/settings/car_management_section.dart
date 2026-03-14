// lib/widgets/settings/car_management_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../data_provider.dart';
import '../../models/recurring_cost.dart';
import '../../services/database_helper.dart';
import '../../services/rdw_service.dart';
import 'accordion_card.dart';

class CarManagementSection extends StatefulWidget {
  final Color appColor;
  final DataProvider provider;
  final List<String> vehicleTypes;

  const CarManagementSection({
    super.key,
    required this.appColor,
    required this.provider,
    required this.vehicleTypes,
  });

  @override
  State<CarManagementSection> createState() => _CarManagementSectionState();
}

class _CarManagementSectionState extends State<CarManagementSection> {
  final Set<int> _expandedCars = {};

  Color get appColor => widget.appColor;
  DataProvider get provider => widget.provider;
  List<String> get vehicleTypes => widget.vehicleTypes;

  void _showAddCarDialog() {
    final plate     = TextEditingController();
    final name      = TextEditingController();
    final insurance = TextEditingController(text: '0');
    final tax       = TextEditingController(text: '0');
    String selectedType = 'Auto';
    DateTime? apk;
    String? fuelType;
    String? owner;
    bool isLoadingRdw = false;
    bool manualMode = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Nieuw Voertuig'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: TextField(
                    controller: plate,
                    decoration: const InputDecoration(labelText: 'Kenteken', hintText: 'Bijv: KT-915-G'),
                    textCapitalization: TextCapitalization.characters,
                  )),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: isLoadingRdw
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    tooltip: 'Gegevens ophalen van RDW',
                    onPressed: isLoadingRdw ? null : () async {
                      if (plate.text.isEmpty) return;
                      setDialogState(() => isLoadingRdw = true);
                      try {
                        final rdwData = await RdwService.getVehicleData(plate.text);
                        if (rdwData == null) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kenteken niet gevonden'), backgroundColor: Colors.orange),
                          );
                        } else {
                          plate.text = RdwService.normalizeLicensePlate(plate.text);
                          setDialogState(() {
                            name.text    = rdwData.getVehicleName();
                            selectedType = rdwData.getVehicleType();
                            apk          = rdwData.apkVervaldatum;
                            fuelType     = rdwData.brandstof;
                            owner        = rdwData.eigenaar;
                            manualMode   = true;
                          });
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
                        );
                      } finally {
                        setDialogState(() => isLoadingRdw = false);
                      }
                    },
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Handmatig invoeren'),
                  value: manualMode,
                  activeTrackColor: appColor,
                  onChanged: (v) => setDialogState(() => manualMode = v),
                ),
                if (manualMode) ...[
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type Voertuig'),
                    items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Naam')),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('APK Datum'),
                    subtitle: Text(apk == null ? 'Kies datum' : DateFormat('dd-MM-yyyy').format(apk!)),
                    trailing: apk != null ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => setDialogState(() => apk = null)) : null,
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: apk ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100), locale: const Locale('nl', 'NL'));
                      if (d != null) setDialogState(() => apk = d);
                    },
                  ),
                  TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Verzekering p/m'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  TextField(controller: tax, decoration: const InputDecoration(labelText: 'Wegenbelasting p/m'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appColor, foregroundColor: Colors.white),
              onPressed: () {
                if (plate.text.isEmpty) return;
                provider.addCar(Car(
                  name: name.text.isNotEmpty ? name.text : 'Auto',
                  licensePlate: RdwService.normalizeLicensePlate(plate.text),
                  type: selectedType,
                  apkDate: apk,
                  insurance: double.tryParse(insurance.text.replaceAll(',', '.')) ?? 0,
                  roadTax: double.tryParse(tax.text.replaceAll(',', '.')) ?? 0,
                  roadTaxFreq: 'Maandelijks',
                  fuelType: fuelType,
                  owner: owner,
                ));
                Navigator.pop(context);
              },
              child: const Text('Toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AccordionCard(
      title: 'Mijn Garage',
      icon: Icons.garage_outlined,
      appColor: appColor,
      children: [
        ...provider.cars.map((car) => _CarTreeItem(
          key: ValueKey(car.id),
          car: car,
          appColor: appColor,
          provider: provider,
          vehicleTypes: vehicleTypes,
          isDark: isDark,
          isExpanded: _expandedCars.contains(car.id),
          onToggle: () => setState(() {
            if (_expandedCars.contains(car.id)) {
              _expandedCars.remove(car.id);
            } else {
              _expandedCars.add(car.id!);
            }
          }),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _showAddCarDialog,
            icon: Icon(Icons.add, color: appColor),
            label: Text('Voertuig toevoegen', style: TextStyle(color: appColor)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: appColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Auto rij met uitklapbare subsecties ─────────────────────────────────────

class _CarTreeItem extends StatefulWidget {
  final Car car;
  final Color appColor;
  final DataProvider provider;
  final List<String> vehicleTypes;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _CarTreeItem({
    super.key,
    required this.car,
    required this.appColor,
    required this.provider,
    required this.vehicleTypes,
    required this.isDark,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_CarTreeItem> createState() => _CarTreeItemState();
}

class _CarTreeItemState extends State<_CarTreeItem> {
  bool _gegevensOpen  = false;
  bool _intervalsOpen = false;
  bool _kostenOpen    = false;
  bool _doelOpen      = false;

  IconData _iconFor(String type) {
    switch (type) {
      case 'Motor':       return Icons.motorcycle;
      case 'Vrachtwagen': return Icons.local_shipping;
      case 'Scooter':     return Icons.moped;
      default:            return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColor = widget.appColor;
    final isDark   = widget.isDark;
    final car      = widget.car;

    return Column(children: [
      // Auto header
      InkWell(
        onTap: widget.onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: appColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(car.type), color: appColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(car.licensePlate, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            )),
            AnimatedRotation(
              turns: widget.isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ]),
        ),
      ),

      // Subsecties
      if (widget.isExpanded) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(children: [
            _SubSection(
              title: 'Voertuiggegevens',
              icon: Icons.info_outline,
              appColor: appColor, isDark: isDark,
              isOpen: _gegevensOpen,
              onToggle: () => setState(() => _gegevensOpen = !_gegevensOpen),
              child: _GegevensForm(car: car, appColor: appColor, vehicleTypes: widget.vehicleTypes, provider: widget.provider),
            ),
            _SubSection(
              title: 'Onderhoud intervallen',
              icon: Icons.build_outlined,
              appColor: appColor, isDark: isDark,
              isOpen: _intervalsOpen,
              onToggle: () => setState(() => _intervalsOpen = !_intervalsOpen),
              child: _IntervalsForm(car: car, appColor: appColor, provider: widget.provider),
            ),
            _SubSection(
              title: 'Kosten',
              icon: Icons.euro_outlined,
              appColor: appColor, isDark: isDark,
              isOpen: _kostenOpen,
              onToggle: () => setState(() => _kostenOpen = !_kostenOpen),
              child: _KostenForm(car: car, appColor: appColor, provider: widget.provider),
            ),
            _SubSection(
              title: 'Doelstellingen',
              icon: Icons.flag_outlined,
              appColor: appColor, isDark: isDark,
              isOpen: _doelOpen,
              onToggle: () => setState(() => _doelOpen = !_doelOpen),
              child: _DoelstellingenForm(car: car, appColor: appColor, provider: widget.provider),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text('Voertuig verwijderen', style: TextStyle(color: Colors.red, fontSize: 13)),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Voertuig verwijderen'),
                  content: Text('Weet je zeker dat je "${car.name}" wilt verwijderen?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () { widget.provider.deleteCar(car.id!); Navigator.pop(context); },
                      child: const Text('Verwijderen'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
      ],
    ]);
  }
}

// ─── Generieke subsectie ─────────────────────────────────────────────────────

class _SubSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color appColor;
  final bool isDark;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  const _SubSection({
    required this.title, required this.icon, required this.appColor,
    required this.isDark, required this.isOpen, required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(children: [
            Icon(icon, size: 18, color: isOpen ? appColor : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(
              fontSize: 14,
              fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
              color: isOpen ? appColor : (isDark ? Colors.white70 : Colors.black87),
            ))),
            Icon(isOpen ? Icons.remove : Icons.add, size: 18,
              color: isOpen ? appColor : (isDark ? Colors.white38 : Colors.black38)),
          ]),
        ),
      ),
      if (isOpen) Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: child,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
    ]);
  }
}

// ─── Voertuiggegevens formulier ──────────────────────────────────────────────

class _GegevensForm extends StatefulWidget {
  final Car car;
  final Color appColor;
  final List<String> vehicleTypes;
  final DataProvider provider;
  const _GegevensForm({required this.car, required this.appColor, required this.vehicleTypes, required this.provider});
  @override State<_GegevensForm> createState() => _GegevensFormState();
}

class _GegevensFormState extends State<_GegevensForm> {
  late final TextEditingController _name;
  late final TextEditingController _plate;
  late String _type;
  late DateTime? _apk;
  bool _isLoadingRdw = false;

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.car.name);
    _plate = TextEditingController(text: widget.car.licensePlate);
    _type  = widget.vehicleTypes.contains(widget.car.type) ? widget.car.type : 'Auto';
    _apk   = widget.car.apkDate;
  }

  @override void dispose() { _name.dispose(); _plate.dispose(); super.dispose(); }

  InputDecoration _fieldDeco(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint, isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  void _save() {
    widget.provider.updateCar(widget.car.copyWith(
      name: _name.text,
      licensePlate: RdwService.normalizeLicensePlate(_plate.text),
      type: _type,
      apkDate: _apk,
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Voertuiggegevens opgeslagen'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColor = widget.appColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(
          controller: _plate,
          decoration: _fieldDeco('Kenteken'),
          textCapitalization: TextCapitalization.characters,
        )),
        const SizedBox(width: 8),
        IconButton(
          icon: _isLoadingRdw
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search, size: 20),
          tooltip: 'RDW opzoeken',
          onPressed: _isLoadingRdw ? null : () async {
            if (_plate.text.isEmpty) return;
            setState(() => _isLoadingRdw = true);
            try {
              final rdw = await RdwService.getVehicleData(_plate.text);
              if (rdw != null) setState(() {
                _name.text = rdw.getVehicleName();
                _type      = rdw.getVehicleType();
                _apk       = rdw.apkVervaldatum;
              });
            } finally { setState(() => _isLoadingRdw = false); }
          },
        ),
      ]),
      const SizedBox(height: 10),
      TextField(controller: _name, decoration: _fieldDeco('Naam')),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _type, isDense: true,
        decoration: _fieldDeco('Type'),
        items: widget.vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _type = v!),
      ),
      const SizedBox(height: 10),
      InkWell(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _apk ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100), locale: const Locale('nl', 'NL'));
          if (d != null) setState(() => _apk = d);
        },
        child: InputDecorator(
          decoration: _fieldDeco('APK Datum'),
          child: Text(_apk == null ? 'Kies datum' : DateFormat('dd-MM-yyyy').format(_apk!), style: const TextStyle(fontSize: 14)),
        ),
      ),
      if (widget.car.fuelType != null) ...[
        const SizedBox(height: 8),
        Text('Brandstof: ${widget.car.fuelType}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
      if (widget.car.owner != null)
        Text('Eigenaar: ${widget.car.owner}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: appColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: _save,
        child: const Text('Opslaan'),
      )),
    ]);
  }
}

// ─── Onderhoud intervallen formulier ─────────────────────────────────────────

class _IntervalsForm extends StatefulWidget {
  final Car car;
  final Color appColor;
  final DataProvider provider;
  const _IntervalsForm({required this.car, required this.appColor, required this.provider});
  @override State<_IntervalsForm> createState() => _IntervalsFormState();
}

class _IntervalsFormState extends State<_IntervalsForm> {
  late Map<String, MaintenanceInterval> _intervals;
  late Map<String, TextEditingController> _kmC;
  late Map<String, TextEditingController> _dayC;

  @override
  void initState() {
    super.initState();
    _intervals = Map.from(widget.car.maintenanceIntervals ?? {});
    _kmC  = {};
    _dayC = {};
    for (final type in kDefaultIntervals.keys) {
      final cur = _intervals[type] ?? kDefaultIntervals[type]!;
      _kmC[type]  = TextEditingController(text: cur.kmInterval?.toStringAsFixed(0) ?? '');
      _dayC[type] = TextEditingController(text: cur.dayInterval?.toString() ?? '');
    }
  }

  @override void dispose() {
    for (final c in _kmC.values) c.dispose();
    for (final c in _dayC.values) c.dispose();
    super.dispose();
  }

  void _save() {
    for (final type in kDefaultIntervals.keys) {
      final cur = _intervals[type] ?? kDefaultIntervals[type]!;
      _intervals[type] = MaintenanceInterval(
        enabled:     cur.enabled,
        kmInterval:  double.tryParse(_kmC[type]!.text),
        dayInterval: int.tryParse(_dayC[type]!.text),
      );
    }
    widget.provider.updateCar(widget.car.copyWith(maintenanceIntervals: _intervals));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Intervallen opgeslagen'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColor = widget.appColor;
    return Column(children: [
      ...kDefaultIntervals.entries.map((entry) {
        final type = entry.key;
        final def  = entry.value;
        final cur  = _intervals[type] ?? def;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Switch(
                value: cur.enabled, activeColor: appColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => setState(() => _intervals[type] = MaintenanceInterval(
                  enabled: val, kmInterval: cur.kmInterval, dayInterval: cur.dayInterval,
                )),
              ),
            ]),
            if (cur.enabled) Row(children: [
              Expanded(child: TextField(
                controller: _kmC[type],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Km', hintText: def.kmInterval?.toStringAsFixed(0) ?? 'geen',
                  suffixText: 'km', isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _dayC[type],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dagen', hintText: def.dayInterval?.toString() ?? 'geen',
                  suffixText: 'dgn', isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )),
            ]),
          ]),
        );
      }),
      SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: appColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: _save,
        child: const Text('Opslaan'),
      )),
    ]);
  }
}

// ─── Kosten formulier (alle kosten als recurring items) ─────────────────────

class _KostenForm extends StatefulWidget {
  final Car car;
  final Color appColor;
  final DataProvider provider;
  const _KostenForm({required this.car, required this.appColor, required this.provider});
  @override State<_KostenForm> createState() => _KostenFormState();
}

class _KostenFormState extends State<_KostenForm> {
  List<RecurringCost> _costs = [];
  bool _loadingCosts = true;

  // Inline nieuw/bewerk formulier
  RecurringCost? _editingCost; // null = nieuw, anders = bewerken
  bool _showForm = false;
  final TextEditingController _formName   = TextEditingController();
  final TextEditingController _formAmount = TextEditingController();
  final TextEditingController _formDesc   = TextEditingController();
  String _formFreq = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  @override
  void dispose() {
    _formName.dispose(); _formAmount.dispose(); _formDesc.dispose();
    super.dispose();
  }

  Future<void> _loadCosts() async {
    if (widget.car.id == null) return;
    final all = await DatabaseHelper.instance.getRecurringCostsByCar(widget.car.id!);
    if (mounted) setState(() { _costs = all; _loadingCosts = false; });
    // Refresh provider met het juiste car id
    await widget.provider.fetchRecurringCostsForCar(widget.car.id!);
  }

  void _openForm({RecurringCost? cost}) {
    setState(() {
      _editingCost = cost;
      _showForm    = true;
      _formName.text   = cost?.name   ?? '';
      _formAmount.text = cost != null ? cost.amount.toStringAsFixed(2).replaceAll('.', ',') : '';
      _formDesc.text   = cost?.description ?? '';
      _formFreq        = cost?.frequency ?? 'monthly';
    });
  }

  void _closeForm() => setState(() { _showForm = false; _editingCost = null; });

  Future<void> _saveForm() async {
    if (_formName.text.isEmpty) return;
    final amount = double.tryParse(_formAmount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    final cost = RecurringCost(
      id:          _editingCost?.id,
      carId:       widget.car.id!,
      name:        _formName.text,
      amount:      amount,
      frequency:   _formFreq,
      description: _formDesc.text.isEmpty ? null : _formDesc.text,
      isActive:    _editingCost?.isActive ?? true,
    );

    if (_editingCost == null) {
      await DatabaseHelper.instance.insertRecurringCost(cost);
    } else {
      await DatabaseHelper.instance.updateRecurringCost(cost);
    }

    _closeForm();
    _loadCosts();
  }

  Future<void> _toggleActive(RecurringCost cost) async {
    await DatabaseHelper.instance.updateRecurringCost(cost.copyWith(isActive: !cost.isActive));
    _loadCosts();
  }

  Future<void> _deleteCost(RecurringCost cost) async {
    await DatabaseHelper.instance.deleteRecurringCost(cost.id!);
    _loadCosts();
  }

  String _freqLabel(String freq) {
    switch (freq) {
      case 'yearly':    return 'per jaar';
      case 'quarterly': return 'per kwartaal';
      default:          return 'per maand';
    }
  }

  String _freqShort(String freq) {
    switch (freq) {
      case 'yearly':    return '/jr';
      case 'quarterly': return '/kw';
      default:          return '/mnd';
    }
  }

  InputDecoration _fieldDeco(String label, {String? prefix}) => InputDecoration(
    labelText: label, isDense: true,
    prefixText: prefix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  @override
  Widget build(BuildContext context) {
    final appColor = widget.appColor;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final activeCosts = _costs.where((c) => c.isActive).toList();
    final totalMnd = activeCosts.fold<double>(0, (s, c) => s + c.monthlyCost);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_loadingCosts)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
      else if (_costs.isEmpty && !_showForm)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Nog geen kosten toegevoegd. Voeg verzekering, wegenbelasting, abonnementen etc. toe.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
          ),
        )
      else
        ..._costs.map((cost) => _CostRow(
          cost: cost,
          appColor: appColor,
          isDark: isDark,
          freqShort: _freqShort(cost.frequency),
          onEdit: () => _openForm(cost: cost),
          onToggle: () => _toggleActive(cost),
          onDelete: () => _deleteCost(cost),
        )),

      // Totaal
      if (activeCosts.isNotEmpty && !_showForm) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: appColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Totaal per maand', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
              Text('€${totalMnd.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appColor)),
            ],
          ),
        ),
      ],

      // Inline formulier
      if (_showForm) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appColor.withValues(alpha: 0.05),
            border: Border.all(color: appColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            TextField(
              controller: _formName,
              decoration: _fieldDeco('Naam (bijv. Verzekering, ANWB)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _formAmount,
                decoration: _fieldDeco('Bedrag', prefix: '€ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                value: _formFreq,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Frequentie', isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly',   child: Text('Per maand',    style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'quarterly', child: Text('Per kwartaal', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'yearly',    child: Text('Per jaar',     style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) => setState(() => _formFreq = v!),
              )),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _formDesc,
              decoration: _fieldDeco('Omschrijving (optioneel)'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _closeForm,
                child: const Text('Annuleer'),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: appColor, foregroundColor: Colors.white),
                onPressed: _saveForm,
                child: Text(_editingCost == null ? 'Toevoegen' : 'Opslaan'),
              )),
            ]),
          ]),
        ),
      ],

      // Toevoegen knop
      if (!_showForm) ...[
        const SizedBox(height: 10),
        TextButton.icon(
          icon: Icon(Icons.add_circle_outline, size: 18, color: appColor),
          label: Text('Kost toevoegen', style: TextStyle(color: appColor, fontSize: 13)),
          onPressed: () => _openForm(),
        ),
      ],
    ]);
  }
}

// ─── Kosten rij ──────────────────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  final RecurringCost cost;
  final Color appColor;
  final bool isDark;
  final String freqShort;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CostRow({
    required this.cost,
    required this.appColor,
    required this.isDark,
    required this.freqShort,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
          color: cost.isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: cost.isActive ? appColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.euro, size: 16,
              color: cost.isActive ? appColor : Colors.grey),
          ),
          title: Text(cost.name,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              decoration: cost.isActive ? null : TextDecoration.lineThrough,
              color: cost.isActive ? null : Colors.grey,
            )),
          subtitle: cost.description != null
              ? Text(cost.description!, style: const TextStyle(fontSize: 11))
              : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('€${cost.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(freqShort, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
            ]),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: isDark ? Colors.white38 : Colors.black38),
              onSelected: (v) {
                if (v == 'edit')   onEdit();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: appColor), const SizedBox(width: 8), const Text('Bewerken'),
                ])),
                PopupMenuItem(value: 'toggle', child: Row(children: [
                  Icon(cost.isActive ? Icons.pause_outlined : Icons.play_arrow_outlined,
                    size: 18, color: Colors.orange), const SizedBox(width: 8),
                  Text(cost.isActive ? 'Pauzeren' : 'Activeren'),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red), const SizedBox(width: 8),
                  const Text('Verwijderen', style: TextStyle(color: Colors.red)),
                ])),
              ],
            ),
          ]),
          onTap: onEdit,
        ),
      ),
    );
  }
}

// ─── Doelstellingen form ──────────────────────────────────────────────────────

class _DoelstellingenForm extends StatefulWidget {
  final Car car;
  final Color appColor;
  final DataProvider provider;
  const _DoelstellingenForm({required this.car, required this.appColor, required this.provider});
  @override State<_DoelstellingenForm> createState() => _DoelstellingenFormState();
}

class _DoelstellingenFormState extends State<_DoelstellingenForm> {
  late TextEditingController _maxPriceCtrl;
  late TextEditingController _efficiencyCtrl;
  late TextEditingController _monthlyKmCtrl;

  @override
  void initState() {
    super.initState();
    _maxPriceCtrl   = TextEditingController(text: widget.car.goalMaxFuelPrice?.toStringAsFixed(3).replaceAll('.', ',') ?? '');
    _efficiencyCtrl = TextEditingController(text: widget.car.goalEfficiency?.toStringAsFixed(1).replaceAll('.', ',') ?? '');
    _monthlyKmCtrl  = TextEditingController(text: widget.car.goalMonthlyKm?.toString() ?? '');
  }

  @override
  void dispose() {
    _maxPriceCtrl.dispose();
    _efficiencyCtrl.dispose();
    _monthlyKmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final maxPrice   = double.tryParse(_maxPriceCtrl.text.replaceAll(',', '.'));
    final efficiency = double.tryParse(_efficiencyCtrl.text.replaceAll(',', '.'));
    final monthlyKm  = int.tryParse(_monthlyKmCtrl.text);

    final updated = widget.car.copyWith(
      goalMaxFuelPrice: maxPrice,
      goalEfficiency:   efficiency,
      goalMonthlyKm:    monthlyKm,
    );
    await widget.provider.updateCar(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Doelstellingen opgeslagen'), backgroundColor: widget.appColor, duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hint = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Max brandstofprijs
          _GoalField(
            label: 'Max brandstofprijs',
            hint: 'bijv. 2,10',
            suffix: '€/L',
            icon: Icons.local_gas_station_outlined,
            controller: _maxPriceCtrl,
            appColor: widget.appColor,
            isDark: isDark,
            description: 'Waarschuwing bij invoer boven dit bedrag',
          ),
          const SizedBox(height: 12),
          // Verbruiksdoel
          _GoalField(
            label: 'Verbruiksdoel',
            hint: 'bijv. 17,5',
            suffix: 'km/L',
            icon: Icons.speed_outlined,
            controller: _efficiencyCtrl,
            appColor: widget.appColor,
            isDark: isDark,
            description: 'Zichtbaar in de efficiëntiekaart',
          ),
          const SizedBox(height: 12),
          // Maandelijks km-doel
          _GoalField(
            label: 'Maandelijks km-doel',
            hint: 'bijv. 1500',
            suffix: 'km',
            icon: Icons.route_outlined,
            controller: _monthlyKmCtrl,
            appColor: widget.appColor,
            isDark: isDark,
            keyboardType: TextInputType.number,
            description: 'Voortgangsbalk op het dashboard',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.appColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Opslaan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;
  final TextEditingController controller;
  final Color appColor;
  final bool isDark;
  final String description;
  final TextInputType keyboardType;

  const _GoalField({
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
    required this.controller,
    required this.appColor,
    required this.isDark,
    required this.description,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: appColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: appColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}