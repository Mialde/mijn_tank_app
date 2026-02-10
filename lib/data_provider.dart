import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'models/car.dart';
import 'models/fuel_entry.dart';
import 'models/user_settings.dart';
import 'models/developer_note.dart';
import 'models/maintenance_entry.dart';
import 'models/stat_item.dart';
import 'models/time_period.dart';
import 'services/database_helper.dart';

class DataProvider with ChangeNotifier {
  List<Car> _cars = [];
  List<FuelEntry> _entries = [];
  List<MaintenanceEntry> _maintenanceEntries = [];
  List<DeveloperNote> _notes = [];
  Car? _selectedCar;
  UserSettings? _settings;
  bool _isLoading = false;
  String _currentQuote = "";
  DateTime? _apkDismissedAt;

  TimePeriod _selectedPeriod = TimePeriod.oneMonth;
  int _selectedIndex = -1;

  static const Map<String, Color> colorOptions = {
    'Mint': Color(0xFF00D09E), 'Blauw': Color(0xFF2979FF), 'Rood': Color(0xFFFF5252),
    'Oranje': Color(0xFFFF9100), 'Paars': Color(0xFFD500F9), 'Roze': Color(0xFFFF4081),
    'Goud': Color(0xFFFFD700), 'Grijs': Color(0xFF78909C),
  };

  // Getters
  List<Car> get cars => _cars;
  List<FuelEntry> get entries => _entries;
  List<MaintenanceEntry> get maintenanceEntries => _maintenanceEntries;
  List<DeveloperNote> get notes => _notes;
  Car? get selectedCar => _selectedCar;
  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String get currentQuote => _currentQuote;
  Color get themeColor => colorOptions[_settings?.accentColor] ?? const Color(0xFF00D09E);
  TimePeriod get selectedPeriod => _selectedPeriod;
  int get selectedIndex => _selectedIndex;

  Future<void> initializeApp() async {
    _setLoading(true);
    _settings = await DatabaseHelper.instance.getSettings();
    _cars = await DatabaseHelper.instance.getAllCars();
    _notes = await DatabaseHelper.instance.getAllNotes();
    if (_cars.isNotEmpty) {
      _selectedCar = _cars.first;
      await fetchEntries();
      await fetchMaintenance();
    }
    _setRandomQuote();
    _setLoading(false);
  }

  void _setRandomQuote() {
    final quotes = ["Volgooien is een kunst.", "Lekker slangetje hoor.", "Vol tot aan het randje."];
    _currentQuote = quotes[Random().nextInt(quotes.length)];
  }

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  Future<void> fetchEntries() async { if (_selectedCar != null) _entries = await DatabaseHelper.instance.getEntriesByCar(_selectedCar!.id!); notifyListeners(); }
  Future<void> fetchMaintenance() async { if (_selectedCar != null) _maintenanceEntries = await DatabaseHelper.instance.getMaintenanceByCar(_selectedCar!.id!); notifyListeners(); }

  List<FuelEntry> getEntriesForCar(int carId) => _entries.where((e) => e.carId == carId).toList();

