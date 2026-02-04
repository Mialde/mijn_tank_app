import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_provider.dart';
import '../widgets/painters.dart';

import '../details/liters_detail_page.dart';
import '../details/consumption_detail_page.dart';
import 'history_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _selCarId;
  final _statsCarDisplayCtrl = TextEditingController();
  
  final List<String> _allPossibleTiles = ['cons', 'apk', 'price', 'dist', 'liters', 'cost', 'hist'];
  
  List<String> _activeTileKeys = ['cons', 'apk', 'price', 'dist', 'liters', 'cost', 'hist'];
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
      case 'cost': return "Kosten p/km"; 
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
    
    // --- BEREKENINGEN VOOR DASHBOARD ---
    double lastLiters = 0;
    String lastDate = "---";
    double trueCostPerKm = 0;

    if (entries.isNotEmpty) {
      entries.sort((a, b) => b['date'].compareTo(a['date']));
      lastLiters = (entries.first['liters'] as num).toDouble();
      DateTime dt = DateTime.parse(entries.first['date']);
      lastDate = "${dt.day}-${dt.month}-${dt.year}";

      if (entries.length > 1) {
        var sorted = List<Map<String, dynamic>>.from(entries);
        sorted.sort((a, b) => a['date'].compareTo(b['date']));
        double startOdo = (sorted.first['odometer'] as num).toDouble();
        double endOdo = (sorted.last['odometer'] as num).toDouble();
        double totalDist = endOdo - startOdo;
        double totalFuelCost = sorted.map((e) => (e['price_total'] as num).toDouble()).reduce((a, b) => a + b);

        double fixedMonthly = 0;
        if (selectedCar != null) {
          fixedMonthly += (selectedCar.insurance ?? 0);
          double tax = (selectedCar.roadTax ?? 0);
          if (selectedCar.roadTaxFreq == 'quarter') { fixedMonthly += (tax / 3); } 
          else { fixedMonthly += tax; }
        }

        DateTime startDt = DateTime.parse(sorted.first['date']);
        DateTime endDt = DateTime.parse(sorted.last['date']);
        int daysDiff = endDt.difference(startDt).inDays;
        if (daysDiff < 1) daysDiff = 1; 
        double monthsActive = daysDiff / 30.44; 

        double totalFixedCost = fixedMonthly * monthsActive;
        double totalAllCosts = totalFuelCost + totalFixedCost;

        if (totalDist > 0) {
          trueCostPerKm = totalAllCosts / totalDist;
        }
      }
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text("Kies een voertuig", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                      const SizedBox(height: 10), 
                      ...data.cars.map((c) => ListTile(
                        leading: Icon(data.getVehicleIcon(c.type), color: Colors.blueAccent), 
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                        subtitle: Text(c.licensePlate ?? ""), 
                        onTap: () { setState(() => _selCarId = c.id); Navigator.pop(ctx); }, 
                        trailing: _selCarId == c.id ? const Icon(Icons.check_circle, color: Colors.green) : null
                      ))
                  ])
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
              return _buildTileContent(key, stats, selectedCar, lastDate, trueCostPerKm);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- AANGEPAST: Geen Material/InkWell meer, maar pure GestureDetector ---
  Widget _baseTile({required Widget child, required VoidCallback onTap, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? _showEditSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          // De schaduw blijft, maar de klik is onzichtbaar
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: child,
      ),
    );
  }

  Widget _buildTileContent(String key, Map<String, dynamic> stats, Car? car, String lastDate, double costPk) {
    final double avg = stats['avgCons'];
    final double last = stats['lastCons'];
    
    // Gauge berekening
    double gEnd = (avg / 5).ceil() * 5.0;
    if (gEnd < 5) gEnd = 5; 
    double maxScale = gEnd;
    double gStart = gEnd - 5.0;
    double oStart = gStart - 5.0;
    if (oStart < 0) oStart = 0;

    switch (key) {
      case 'cons':
        return _consumptionTile(avg, last, maxScale, oStart, gStart);
      case 'apk':
        return _apkTile(car);
      case 'price':
        return _simpleGridTile("Literprijs", "€${stats['lastPrice'].toStringAsFixed(3)}", Icons.euro_symbol_rounded, Colors.green);
      case 'dist':
        return _simpleGridTile("Laatste Rit", "${stats['lastDist'].toStringAsFixed(0)} KM", Icons.map_rounded, Colors.purpleAccent);
      case 'liters':
        return _litersTile(stats['lastLiters'], lastDate);
      case 'cost':
        return _simpleGridTile("Kosten p/km", "€${costPk.toStringAsFixed(2)}", Icons.currency_exchange, Colors.amber[700]!);
      case 'hist':
        return _historyGridTile(Icons.history_rounded, Colors.blueAccent);
      default:
        return const SizedBox();
    }
  }

  Widget _simpleGridTile(String t, String v, IconData i, Color c) {
    return _baseTile(
      onTap: () {}, 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: c, size: 32),
          const SizedBox(height: 12),
          Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _litersTile(double liters, String date) {
    return _baseTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LitersDetailPage(carId: _selCarId))),
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
                child: Text("${liters.toStringAsFixed(1)} L", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(date, style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _historyGridTile(IconData i, Color c) {
    return _baseTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage(carId: _selCarId))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: c, size: 32),
          const SizedBox(height: 12),
          Text("Geschiedenis", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text("Bekijken", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _consumptionTile(double avg, double last, double max, double oStart, double gStart) {
    return _baseTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsumptionDetailPage(carId: _selCarId))),
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
                      painter: GaugePainter(value: last, max: max, oStart: oStart, gStart: gStart, isDark: Theme.of(context).brightness == Brightness.dark),
                    ),
                    Positioned(
                      bottom: -24, 
                      child: Container(
                        width: 60, height: 60,
                        alignment: Alignment.center,
                        child: Text(last.toStringAsFixed(1).replaceAll('.', ','), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w900, fontSize: 18)),
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
            child: Text("Gem. 1L op ${avg.toStringAsFixed(1)}KM", style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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

    return _baseTile(
      onTap: () => setState(() => _showApkDate = !_showApkDate),
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
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                  ),
                ),
                IntrinsicWidth(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: Text(upperLeftText, style: labelStyle)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(mainCenterText, style: TextStyle(fontSize: centerSize, fontWeight: FontWeight.w900, color: ringColor, height: 1.0)),
                      ),
                      Align(alignment: Alignment.centerRight, child: Text(lowerRightText, style: labelStyle)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(footerText, style: TextStyle(fontSize: 8.5, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // AANGEPAST: De functie weer toegevoegd om crash te voorkomen
  String _getMonthAbbr(int m) {
    const months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    if (m < 1 || m > 12) return "";
    return months[m - 1];
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