import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:csv/csv.dart';
import '../models/car.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';

class DataService {
  // De bestandsnaam volgt nu: TankAppie_backup_ddmmyyyyhhmmss.ext
  static String _getFilename(String extension) {
    final now = DateTime.now();
    final timestamp = DateFormat('ddMMyyyyHHmmss').format(now);
    return 'TankAppie_backup_$timestamp.$extension';
  }

  // Helper om autonaam op te halen
  static String _getCarName(int carId, List<Car> cars) {
    try {
      final car = cars.firstWhere((c) => c.id == carId);
      return '${car.name} (${car.licensePlate})';
    } catch (e) {
      return 'Onbekend voertuig';
    }
  }

  // --- PDF GENERATIE ---
  static Future<pw.Document> _generatePDFDoc(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    // Laad Google Fonts in via de printing package voor Euroteken (€) ondersteuning
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );
    
    final dateFormat = DateFormat('dd-MM-yyyy', 'nl_NL');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TankAppie Rapport', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Alle Voertuigen', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          pw.Text('Tankbeurten', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00D09E)),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headers: ['Voertuig', 'Datum', 'KM-stand', 'Liters', 'Prijs/L', 'Totaal'],
            data: fuelEntries.map((e) {
              final pricePerLiter = e.liters > 0 ? e.priceTotal / e.liters : 0.0;
              return [
                _getCarName(e.carId, cars),
                dateFormat.format(e.date),
                '${e.odometer.toInt()} km',
                '${e.liters.toStringAsFixed(2)} L',
                '€ ${pricePerLiter.toStringAsFixed(3)}',
                '€ ${e.priceTotal.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          if (maintenanceEntries.isNotEmpty) ...[
            pw.Text('Onderhoud', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headers: ['Voertuig', 'Datum', 'Type', 'Omschrijving', 'KM', 'Kosten'],
              data: maintenanceEntries.map((e) => [
                _getCarName(e.carId, cars),
                dateFormat.format(e.date),
                e.type,
                e.description,
                '${e.odometer.toInt()} km',
                '€ ${e.cost.toStringAsFixed(2)}',
              ]).toList(),
            ),
          ]
        ],
      ),
    );
    return pdf;
  }

  static Future<void> exportToPDF(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final pdf = await _generatePDFDoc(cars, fuelEntries, maintenanceEntries);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> savePDFLocally(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final pdf = await _generatePDFDoc(cars, fuelEntries, maintenanceEntries);
    final bytes = await pdf.save();
    await FilePicker.platform.saveFile(
      dialogTitle: 'Sla PDF Rapport op',
      fileName: _getFilename('pdf'),
      bytes: bytes,
    );
  }

  // --- CSV GENERATIE ---
  static String _generateCSVString(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) {
    List<List<dynamic>> rows = [];
    
    rows.add(["--- TANKBEURTEN ---"]);
    rows.add(["Voertuig", "Datum", "KM-stand", "Liters", "Prijs/L", "Totaal"]);
    for (var e in fuelEntries) {
      final pricePerLiter = e.liters > 0 ? e.priceTotal / e.liters : 0.0;
      rows.add([
        _getCarName(e.carId, cars),
        e.date.toIso8601String().split('T')[0],
        e.odometer,
        e.liters,
        pricePerLiter,
        e.priceTotal
      ]);
    }

    if (maintenanceEntries.isNotEmpty) {
      rows.add([]);
      rows.add(["--- ONDERHOUD ---"]);
      rows.add(["Voertuig", "Datum", "Type", "Omschrijving", "KM-stand", "Kosten"]);
      for (var e in maintenanceEntries) {
        rows.add([
          _getCarName(e.carId, cars),
          e.date.toIso8601String().split('T')[0],
          e.type,
          e.description,
          e.odometer,
          e.cost
        ]);
      }
    }
    return const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
  }

  static Future<void> shareAsCSV(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final csvData = _generateCSVString(cars, fuelEntries, maintenanceEntries);
    final fileName = _getFilename('csv');
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Tank Data CSV');
  }

  static Future<void> saveCSVLocally(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final csvData = _generateCSVString(cars, fuelEntries, maintenanceEntries);
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    await FilePicker.platform.saveFile(
      dialogTitle: 'Sla CSV op',
      fileName: _getFilename('csv'),
      bytes: bytes,
    );
  }

  // --- EXCEL GENERATIE ---
  static Uint8List? _generateExcelBytes(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) {
    var excel = ex.Excel.createExcel();
    excel.rename(excel.getDefaultSheet()!, 'Tankbeurten');
    
    ex.Sheet fuelSheet = excel['Tankbeurten'];
    fuelSheet.appendRow([ex.TextCellValue("Voertuig"), ex.TextCellValue("Datum"), ex.TextCellValue("KM-stand"), ex.TextCellValue("Liters"), ex.TextCellValue("Prijs/L"), ex.TextCellValue("Totaal")]);
    for (var e in fuelEntries) {
      final pricePerLiter = e.liters > 0 ? e.priceTotal / e.liters : 0.0;
      fuelSheet.appendRow([
        ex.TextCellValue(_getCarName(e.carId, cars)),
        ex.TextCellValue(e.date.toIso8601String().split('T')[0]),
        ex.DoubleCellValue(e.odometer),
        ex.DoubleCellValue(e.liters),
        ex.DoubleCellValue(pricePerLiter),
        ex.DoubleCellValue(e.priceTotal)
      ]);
    }

    if (maintenanceEntries.isNotEmpty) {
      ex.Sheet maintSheet = excel['Onderhoud'];
      maintSheet.appendRow([ex.TextCellValue("Voertuig"), ex.TextCellValue("Datum"), ex.TextCellValue("Type"), ex.TextCellValue("Omschrijving"), ex.TextCellValue("KM-stand"), ex.TextCellValue("Kosten")]);
      for (var e in maintenanceEntries) {
        maintSheet.appendRow([
          ex.TextCellValue(_getCarName(e.carId, cars)),
          ex.TextCellValue(e.date.toIso8601String().split('T')[0]),
          ex.TextCellValue(e.type),
          ex.TextCellValue(e.description),
          ex.DoubleCellValue(e.odometer),
          ex.DoubleCellValue(e.cost)
        ]);
      }
    }

    final bytes = excel.save();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  static Future<void> shareAsExcel(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final bytes = _generateExcelBytes(cars, fuelEntries, maintenanceEntries);
    if (bytes != null) {
      final fileName = _getFilename('xlsx');
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Tank Data Excel');
    }
  }

  static Future<void> saveExcelLocally(List<Car> cars, List<FuelEntry> fuelEntries, List<MaintenanceEntry> maintenanceEntries) async {
    final bytes = _generateExcelBytes(cars, fuelEntries, maintenanceEntries);
    if (bytes != null) {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Sla Excel op',
        fileName: _getFilename('xlsx'),
        bytes: bytes,
      );
    }
  }

  // --- JSON BACKUP ---
  static Future<void> saveBackupJSON(Map<String, dynamic> data) async {
    String jsonString = const JsonEncoder.withIndent('  ').convert(data);
    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
    await FilePicker.platform.saveFile(
      dialogTitle: 'Backup opslaan',
      fileName: _getFilename('json'),
      bytes: bytes,
    );
  }

  static Future<void> shareBackupJSON(Map<String, dynamic> data) async {
    String jsonString = jsonEncode(data);
    final fileName = _getFilename('json');
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Tank Backup JSON');
  }

  // --- SMART IMPORT TOOLS ---
  static Future<List<List<dynamic>>?> pickAndParseCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter(fieldDelimiter: ';').convert(input);
      if (rows.isNotEmpty && rows[0].length <= 1) {
        rows = const CsvToListConverter(fieldDelimiter: ',').convert(input);
      }
      return rows;
    }
    return null;
  }

  static Future<List<List<dynamic>>?> pickAndParseExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null && result.files.single.bytes != null) {
      var excel = ex.Excel.decodeBytes(result.files.single.bytes!);
      List<List<dynamic>> rows = [];
      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          rows.add(row.map((cell) => cell?.value?.toString() ?? "").toList());
        }
        break; 
      }
      return rows;
    }
    return null;
  }

  static Future<String?> pickFile(List<String> extensions) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!).readAsString();
    }
    return null;
  }
}