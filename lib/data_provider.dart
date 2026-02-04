import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// MODEL CLASSES
// =============================================================================

class Car {
  final int? id;
  final String name;
  final String? licensePlate;
  final String type; // 'auto', 'motor', etc.
  final String? apkDate;
  
  // NIEUWE VELDEN VOOR TCO
  final double? insurance;    // Bedrag per maand
  final double? roadTax;      // Bedrag per maand of kwartaal
  final String roadTaxFreq;   // 'month' of 'quarter'

  Car({
    this.id, 
    required this.name, 
    this.licensePlate, 
    this.type = 'auto', 
    this.apkDate,
    this.insurance,
    this.roadTax,
    this.roadTaxFreq = 'month',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license_plate': licensePlate,
      'type': type,
      'apk_date': apkDate,
      'insurance': insurance,
      'road_tax': roadTax,
      'road_tax_freq': roadTaxFreq,
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      name: map['name'],
      licensePlate: map['license_plate'],
      type: map['type'] ?? 'auto',
      apkDate: map['apk_date'],
      insurance: map['insurance'] != null ? (map['insurance'] as num).toDouble() : 0.0,
      roadTax: map['road_tax'] != null ? (map['road_tax'] as num).toDouble() : 0.0,
      roadTaxFreq: map['road_tax_freq'] ?? 'month',
    );
  }
}

// =============================================================================
// DATA PROVIDER (STATE MANAGEMENT)
// =============================================================================

class DataProvider extends ChangeNotifier {
  List<Car> _cars = [];
  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic> _user = {};
  ThemeMode _themeMode = ThemeMode.system;
  
  // EASTER EGG STATUS
  bool _secretUnlocked = false;

  List<Car> get cars => _cars;
  Map<String, dynamic> get user => _user;
  ThemeMode get themeMode => _themeMode;
  bool get secretUnlocked => _secretUnlocked;

  Future<void> loadData() async {
    _cars = await DatabaseHelper.instance.getCars();
    _entries = await DatabaseHelper.instance.getEntries();
    _user = await DatabaseHelper.instance.getUserSettings();
    
    // Thema laden
    String? t = _user['theme_mode'];
    if (t == 'light') {
      _themeMode = ThemeMode.light;
    } else if (t == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Secret laden
    final prefs = await SharedPreferences.getInstance();
    _secretUnlocked = prefs.getBool('secret_unlocked') ?? false;

    notifyListeners();
  }

  // --- EASTER EGG ACTIONS ---
  Future<void> unlockSecret() async {
    _secretUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('secret_unlocked', true);
    notifyListeners();
  }

  // NIEUW: Secret weer verbergen
  Future<void> lockSecret() async {
    _secretUnlocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('secret_unlocked', false);
    notifyListeners();
  }

  // --- CAR ACTIONS ---
  Future<void> addCar(Car car) async {
    await DatabaseHelper.instance.addCar(car);
    await loadData();
  }

  Future<void> updateCar(Car car) async {
    if (car.id == null) {
      await addCar(car);
    } else {
      await DatabaseHelper.instance.updateCar(car);
      await loadData();
    }
  }

  Future<void> deleteCar(int id) async {
    await DatabaseHelper.instance.deleteCar(id);
    await loadData();
  }

  // --- ENTRY ACTIONS ---
  Future<void> addEntry(int carId, DateTime date, double odo, double liters, double price) async {
    double pricePerLiter = liters > 0 ? price / liters : 0;
    Map<String, dynamic> entry = {
      'car_id': carId,
      'date': date.toIso8601String(),
      'odometer': odo,
      'liters': liters,
      'price_total': price,
      'price_per_liter': pricePerLiter
    };
    await DatabaseHelper.instance.addEntry(entry);
    await loadData();
  }

  // --- SETTINGS ACTIONS ---
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await DatabaseHelper.instance.updateUser(updates);
    await loadData();
  }

