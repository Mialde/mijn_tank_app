import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart'; 
import 'data_provider.dart';
import 'services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
      create: (context) => DataProvider()..loadData(), 
      child: const TankBuddyApp()));
}

// =============================================================================
// 1. HOOFD APP CONFIGURATIE & THEMA
// =============================================================================

class TankBuddyApp extends StatelessWidget {
  const TankBuddyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardColor: Colors.white,
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: data.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// 2. NAVIGATIE STRUKTUUR
// =============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _curr = 0;
  bool _showEgg = false;
  bool _isTimeMachine = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _curr = i),
          children: [
            const TankbeurtScreen(),
            const StatsScreen(), 
            SettingsScreen(onEasterEgg: (isTimeMachine) => setState(() { _isTimeMachine = isTimeMachine; _showEgg = true; }))
          ],
        ),
        if (_showEgg) ZoomCarEasterEgg(isTimeMachine: _isTimeMachine, onFinished: () => setState(() => _showEgg = false)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _curr,
        onDestinationSelected: (i) {
          setState(() => _curr = i);
          _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_gas_station_rounded), label: 'Tanken'),
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overzicht'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Instellingen'),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. TAB 1: TANKBEURT INVOEREN
// =============================================================================

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

// =============================================================================
// 4. TAB 2: DASHBOARD & STATISTIEKEN (StatsScreen)
// =============================================================================

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _selCarId;
  final _statsCarDisplayCtrl = TextEditingController();
  
  final List<String> _allPossibleTiles = ['cons', 'apk', 'price', 'dist', 'liters', 'hist'];
  
  List<String> _activeTileKeys = ['cons', 'apk', 'price', 'dist', 'liters', 'hist'];
  List<String> _hiddenTileKeys = [];

  bool _showApkDate = false;

  @override
  void initState() {
    super.initState();
    _loadTileConfig();
  }

  Future<void> _loadTileConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('tile_order');
    final savedHidden = prefs.getStringList('hidden_tiles');

    if (savedOrder != null && savedOrder.isNotEmpty) {
      final validSaved = savedOrder.where((k) => _allPossibleTiles.contains(k)).toList();
      final missing = _allPossibleTiles.where((k) => !validSaved.contains(k));
      setState(() {
        _activeTileKeys = [...validSaved, ...missing];
      });
    }
    if (savedHidden != null) {
      setState(() {
        _hiddenTileKeys = savedHidden;
      });
    }
  }

  Future<void> _saveTileConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tile_order', _activeTileKeys);
    await prefs.setStringList('hidden_tiles', _hiddenTileKeys);
  }

  String _getTileTitle(String key) {
    switch (key) {
      case 'cons': return "Verbruik Meter";
      case 'apk': return "APK Status";
      case 'price': return "Literprijs";
      case 'dist': return "Laatste Rit";
      case 'liters': return "Getankt";
      case 'hist': return "Geschiedenis";
      default: return key;
    }
  }

  void _showEditSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Dashboard Tegels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Klaar")),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ReorderableListView(
                        padding: const EdgeInsets.all(16),
                        onReorder: (oldIndex, newIndex) {
                          setSheetState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final String item = _activeTileKeys.removeAt(oldIndex);
                            _activeTileKeys.insert(newIndex, item);
                          });
                          setState(() {}); 
                          _saveTileConfig();
                        },
                        children: _activeTileKeys.map((key) {
                          final isHidden = _hiddenTileKeys.contains(key);
                          return ListTile(
                            key: ValueKey(key),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            leading: Icon(Icons.drag_handle, color: Colors.grey[400]),
                            title: Text(_getTileTitle(key), style: TextStyle(fontWeight: FontWeight.bold, color: isHidden ? Colors.grey : null)),
                            trailing: Switch(
                              value: !isHidden,
                              activeTrackColor: Colors.blueAccent,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val) {
                                    _hiddenTileKeys.remove(key);
                                  } else {
                                    _hiddenTileKeys.add(key);
                                  }
                                });
                                setState(() {});
                                _saveTileConfig();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    
    if (_selCarId == null && data.cars.isNotEmpty) { 
      _selCarId = data.cars.first.id; 
    }
    Car? selectedCar;
    if (_selCarId != null && data.cars.isNotEmpty) {
      selectedCar = data.cars.firstWhere((c) => c.id == _selCarId, orElse: () => data.cars.first);
      _statsCarDisplayCtrl.text = selectedCar.name;
    }

    final stats = data.getStats(_selCarId);
    final entries = data.getEntriesForCar(_selCarId);
    double lastLiters = 0;
    String lastDate = "---";
    if (entries.isNotEmpty) {
      entries.sort((a, b) => b['date'].compareTo(a['date']));
      lastLiters = (entries.first['liters'] as num).toDouble();
      DateTime dt = DateTime.parse(entries.first['date']);
      lastDate = "${dt.day}-${dt.month}-${dt.year}";
    }
    stats['lastLiters'] = lastLiters; 

    final visibleTiles = _activeTileKeys.where((k) => !_hiddenTileKeys.contains(k)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          const SizedBox(height: 20),
          const Text("Voertuig", style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          
          TextField(
            controller: _statsCarDisplayCtrl, 
            readOnly: true, 
            decoration: _deco("", 
              _selCarId != null && data.cars.isNotEmpty 
                ? data.getVehicleIcon(data.cars.firstWhere((c) => c.id == _selCarId).type) 
                : Icons.directions_car_outlined, 
              suffix: data.cars.length > 1 ? const Icon(Icons.arrow_drop_down, color: Colors.blueAccent) : null
            ), 
            onTap: () {
              if (data.cars.isEmpty) return;
              showModalBottomSheet(
                context: context, 
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(20), 
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      const Text("Kies een voertuig", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                      const SizedBox(height: 10), 
                      ...data.cars.map((c) => ListTile(
                        leading: Icon(data.getVehicleIcon(c.type), color: Colors.blueAccent), 
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                        subtitle: Text(c.licensePlate ?? ""), 
                        onTap: () { 
                          setState(() => _selCarId = c.id); 
                          Navigator.pop(ctx); 
                        }, 
                        trailing: _selCarId == c.id ? const Icon(Icons.check_circle, color: Colors.green) : null
                      ))
                    ]
                  )
                )
              );
            }
          ),
          
          const SizedBox(height: 24),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, 
            ),
            itemCount: visibleTiles.length,
            itemBuilder: (context, index) {
              final key = visibleTiles[index];
              return _buildTileContent(key, stats, selectedCar, lastDate);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTileContent(String key, Map<String, dynamic> stats, Car? car, String lastDate) {
    final double avg = stats['avgCons'];
    final double last = stats['lastCons'];
    
    // Gauge berekening
    double gEnd = (avg / 5).ceil() * 5.0;
    if (gEnd < 5) gEnd = 5; 
    double maxScale = gEnd;
    double gStart = gEnd - 5.0;
    double oStart = gStart - 5.0;
    if (oStart < 0) oStart = 0;

    Widget content;
    switch (key) {
      case 'cons':
        content = _consumptionTile(avg, last, maxScale, oStart, gStart);
        break;
      case 'apk':
        content = _apkTile(car);
        break;
      case 'price':
        content = _simpleGridTile("Literprijs", "€${stats['lastPrice'].toStringAsFixed(3)}", Icons.euro_symbol_rounded, Colors.green);
        break;
      case 'dist':
        content = _simpleGridTile("Laatste Rit", "${stats['lastDist'].toStringAsFixed(0)} KM", Icons.map_rounded, Colors.purpleAccent);
        break;
      case 'liters':
        // Aangepaste Liters tegel
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LitersDetailPage(carId: _selCarId))),
          onLongPress: _showEditSheet,
          child: _litersTile(stats['lastLiters'], lastDate),
        );
      case 'hist':
        content = _historyGridTile(Icons.history_rounded, Colors.blueAccent);
        break;
      default:
        content = const SizedBox();
    }

    if (key == 'liters') return content;

    return GestureDetector(
      onLongPress: _showEditSheet,
      child: content,
    );
  }

  Widget _simpleGridTile(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: c, size: 32),
          const SizedBox(height: 12),
          Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  // NIEUWE SPECIFIEKE TEGEL VOOR LITERS
  Widget _litersTile(double liters, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Getankt", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Icon(Icons.water_drop_rounded, color: Colors.teal, size: 20),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${liters.toStringAsFixed(1)} L",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              date,
              style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyGridTile(IconData i, Color c) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage(carId: _selCarId))),
      onLongPress: _showEditSheet, 
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(24), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: c, size: 32),
            const SizedBox(height: 12),
            Text("Geschiedenis", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text("Bekijken", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        )
      ),
    );
  }

  Widget _consumptionTile(double avg, double last, double max, double oStart, double gStart) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsumptionDetailPage(carId: _selCarId))),
      onLongPress: _showEditSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Verbruik", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Icon(Icons.local_gas_station_rounded, color: Colors.orange, size: 20),
              ],
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: GaugePainter(
                          value: last,
                          max: max,
                          oStart: oStart,
                          gStart: gStart,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      Positioned(
                        bottom: -24, 
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.transparent, 
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            last.toStringAsFixed(1).replaceAll('.', ','),
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w900, 
                                fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Gem. 1L op ${avg.toStringAsFixed(1)}KM",
                style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int m) {
    const months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    if (m < 1 || m > 12) return "";
    return months[m - 1];
  }

  Widget _apkTile(Car? car) {
    String mainCenterText = "---";
    String upperLeftText = "nog";
    String lowerRightText = "dagen";
    String footerText = "N.v.t.";
    Color ringColor = Colors.green;
    double progress = 0.0;
    final themeTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    double centerSize = _showApkDate ? 22.0 : 32.0;
    double labelSize = _showApkDate ? 11.0 : 14.0;
    final labelStyle = TextStyle(fontSize: labelSize, fontWeight: FontWeight.bold, color: themeTextColor, height: 1.0);

    if (car?.apkDate != null) {
      final apk = DateTime.parse(car!.apkDate!);
      final now = DateTime.now();
      final fullDateStr = DateFormat('dd-MM-yyyy').format(apk);
      final diff = apk.difference(now).inDays + 1; 
      if (diff < 30) { ringColor = Colors.red; } else if (diff < 60) { ringColor = Colors.orange; } else { ringColor = Colors.green; }
      progress = (diff / 365).clamp(0.0, 1.0);

      if (_showApkDate) {
        upperLeftText = "tot";
        mainCenterText = "${apk.day} ${_getMonthAbbr(apk.month)}";
        lowerRightText = "geldig";
        String suffix = "dagen";
        if (diff == 1) suffix = "dag";
        footerText = "$diff $suffix";
      } else {
        upperLeftText = "nog";
        mainCenterText = diff.toString();
        String suffix = "dagen";
        if (diff == 1) suffix = "dag";
        lowerRightText = suffix;
        footerText = fullDateStr;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showApkDate = !_showApkDate;
        });
      },
      onLongPress: _showEditSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("APK", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Icon(Icons.fact_check_outlined, color: Colors.blueAccent, size: 20),
              ],
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        painter: ApkRingPainter(
                          progress: progress,
                          color: ringColor,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white10 
                              : Colors.grey[200]!,
                        ),
                      ),
                    ),
                  ),
                  IntrinsicWidth(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(upperLeftText, style: labelStyle),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            mainCenterText,
                            style: TextStyle(
                              fontSize: centerSize,
                              fontWeight: FontWeight.w900,
                              color: ringColor,
                              height: 1.0
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(lowerRightText, style: labelStyle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                footerText, 
                style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) => InputDecoration(
    labelText: label.isEmpty ? null : label, 
    prefixIcon: Icon(icon, color: Colors.blueAccent), 
    suffixIcon: suffix, 
    filled: true, 
    fillColor: Theme.of(context).cardColor, 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)), 
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
  );
}

