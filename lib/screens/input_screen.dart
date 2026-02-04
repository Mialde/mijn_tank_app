import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../data_provider.dart'; // Let op de puntjes: we gaan één map omhoog

class TankbeurtScreen extends StatefulWidget {
  const TankbeurtScreen({super.key});
  @override
  State<TankbeurtScreen> createState() => _TankbeurtScreenState();
}

class _TankbeurtScreenState extends State<TankbeurtScreen> {
  int? _selId;
  DateTime _date = DateTime.now();
  final _o = TextEditingController(), _l = TextEditingController(), _p = TextEditingController();
  final _carDisplayCtrl = TextEditingController();
  String _randomQuote = "";

  final List<String> _quotes = [
    "Volgooien is een kunst.", "Jij bent de motor van dit geheel.", "Lekker slangetje hoor.", "Even die spuit erin hangen.", "Klaar voor een ritje?",
    "Wat zie je er goed uit in die spiegel.", "Gas erop!", "Hij zit er weer diep in.", "Jij maakt deze auto onbetaalbaar.", "Tijd voor een pitstop, kampioen.",
    "Jij straalt meer dan je koplampen.", "Even lekker pompen.", "Vol tot aan het randje.", "Jij stuurt als de beste.", "Die zit weer lekker vol.",
    "Laat die motor maar ronken.", "Jij bent heter dan mijn motorblok.", "Riemen vast, daar gaan we.", "Tank leeg, karakter vol.", "Geen berg te hoog voor jou.",
    "Soepel schakelen is jouw ding.", "Jij bent de turbo in mijn day.", "Niet morsen he...", "Klaar voor de start?", "Jouw glimlach is mijn brandstof.",
    "Zullen we nog een rondje?", "Even bijtanken, kanjer.", "Jij hebt de controle.", "Spiegeltje, spiegeltje, what a driver.", "Hou 'm recht vandaag!",
    "Jij bent goud waard (net als benzine).", "Lekker bezig pik.", "Glij 'm er maar in.", "Volgas het weekend in.", "Jij bent de APK van mijn hart.",
    "Hoge toeren, lage zorgen.", "Wat een prachtige bumper.", "Jij mag er zijn, bestuurder.", "Lekker cruisen vandaag.", "Handjes aan het stuur.",
    "Jij bent niet te stoppen.", "Alles geven vandaag!", "Mooie velgen, maar jij bent mooier.", "Tank vol, blik op oneindig.", "Even ontladen en opladen.",
    "Jij bent mijn favoriete route.", "Vroem vroem, tijger.", "Zuinig op jou.", "Jij bent limited edition.", "Dat was weer een lekkere beurt."
  ];

  @override
  void initState() { super.initState(); _randomQuote = _quotes[Random().nextInt(_quotes.length)]; }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    if (_selId == null && data.cars.isNotEmpty) { _selId = data.cars.first.id; }
    if (_selId != null && data.cars.isNotEmpty) {
      final selectedCar = data.cars.firstWhere((c) => c.id == _selId, orElse: () => data.cars.first);
      _carDisplayCtrl.text = selectedCar.name;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (data.user['use_greeting'] == 1)
                    Text(data.getGreeting(), style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(data.user['first_name'] ?? "Bestuurder", style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, height: 1.1, color: isDark ? Colors.white : Colors.black87))),
                  if (data.user['show_quotes'] == 1)
                    Padding(padding: const EdgeInsets.only(top: 8, bottom: 40), child: Text(_randomQuote, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey[600]))),
                  TextField(controller: _carDisplayCtrl, readOnly: true, decoration: _deco("Voertuig", _selId != null && data.cars.isNotEmpty ? data.getVehicleIcon(data.cars.firstWhere((c) => c.id == _selId).type) : Icons.directions_car_outlined, suffix: data.cars.length > 1 ? const Icon(Icons.arrow_drop_down, color: Colors.blueAccent) : null), onTap: () {
                        if (data.cars.isEmpty) { return; }
                        showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Kies een voertuig", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), ...data.cars.map((c) => ListTile(leading: Icon(data.getVehicleIcon(c.type), color: Colors.blueAccent), title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(c.licensePlate ?? ""), onTap: () { setState(() => _selId = c.id); Navigator.pop(ctx); }, trailing: _selId == c.id ? const Icon(Icons.check_circle, color: Colors.green) : null))])));
                      }),
                  const SizedBox(height: 16),
                  TextField(controller: _o, keyboardType: TextInputType.number, decoration: _deco("Kilometerstand", Icons.speed)),
                  const SizedBox(height: 16),
                  TextField(controller: _l, keyboardType: TextInputType.number, decoration: _deco("Liters", Icons.opacity)),
                  const SizedBox(height: 16),
                  TextField(controller: _p, keyboardType: TextInputType.number, decoration: _deco("Prijs (€)", Icons.euro)),
                  const SizedBox(height: 16),
                  TextField(readOnly: true, controller: TextEditingController(text: DateFormat('dd-MM-yyyy').format(_date)), decoration: _deco("Datum", Icons.calendar_today), onTap: () async {
                        final res = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (res != null) { setState(() => _date = res); }
                      }),
                ],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(24.0), child: SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () {
                        if (_selId == null || _o.text.isEmpty) { return; }
                        data.addEntry(_selId!, _date, double.tryParse(_o.text.replaceAll(',', '.')) ?? 0, double.tryParse(_l.text.replaceAll(',', '.')) ?? 0, double.tryParse(_p.text.replaceAll(',', '.')) ?? 0);
                        _o.clear(); _l.clear(); _p.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rit opgeslagen!"), behavior: SnackBarBehavior.floating));
                      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("TOEVOEGEN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))),
        ],
      ),
    );
  }
  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) => InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.blueAccent), suffixIcon: suffix, filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20));
}