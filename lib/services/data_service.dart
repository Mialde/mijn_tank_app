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

class DataService {
  // De bestandsnaam volgt nu: TankAppie_backup_ddmmyyyyhhmmss.ext
  static String _getFilename(String extension) {
    final now = DateTime.now();
    final timestamp = DateFormat('ddMMyyyyHHmmss').format(now);
    return 'TankAppie_backup_$timestamp.$extension';
  }

  // --- PDF GENERATIE ---
  static Future<pw.Document> _generatePDFDoc(Car car, List<FuelEntry> entries) async {
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
                pw.Text('TankAppie Rapport', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
    return pdf;
  }

  static Future<void> exportToPDF(Car car, List<FuelEntry> entries) async {
    final pdf = await _generatePDFDoc(car, entries);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> savePDFLocally(Car car, List<FuelEntry> entries) async {
    final pdf = await _generatePDFDoc(car, entries);
    final bytes = await pdf.save();
    await FilePicker.platform.saveFile(
      dialogTitle: 'Sla PDF Rapport op',
      fileName: _getFilename('pdf'),
      bytes: bytes,
    );
  }

  // --- CSV GENERATIE ---
  static String _generateCSVString(List<FuelEntry> entries) {
    List<List<dynamic>> rows = [["Datum", "KM-stand", "Liters", "Totaal"]];
    for (var e in entries) {
      rows.add([e.date.toIso8601String(), e.odometer, e.liters, e.priceTotal]);
    }
    return const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
  }

  static Future<void> shareAsCSV(List<FuelEntry> entries) async {
    final csvData = _generateCSVString(entries);
    final fileName = _getFilename('csv');
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Tank Data CSV');
  }

  static Future<void> saveCSVLocally(List<FuelEntry> entries) async {
    final csvData = _generateCSVString(entries);
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    await FilePicker.platform.saveFile(
      dialogTitle: 'Sla CSV op',
      fileName: _getFilename('csv'),
      bytes: bytes,
    );
  }

  // --- EXCEL GENERATIE ---
  static Uint8List? _generateExcelBytes(List<FuelEntry> entries) {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheet = excel['TankData'];
    sheet.appendRow([ex.TextCellValue("Datum"), ex.TextCellValue("KM"), ex.TextCellValue("Liters"), ex.TextCellValue("Prijs")]);
    for (var e in entries) {
      sheet.appendRow([ex.TextCellValue(e.date.toString()), ex.DoubleCellValue(e.odometer), ex.DoubleCellValue(e.liters), ex.DoubleCellValue(e.priceTotal)]);
    }
    final bytes = excel.save();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  static Future<void> shareAsExcel(List<FuelEntry> entries) async {
    final bytes = _generateExcelBytes(entries);
    if (bytes != null) {
      final fileName = _getFilename('xlsx');
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Tank Data Excel');
    }
  }

  static Future<void> saveExcelLocally(List<FuelEntry> entries) async {
    final bytes = _generateExcelBytes(entries);
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