// =============================================================================
// 5. NIEUWE PAGINA: LITERS DETAIL (MET SCROLLBARE GRAFIEK & LIJST)
// =============================================================================

class LitersDetailPage extends StatelessWidget {
  final int? carId;
  const LitersDetailPage({super.key, this.carId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final entries = data.getEntriesForCar(carId);
    entries.sort((a, b) => a['date'].compareTo(b['date'])); 

    // 1. Data voorbereiden: Groepeer per maand (Year-Month key)
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in entries) {
      DateTime dt = DateTime.parse(e['date']);
      String key = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(e);
    }
    
    // Sorteer sleutels voor de grafiek (Oud -> Nieuw)
    final sortedKeys = grouped.keys.toList()..sort();
    
    // Sorteer sleutels voor de lijst (Nieuw -> Oud)
    final reversedKeys = sortedKeys.reversed.toList();

    double totalLiters = 0;
    if (entries.isNotEmpty) {
      totalLiters = entries.map((e) => (e['liters'] as num).toDouble()).reduce((a, b) => a + b);
    }
    double avgLiters = entries.isNotEmpty ? totalLiters / entries.length : 0;

    // Kleurenpalet
    final List<Color> stackColors = [
      Colors.teal, Colors.blueAccent, Colors.orange, Colors.purpleAccent, 
      Colors.redAccent, Colors.green, Colors.amber, Colors.indigo, Colors.pink
    ];

    // 2. Grafiek data bouwen
    List<BarChartGroupData> bars = [];
    double maxTotal = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      String key = sortedKeys[i];
      List<Map<String, dynamic>> monthEntries = grouped[key]!;
      
      double currentY = 0;
      List<BarChartRodStackItem> stacks = [];
      
      for (int j = 0; j < monthEntries.length; j++) {
        double val = (monthEntries[j]['liters'] as num).toDouble();
        Color color = stackColors[j % stackColors.length];
        
        stacks.add(BarChartRodStackItem(currentY, currentY + val, color));
        currentY += val;
      }

      if (currentY > maxTotal) maxTotal = currentY;

      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: currentY,
            width: 24, // Iets smaller voor elegante 6-op-een-rij
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            rodStackItems: stacks,
          )
        ],
        showingTooltipIndicators: [], // GEEN waardes boven de staaf
      ));
    }

    double maxY = ((maxTotal / 10).ceil() * 10.0) + 10;
    if (maxY == maxTotal + 10) { maxY = maxTotal; } 

    return Scaffold(
      appBar: AppBar(title: const Text("Getankte Liters")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // BEREKENING VOOR PRECIES 6 STAVEN OP HET SCHERM
              // We willen dat 6 staven precies de breedte van het scherm vullen.
              // Als er minder data is, blijven de staven links en is rechts leeg.
              // Als er meer data is, wordt de chart breder en kun je scrollen.
              
              double screenWidth = constraints.maxWidth;
              double widthPerBarSlot = screenWidth / 6; 
              
              // Totale breedte van de chart container
              double finalChartWidth = max(screenWidth, sortedKeys.length * widthPerBarSlot);

              // Padding tussen groepen berekenen (Slot breedte - Bar breedte)
              double spacing = widthPerBarSlot - 24; // 24 is de bar width

              return Container(
                height: 220, // LAGER zoals gevraagd
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 10), // Padding links weggehaald, chart regelt dit
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: finalChartWidth,
                    padding: const EdgeInsets.only(left: 10, right: 10), // Algemene padding voor scrollview
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.start, // Links uitlijnen!
                        groupsSpace: spacing, // Dynamische ruimte zodat het precies past
                        barGroups: bars,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40, // Ruimte voor Y-as labels en afstand tot 1e staaf
                              interval: 10,
                              getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            )
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (val, meta) {
                                int idx = val.toInt();
                                if (idx >= 0 && idx < sortedKeys.length) {
                                  List<String> parts = sortedKeys[idx].split('-');
                                  int m = int.parse(parts[1]);
                                  const mNames = ["", "Jan", "Feb", "Mrt", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"];
                                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(mNames[m], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
                                }
                                return const SizedBox();
                              },
                            )
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.grey, width: 1),
                            left: BorderSide(color: Colors.grey, width: 1),
                            top: BorderSide.none,
                            right: BorderSide.none,
                          )
                        ),
                        barTouchData: BarTouchData(enabled: false), // Geen interactie op de grafiek zelf
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statCard(context, "Totaal Getankt", "${totalLiters.toStringAsFixed(0)} L", Icons.water_drop, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _statCard(context, "Gemiddeld p/beurt", "${avgLiters.toStringAsFixed(2)} L", Icons.functions, Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 24),
          
          // LIJST MET MAANDKAARTEN
          ...reversedKeys.map((key) {
             List<Map<String, dynamic>> monthEntries = grouped[key]!;
             double monthTotal = monthEntries.map((e) => (e['liters'] as num).toDouble()).reduce((a, b) => a + b);
             
             List<String> parts = key.split('-');
             int m = int.parse(parts[1]);
             int y = int.parse(parts[0]);
             const mNames = ["", "Januari", "Februari", "Maart", "April", "Mei", "Juni", "Juli", "Augustus", "September", "Oktober", "November", "December"];
             String monthName = "${mNames[m]} $y";

             return Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Theme.of(context).cardColor,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(monthName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       Text("${monthTotal.toStringAsFixed(1).replaceAll('.', ',')} L", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                     ],
                   ),
                   const Divider(),
                   ...monthEntries.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var e = entry.value;
                      double l = (e['liters'] as num).toDouble();
                      DateTime d = DateTime.parse(e['date']);
                      Color dotColor = stackColors[idx % stackColors.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Text("${l.toStringAsFixed(1).replaceAll('.', ',')} L", style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text("op ${d.day} ${mNames[d.month].toLowerCase()}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      );
                   }),
                 ],
               ),
             );
          }),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. CONSUMPTION DETAIL PAGINA
