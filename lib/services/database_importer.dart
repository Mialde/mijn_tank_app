// LAATST BIJGEWERKT: 2026-02-15 19:15 UTC
// WIJZIGING: Removed unused dart:convert import
// REDEN: Clean code, fix linter warning

import '../models/car.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import 'rdw_service.dart';

class DatabaseImporter {
  
  /// Detecteert of JSON oude versie is (missende velden)
  static ImportAnalysis analyzeJson(Map<String, dynamic> json) {
    final cars = json['cars'] as List? ?? [];
    
    int missingFuelType = 0;
    int missingOwner = 0;
    List<Map<String, dynamic>> carsData = [];
    
    for (var carJson in cars) {
      final carMap = carJson as Map<String, dynamic>;
      carsData.add(carMap);
      
      if (!carMap.containsKey('fuel_type') || carMap['fuel_type'] == null) {
        missingFuelType++;
      }
      if (!carMap.containsKey('owner') || carMap['owner'] == null) {
        missingOwner++;
      }
    }
    
    return ImportAnalysis(
      totalCars: cars.length,
      missingFuelType: missingFuelType,
      missingOwner: missingOwner,
      needsMigration: missingFuelType > 0 || missingOwner > 0,
      carsData: carsData,
      fullJson: json,
    );
  }
  
  /// Vult ontbrekende velden aan via RDW
  static Future<List<Car>> fillFromRdw(
    List<Map<String, dynamic>> carsData,
    Function(int current, int total, String carName)? onProgress,
  ) async {
    List<Car> migratedCars = [];
    
    for (int i = 0; i < carsData.length; i++) {
      final carMap = carsData[i];
      final licensePlate = carMap['license_plate'] as String?;
      final carName = carMap['name'] as String? ?? 'Onbekend';
      
      onProgress?.call(i + 1, carsData.length, carName);
      
      String? fuelType = carMap['fuel_type'];
      String? owner = carMap['owner'];
      
      // Als kenteken beschikbaar en data ontbreekt, probeer RDW
      if (licensePlate != null && licensePlate.isNotEmpty) {
        if (fuelType == null || owner == null) {
          try {
            final rdwData = await RdwService.getVehicleData(licensePlate);
            
            if (rdwData != null) {
              fuelType ??= rdwData.brandstof;
              owner ??= rdwData.eigenaar;
              
              print('✓ RDW data opgehaald voor $carName: $fuelType, $owner');
            }
          } catch (e) {
            print('⚠️ RDW lookup failed voor $carName: $e');
            // Continue zonder RDW data
          }
        }
      }
      
      // Maak Car object met alle data
      final car = Car(
        id: carMap['id'],
        name: carName,
        licensePlate: licensePlate ?? '',
        type: carMap['type'] ?? 'Auto',
        apkDate: carMap['apk_date'] != null 
            ? DateTime.tryParse(carMap['apk_date']) 
            : null,
        insurance: (carMap['insurance'] ?? 0).toDouble(),
        roadTax: (carMap['road_tax'] ?? 0).toDouble(),
        roadTaxFreq: carMap['road_tax_freq'] ?? 'Jaar',
        fuelType: fuelType,
        owner: owner,
      );
      
      migratedCars.add(car);
    }
    
    return migratedCars;
  }
  
  /// Parse fuel entries van JSON
  static List<FuelEntry> parseFuelEntries(Map<String, dynamic> json) {
    final entries = json['entries'] as List? ?? [];
    
    return entries.map((entryJson) {
      final map = entryJson as Map<String, dynamic>;
      return FuelEntry(
        id: map['id'],
        carId: map['car_id'],
        date: DateTime.parse(map['date']),
        odometer: (map['odometer'] ?? 0).toDouble(),
        liters: (map['liters'] ?? 0).toDouble(),
        priceTotal: (map['price_total'] ?? 0).toDouble(),
        pricePerLiter: (map['price_per_liter'] ?? 0).toDouble(),
        fuelType: map['fuel_type'],
      );
    }).toList();
  }
  
  /// Parse maintenance entries van JSON
  static List<MaintenanceEntry> parseMaintenanceEntries(Map<String, dynamic> json) {
    final entries = json['maintenance'] as List? ?? [];
    
    return entries.map((entryJson) {
      final map = entryJson as Map<String, dynamic>;
      return MaintenanceEntry(
        id: map['id'],
        carId: map['car_id'],
        date: DateTime.parse(map['date']),
        odometer: (map['odometer'] ?? 0).toDouble(),
        type: map['type'] ?? 'Onderhoud',
        description: map['description'] ?? '',
        cost: (map['cost'] ?? 0).toDouble(),
      );
    }).toList();
  }
}

/// Resultaat van JSON analyse
class ImportAnalysis {
  final int totalCars;
  final int missingFuelType;
  final int missingOwner;
  final bool needsMigration;
  final List<Map<String, dynamic>> carsData;
  final Map<String, dynamic> fullJson;
  
  ImportAnalysis({
    required this.totalCars,
    required this.missingFuelType,
    required this.missingOwner,
    required this.needsMigration,
    required this.carsData,
    required this.fullJson,
  });
  
  String getSummary() {
    if (!needsMigration) {
      return 'Backup is up-to-date! Alle velden aanwezig.';
    }
    
    List<String> missing = [];
    if (missingFuelType > 0) {
      missing.add('Brandstoftype ($missingFuelType auto\'s)');
    }
    if (missingOwner > 0) {
      missing.add('Eigenaar ($missingOwner auto\'s)');
    }
    
    return 'Ontbrekende gegevens:\n${missing.join('\n')}';
  }
}