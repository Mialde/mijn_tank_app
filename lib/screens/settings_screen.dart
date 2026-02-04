import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../data_provider.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBugEgg;      
  final Function(bool) onRocketEgg; 
  
  const SettingsScreen({
    super.key, 
    required this.onBugEgg, 
    required this.onRocketEgg
  });
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  int _clicks = 0;
  late ConfettiController _confettiCtrl;
  
  late AnimationController _pulseCtrl;
  late Animation<Color?> _pulseColor;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseColor = ColorTween(begin: Colors.grey[400], end: Colors.greenAccent[700]).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _cycleTheme(DataProvider data) {
    String current = data.user['theme_mode'] ?? 'system';
    String next = 'system';
    
    if (current == 'system') {
      next = 'light';
    } else if (current == 'light') {
      next = 'dark';
    } else if (current == 'dark') {
      next = 'system';
    }

    data.updateUserSettings({'theme_mode': next});
  }

  IconData _getThemeIcon(String? mode) {
    switch (mode) {
      case 'light': return Icons.wb_sunny_rounded;
      case 'dark': return Icons.nightlight_round_rounded;
      default: return Icons.brightness_auto_rounded;
    }
  }

  String _getThemeText(String? mode) {
    switch (mode) {
      case 'light': return "Licht";
      case 'dark': return "Donker";
      default: return "Systeem";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final user = data.user;
    
    String carTitle = data.cars.length > 1 ? "Voertuigen" : "Voertuig";

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const SizedBox(height: 20), 

                // --- SECTIE 1: PERSONALISATIE ---
                _buildSectionHeader("Personalisatie"),
                _buildSettingsCard(context, [
                  _buildListTile(
                    icon: Icons.person_outline,
                    title: "Naam", 
                    subtitle: user['first_name'] ?? "Bestuurder",
                    onTap: () => _nameDlg(context, data),
                  ),
                  _buildDivider(),
                  
                  // Begroeting Toggle
                  _buildListTile(
                    icon: Icons.waving_hand_outlined,
                    title: "Begroeting",
                    subtitle: (user['use_greeting'] ?? 1) == 1 ? "Staat aan" : "Staat uit",
                    trailing: _buildVisibilityIcon(
                      isOn: (user['use_greeting'] ?? 1) == 1,
                      onTap: () => data.updateUserSettings({'use_greeting': (user['use_greeting'] ?? 1) == 1 ? 0 : 1}),
                    ),
                  ),
                  _buildDivider(),

                  // Quotes Toggle
                  _buildListTile(
                    icon: Icons.format_quote_outlined,
                    title: "Quotes",
                    subtitle: (user['show_quotes'] ?? 1) == 1 ? "Staat aan" : "Staat uit",
                    trailing: _buildVisibilityIcon(
                      isOn: (user['show_quotes'] ?? 1) == 1,
                      onTap: () => data.updateUserSettings({'show_quotes': (user['show_quotes'] ?? 1) == 1 ? 0 : 1}),
                    ),
                  ),
                  _buildDivider(),

                  // Thema
                  _buildListTile(
                    icon: Icons.palette_outlined,
                    title: "Thema",
                    subtitle: _getThemeText(user['theme_mode']),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(_getThemeIcon(user['theme_mode']), color: Colors.blueAccent),
                    ),
                    onTap: () => _cycleTheme(data),
                  ),
                ]),

                const SizedBox(height: 24),

                // --- SECTIE 2: GARAGE ---
                _buildSectionHeader("Garage"),
                _buildSettingsCard(context, [
                  _buildListTile(
                    icon: Icons.directions_car_outlined,
                    title: carTitle, 
                    subtitle: "Toevoegen, wijzigen en verwijderen",
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _manageCars(context, data),
                  ),
                ]),

                const SizedBox(height: 24),

                // --- SECTIE 3: SYSTEEM ---
                _buildSectionHeader("Systeem"),
                _buildSettingsCard(context, [
                  
                  // >>> GEHEIME OPTIE <<<
                  if (data.secretUnlocked) ...[
                    AnimatedBuilder(
                      animation: _pulseColor,
                      builder: (context, child) {
                        return _buildListTile(
                          icon: Icons.local_gas_station,
                          title: "Gratis Tanken Modus",
                          subtitle: "Schakel 100% korting in",
                          iconColor: Colors.amber,
                          textColor: Colors.amber[800],
                          trailing: IconButton(
                            icon: const Icon(Icons.power_settings_new),
                            color: _pulseColor.value, // De pulserende kleur
                            iconSize: 28,
                            onPressed: () {
                               _confettiCtrl.play();
                               showDialog(
                                 context: context, 
                                 builder: (ctx) => AlertDialog(
                                   title: const Text("Grapje!"), 
                                   content: const Text("Was het maar zo'n feest.\nMaar dromen mag altijd..."),
                                   actions: [
                                     TextButton(
                                       onPressed: () {
                                         data.lockSecret();
                                         Navigator.pop(ctx);
                                       }, 
                                       child: const Text("Oké")
                                     )
                                   ]
                                 )
                               );
                            },
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                  ],
                  // >>> EINDE GEHEIME OPTIE <<<

                  _buildListTile(
                    icon: Icons.upload_file,
                    title: "Backup maken",
                    subtitle: "Lokaal of Delen",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.save, color: Colors.blueAccent), tooltip: "Lokaal opslaan", onPressed: () async { await data.saveLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup lokaal opgeslagen!"))); } }),
                        IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Delen / Exporteren", onPressed: () => data.exportDataShare())
                      ],
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.download_rounded,
                    title: "Backup herstellen",
                    subtitle: "Lokaal of Bestand",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.restore, color: Colors.blueAccent), tooltip: "Lokaal herstellen", onPressed: () async { bool success = await data.importLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Lokale backup hersteld!" : "Geen lokale backup gevonden."))); } }),
                        IconButton(icon: const Icon(Icons.folder_open, color: Colors.blueAccent), tooltip: "Bestand kiezen", onPressed: () async { bool success = await data.importDataPicker(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Backup hersteld!" : "Geen bestand gekozen."))); } })
                      ],
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.table_view,
                    title: "Excel Export",
                    subtitle: "Opslaan als CSV",
                    trailing: IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Excel/CSV delen", onPressed: () => data.exportCSV()),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: Colors.red,
                    title: "Alle data wissen",
                    textColor: Colors.red,
                    onTap: () => _clearDlg(context, data),
                  ),
                ]),

                const SizedBox(height: 40),
                
                // VERSIE & TRIGGERS
                Center(
                  child: GestureDetector(
                    onTap: () { 
                      if (++_clicks >= 7) { 
                        _clicks = 0; 
                        widget.onBugEgg(); 
                      } 
                    },
                    onLongPress: () {
                        bool isDeLorean = data.cars.any((c) => c.licensePlate?.toUpperCase() == 'OUTATIME'); 
                        widget.onRocketEgg(isDeLorean);
                    },
                    child: Text(
                      "TankBuddy v1.1.09", 
                      style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)
                    )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive, 
            shouldLoop: false, 
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            createParticlePath: drawStar, 
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep), halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.w600)
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    // AANGEPAST: Gewoon weer Container, dus geen Material ripple effect.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, 
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing, 
    VoidCallback? onTap,
    Color iconColor = Colors.blueAccent,
    Color? textColor,
  }) {
    // AANGEPAST: ListTile gewikkeld in Theme om splash onzichtbaar te maken
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildVisibilityIcon({required bool isOn, required VoidCallback onTap, Color color = Colors.blueAccent}) {
    return IconButton(
      icon: Icon(isOn ? Icons.visibility_off : Icons.visibility),
      color: isOn ? Colors.grey : color,
      onPressed: onTap,
      tooltip: isOn ? "Uitzetten" : "Aanzetten",
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1, 
      thickness: 0.5, 
      color: Colors.grey.withValues(alpha: 0.2),
      indent: 16, 
      endIndent: 16,
    );
  }

  // --- LOGICA ---

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
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: "Soort Voertuig", border: OutlineInputBorder()), items: types.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(data.getVehicleIcon(t), color: Colors.grey), const SizedBox(width: 10), Text(t[0].toUpperCase() + t.substring(1))]))).toList(), onChanged: (v) => setS(() => type = v!)), 
          const SizedBox(height: 16), TextField(controller: n, decoration: const InputDecoration(labelText: "Naam", border: OutlineInputBorder())), 
          const SizedBox(height: 16), TextField(controller: k, decoration: const InputDecoration(labelText: "Kenteken", border: OutlineInputBorder())), 
          const SizedBox(height: 16), TextField(controller: insCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Verzekering (p/mnd)", border: OutlineInputBorder(), prefixText: "€ ")),
          const SizedBox(height: 16), Row(children: [Expanded(child: TextField(controller: taxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Wegenbelasting", border: OutlineInputBorder(), prefixText: "€ "))), const SizedBox(width: 8), SizedBox(width: 110, child: DropdownButtonFormField<String>(value: taxFreq, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)), items: const [DropdownMenuItem(value: 'month', child: Text("p/mnd")), DropdownMenuItem(value: 'quarter', child: Text("p/kwrt"))], onChanged: (v) => setS(() => taxFreq = v!)))]),
          const SizedBox(height: 16), TextField(controller: dCtrl, readOnly: true, decoration: const InputDecoration(labelText: "APK Vervaldatum", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month, color: Colors.blueAccent)), onTap: () async { final d = await showDatePicker(context: context, initialDate: apk ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030), locale: const Locale('nl')); if (d != null) { setS(() => apk = d); dCtrl.text = DateFormat('dd-MM-yyyy').format(d); }})
        ])), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), 
        ElevatedButton(
          onPressed: () { 
            if (n.text.isEmpty) { return; } 
            double? ins = double.tryParse(insCtrl.text.replaceAll(',', '.'));
            double? tax = double.tryParse(taxCtrl.text.replaceAll(',', '.'));
            data.updateCar(Car(id: car?.id, name: n.text, licensePlate: k.text, apkDate: apk?.toIso8601String(), type: type, insurance: ins, roadTax: tax, roadTaxFreq: taxFreq)); 
            Navigator.pop(ctx); 
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), 
          child: const Text("Opslaan")
        )
      ]
    )));
  }
}