import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/car.dart';
import '../models/fuel_entry.dart';

class DataService {
  // --- PDF EXPORT ---
  static Future<void> exportToPDF(Car car, List<FuelEntry> entries) async {
    final pdf = pw.Document();
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
                pw.Text('TankBuddy Rapport', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(car.name, style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00D09E)),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headers: ['Datum', 'KM-stand', 'Liters', 'Totaal'],
            data: entries.map((e) => [
              dateFormat.format(e.date),
              '${e.odometer.toInt()} km',
              '${e.liters.toStringAsFixed(2)} L',
              '€ ${e.priceTotal.toStringAsFixed(2)}',
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- EXPORT TOOLS ---
  static Future<void> shareAsCSV(List<FuelEntry> entries) async {
    List<List<dynamic>> rows = [["Datum", "KM-stand", "Liters", "Totaal"]];
    for (var e in entries) {
      rows.add([e.date.toIso8601String(), e.odometer, e.liters, e.priceTotal]);
    }
    String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final file = File('${Directory.systemTemp.path}/export.csv');
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Tank Data CSV');
  }

  static Future<void> shareAsExcel(List<FuelEntry> entries) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['TankData'];
    sheet.appendRow([TextCellValue("Datum"), TextCellValue("KM"), TextCellValue("Liters"), TextCellValue("Prijs")]);
    for (var e in entries) {
      sheet.appendRow([TextCellValue(e.date.toString()), DoubleCellValue(e.odometer), DoubleCellValue(e.liters), DoubleCellValue(e.priceTotal)]);
    }
    var fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File('${Directory.systemTemp.path}/export.xlsx');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Tank Data Excel');
    }
  }

  static Future<void> saveBackupJSON(Map<String, dynamic> data) async {
    String jsonString = const JsonEncoder.withIndent('  ').convert(data);
    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
    await FilePicker.platform.saveFile(
      dialogTitle: 'Backup opslaan',
      fileName: 'tankbuddy_backup.json',
      bytes: bytes,
    );
  }

  static Future<void> shareBackupJSON(Map<String, dynamic> data) async {
    String jsonString = jsonEncode(data);
    final file = File('${Directory.systemTemp.path}/backup.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Tank Backup JSON');
  }

  // --- SMART IMPORT TOOLS ---
  
  // Haalt alleen de headers op van een CSV bestand
  static Future<List<String>?> getCSVHeaders() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter(fieldDelimiter: ';')).first;
      return fields.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Haalt de volledige content op (ruwe string)
  static Future<String?> pickFile(List<String> extensions) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!).readAsString();
    }
    return null;
  }
}