// =============================================================================

class ConsumptionDetailPage extends StatefulWidget {
  final int? carId;
  const ConsumptionDetailPage({super.key, this.carId});
  @override
  State<ConsumptionDetailPage> createState() => _ConsumptionDetailPageState();
}

class _ConsumptionDetailPageState extends State<ConsumptionDetailPage> {
  bool isBarChart = true;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    
    // 1. DATA OPHALEN & VOORBEREIDEN
    List<Map<String, dynamic>> rawEntries = data.getEntriesForCar(widget.carId);
    rawEntries.sort((a, b) => b['date'].compareTo(a['date'])); // Nieuw naar Oud

    List<Map<String, dynamic>> calculatedData = [];
    
    // Statistiek variabelen
    double bestRun = 0;
    int bestRunDays = 0;
    
    double worstRun = 0; 
    int worstRunDays = 0;

    int totalDays = 0; // Totaal aantal dagen
    
    bool firstValidRunFound = false;

    if (rawEntries.length > 1) {
      for (int i = 0; i < rawEntries.length - 1; i++) {
        double dist = (rawEntries[i]['odometer'] as num).toDouble() - (rawEntries[i+1]['odometer'] as num).toDouble();
        double liters = (rawEntries[i]['liters'] as num).toDouble();
        
        DateTime currDate = DateTime.parse(rawEntries[i]['date']);
        DateTime prevDate = DateTime.parse(rawEntries[i+1]['date']);
        int days = currDate.difference(prevDate).inDays;
        if (days == 0) days = 1; 

        if (dist > 0 && liters > 0) {
          double cons = dist / liters;
          totalDays += days;

          if (!firstValidRunFound) {
            worstRun = cons; 
            worstRunDays = days;
            
            bestRun = cons;
            bestRunDays = days;
            
            firstValidRunFound = true;
          }

          if (cons > bestRun) {
            bestRun = cons;
            bestRunDays = days;
          }
          if (cons < worstRun) {
            worstRun = cons;
            worstRunDays = days;
          }

          calculatedData.add({
            'val': cons,
            'date': rawEntries[i]['date']
          });
        }
      }
    }
    
