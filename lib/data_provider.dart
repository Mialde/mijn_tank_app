import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:file_picker/file_picker.dart'; 
import 'package:intl/intl.dart';
import 'services/database_helper.dart';

class DataProvider with ChangeNotifier {
  List<Car> _cars = [];
  Map<String, dynamic> _user = {'first_name': 'Bestuurder', 'greeting_type': 'time', 'use_greeting': 1, 'show_quotes': 1, 'theme_mode': 'system'};
  List<Map<String, dynamic>> _allEntries = [];
  
  List<Car> get cars => _cars;
  Map<String, dynamic> get user => _user;

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

  List<Map<String, dynamic>> getEntriesForCar(int? carId) {
    if (carId == null) return [];
    return _allEntries.where((e) => e['car_id'] == carId).toList();
  }

  ThemeMode get themeMode {
    final mode = _user['theme_mode'] ?? 'system';
    return mode == 'light' ? ThemeMode.light : mode == 'dark' ? ThemeMode.dark : ThemeMode.system;
  }

  Future<void> loadData() async {
    _cars = await DatabaseHelper.instance.getAllCars();
    _user = await DatabaseHelper.instance.getUser();
    _allEntries = await DatabaseHelper.instance.getAllEntries();
    notifyListeners();
  }

  List<Map<String, dynamic>> _getSortedEntries(int? carId) {
    final entries = getEntriesForCar(carId);
    entries.sort((a, b) => (a['odometer'] as num).compareTo(b['odometer'] as num));
    return entries;
  }

  List<Map<String, dynamic>> getConsumptionHistory(int? carId) {
    final sorted = _getSortedEntries(carId);
    if (sorted.length < 2) return [];

    List<Map<String, dynamic>> history = [];

    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = sorted[i - 1];

      // FIX: .toDouble() toegevoegd om type errors te voorkomen
      double distance = ((current['odometer'] as num) - (previous['odometer'] as num)).toDouble();
      double liters = (current['liters'] as num).toDouble();

      if (liters > 0 && distance > 0) {
        double consumption = distance / liters; 
        history.add({
          'val': consumption,
          'date': current['date'],
          'distance': distance,
          'liters': liters,
        });
      }
    }
    return history;
  }

  Map<String, dynamic> getStats(int? carId) {
    final sorted = _getSortedEntries(carId);
    
    double avgCons = 0.0;
    double lastDist = 0.0;
    double lastPrice = 0.0;
    double lastCons = 0.0;

    if (sorted.isNotEmpty) {
      final latest = sorted.last;
      lastPrice = (latest['price_total'] as num).toDouble() / (latest['liters'] as num).toDouble();

      if (sorted.length > 1) {
        final previous = sorted[sorted.length - 2];
        final oldest = sorted.first;

        // FIX: .toDouble() toegevoegd
        lastDist = ((latest['odometer'] as num) - (previous['odometer'] as num)).toDouble();
        lastCons = (latest['liters'] as num) > 0 ? lastDist / (latest['liters'] as num).toDouble() : 0.0;

        double totalDist = ((latest['odometer'] as num) - (oldest['odometer'] as num)).toDouble();
        double totalLiters = sorted.skip(1).fold(0.0, (sum, e) => sum + (e['liters'] as num).toDouble());

        avgCons = totalLiters > 0 ? totalDist / totalLiters : 0.0;
      }
    }
    return {
      'avgCons': avgCons, 
      'lastDist': lastDist, 
      'lastPrice': lastPrice, 
      'lastCons': lastCons
    };
  }

  Future<void> exportCSV() async {
    StringBuffer csv = StringBuffer();
    csv.writeln("Datum,Tijd,Voertuig,Kenteken,Kilometerstand,Liters,Totaal Prijs,Literprijs");
    for (var e in _allEntries) {
      final car = _cars.firstWhere((c) => c.id == e['car_id'], orElse: () => Car(name: "Onbekend", type: "auto"));
      final date = DateTime.parse(e['date']);
      final literPrijs = (e['price_total'] / e['liters']).toStringAsFixed(3);
      csv.writeln("${DateFormat('dd-MM-yyyy').format(date)},${DateFormat('HH:mm').format(date)},${car.name},${car.licensePlate ?? ''},${e['odometer']},${e['liters']},${e['price_total']},$literPrijs");
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tankbuddy_export.csv');
    await file.writeAsString(csv.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Mijn TankBuddy Excel Export');
  }

  Future<String> _generateJsonData() async {
    final data = {'version': 1, 'timestamp': DateTime.now().toIso8601String(), 'user': _user, 'cars': _cars.map((c) => c.toMap()).toList(), 'entries': _allEntries};
    return jsonEncode(data);
  }

  Future<void> exportDataShare() async {
    final jsonString = await _generateJsonData();
    final dir = await getTemporaryDirectory();
    final fileName = "tankbuddy_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json";
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Mijn TankBuddy Backup');
  }

  Future<void> saveLocalBackup() async {
    final jsonString = await _generateJsonData();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/tankbuddy_local_backup.json');
    await file.writeAsString(jsonString);
  }

  Future<bool> _processImport(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent);
      await DatabaseHelper.instance.clearAllData();
      if (data['user'] != null) { Map<String, dynamic> u = data['user']; u.remove('id'); await DatabaseHelper.instance.updateUser(u); }
      for (var c in data['cars']) { await DatabaseHelper.instance.createCar(Car.fromMap(c)); }
      for (var e in data['entries']) { await DatabaseHelper.instance.insertEntry(e); }
      await loadData();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> importDataPicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await _processImport(await file.readAsString());
      }
      return false; 
    } catch (e) { return false; }
  }

  Future<bool> importLocalBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tankbuddy_local_backup.json');
      if (!await file.exists()) return false;
      return await _processImport(await file.readAsString());
    } catch (e) { return false; }
  }

  String getGreeting() {
    if ((_user['use_greeting'] ?? 1) == 0) return "Hallo";
    final hour = DateTime.now().hour;
    if (hour < 12) return "Goedemorgen";
    if (hour < 18) return "Goedemiddag";
    return "Goedenavond";
  }

  Future<void> addEntry(int carId, DateTime date, double odo, double l, double p) async {
    await DatabaseHelper.instance.insertEntry({'car_id': carId, 'date': date.toIso8601String(), 'odometer': odo, 'liters': l, 'price_total': p});
    await loadData();
  }
  
  Future<void> updateUserSettings(Map<String, dynamic> s) async { await DatabaseHelper.instance.updateUser(s); await loadData(); }
  
  Future<void> updateCar(Car car) async { 
    car.id == null ? await DatabaseHelper.instance.createCar(car) : await DatabaseHelper.instance.updateCar(car); 
    await loadData(); 
  }

  Future<void> deleteCar(int id) async { await DatabaseHelper.instance.deleteCar(id); await loadData(); }
  Future<void> deleteEntry(int id) async { await DatabaseHelper.instance.deleteEntry(id); await loadData(); }
}