  // --- HELPERS ---
  List<Map<String, dynamic>> getEntriesForCar(int? carId) {
    if (carId == null) return [];
    return _entries.where((e) => e['car_id'] == carId).toList();
  }

  Map<String, dynamic> getStats(int? carId) {
    final list = getEntriesForCar(carId);
    if (list.isEmpty) return {'avgCons': 0.0, 'lastCons': 0.0, 'lastPrice': 0.0, 'lastDist': 0.0};

    // Sorteer op datum (oud -> nieuw)
    list.sort((a, b) => a['date'].compareTo(b['date']));

    double totalDist = 0;
    double totalLiters = 0;
    double lastCons = 0;
    double lastDist = 0;

    // Gemiddeld verbruik berekening
    if (list.length > 1) {
      double startOdo = (list.first['odometer'] as num).toDouble();
      double endOdo = (list.last['odometer'] as num).toDouble();
      totalDist = endOdo - startOdo;
      
      // We tellen alle liters op behalve de allereerste tankbeurt
      totalLiters = list.skip(1).map((e) => (e['liters'] as num).toDouble()).reduce((a, b) => a + b);
    }

    double avg = (totalLiters > 0) ? totalDist / totalLiters : 0;

    // Laatste verbruik (alleen als er minstens 2 entries zijn)
    if (list.length > 1) {
      var last = list.last;
      var prev = list[list.length - 2];
      double d = (last['odometer'] as num).toDouble() - (prev['odometer'] as num).toDouble();
      double l = (last['liters'] as num).toDouble();
      lastDist = d;
      if (l > 0) lastCons = d / l;
    }

    return {
      'avgCons': avg,
      'lastCons': lastCons,
      'lastPrice': (list.last['price_per_liter'] as num).toDouble(),
      'lastDist': lastDist
    };
  }
  
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 6) return "Goedenacht,";
    if (hour < 12) return "Goedemorgen,";
    if (hour < 18) return "Goedemiddag,";
    return "Goedenavond,";
  }

  IconData getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'motor': return Icons.two_wheeler;
      case 'scooter': return Icons.moped;
      case 'vrachtwagen': return Icons.local_shipping;
      case 'trekker': return Icons.agriculture;
      case 'bus': return Icons.directions_bus;
      case 'camper': return Icons.airport_shuttle;
      default: return Icons.directions_car;
    }
  }

  // --- BACKUP & EXPORT ---
  Future<void> saveLocalBackup() async {
    final dbPath = await DatabaseHelper.instance.getDbPath();
    final directory = await getApplicationDocumentsDirectory();
    final backupPath = '${directory.path}/tankbuddy_backup.db';
    await File(dbPath).copy(backupPath);
  }

  Future<bool> importLocalBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/tankbuddy_backup.db';
      final file = File(backupPath);
      if (await file.exists()) {
        await DatabaseHelper.instance.restoreBackup(backupPath);
        await loadData();
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }
  
  Future<void> exportDataShare() async {
    final dbPath = await DatabaseHelper.instance.getDbPath();
    await Share.shareXFiles([XFile(dbPath)], text: 'Hier is mijn TankBuddy backup!');
  }

  Future<bool> importDataPicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        await DatabaseHelper.instance.restoreBackup(file.path);
        await loadData();
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  Future<void> exportCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["Datum", "Auto", "KM Stand", "Liters", "Prijs Totaal", "Prijs/L"]);
    
    for (var e in _entries) {
      String carName = _cars.firstWhere((c) => c.id == e['car_id'], orElse: () => Car(name: "?")).name;
      rows.add([e['date'], carName, e['odometer'], e['liters'], e['price_total'], e['price_per_liter']]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/tankbuddy_export.csv";
    File f = File(path);
    await f.writeAsString(csv);
    await Share.shareXFiles([XFile(path)], text: 'Mijn TankBuddy Excel Export');
  }
}