    final chartData = calculatedData.reversed.toList();

    double averageVal = 0;
    if (chartData.isNotEmpty) {
      averageVal = chartData.map((e) => e['val'] as double).reduce((a, b) => a + b) / chartData.length;
    }

    // --- LOGICA VOOR SCROLLEN & UITLIJNING (Ongewijzigd) ---
    double totalPadding = 88; 
    double screenAvailableWidth = MediaQuery.of(context).size.width - totalPadding;
    int minItemsOnScreen = 10;
    double slotWidth = screenAvailableWidth / minItemsOnScreen;
    double barWidth = slotWidth * 0.5; 

    int totalSlots = max(chartData.length, minItemsOnScreen);
    double totalChartWidth = slotWidth * totalSlots;

    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    double maxY = _calculateMaxY(chartData);

    double xMin = -0.5;
    double xMax = totalSlots - 0.5;

    return Scaffold(
      appBar: AppBar(title: const Text("Verbruik Details")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // GRAFIEK CONTAINER (CARD)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Knoppen rechts
                  children: [
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(value: true, icon: Icon(Icons.bar_chart)),
                        ButtonSegment(value: false, icon: Icon(Icons.show_chart)),
                      ],
                      selected: {isBarChart},
                      onSelectionChanged: (val) => setState(() => isBarChart = val.first),
                    ),
                  ],
                ),
                const SizedBox(height: 4), 
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalChartWidth,
                    height: 220, 
                    padding: const EdgeInsets.only(top: 30, bottom: 0),
                    child: chartData.isEmpty 
                      ? const Center(child: Text("Nog niet genoeg data (minimaal 2 tankbeurten)"))
                      : isBarChart 
                        ? _buildBarChart(chartData, totalSlots, averageVal, barWidth, textColor, maxY, bestRun, worstRun) 
                        : _buildLineChart(chartData, averageVal, textColor, maxY, xMin, xMax, bestRun, worstRun),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), 
          
          if (chartData.isNotEmpty)
            Column(
              children: [
                _detailedStatCard(
                  title: "Zuinigste verbruik",
                  val: bestRun,
                  days: bestRunDays,
                  color: Colors.green,
                  icon: Icons.eco_rounded,
                  compareText: "Dit was ${worstRun > 0 ? ((bestRun - worstRun) / worstRun * 100).toStringAsFixed(0) : '0'}% zuiniger dan je slechtste rit en ${averageVal > 0 ? ((bestRun - averageVal) / averageVal * 100).toStringAsFixed(0) : '0'}% beter dan gemiddeld.",
                  iconCompare: Icons.trending_up,
                ),
                const SizedBox(height: 16),
                _detailedStatCard(
                  title: "Minst zuinige verbruik",
                  val: worstRun,
                  days: worstRunDays,
                  color: Colors.orange,
                  icon: Icons.warning_amber_rounded,
                  compareText: "Dit was ${averageVal > 0 ? ((averageVal - worstRun) / averageVal * 100).abs().toStringAsFixed(0) : '0'}% minder zuinig dan je gemiddelde verbruik.",
                  iconCompare: Icons.trending_down,
                ),
                const SizedBox(height: 16),
                _detailedStatCard(
                  title: "Gemiddeld verbruik",
                  val: averageVal,
                  days: totalDays,
                  color: Colors.blueAccent,
                  icon: Icons.functions_rounded, 
                  compareText: null, // GEEN TEKST
                  iconCompare: null, // GEEN ICOON
                ),
              ],
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _detailedStatCard({
    required String title,
    required double val,
    required int days,
    required Color color,
    required IconData icon,
    String? compareText, // Optioneel
    IconData? iconCompare, // Optioneel
  }) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("1 op", style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 2.5)),
              const SizedBox(width: 6),
              Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          _infoLine(Icons.calendar_today_outlined, "Gemeten over totaal $days ${days == 1 ? 'dag' : 'dagen'}.", bodyColor),
          
          if (compareText != null && iconCompare != null) ...[
             const SizedBox(height: 8),
            _infoLine(iconCompare, compareText, bodyColor),
          ]
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text, Color? color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 10),
          child: Icon(icon, size: 16, color: color?.withValues(alpha: 0.7) ?? Colors.grey),
        ),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color?.withValues(alpha: 0.8), height: 1.3)),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate);
      return DateFormat('dd-MM').format(dt);
    } catch (e) {
      return "";
    }
  }

  double _calculateMaxY(List<Map<String, dynamic>> data) {
    double maxVal = 0;
    if (data.isNotEmpty) {
      maxVal = data.map((e) => e['val'] as double).reduce(max);
    }
    double target = maxVal + 5;
    return (target / 5).ceil() * 5.0;
  }

  FlBorderData _getBorderData() {
    return FlBorderData(
      show: true,
      border: const Border(
        bottom: BorderSide(color: Colors.grey, width: 1.5), 
        left: BorderSide(color: Colors.grey, width: 1.5),   
        top: BorderSide.none,
        right: BorderSide.none,
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, int totalSlots, double avg, double barW, Color textColor, double sharedMaxY, double bestRun, double worstRun) {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < totalSlots; i++) {
      if (i < data.length) {
        
        double val = data[i]['val'];
        Color barColor = Colors.blueAccent;
        if (val == bestRun) barColor = Colors.green;
        else if (val == worstRun) barColor = Colors.orange;

        groups.add(BarChartGroupData(
          x: i, 
          showingTooltipIndicators: [0],
          barRods: [BarChartRodData(
            toY: val, 
            color: barColor, 
            width: barW, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          )] 
        ));
      } else {
        groups.add(BarChartGroupData(
          x: i, 
          showingTooltipIndicators: [], 
          barRods: [BarChartRodData(
            toY: 0, 
            color: Colors.transparent, 
            width: barW, 
          )] 
        ));
      }
    }

    return BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, 
        maxY: sharedMaxY,
        minY: 0,
        barGroups: groups,
        
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, 
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: avg, color: Colors.grey, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, labelResolver: (l) => "Gem", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), alignment: Alignment.topRight))
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30,
            interval: 5, 
            getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          )), 
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            interval: 1, 
            reservedSize: 30,
            getTitlesWidget: (val, meta) {
              int idx = val.toInt();
              if (idx >= 0 && idx < data.length) {
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_formatDate(data[idx]['date']), style: const TextStyle(fontSize: 10)));
              }
              return const SizedBox();
            }
          )), 
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
        ),
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4, 
            getTooltipColor: (group) => Colors.transparent, 
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rod.toY == 0) return null;
              return BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11),
              );
            },
          ),
        ),
        borderData: _getBorderData(), 
      ));
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, double avg, Color textColor, double sharedMaxY, double xMin, double xMax, double bestRun, double worstRun) {
    final lineChartBarData = LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['val'])).toList(), 
      isCurved: true, 
      color: Colors.blueAccent, 
      barWidth: 3, 
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          Color dotColor = Colors.blueAccent;
          if (spot.y == bestRun) {
            dotColor = Colors.green;
          } else if (spot.y == worstRun) {
            dotColor = Colors.orange;
          }

          return FlDotCirclePainter(
            radius: 4,
            color: dotColor,
            strokeWidth: 0, 
          );
        }
      ),
    );

    return LineChart(LineChartData(
        minY: 0,
        maxY: sharedMaxY, 
        minX: xMin, 
        maxX: xMax, 
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: true, 
          horizontalInterval: 5,
          verticalInterval: 1, 
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: avg, color: Colors.grey, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, labelResolver: (l) => "Gem", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), alignment: Alignment.topRight))
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30,
            interval: 5, 
            getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          )), 
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            interval: 1, 
            reservedSize: 30,
            getTitlesWidget: (val, meta) {
              if (val % 1 != 0) return const SizedBox();
              int idx = val.toInt();
              if (idx >= 0 && idx < data.length) {
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_formatDate(data[idx]['date']), style: const TextStyle(fontSize: 10)));
              }
              return const SizedBox();
            }
          )), 
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))
        ),
        
        borderData: _getBorderData(), 

        showingTooltipIndicators: data.asMap().entries.map((entry) {
          return ShowingTooltipIndicators([
            LineBarSpot(
              lineChartBarData,
              0, 
              lineChartBarData.spots[entry.key],
            ),
          ]);
        }).toList(),
        
        lineBarsData: [lineChartBarData],
        
        lineTouchData: LineTouchData(
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.transparent, 
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 10, 
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900),
                );
              }).toList();
            },
          ),
        ),
      ));
  }
}

