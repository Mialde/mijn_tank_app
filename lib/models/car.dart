import 'dart:convert';

class MaintenanceInterval {
  final bool enabled;
  final double? kmInterval;
  final int? dayInterval;

  const MaintenanceInterval({
    this.enabled = true,
    this.kmInterval,
    this.dayInterval,
  });

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'km': kmInterval,
    'days': dayInterval,
  };

  factory MaintenanceInterval.fromMap(Map<String, dynamic> map) =>
      MaintenanceInterval(
        enabled: map['enabled'] ?? true,
        kmInterval: (map['km'] as num?)?.toDouble(),
        dayInterval: map['days'] as int?,
      );
}

/// Standaard intervallen per onderhoudstype
const Map<String, MaintenanceInterval> kDefaultIntervals = {
  'Kleine beurt': MaintenanceInterval(kmInterval: 15000, dayInterval: 365),
  'Grote beurt':  MaintenanceInterval(kmInterval: 30000, dayInterval: 730),
  'Banden':       MaintenanceInterval(kmInterval: 40000, dayInterval: 1825),
  'APK':          MaintenanceInterval(kmInterval: null,  dayInterval: 365),
};

class Car {
  final int? id;
  final String name;
  final String licensePlate;
  final String type;
  final DateTime? apkDate;
  final double insurance;
  final double roadTax;
  final String roadTaxFreq;
  final String? fuelType;
  final String? owner;
  /// Per-auto overschrijving van onderhoud intervallen (null = gebruik globale standaard)
  final Map<String, MaintenanceInterval>? maintenanceIntervals;

  // Doelstellingen
  final double? goalMaxFuelPrice;   // Max prijs per liter (alert bij overschrijding)
  final double? goalEfficiency;     // Gewenst verbruik in km/L
  final int?    goalMonthlyKm;      // Gewenst aantal km per maand

  Car({
    this.id,
    required this.name,
    required this.licensePlate,
    required this.type,
    this.apkDate,
    required this.insurance,
    required this.roadTax,
    required this.roadTaxFreq,
    this.fuelType,
    this.owner,
    this.maintenanceIntervals,
    this.goalMaxFuelPrice,
    this.goalEfficiency,
    this.goalMonthlyKm,
  });

  /// Geeft het interval voor een type terug — auto-specifiek of standaard
  MaintenanceInterval intervalFor(String type) =>
      maintenanceIntervals?[type] ?? kDefaultIntervals[type] ?? const MaintenanceInterval();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license_plate': licensePlate,
      'type': type,
      'apk_date': apkDate?.toIso8601String(),
      'insurance': insurance,
      'road_tax': roadTax,
      'road_tax_freq': roadTaxFreq,
      'fuel_type': fuelType,
      'owner': owner,
      'maintenance_intervals': maintenanceIntervals != null
          ? jsonEncode(maintenanceIntervals!.map((k, v) => MapEntry(k, v.toMap())))
          : null,
      'goal_max_fuel_price': goalMaxFuelPrice,
      'goal_efficiency': goalEfficiency,
      'goal_monthly_km': goalMonthlyKm,
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    Map<String, MaintenanceInterval>? intervals;
    final raw = map['maintenance_intervals'];
    if (raw != null && raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        intervals = decoded.map((k, v) =>
            MapEntry(k, MaintenanceInterval.fromMap(v as Map<String, dynamic>)));
      } catch (_) {}
    }

    return Car(
      id: map['id'],
      name: map['name'],
      licensePlate: map['license_plate'],
      type: map['type'],
      apkDate: map['apk_date'] != null ? DateTime.parse(map['apk_date']) : null,
      insurance: (map['insurance'] as num).toDouble(),
      roadTax: (map['road_tax'] as num).toDouble(),
      roadTaxFreq: map['road_tax_freq'],
      fuelType: map['fuel_type'],
      owner: map['owner'],
      maintenanceIntervals: intervals,
      goalMaxFuelPrice: map['goal_max_fuel_price'] != null ? (map['goal_max_fuel_price'] as num).toDouble() : null,
      goalEfficiency:   map['goal_efficiency']     != null ? (map['goal_efficiency']     as num).toDouble() : null,
      goalMonthlyKm:    map['goal_monthly_km']     != null ? (map['goal_monthly_km']     as num).toInt()    : null,
    );
  }

  Car copyWith({
    int? id,
    String? name,
    String? licensePlate,
    String? type,
    DateTime? apkDate,
    double? insurance,
    double? roadTax,
    String? roadTaxFreq,
    String? fuelType,
    String? owner,
    Map<String, MaintenanceInterval>? maintenanceIntervals,
    Object? goalMaxFuelPrice = _sentinel,
    Object? goalEfficiency   = _sentinel,
    Object? goalMonthlyKm    = _sentinel,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      type: type ?? this.type,
      apkDate: apkDate ?? this.apkDate,
      insurance: insurance ?? this.insurance,
      roadTax: roadTax ?? this.roadTax,
      roadTaxFreq: roadTaxFreq ?? this.roadTaxFreq,
      fuelType: fuelType ?? this.fuelType,
      owner: owner ?? this.owner,
      maintenanceIntervals: maintenanceIntervals ?? this.maintenanceIntervals,
      goalMaxFuelPrice: goalMaxFuelPrice == _sentinel ? this.goalMaxFuelPrice : goalMaxFuelPrice as double?,
      goalEfficiency:   goalEfficiency   == _sentinel ? this.goalEfficiency   : goalEfficiency   as double?,
      goalMonthlyKm:    goalMonthlyKm    == _sentinel ? this.goalMonthlyKm    : goalMonthlyKm    as int?,
    );
  }
}

// Sentinel voor nullable copyWith
const _sentinel = Object();