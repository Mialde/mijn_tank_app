// LAATST BIJGEWERKT: 2026-02-15 19:15 UTC
// WIJZIGING: Integrated smart database importer with migration support
// REDEN: Handle oude backups met missende velden (fuel_type, owner)

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/fuel_entry.dart';
import '../models/car.dart';
import '../models/maintenance_entry.dart';
import 'database_importer.dart';

class BackupService {
  static Future<void> createBackup(
    List<Car> cars, 
    List<FuelEntry> allEntries,
    {List<MaintenanceEntry>? maintenanceEntries}
  ) async {
    Map<String, dynamic> backupData = {
      "version": 3, // Updated voor nieuwe velden
      "cars": cars.map((c) => c.toMap()).toList(),
      "entries": allEntries.map((e) => e.toMap()).toList(),
      "maintenance": maintenanceEntries?.map((m) => m.toMap()).toList() ?? [],
    };

    String jsonString = jsonEncode(backupData);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/tank_app_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Mijn Tank App Backup');
  }

  /// Importeert backup EN analyseert voor oude versies
  /// Returned ImportAnalysis voor migration dialog
  static Future<BackupImportResult?> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return null;

    File file = File(result.files.single.path!);
    String content = await file.readAsString();
    Map<String, dynamic> json = jsonDecode(content);
    
    // Analyseer voor oude versie
    final analysis = DatabaseImporter.analyzeJson(json);
    
    return BackupImportResult(
      rawJson: json,
      analysis: analysis,
      fuelEntries: DatabaseImporter.parseFuelEntries(json),
      maintenanceEntries: DatabaseImporter.parseMaintenanceEntries(json),
    );
  }
}

/// Result van backup import met migration analysis
class BackupImportResult {
  final Map<String, dynamic> rawJson;
  final ImportAnalysis analysis;
  final List<FuelEntry> fuelEntries;
  final List<MaintenanceEntry> maintenanceEntries;
  
  BackupImportResult({
    required this.rawJson,
    required this.analysis,
    required this.fuelEntries,
    required this.maintenanceEntries,
  });
}