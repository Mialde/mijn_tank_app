import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/car.dart';
import 'models/fuel_entry.dart';
import 'models/user_settings.dart';
import 'models/developer_note.dart';
import 'models/maintenance_entry.dart';
import 'models/recurring_cost.dart';
import 'models/stat_item.dart';
import 'models/time_period.dart';
import 'models/card_config.dart';
import 'services/database_helper.dart';

class DataProvider with ChangeNotifier {
  List<Car> _cars = [];
  List<FuelEntry> _entries = [];
  List<MaintenanceEntry> _maintenanceEntries = [];
  List<RecurringCost> _recurringCosts = [];
  List<DeveloperNote> _notes = [];
  Car? _selectedCar;
  UserSettings? _settings;
  bool _isLoading = false;
  String _currentQuote = "";
  DateTime? _apkDismissedAt;
  final Map<String, DateTime> _dismissedMaintenanceWarnings = {};

  // Cache voor zware berekeningen
  List<StatItem>? _cachedStats;
  double? _cachedTotal;
  TimePeriod? _cachedPeriod;
  int? _cachedCarId;
  int? _cachedEntriesCount;
  int? _cachedMaintenanceCount;
  String? _cachedFuelType;

  TimePeriod _selectedPeriod = TimePeriod.oneMonth;
  int _selectedIndex = -1;
  String? _selectedFuelType; // null = alle brandstoftypes
  
  // Card visibility state
  List<DashboardCardConfig> _visibleCards = DashboardCards.allCards;

  static const Map<String, Color> colorOptions = {
    'Mint': Color(0xFF00D09E), 'Blauw': Color(0xFF2979FF), 'Rood': Color(0xFFFF5252),
    'Oranje': Color(0xFFFF9100), 'Paars': Color(0xFFD500F9), 'Roze': Color(0xFFFF4081),
    'Goud': Color(0xFFFFD700), 'Grijs': Color(0xFF78909C),
  };

  // Getters
  List<Car> get cars => _cars;
  List<FuelEntry> get entries => _entries;
  List<MaintenanceEntry> get maintenanceEntries => _maintenanceEntries;
  List<RecurringCost> get recurringCosts => _recurringCosts;
  List<DeveloperNote> get notes => _notes;
  Car? get selectedCar => _selectedCar;

  // ─── Doelstellingen getters ───────────────────────────────────────────────
  double? get goalMaxFuelPrice => _selectedCar?.goalMaxFuelPrice;
  double? get goalEfficiency   => _selectedCar?.goalEfficiency;
  int?    get goalMonthlyKm    => _selectedCar?.goalMonthlyKm;

  /// Geeft true als de meegegeven prijs per liter boven het doel ligt
  bool isFuelPriceAboveGoal(double pricePerLiter) {
    final goal = goalMaxFuelPrice;
    return goal != null && pricePerLiter > goal;
  }

  /// Gereden km in de huidige kalendermaand
  double get kmThisMonth {
    if (_entries.isEmpty) return 0;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final monthEntries = _entries
        .where((e) => !e.date.isBefore(start))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (monthEntries.length < 2) return 0;
    return (monthEntries.last.odometer - monthEntries.first.odometer).abs();
  }

  /// Voortgang km-doel deze maand (0.0 – 1.0+)
  double get monthlyKmProgress {
    final goal = goalMonthlyKm;
    if (goal == null || goal <= 0) return 0;
    return (kmThisMonth / goal).clamp(0.0, 1.5);
  }
  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String get currentQuote => _currentQuote;
  Color get themeColor => colorOptions[_settings?.accentColor] ?? const Color(0xFF00D09E);
  TimePeriod get selectedPeriod => _selectedPeriod;
  int get selectedIndex => _selectedIndex;
  String? get selectedFuelType => _selectedFuelType;