// =============================================================================
// 7. GAUGE PAINTER
// =============================================================================

class GaugePainter extends CustomPainter {
  final double value; 
  final double max;   
  final double oStart; 
  final double gStart; 
  final bool isDark;

  GaugePainter({required this.value, required this.max, required this.oStart, required this.gStart, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.45;
    final strokeWidth = size.width * 0.14;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth;

    paint.color = Colors.red.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, (oStart / max) * pi, false, paint);

    paint.color = Colors.orange.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + (oStart / max) * pi, ((gStart - oStart) / max) * pi, false, paint);

    paint.color = Colors.green.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi + (gStart / max) * pi, ((max - gStart) / max) * pi, false, paint);

    final tickPaint = Paint()..color = isDark ? Colors.white54 : Colors.black45..style = PaintingStyle.stroke;

    for (int i = 0; i <= max.toInt(); i++) {
      double angle = pi + (i / max) * pi;
      bool isMajor = i % 5 == 0;
      tickPaint.strokeWidth = isMajor ? 1.5 : 0.8;
      double len = isMajor ? 8 : 4;
      
      double innerR = radius + (strokeWidth / 2);
      double outerR = innerR + len;
      
      Offset p1 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      Offset p2 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    final needlePaint = Paint()..color = isDark ? Colors.white : Colors.black..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    double displayVal = value > max ? max : (value < 0 ? 0 : value);
    double needleAngle = pi + (displayVal / max) * pi;
    
    Offset pStart = Offset(center.dx + (radius * 0.45) * cos(needleAngle), center.dy + (radius * 0.45) * sin(needleAngle));
    Offset pEnd = Offset(center.dx + (radius * 1.05) * cos(needleAngle), center.dy + (radius * 1.05) * sin(needleAngle));
    canvas.drawLine(pStart, pEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// 8. APK RING PAINTER
// =============================================================================

class ApkRingPainter extends CustomPainter {
  final double progress; 
  final Color color;
  final Color backgroundColor;

  ApkRingPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Dikte ring aangepast naar 9.0 (dunner van binnenuit)
    final strokeWidth = 9.0;
    final radius = min(size.width, size.height) / 2 - (strokeWidth / 2); 

    // Achtergrond ring (grijs)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Voorgrond ring (kleur)
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Tegen de klok in
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, -(progress * 2 * pi), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// 9. HISTORIE PAGINA
// =============================================================================

class HistoryPage extends StatelessWidget {
  final int? carId;
  const HistoryPage({super.key, this.carId});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final entries = data.getEntriesForCar(carId);
    return Scaffold(
        appBar: AppBar(title: const Text("Geschiedenis")),
        body: entries.isEmpty
            ? const Center(child: Text("Geen tankbeurten gevonden."))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.local_gas_station, color: Colors.white, size: 20)),
                    title: Text("€${entries[i]['price_total']}  -  ${entries[i]['liters']} L"),
                    subtitle: Text("${entries[i]['date'].substring(0, 10)} | KM: ${entries[i]['odometer']}"),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => DatabaseHelper.instance.deleteEntry(entries[i]['id']).then((_) => data.loadData())))));
  }
}

