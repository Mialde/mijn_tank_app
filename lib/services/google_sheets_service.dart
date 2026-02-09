import 'package:gsheets/gsheets.dart';
import 'package:flutter/material.dart';
import '../models/fuel_entry.dart';

class GoogleSheetsService {
  // Credentials placeholders
  static const _credentials = r'''
  {
    "type": "service_account",
    "project_id": "jouw-project-id",
    "private_key_id": "jouw-key-id",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...jouw-key...\n-----END PRIVATE KEY-----\n",
    "client_email": "jouw-service-account@project.iam.gserviceaccount.com",
    "client_id": "jouw-client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "jouw-cert-url"
  }
  ''';
  
  static const _spreadsheetId = 'JOUW_SPREADSHEET_ID_HIER';
  
  static GSheets? _gsheets;
  static Worksheet? _userSheet;

  static Future<void> init() async {
    // Check of de placeholders nog aanwezig zijn. Zo ja, stop direct.
    if (_credentials.contains('...jouw-key...') || _spreadsheetId.contains('JOUW_SPREADSHEET')) {
      debugPrint('Google Sheets: Geen geldige inloggegevens gevonden. Synchronisatie staat uit.');
      return;
    }

    try {
      _gsheets = GSheets(_credentials);
      final ss = await _gsheets!.spreadsheet(_spreadsheetId);
      _userSheet = await _getWorksheet(ss, title: 'Entries');
      
      final values = await _userSheet!.values.row(1);
      if (values.isEmpty) {
        await _userSheet!.values.insertRow(1, [
          'Datum', 
          'Kilometerstand', 
          'Liters', 
          'Totaal Prijs', 
          'Prijs per Liter', 
          'Auto ID'
        ]);
      }
    } catch (e) {
      debugPrint('Fout bij initialiseren Google Sheets: $e');
    }
  }

  static Future<Worksheet> _getWorksheet(Spreadsheet ss, {required String title}) async {
    try {
      return ss.worksheetByTitle(title) ?? await ss.addWorksheet(title);
    } catch (e) {
      return await ss.addWorksheet(title);
    }
  }

  static Future<bool> syncEntry(FuelEntry entry) async {
    if (_userSheet == null) return false;

    try {
      final row = [
        entry.date.toIso8601String().split('T')[0],
        entry.odometer,
        entry.liters,
        entry.priceTotal,
        entry.pricePerLiter,
        entry.carId,
      ];

      return await _userSheet!.values.appendRow(row);
    } catch (e) {
      debugPrint('Fout bij synchroniseren van entry: $e');
      return false;
    }
  }
}