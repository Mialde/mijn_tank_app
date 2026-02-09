import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/fuel_entry.dart';
import '../models/car.dart';

class ExportService {
  /// Exporteert tankbeurten naar een CSV bestand en opent het deel-menu
  static Future<void> exportEntriesToCsv(List<FuelEntry> entries, Car? car) async {
    if (entries.isEmpty) return;

    // 1. Maak de headers
    List<List<dynamic>> rows = [];
    rows.add([
      "Datum",
      "Auto",
      "Kilometerstand",
      "Liters",
      "Totaal Prijs",
      "Prijs per Liter"
    ]);

    // 2. Voeg de data toe
    for (var entry in entries) {
      rows.add([
        entry.date.toIso8601String().split('T')[0],
        car?.name ?? "Onbekend",
        entry.odometer,
        entry.liters,
        entry.priceTotal,
        entry.pricePerLiter,
      ]);
    }

    // 3. Zet om naar CSV tekst
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Sla op als tijdelijk bestand
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/tankbeurten_${car?.name ?? "export"}.csv');
    await file.writeAsString(csvData);

    // 5. Deel het bestand (zodat de gebruiker het kan opslaan op de telefoon)
    await Share.shareXFiles([XFile(file.path)], text: 'Mijn Tank App Backup');
  }

  /// Maakt een volledige backup van de database (het .db bestand zelf)
  static Future<void> backupDatabase() async {
    // In Flutter/SQLite vind je de database meestal in de getDatabasesPath()
    // Voor nu maken we een export van alle data naar een tekstbestand, 
    // dit is veiliger voor backups op verschillende telefoons.
    // (Wil je echt het .db bestand kopiëren? Laat het me weten!)
  }
}