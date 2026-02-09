import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/fuel_entry.dart';
import '../models/car.dart';

class BackupService {
  static Future<void> createBackup(List<Car> cars, List<FuelEntry> allEntries) async {
    Map<String, dynamic> backupData = {
      "version": 1,
      "cars": cars.map((c) => c.toMap()).toList(),
      "entries": allEntries.map((e) => e.toMap()).toList(),
    };

    String jsonString = jsonEncode(backupData);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/tank_app_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Mijn Tank App Backup');
  }

  static Future<Map<String, dynamic>?> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      return jsonDecode(content);
    }
    return null;
  }
}