// =============================================================================
// 10. TAB 3: INSTELLINGEN
// =============================================================================

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onEasterEgg;
  const SettingsScreen({super.key, required this.onEasterEgg});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _clicks = 0;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final user = data.user;
    Widget buildToggle(int value, Function(int) onChanged) {
      return SizedBox(width: 100, child: SegmentedButton<int>(showSelectedIcon: false, style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: WidgetStateProperty.all(EdgeInsets.zero)), segments: const [ButtonSegment(value: 0, label: Text("O", style: TextStyle(fontWeight: FontWeight.bold))), ButtonSegment(value: 1, label: Text("I", style: TextStyle(fontWeight: FontWeight.bold)))], selected: {value}, onSelectionChanged: (Set<int> newSelection) => onChanged(newSelection.first)));
    }
    return SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 20), // STANDAARD HOOGTE REFERENTIE
                      _section("Personalisatie"),
                      ListTile(title: const Text("Naam aanpassen"), subtitle: Text(user['first_name'] ?? "Bestuurder"), leading: const Icon(Icons.person_outline, color: Colors.blueAccent), onTap: () => _nameDlg(context, data)),
                      ListTile(title: const Text("Begroeting"), leading: const Icon(Icons.waving_hand_outlined, color: Colors.blueAccent), trailing: buildToggle(user['use_greeting'] ?? 1, (v) => data.updateUserSettings({'use_greeting': v}))),
                      ListTile(title: const Text("Quotes"), leading: const Icon(Icons.format_quote_outlined, color: Colors.blueAccent), trailing: buildToggle(user['show_quotes'] ?? 1, (v) => data.updateUserSettings({'show_quotes': v}))),
                      ListTile(title: const Text("Thema"), leading: const Icon(Icons.palette_outlined, color: Colors.blueAccent), trailing: SizedBox(width: 150, child: SegmentedButton<String>(showSelectedIcon: false, style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: WidgetStateProperty.all(EdgeInsets.zero)), segments: const [ButtonSegment(value: 'light', icon: Icon(Icons.wb_sunny_outlined, size: 20)), ButtonSegment(value: 'dark', icon: Icon(Icons.nightlight_round_outlined, size: 20)), ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto, size: 20))], selected: {user['theme_mode'] ?? 'system'}, onSelectionChanged: (Set<String> newSelection) => data.updateUserSettings({'theme_mode': newSelection.first})))) ,
                      const SizedBox(height: 24),
                      _section("Garage"),
                      ListTile(title: const Text("Voertuig beheer"), subtitle: const Text("Toevoegen, wijzigen en verwijderen"), leading: const Icon(Icons.directions_car_outlined, color: Colors.blueAccent), trailing: const Icon(Icons.chevron_right), onTap: () => _manageCars(context, data)),
                      const SizedBox(height: 24),
                      _section("Systeem"),
                      ListTile(title: const Text("Backup maken"), subtitle: const Text("Lokaal of Delen"), leading: const Icon(Icons.upload_file, color: Colors.blueAccent), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.save, color: Colors.blueAccent), tooltip: "Lokaal opslaan", onPressed: () async { await data.saveLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup lokaal opgeslagen!"))); } }), IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Delen / Exporteren", onPressed: () => data.exportDataShare())])),
                      ListTile(title: const Text("Backup herstellen"), subtitle: const Text("Lokaal of Bestand"), leading: const Icon(Icons.download_rounded, color: Colors.blueAccent), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.restore, color: Colors.blueAccent), tooltip: "Lokaal herstellen", onPressed: () async { bool success = await data.importLocalBackup(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Lokale backup hersteld!" : "Geen lokale backup gevonden."))); } }), IconButton(icon: const Icon(Icons.folder_open, color: Colors.blueAccent), tooltip: "Bestand kiezen", onPressed: () async { bool success = await data.importDataPicker(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Backup hersteld!" : "Geen bestand gekozen."))); } })])),
                      ListTile(title: const Text("Excel Export"), subtitle: const Text("Opslaan als CSV"), leading: const Icon(Icons.table_view, color: Colors.blueAccent), trailing: IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), tooltip: "Excel/CSV delen", onPressed: () => data.exportCSV())),
                      const SizedBox(height: 20),
                      ListTile(title: const Text("Alle data wissen", style: TextStyle(color: Colors.red)), leading: const Icon(Icons.delete_forever_outlined, color: Colors.red), onTap: () => _clearDlg(context, data)),
                ])),
                Padding(padding: const EdgeInsets.all(20), child: GestureDetector(onTap: () { if (++_clicks >= 7) { _clicks = 0; bool isDeLorean = data.cars.any((c) => c.licensePlate?.toUpperCase() == 'OUTATIME'); widget.onEasterEgg(isDeLorean); } }, child: const Text("TankBuddy v1.1.00", style: TextStyle(color: Colors.grey)))),
              ],
            )));
      },
    ));
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.w600)));
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
    final n = TextEditingController(text: car?.name); final k = TextEditingController(text: car?.licensePlate);
    String type = car?.type ?? 'auto'; DateTime? apk = car?.apkDate != null ? DateTime.parse(car!.apkDate!) : null;
    final dCtrl = TextEditingController(text: apk != null ? DateFormat('dd-MM-yyyy').format(apk) : "");
    final types = ['auto', 'motor', 'scooter', 'vrachtwagen', 'trekker', 'bus', 'camper'];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(title: Text(car == null ? "Nieuw Voertuig" : "Voertuig Wijzigen"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: "Soort Voertuig", border: OutlineInputBorder()), items: types.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(data.getVehicleIcon(t), color: Colors.grey), const SizedBox(width: 10), Text(t[0].toUpperCase() + t.substring(1))]))).toList(), onChanged: (v) => setS(() => type = v!)
                      ), const SizedBox(height: 16), TextField(controller: n, decoration: const InputDecoration(labelText: "Naam", border: OutlineInputBorder())), const SizedBox(height: 16), TextField(controller: k, decoration: const InputDecoration(labelText: "Kenteken", border: OutlineInputBorder())), const SizedBox(height: 16), TextField(controller: dCtrl, readOnly: true, decoration: const InputDecoration(labelText: "APK Vervaldatum", border: OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_month, color: Colors.blueAccent)), onTap: () async { 
                        final d = await showDatePicker(context: context, initialDate: apk ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); 
                        if (d != null) { setS(() => apk = d); dCtrl.text = DateFormat('dd-MM-yyyy').format(d); }})])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuleren")), ElevatedButton(onPressed: () { if (n.text.isEmpty) { return; } data.updateCar(Car(id: car?.id, name: n.text, licensePlate: k.text, apkDate: apk?.toIso8601String(), type: type)); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), child: const Text("Opslaan"))])));
  }
}

