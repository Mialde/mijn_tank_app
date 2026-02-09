import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'models/car.dart';
import 'models/fuel_entry.dart';
import 'models/user_settings.dart';
import 'models/developer_note.dart';
import 'services/database_helper.dart';

class DataProvider with ChangeNotifier {
  List<Car> _cars = [];
  List<FuelEntry> _entries = [];
  List<DeveloperNote> _notes = [];
  Car? _selectedCar;
  UserSettings? _settings;
  bool _isLoading = false;
  String _currentQuote = "";

  // --- THEME ENGINE ---
  static const Map<String, Color> colorOptions = {
    'Mint': Color(0xFF00D09E),
    'Blauw': Color(0xFF2979FF),
    'Rood': Color(0xFFFF5252),
    'Oranje': Color(0xFFFF9100),
    'Paars': Color(0xFFD500F9),
    'Roze': Color(0xFFFF4081),
    'Goud': Color(0xFFFFD700),
    'Grijs': Color(0xFF78909C),
  };

  Color get themeColor {
    if (_settings == null) return const Color(0xFF00D09E);
    return colorOptions[_settings!.accentColor] ?? const Color(0xFF00D09E);
  }

  // Getters
  List<Car> get cars => _cars;
  List<FuelEntry> get entries => _entries;
  List<DeveloperNote> get notes => _notes;
  Car? get selectedCar => _selectedCar;
  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String get currentQuote => _currentQuote;

  final List<String> _quotes = [
    "Volgooien is een kunst.", "Jij bent de motor van dit geheel.", "Lekker slangetje hoor.",
    "Even die spuit erin hangen.", "Klaar voor een ritje?", "Hij zit er weer diep in.",
    "Tijd voor een pitstop, kampioen.", "Lekker pompen.", "Vol tot aan het randje."
  ];

  Future<void> initializeApp() async {
    _setLoading(true);
    _settings ??= await DatabaseHelper.instance.getSettings();
    _cars = await DatabaseHelper.instance.getAllCars();
    _notes = await DatabaseHelper.instance.getAllNotes();
    _setRandomQuote();
    if (_cars.isNotEmpty) {
      _selectedCar = _cars.first;
      await fetchEntries();
    }
    _setLoading(false);
  }

  void _setRandomQuote() => _currentQuote = _quotes[Random().nextInt(_quotes.length)];
  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  Future<void> fetchEntries() async {
    if (_selectedCar == null) return;
    _entries = await DatabaseHelper.instance.getEntriesByCar(_selectedCar!.id!);
    notifyListeners();
  }

  List<FuelEntry> getEntriesForCar(int carId) => _entries.where((e) => e.carId == carId).toList();

  // --- CRUD OPERATIONS ---

  Future<void> addFuelEntry(FuelEntry entry) async {
    await DatabaseHelper.instance.insertEntry(entry);
    await fetchEntries();
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    await DatabaseHelper.instance.updateEntry(entry);
    await fetchEntries();
  }

  Future<void> deleteFuelEntry(int id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    await fetchEntries();
  }

  Future<void> addCar(Car car) async {
    await DatabaseHelper.instance.insertCar(car);
    _cars = await DatabaseHelper.instance.getAllCars();
    
    // FIX: Null-aware assignment (Lost de linter warning op)
    // Als _selectedCar null is, wijs dan de eerste auto toe.
    if (_cars.isNotEmpty) {
      _selectedCar ??= _cars.first;
    }
    
    notifyListeners();
  }

  Future<void> updateCar(Car car) async {
    await DatabaseHelper.instance.updateCar(car);
    _cars = await DatabaseHelper.instance.getAllCars();
    if (_selectedCar?.id == car.id) _selectedCar = car;
    notifyListeners();
  }

  Future<void> deleteCar(int id) async {
    await DatabaseHelper.instance.deleteCar(id);
    _cars = await DatabaseHelper.instance.getAllCars();
    if (_selectedCar?.id == id) _selectedCar = _cars.isNotEmpty ? _cars.first : null;
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    await DatabaseHelper.instance.saveSettings(newSettings);
    _settings = newSettings;
    notifyListeners();
  }

  // --- DEVELOPER NOTES ---
  Future<void> addNote(String content) async {
    final note = DeveloperNote(content: content, date: DateTime.now());
    await DatabaseHelper.instance.insertNote(note);
    _notes = await DatabaseHelper.instance.getAllNotes();
    notifyListeners();
  }

  Future<void> toggleNote(DeveloperNote note) async {
    final updated = note.copyWith(isCompleted: !note.isCompleted);
    await DatabaseHelper.instance.updateNote(updated);
    _notes = await DatabaseHelper.instance.getAllNotes();
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await DatabaseHelper.instance.deleteNote(id);
    _notes = await DatabaseHelper.instance.getAllNotes();
    notifyListeners();
  }

  // --- IMPORT ---
  Future<void> importJsonBackup(String jsonContent) async {
    final data = jsonDecode(jsonContent);
    _setLoading(true);
    for (var carMap in data['cars']) await DatabaseHelper.instance.insertCar(Car.fromMap(carMap));
    for (var entryMap in data['entries']) await DatabaseHelper.instance.insertEntry(FuelEntry.fromMap(entryMap));
    await initializeApp();
    _setLoading(false);
  }

  Future<void> importMappedCSV(String csvContent, Map<String, int> mapping) async {
    if (_selectedCar == null) return;
    _setLoading(true);
    List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: ';').convert(csvContent);
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      try {
        String rawDate = row[mapping['date']!].toString();
        DateTime parsedDate;
        try { parsedDate = DateTime.parse(rawDate); } catch (_) {
          try { rawDate = rawDate.replaceAll('/', '-'); parsedDate = DateFormat('dd-MM-yyyy').parse(rawDate); } catch (_) { parsedDate = DateTime.now(); }
        }
        await addFuelEntry(FuelEntry(
          carId: _selectedCar!.id!, date: parsedDate,
          odometer: double.tryParse(row[mapping['odo']!].toString().replaceAll(',', '.')) ?? 0,
          liters: double.tryParse(row[mapping['liters']!].toString().replaceAll(',', '.')) ?? 0,
          priceTotal: double.tryParse(row[mapping['price']!].toString().replaceAll(',', '.')) ?? 0, pricePerLiter: 0,
        ));
      } catch (e) { debugPrint("Fout bij regel $i: $e"); }
    }
    await fetchEntries();
    _setLoading(false);
  }

  void selectCar(Car car) { _selectedCar = car; fetchEntries(); }
  
  double get monthlyInsurance => _selectedCar?.insurance ?? 0.0;
  double get monthlyRoadTax => (_selectedCar?.roadTaxFreq == 'Kwartaal' ? (_selectedCar?.roadTax ?? 0) / 3 : (_selectedCar?.roadTax ?? 0));
  double get monthlyFuelCost {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _entries.where((e) => e.date.isAfter(thirtyDaysAgo)).fold(0.0, (sum, e) => sum + e.priceTotal);
  }
}