  // --- APK & DISMISS ---
  void dismissApkWarning() { _apkDismissedAt = DateTime.now(); notifyListeners(); }
  Map<String, dynamic> get apkStatus {
    if (_selectedCar?.apkDate == null) return {'show': false};
    final now = DateTime.now();
    final daysLeft = _selectedCar!.apkDate!.difference(now).inDays;
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedCar!.apkDate!);
    if (daysLeft <= 31) return {'show': true, 'color': Colors.red, 'text': 'Let op! De APK verloopt op $dateStr', 'urgent': true, 'dismissible': false};
    if (daysLeft <= 61) {
      bool isTimedOut = _apkDismissedAt == null || now.difference(_apkDismissedAt!).inHours >= 24;
      return {'show': isTimedOut, 'color': Colors.orange, 'text': 'Let op: de APK verloopt op $dateStr', 'urgent': false, 'dismissible': true};
    }
    return {'show': false};
  }

  // --- DATA OPERATIONS ---
  Future<void> addFuelEntry(FuelEntry entry) async { await DatabaseHelper.instance.insertEntry(entry); await fetchEntries(); }
  Future<void> updateFuelEntry(FuelEntry entry) async { await DatabaseHelper.instance.updateEntry(entry); await fetchEntries(); }
  Future<void> deleteFuelEntry(int id) async { await DatabaseHelper.instance.deleteEntry(id); await fetchEntries(); }
  Future<void> addMaintenance(MaintenanceEntry entry) async { await DatabaseHelper.instance.insertMaintenance(entry); await fetchMaintenance(); }
  Future<void> updateMaintenance(MaintenanceEntry entry) async { await DatabaseHelper.instance.updateMaintenance(entry); await fetchMaintenance(); }
  Future<void> deleteMaintenance(int id) async { await DatabaseHelper.instance.deleteMaintenance(id); await fetchMaintenance(); }
  Future<void> addCar(Car car) async { await DatabaseHelper.instance.insertCar(car); _cars = await DatabaseHelper.instance.getAllCars(); notifyListeners(); }
  Future<void> updateCar(Car car) async { await DatabaseHelper.instance.updateCar(car); _cars = await DatabaseHelper.instance.getAllCars(); notifyListeners(); }
  Future<void> deleteCar(int id) async { await DatabaseHelper.instance.deleteCar(id); _cars = await DatabaseHelper.instance.getAllCars(); if (_selectedCar?.id == id) _selectedCar = _cars.firstOrNull; notifyListeners(); }
  Future<void> updateSettings(UserSettings newSettings) async { await DatabaseHelper.instance.saveSettings(newSettings); _settings = newSettings; notifyListeners(); }
  Future<void> clearAllEntries() async { if (_selectedCar != null) { await DatabaseHelper.instance.deleteEntriesByCar(_selectedCar!.id!); await fetchEntries(); } }
  Future<void> factoryReset() async { _setLoading(true); await DatabaseHelper.instance.deleteAllData(); _cars = []; _entries = []; _maintenanceEntries = []; _notes = []; _selectedCar = null; await initializeApp(); _setLoading(false); }

  // --- NOTES ---
  Future<void> addNote(String content) async { await DatabaseHelper.instance.insertNote(DeveloperNote(content: content, date: DateTime.now())); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }
  Future<void> toggleNote(DeveloperNote note) async { await DatabaseHelper.instance.updateNote(note.copyWith(isCompleted: !note.isCompleted)); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }
  Future<void> deleteNote(int id) async { await DatabaseHelper.instance.deleteNote(id); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }

  void selectCar(Car car) { _selectedCar = car; _apkDismissedAt = null; fetchEntries(); fetchMaintenance(); }
  void setTimePeriod(TimePeriod p) { _selectedPeriod = p; _selectedIndex = -1; notifyListeners(); }
  void setSelectedIndex(int i) { _selectedIndex = i; notifyListeners(); }

  // --- BEREKENINGEN ---
  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.oneMonth: return DateTime(now.year, now.month, 1);
      case TimePeriod.sixMonths: return DateTime(now.year, now.month - 6, now.day);
      case TimePeriod.oneYear: return DateTime(now.year - 1, now.month, now.day);
      case TimePeriod.allTime: return DateTime(2000); 
    }
  }

  int _calculateRealMonths(List<FuelEntry> allEntriesForCar) {
    if (allEntriesForCar.isEmpty) return 1;
    if (_selectedPeriod == TimePeriod.oneMonth) return 1;
    final sorted = List<FuelEntry>.from(allEntriesForCar)..sort((a, b) => a.date.compareTo(b.date));
    DateTime effectiveStart = sorted.first.date.isAfter(_getStartDate()) ? sorted.first.date : _getStartDate();
    DateTime now = DateTime.now();
    int months = (now.year - effectiveStart.year) * 12 + now.month - effectiveStart.month;
    return max(1, months + 1);
  }

  List<StatItem> getStatsForPeriod() {
    if (_selectedCar == null) return [];
    final startDate = _getStartDate();
    final filteredEntries = _entries.where((e) => e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate)).toList();
    final filteredMaintenance = _maintenanceEntries.where((m) => m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate)).toList();

    List<StatItem> items = [];
    double totalFuelCost = 0.0;

    // A. Brandstof Groeperen (SORTORDER = 0)
    if (_selectedPeriod == TimePeriod.oneMonth) {
      for (var entry in filteredEntries) {
        items.add(StatItem(
          title: DateFormat('dd-MM', 'nl_NL').format(entry.date),
          value: entry.priceTotal,
          color: Colors.grey,
          percentage: 0,
          isFuelGroup: true,
          sortOrder: 0, // Tanken bovenaan
          date: entry.date,
        ));
        totalFuelCost += entry.priceTotal;
      }
    } else {
      final groupedByMonth = groupBy(filteredEntries, (FuelEntry e) => DateTime(e.date.year, e.date.month));
      groupedByMonth.forEach((monthDate, entriesInMonth) {
        double monthlyTotal = entriesInMonth.fold(0.0, (sum, e) => sum + e.priceTotal);
        items.add(StatItem(
          title: DateFormat('MMM yyyy', 'nl_NL').format(monthDate),
          value: monthlyTotal,
          color: Colors.grey,
          percentage: 0,
          isFuelGroup: true,
          sortOrder: 0, // Tanken bovenaan
          date: monthDate,
        ));
        totalFuelCost += monthlyTotal;
      });
    }

    // B. Onderhoud (SORTORDER = 1)
    if (filteredMaintenance.isNotEmpty) {
      double totalMaint = filteredMaintenance.fold(0.0, (sum, m) => sum + m.cost);
      items.add(StatItem(
        title: 'Onderhoud',
        value: totalMaint,
        color: Colors.grey,
        percentage: 0,
        sortOrder: 1, // Onderhoud in het midden
      ));
    }

    // C. Vaste Lasten (SORTORDER = 2)
    int monthsCount = _calculateRealMonths(_entries);
    double monthlyRoadTax = (_selectedCar!.roadTaxFreq == 'Kwartaal' ? _selectedCar!.roadTax / 3 : _selectedCar!.roadTax);
    
    double totalInsurance = (_selectedCar!.insurance) * monthsCount;
    double totalRoadTax = (monthlyRoadTax) * monthsCount; 

    if (totalInsurance > 0) items.add(StatItem(title: 'Verzekering', value: totalInsurance, color: Colors.grey, percentage: 0, sortOrder: 2));
    if (totalRoadTax > 0) items.add(StatItem(title: 'Wegenbelasting', value: totalRoadTax, color: Colors.grey, percentage: 0, sortOrder: 2));

    double grandTotal = totalFuelCost + totalInsurance + totalRoadTax + (filteredMaintenance.fold(0, (sum, m) => sum + m.cost));
    if (grandTotal == 0) return [];

    // --- NIEUWE SORTERING ---
    // 1. SortOrder (0, 1, 2)
    // 2. Datum (Nieuwste eerst)
    // 3. Waarde (Hoogste eerst, fallback)
    items.sort((a, b) {
      int order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      if (a.date != null && b.date != null) return b.date!.compareTo(a.date!);
      return b.value.compareTo(a.value);
    });

    // KLEUREN
    // We bepalen de kleuren op basis van GROOTTE (Value), niet op lijstvolgorde.
    // Dus we maken even een kopie om de grootste te vinden voor de kleurtoewijzing.
    List<StatItem> valueSorted = List.from(items)..sort((a, b) => b.value.compareTo(a.value));
    
    // Zoek het item met de hoogste waarde voor de automatische selectie
    StatItem highestValueItem = valueSorted.first;

    List<Color> palette = [Colors.blue.shade700, Colors.orange.shade700, Colors.purple.shade600, Colors.green.shade600, Colors.red.shade600, Colors.teal.shade600, Colors.pink.shade400];
    
    // Kleuren toewijzen en Percentages berekenen
    // Let op: items staan nu in LIJST volgorde (Tanken -> Onderhoud -> Vast)
    for (int i = 0; i < items.length; i++) {
      // Bepaal kleur op basis van rangorde in WAARDE
      int valueRank = valueSorted.indexOf(items[i]);
      Color c = (valueRank == 0) ? themeColor : palette[(valueRank - 1) % palette.length];

      items[i] = StatItem(
        title: items[i].title,
        value: items[i].value,
        color: c,
        percentage: items[i].value / grandTotal * 100,
        isFuelGroup: items[i].isFuelGroup,
        sortOrder: items[i].sortOrder,
        date: items[i].date,
      );
    }

    // AUTO SELECTIE
    // Als er nog niets geselecteerd is (-1), selecteer dan het item met de HOOGSTE WAARDE.
    // We moeten de index van dat item vinden in de HUIDIGE (op datum gesorteerde) lijst.
    if (_selectedIndex == -1) {
       int indexOnScreen = items.indexWhere((item) => item.title == highestValueItem.title && item.value == highestValueItem.value);
       if (indexOnScreen != -1) {
         // Gebruik microtask om build errors te voorkomen
         Future.microtask(() {
           if (_selectedIndex == -1) setSelectedIndex(indexOnScreen);
         });
       }
    }

    return items;
  }

  double getTotalForPeriod() => getStatsForPeriod().fold(0, (sum, item) => sum + item.value);

  Future<void> importJsonBackup(String jsonContent) async {
    final data = jsonDecode(jsonContent);
    _setLoading(true);
    if (data['cars'] != null) for (var c in data['cars']) await DatabaseHelper.instance.insertCar(Car.fromMap(c));
    if (data['entries'] != null) for (var e in data['entries']) await DatabaseHelper.instance.insertEntry(FuelEntry.fromMap(e));
    await initializeApp();
    _setLoading(false);
  }
}