  /// Unieke brandstoftypes in de entries van de geselecteerde auto
  List<String> get availableFuelTypes {
    final types = _entries
        .map((e) => e.fuelType)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  /// Gefilterde entries op basis van geselecteerd brandstoftype
  List get filteredEntries =>
      _selectedFuelType == null
          ? _entries
          : _entries.where((e) => e.fuelType == _selectedFuelType).toList();
  List<DashboardCardConfig> get visibleCards => _visibleCards;
  
  Future<void> updateCardVisibility(List<DashboardCardConfig> cards) async {
    _visibleCards = cards;
    notifyListeners();
    await _saveCardConfig();
  }
  
  Future<void> reorderCards(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final card = _visibleCards.removeAt(oldIndex);
    _visibleCards.insert(newIndex, card);
    notifyListeners();
    await _saveCardConfig();
  }

  Future<void> initializeApp() async {
    _setLoading(true);
    _settings = await DatabaseHelper.instance.getSettings();
    _cars = await DatabaseHelper.instance.getAllCars();
    _notes = await DatabaseHelper.instance.getAllNotes();
    await _loadCardConfig();
    
    // Auto selectie logica
    if (_cars.isNotEmpty) {
      // Selecteer eerste auto (of later: laatst gebruikte)
      _selectedCar = _cars.first;
      print('✓ Auto geselecteerd: ${_selectedCar!.name} (${_selectedCar!.licensePlate})');
      await fetchEntries();
      await fetchMaintenance();
      await fetchRecurringCosts(); // Now enabled with database v4
    } else {
      print('⚠ Geen auto\'s gevonden in database');
      _selectedCar = null;
    }
    
    _setRandomQuote();
    _setLoading(false);
    
    // Debug info
    print('App geïnitialiseerd:');
    print('  - Auto\'s: ${_cars.length}');
    print('  - Geselecteerde auto: ${_selectedCar?.name ?? "GEEN"}');
    print('  - Tankbeurten: ${_entries.length}');
  }

  void _setRandomQuote() {
    final quotes = ["Volgooien is een kunst.", "Lekker slangetje hoor.", "Vol tot aan het randje."];
    _currentQuote = quotes[Random().nextInt(quotes.length)];
  }

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  Future<void> fetchEntries() async { if (_selectedCar != null) { _entries = await DatabaseHelper.instance.getEntriesByCar(_selectedCar!.id!); _invalidateCache(); } notifyListeners(); }
  Future<void> fetchMaintenance() async { if (_selectedCar != null) { _maintenanceEntries = await DatabaseHelper.instance.getMaintenanceByCar(_selectedCar!.id!); _invalidateCache(); } notifyListeners(); }
  Future<void> fetchRecurringCosts() async { if (_selectedCar != null) { _recurringCosts = await DatabaseHelper.instance.getActiveRecurringCostsByCar(_selectedCar!.id!); _invalidateCache(); } notifyListeners(); }
  Future<void> fetchRecurringCostsForCar(int carId) async { _recurringCosts = await DatabaseHelper.instance.getActiveRecurringCostsByCar(carId); _invalidateCache(); notifyListeners(); }

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

  /// Uitsplitsing van vaste kosten voor detail-weergave in grafiek
  List<Map<String, dynamic>> getFixedCostsBreakdown() {
    if (_selectedCar == null) return [];
    final months = _calculateRealMonths(_entries);
    return _recurringCosts.map((cost) => {
      'name': cost.name,
      'monthly': cost.monthlyCost,
      'total': cost.monthlyCost * months,
      'freq': cost.frequency,
    }).toList();
  }

  void dismissMaintenanceWarning(String key) {
    _dismissedMaintenanceWarnings[key] = DateTime.now();
    notifyListeners();
  }

  /// Geeft lijst van actieve onderhoud-herinneringen terug
  /// Respecteert globale settings (aan/uit) en per-auto intervallen
  List<Map<String, dynamic>> get maintenanceWarnings {
    if (_selectedCar == null || _maintenanceEntries.isEmpty || _entries.isEmpty) return [];
    final now = DateTime.now();
    final warnings = <Map<String, dynamic>>[];

    // Huidige kilometerstand = laatste tankbeurt odometer
    final sortedEntries = List.from(_entries)..sort((a, b) => a.date.compareTo(b.date));
    final currentKm = (sortedEntries.last as dynamic).odometer as double;

    for (final type in kDefaultIntervals.keys) {
      // Globale check: is dit type ingeschakeld in instellingen?
      if (_settings != null && !_settings!.isMaintenanceEnabled(type)) continue;

      // Interval: per-auto overschrijving of standaard
      final interval = _selectedCar!.intervalFor(type);
      if (!interval.enabled) continue;

      final kmInterval = interval.kmInterval;
      final dayInterval = interval.dayInterval;
      if (dayInterval == null && kmInterval == null) continue;

      // Zoek de meest recente onderhoud van dit type
      final relevant = _maintenanceEntries
          .where((m) => m.type.toLowerCase().contains(type.toLowerCase()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (relevant.isEmpty) continue;
      final last = relevant.first;
      final daysSince = now.difference(last.date).inDays;
      final kmSince = currentKm - last.odometer;

      bool shouldWarn = false;
      bool urgent = false;
      String reason = '';

      if (dayInterval != null) {
        final daysLeft = dayInterval - daysSince;
        if (daysLeft <= 30 && daysLeft >= 0) {
          shouldWarn = true;
          urgent = daysLeft <= 14;
          reason = 'over $daysLeft dagen';
        } else if (daysLeft < 0) {
          shouldWarn = true;
          urgent = true;
          reason = '${-daysLeft} dagen verlopen';
        }
      }

      if (kmInterval != null) {
        final kmLeft = kmInterval - kmSince;
        if (kmLeft <= 1500 && kmLeft >= 0) {
          shouldWarn = true;
          urgent = urgent || kmLeft <= 500;
          final kmStr = 'nog ${kmLeft.toStringAsFixed(0)} km';
          reason = reason.isEmpty ? kmStr : '$reason / $kmStr';
        } else if (kmLeft < 0) {
          shouldWarn = true;
          urgent = true;
          final kmStr = '${(-kmLeft).toStringAsFixed(0)} km over';
          reason = reason.isEmpty ? kmStr : '$reason / $kmStr';
        }
      }

      if (!shouldWarn) continue;

      final key = 'maintenance_$type';
      if (!urgent) {
        final dismissedAt = _dismissedMaintenanceWarnings[key];
        if (dismissedAt != null && now.difference(dismissedAt).inHours < 24) continue;
      }

      warnings.add({
        'key': key,
        'type': type,
        'text': '$type: $reason',
        'color': urgent ? Colors.red : Colors.orange,
        'urgent': urgent,
        'dismissible': !urgent,
      });
    }

    return warnings;
  }

  // --- DATA OPERATIONS ---
  Future<void> addFuelEntry(FuelEntry entry) async { await DatabaseHelper.instance.insertEntry(entry); await fetchEntries(); }
  Future<void> updateFuelEntry(FuelEntry entry) async { await DatabaseHelper.instance.updateEntry(entry); await fetchEntries(); }
  Future<void> deleteFuelEntry(int id) async { await DatabaseHelper.instance.deleteEntry(id); await fetchEntries(); }
  Future<void> addMaintenance(MaintenanceEntry entry) async { await DatabaseHelper.instance.insertMaintenance(entry); await fetchMaintenance(); }
  Future<void> updateMaintenance(MaintenanceEntry entry) async { await DatabaseHelper.instance.updateMaintenance(entry); await fetchMaintenance(); }
  Future<void> deleteMaintenance(int id) async { await DatabaseHelper.instance.deleteMaintenance(id); await fetchMaintenance(); }
  Future<void> addCar(Car car) async { 
    await DatabaseHelper.instance.insertCar(car); 
    _cars = await DatabaseHelper.instance.getAllCars(); 
    
    // Selecteer de nieuw toegevoegde auto automatisch
    // De nieuwe auto is de laatste in de lijst (heeft hoogste ID)
    if (_cars.isNotEmpty) {
      _selectedCar = _cars.last;
      print('✓ Nieuw toegevoegde auto geselecteerd: ${_selectedCar!.name}');
      await fetchEntries();
      await fetchMaintenance();
    }
    
    notifyListeners(); 
  }
  
  Future<void> updateCar(Car car) async { 
    await DatabaseHelper.instance.updateCar(car); 
    _cars = await DatabaseHelper.instance.getAllCars(); 
    
    // Als de geüpdatete auto de geselecteerde auto is, update de referentie
    if (_selectedCar?.id == car.id) {
      _selectedCar = _cars.firstWhere((c) => c.id == car.id);
      print('✓ Geselecteerde auto geüpdatet: ${_selectedCar!.name}');
      await fetchEntries();
      await fetchMaintenance();
    }
    
    notifyListeners(); 
  }
  Future<void> deleteCar(int id) async { await DatabaseHelper.instance.deleteCar(id); _cars = await DatabaseHelper.instance.getAllCars(); if (_selectedCar?.id == id) _selectedCar = _cars.firstOrNull; notifyListeners(); }
  Future<void> updateSettings(UserSettings newSettings) async { await DatabaseHelper.instance.saveSettings(newSettings); _settings = newSettings; notifyListeners(); }
  Future<void> clearAllEntries() async { if (_selectedCar != null) { await DatabaseHelper.instance.deleteEntriesByCar(_selectedCar!.id!); await fetchEntries(); } }
  Future<void> factoryReset() async { _setLoading(true); await DatabaseHelper.instance.deleteAllData(); _cars = []; _entries = []; _maintenanceEntries = []; _notes = []; _selectedCar = null; await initializeApp(); _setLoading(false); }

  // --- NOTES ---
  Future<void> addNote(String content) async { await DatabaseHelper.instance.insertNote(DeveloperNote(content: content, date: DateTime.now())); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }
  Future<void> toggleNote(DeveloperNote note) async { await DatabaseHelper.instance.updateNote(note.copyWith(isCompleted: !note.isCompleted)); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }
  Future<void> deleteNote(int id) async { await DatabaseHelper.instance.deleteNote(id); _notes = await DatabaseHelper.instance.getAllNotes(); notifyListeners(); }

  void selectCar(Car car) { _selectedCar = car; _apkDismissedAt = null; _invalidateCache(); fetchEntries(); fetchMaintenance(); fetchRecurringCosts(); }
  void setTimePeriod(TimePeriod p) { _selectedPeriod = p; _selectedIndex = -1; _invalidateCache(); notifyListeners(); }
  void setFuelTypeFilter(String? type) { _selectedFuelType = type; _selectedIndex = -1; _invalidateCache(); notifyListeners(); }
  void setSelectedIndex(int i) { _selectedIndex = i; notifyListeners(); }

  void _invalidateCache() {
    _cachedStats = null;
    _cachedTotal = null;
    _cachedPeriod = null;
    _cachedCarId = null;
    _cachedEntriesCount = null;
    _cachedMaintenanceCount = null;
    _cachedFuelType = null;
  }

  // --- BEREKENINGEN ---
  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.oneMonth: 
        return DateTime(now.year, now.month, 1);
      case TimePeriod.sixMonths: 
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 180));
      case TimePeriod.oneYear: 
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365));
      case TimePeriod.allTime: 
        return DateTime(2000); 
    }
  }

  /// Stats voor een specifieke periode zonder de huidige periode te wijzigen
  List<StatItem> getStatsForSpecificPeriod(TimePeriod period) {
    if (period == _selectedPeriod) return getStatsForPeriod();
    final saved = _selectedPeriod;
    _selectedPeriod = period;
    _cachedStats = null;
    final result = getStatsForPeriod();
    _selectedPeriod = saved;
    _cachedStats = null;
    return result;
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

    // Cache check — returneer direct als data niet veranderd is
    if (_cachedStats != null &&
        _cachedPeriod == _selectedPeriod &&
        _cachedCarId == _selectedCar!.id &&
        _cachedEntriesCount == _entries.length &&
        _cachedMaintenanceCount == _maintenanceEntries.length &&
        _cachedFuelType == _selectedFuelType) {
      return _cachedStats!;
    }
    final startDate = _getStartDate();
    final sourceEntries = _selectedFuelType == null
        ? _entries
        : _entries.where((e) => e.fuelType == _selectedFuelType).toList();
    final filteredEntries = sourceEntries.where((e) => e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate)).toList();
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
    double totalMaint = 0.0;
    if (filteredMaintenance.isNotEmpty) {
      totalMaint = filteredMaintenance.fold(0.0, (sum, m) => sum + m.cost);
      items.add(StatItem(
        title: 'Onderhoud',
        value: totalMaint,
        color: Colors.grey,
        percentage: 0,
        sortOrder: 1,
      ));
    }

    // C. Alle kosten: recurring costs (verzekering, wegenbelasting, abonnementen, etc.)
    int monthsCount = _calculateRealMonths(_entries);
    double totalFixedCosts = 0.0;

    // _recurringCosts bevat actieve kosten (al geladen via fetchRecurringCosts)
    // Recurring costs — de enige bron van vaste kosten
    for (final cost in _recurringCosts) {
      final total = cost.monthlyCost * monthsCount;
      if (total > 0) {
        totalFixedCosts += total;
        items.add(StatItem(title: cost.name, value: total, color: Colors.grey, percentage: 0, sortOrder: 2));
      }
    }

    double grandTotal = totalFuelCost + totalMaint + totalFixedCosts;
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
        // Direct instellen zonder notifyListeners() om rebuild loop te voorkomen.
        // De widget leest _selectedIndex al in dezelfde build, dus dit is veilig.
        _selectedIndex = indexOnScreen;
      }
    }

    // Sla resultaat op in cache
    _cachedStats = items;
    _cachedTotal = items.fold<double>(0.0, (sum, item) => sum + item.value);
    _cachedPeriod = _selectedPeriod;
    _cachedCarId = _selectedCar!.id;
    _cachedEntriesCount = _entries.length;
    _cachedMaintenanceCount = _maintenanceEntries.length;
    _cachedFuelType = _selectedFuelType;

    return items;
  }

  double getTotalForPeriod() {
    // Gebruik gecachte total als beschikbaar, anders bereken via getStatsForPeriod
    if (_cachedTotal != null &&
        _cachedPeriod == _selectedPeriod &&
        _cachedCarId == _selectedCar?.id &&
        _cachedEntriesCount == _entries.length &&
        _cachedMaintenanceCount == _maintenanceEntries.length &&
        _cachedFuelType == _selectedFuelType) {
      return _cachedTotal!;
    }
    return getStatsForPeriod().fold(0, (sum, item) => sum + item.value);
  }

  Future<void> importJsonBackup(String jsonContent) async {
    final data = jsonDecode(jsonContent);
    _setLoading(true);
    
    // Get existing cars to check for duplicates
    final existingCars = await DatabaseHelper.instance.getAllCars();
    final Map<int, int> oldIdToNewId = {}; // Map old IDs to new/existing IDs
    
    // Import cars with duplicate check
    if (data['cars'] != null) {
      for (var c in data['cars']) {
        final carMap = Map<String, dynamic>.from(c);
        final oldId = carMap['id'];
        final licensePlate = (carMap['license_plate'] as String?)?.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '') ?? '';
        
        // Check if car with same license plate exists
        final existingCar = existingCars.firstWhere(
          (car) => car.licensePlate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '') == licensePlate,
          orElse: () => Car(
            name: '',
            licensePlate: '',
            type: '',
            insurance: 0,
            roadTax: 0,
            roadTaxFreq: '',
          ),
        );
        
        if (existingCar.licensePlate.isNotEmpty) {
          // Update existing car instead of creating duplicate
          print('⚙️ Updating existing car: ${existingCar.name} ($licensePlate)');
          
          final updatedCar = Car(
            id: existingCar.id,
            name: carMap['name'] ?? existingCar.name,
            licensePlate: existingCar.licensePlate,
            type: carMap['type'] ?? existingCar.type,
            apkDate: carMap['apk_date'] != null ? DateTime.tryParse(carMap['apk_date']) : existingCar.apkDate,
            insurance: (carMap['insurance'] ?? existingCar.insurance).toDouble(),
            roadTax: (carMap['road_tax'] ?? existingCar.roadTax).toDouble(),
            roadTaxFreq: carMap['road_tax_freq'] ?? existingCar.roadTaxFreq,
            fuelType: carMap['fuel_type'] ?? existingCar.fuelType,
            owner: carMap['owner'] ?? existingCar.owner,
          );
          
          await DatabaseHelper.instance.updateCar(updatedCar);
          oldIdToNewId[oldId] = existingCar.id!;
          
        } else {
          // New car - insert
          carMap.remove('id'); // Let DB assign new ID
          final newCarId = await DatabaseHelper.instance.insertCar(Car.fromMap(carMap));
          oldIdToNewId[oldId] = newCarId;
        }
      }
    }
    
    // Import entries with mapped car IDs and duplicate check
    if (data['entries'] != null && data['entries'] is List) {
      final oldEntries = data['entries'] as List;
      
      for (var e in oldEntries) {
        final entryMap = Map<String, dynamic>.from(e);
        final oldCarId = entryMap['car_id'];
        
        // Map to new car ID
        if (oldCarId != null && oldIdToNewId.containsKey(oldCarId)) {
          final newCarId = oldIdToNewId[oldCarId]!;
          entryMap['car_id'] = newCarId;
          
          // Check for duplicate entry (same car, date, odometer, liters)
          final existingEntries = await DatabaseHelper.instance.getEntriesByCar(newCarId);
          final entryDate = DateTime.tryParse(entryMap['date']) ?? DateTime.now();
          final isDuplicate = existingEntries.any((existing) {
            final sameDate = existing.date.year == entryDate.year &&
                           existing.date.month == entryDate.month &&
                           existing.date.day == entryDate.day;
            return sameDate &&
                   existing.odometer == entryMap['odometer'] &&
                   existing.liters == entryMap['liters'];
          });
          
          if (!isDuplicate) {
            entryMap.remove('id'); // Let DB assign new ID
            await DatabaseHelper.instance.insertEntry(FuelEntry.fromMap(entryMap));
          } else {
            print('⏭️ Skipping duplicate entry: ${entryMap['date']}');
          }
        }
      }
    }
    
    // Import maintenance with duplicate check
    if (data['maintenance_entries'] != null && data['maintenance_entries'] is List) {
      final oldMaintenance = data['maintenance_entries'] as List;
      
      for (var m in oldMaintenance) {
        final maintenanceMap = Map<String, dynamic>.from(m);
        final oldCarId = maintenanceMap['car_id'];
        
        if (oldCarId != null && oldIdToNewId.containsKey(oldCarId)) {
          final newCarId = oldIdToNewId[oldCarId]!;
          maintenanceMap['car_id'] = newCarId;
          
          // Check for duplicate maintenance
          final existingMaintenance = await DatabaseHelper.instance.getMaintenanceByCar(newCarId);
          final maintenanceDate = DateTime.tryParse(maintenanceMap['date']) ?? DateTime.now();
          final isDuplicate = existingMaintenance.any((existing) {
            final sameDate = existing.date.year == maintenanceDate.year &&
                           existing.date.month == maintenanceDate.month &&
                           existing.date.day == maintenanceDate.day;
            return sameDate &&
                   existing.odometer == maintenanceMap['odometer'] &&
                   existing.type == maintenanceMap['type'];
          });
          
          if (!isDuplicate) {
            maintenanceMap.remove('id');
            await DatabaseHelper.instance.insertMaintenance(MaintenanceEntry.fromMap(maintenanceMap));
          } else {
            print('⏭️ Skipping duplicate maintenance: ${maintenanceMap['date']}');
          }
        }
      }
    }
    
    // Import user settings if present
    if (data['user_settings'] != null) {
      try {
        final settingsMap = Map<String, dynamic>.from(data['user_settings']);
        final importedSettings = UserSettings.fromMap(settingsMap);
        await DatabaseHelper.instance.saveSettings(importedSettings);
        print('✅ User settings imported: ${importedSettings.firstName}');
      } catch (e) {
        print('⚠️ Could not import user settings: $e');
      }
    }
    
    await initializeApp();
    _setLoading(false);
  }

  // ============ CARD CONFIG PERSISTENCE WITH SIZE ============
  
  Future<void> _saveCardConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardData = _visibleCards.map((c) => {
        'id': c.id,
        'isVisible': c.isVisible,
        'size': c.size.name, // Save size!
      }).toList();
      await prefs.setString('dashboard_cards', jsonEncode(cardData));
      debugPrint('💾 Saved card config with sizes');
    } catch (e) {
      debugPrint('❌ Error saving card config: $e');
    }
  }
  
  Future<void> _loadCardConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardDataString = prefs.getString('dashboard_cards');
      
      if (cardDataString != null) {
        final List<dynamic> cardData = jsonDecode(cardDataString);
        final Map<String, bool> visibilityMap = {};
        final Map<String, CardSize> sizeMap = {};
        final List<String> orderList = [];
        
        for (var item in cardData) {
          final id = item['id'] as String;
          orderList.add(id);
          visibilityMap[id] = item['isVisible'] as bool;
          
          // Load size (default to XL if not found)
          final sizeString = item['size'] as String?;
          sizeMap[id] = CardSize.values.firstWhere(
            (s) => s.name == sizeString,
            orElse: () => CardSize.xl,
          );
        }
        
        final reorderedCards = <DashboardCardConfig>[];
        for (var id in orderList) {
          final card = DashboardCards.allCards.firstWhereOrNull((c) => c.id == id);
          if (card != null) {
            reorderedCards.add(card.copyWith(
              isVisible: visibilityMap[id],
              size: sizeMap[id],
            ));
          }
        }
        
        // Add new cards not in saved config
        for (var card in DashboardCards.allCards) {
          if (!orderList.contains(card.id)) {
            reorderedCards.add(card);
          }
        }
        
        _visibleCards = reorderedCards;
        debugPrint('📂 Loaded ${_visibleCards.length} cards with sizes');
      }
    } catch (e) {
      debugPrint('❌ Error loading card config: $e');
    }
  }
}