class FuelEntry {
  final int? id;
  final int carId;
  final DateTime date;
  final double odometer;
  final double liters;
  final double priceTotal;
  final double pricePerLiter;
  final String fuelType;

  FuelEntry({
    this.id,
    required this.carId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.priceTotal,
    required this.pricePerLiter,
    this.fuelType = '', 
  });

  // HIER ZAT DE FOUT: De keys (links) moeten matchen met de database kolommen
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,            // BELANGRIJK: car_id (niet carId)
      'date': date.toIso8601String(),
      'odometer': odometer,
      'liters': liters,
      'price_total': priceTotal,       // BELANGRIJK: price_total
      'price_per_liter': pricePerLiter, // BELANGRIJK: price_per_liter
      'fuel_type': fuelType,           // BELANGRIJK: fuel_type
    };
  }

  // En hier vertalen we het weer terug naar de App
  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    final liters = map['liters'] as double;
    final priceTotal = map['price_total'] as double;
    var pricePerLiter = map['price_per_liter'] as double;
    
    // Auto-calculate pricePerLiter if it's 0 or null but we have total and liters
    if ((pricePerLiter == 0 || pricePerLiter == null) && liters > 0 && priceTotal > 0) {
      pricePerLiter = priceTotal / liters;
    }
    
    return FuelEntry(
      id: map['id'],
      carId: map['car_id'],            
      date: DateTime.parse(map['date']),
      odometer: map['odometer'],
      liters: liters,
      priceTotal: priceTotal,      
      pricePerLiter: pricePerLiter, 
      fuelType: map['fuel_type'] ?? '',     
    );
  }
}