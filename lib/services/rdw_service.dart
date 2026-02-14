import 'dart:convert';
import 'package:http/http.dart' as http;

class RdwService {
  static const String _baseUrl = 'https://opendata.rdw.nl/resource';
  
  /// Haalt voertuiggegevens op van de RDW open data API
  /// Kenteken format: Alle leestekens worden verwijderd, alleen letters en cijfers
  static Future<RdwVehicleData?> getVehicleData(String licensePlate) async {
    try {
      // Kenteken normaliseren: hoofdletters, ALLEEN letters en cijfers
      final cleanPlate = licensePlate
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), ''); // Verwijder ALLES behalve letters en cijfers
      
      if (cleanPlate.length < 4 || cleanPlate.length > 8) {
        throw Exception('Ongeldig kenteken format');
      }

      // RDW API endpoints
      final basisUrl = '$_baseUrl/m9d7-ebf2.json?kenteken=$cleanPlate';
      final eigenaarUrl = '$_baseUrl/vwe4-gjpa.json?kenteken=$cleanPlate';
      
      // Basis voertuiggegevens ophalen
      final basisResponse = await http.get(Uri.parse(basisUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('RDW timeout - probeer later opnieuw'),
      );

      if (basisResponse.statusCode != 200) {
        throw Exception('RDW API error: ${basisResponse.statusCode}');
      }

      final List<dynamic> basisData = jsonDecode(basisResponse.body);
      
      if (basisData.isEmpty) {
        return null; // Kenteken niet gevonden
      }

      final vehicleInfo = basisData.first;

      // Eigenaar gegevens ophalen (optioneel)
      String? owner;
      try {
        final eigenaarResponse = await http.get(Uri.parse(eigenaarUrl)).timeout(
          const Duration(seconds: 5),
        );
        
        if (eigenaarResponse.statusCode == 200) {
          final List<dynamic> eigenaarData = jsonDecode(eigenaarResponse.body);
          if (eigenaarData.isNotEmpty) {
            owner = eigenaarData.first['tenaamstelling_houder'] ?? 
                    eigenaarData.first['tenaamstelling_eigenaar'];
          }
        }
      } catch (e) {
        // Eigenaar ophalen niet kritisch, ga door zonder
        print('Eigenaar ophalen mislukt: $e');
      }

      return RdwVehicleData.fromJson(vehicleInfo, owner);
      
    } catch (e) {
      print('RDW Service Error: $e');
      rethrow;
    }
  }

  /// Normaliseert een kenteken: alleen hoofdletters, letters en cijfers
  static String normalizeLicensePlate(String plate) {
    return plate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class RdwVehicleData {
  final String? merk;
  final String? handelsbenaming;
  final String? voertuigsoort;
  final DateTime? apkVervaldatum;
  final String? brandstof;
  final String? eigenaar;
  final int? bouwjaar;
  final String? kleur;

  RdwVehicleData({
    this.merk,
    this.handelsbenaming,
    this.voertuigsoort,
    this.apkVervaldatum,
    this.brandstof,
    this.eigenaar,
    this.bouwjaar,
    this.kleur,
  });

  factory RdwVehicleData.fromJson(Map<String, dynamic> json, String? eigenaar) {
    // Parse APK datum
    DateTime? apkDate;
    final String? apkString = json['vervaldatum_apk'];
    if (apkString != null && apkString.isNotEmpty) {
      try {
        // RDW format: "20261231" (YYYYMMDD)
        final year = int.parse(apkString.substring(0, 4));
        final month = int.parse(apkString.substring(4, 6));
        final day = int.parse(apkString.substring(6, 8));
        apkDate = DateTime(year, month, day);
      } catch (e) {
        print('APK datum parse error: $e');
      }
    }

    // Parse bouwjaar
    int? bouwjaar;
    final String? datumEersteToelating = json['datum_eerste_toelating'];
    if (datumEersteToelating != null && datumEersteToelating.length >= 4) {
      try {
        bouwjaar = int.parse(datumEersteToelating.substring(0, 4));
      } catch (e) {
        print('Bouwjaar parse error: $e');
      }
    }

    return RdwVehicleData(
      merk: json['merk'],
      handelsbenaming: json['handelsbenaming'],
      voertuigsoort: json['voertuigsoort'],
      apkVervaldatum: apkDate,
      brandstof: _parseBrandstof(json['brandstof_omschrijving']),
      eigenaar: eigenaar,
      bouwjaar: bouwjaar,
      kleur: json['eerste_kleur'],
    );
  }

  /// Vertaalt RDW brandstof codes naar leesbare namen
  static String? _parseBrandstof(String? rdwBrandstof) {
    if (rdwBrandstof == null) return null;
    
    final brandstofLower = rdwBrandstof.toLowerCase();
    
    if (brandstofLower.contains('benzine')) return 'Benzine';
    if (brandstofLower.contains('diesel')) return 'Diesel';
    if (brandstofLower.contains('elektr')) return 'Elektrisch';
    if (brandstofLower.contains('lpg')) return 'LPG';
    if (brandstofLower.contains('cng')) return 'CNG';
    if (brandstofLower.contains('waterstof')) return 'Waterstof';
    if (brandstofLower.contains('hybr')) return 'Hybride';
    
    return rdwBrandstof; // Return origineel als we het niet herkennen
  }

  /// Genereert een voertuignaam uit merk en model
  String getVehicleName() {
    // Voorkom dubbele merknaam (bijv. "Toyota Toyota Yaris")
    if (handelsbenaming != null && merk != null) {
      // Check of handelsbenaming al het merk bevat
      if (handelsbenaming!.toLowerCase().contains(merk!.toLowerCase())) {
        return handelsbenaming!; // Gebruik alleen handelsbenaming
      }
      return '$merk $handelsbenaming'; // Combineer beide
    } else if (handelsbenaming != null) {
      return handelsbenaming!;
    } else if (merk != null) {
      return merk!;
    }
    return 'Onbekend voertuig';
  }

  /// Vertaalt RDW voertuigsoort naar app types
  String getVehicleType() {
    if (voertuigsoort == null) return 'Auto';
    
    final soortLower = voertuigsoort!.toLowerCase();
    
    if (soortLower.contains('motor')) return 'Motor';
    if (soortLower.contains('vracht')) return 'Vrachtwagen';
    if (soortLower.contains('scooter') || soortLower.contains('bromfiets')) return 'Scooter';
    if (soortLower.contains('bus')) return 'Bus';
    if (soortLower.contains('camper')) return 'Camper';
    if (soortLower.contains('tractor')) return 'Tractor';
    if (soortLower.contains('bestel')) return 'Bestelwagen';
    
    return 'Auto'; // Default
  }
}