// =============================================================================
// 11. PAAS-EI ANIMATIE
// =============================================================================

class ZoomCarEasterEgg extends StatefulWidget {
  final VoidCallback onFinished; final bool isTimeMachine;
  const ZoomCarEasterEgg({super.key, required this.onFinished, required this.isTimeMachine});
  @override State<ZoomCarEasterEgg> createState() => _ZoomCarEasterEggState();
}
class _ZoomCarEasterEggState extends State<ZoomCarEasterEgg> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _scale; late Animation<double> _opacity;
  @override void initState() {
    super.initState();
    int duration = widget.isTimeMachine ? 6 : 4;
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: duration));
    _scale = Tween<double>(begin: 0.1, end: 35.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInQuad));
    _opacity = TweenSequence([TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15), TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70), TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15)]).animate(_ctrl);
    _ctrl.forward().then((_) => widget.onFinished());
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Center(child: AnimatedBuilder(animation: _ctrl, builder: (context, child) {
              return Opacity(opacity: _opacity.value, child: Transform.scale(scale: _scale.value, child: widget.isTimeMachine ? Icon(Icons.rocket_launch, size: 80, color: Colors.blueGrey[300]) : Stack(alignment: Alignment.center, children: [const Icon(Icons.directions_car, size: 100, color: Colors.blue), Positioned(bottom: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5), decoration: BoxDecoration(color: Colors.yellow, border: Border.all(color: Colors.black, width: 0.5), borderRadius: BorderRadius.circular(1)), child: const Text("53ND NUD35", style: TextStyle(color: Colors.black, fontSize: 5, fontWeight: FontWeight.bold, letterSpacing: 0.5))))])));
    }));
  }
}