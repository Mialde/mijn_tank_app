class MaintenanceEntry {
  final int? id;
  final int carId;
  final DateTime date;
  final double odometer;
  final String type; // Bijv: Kleine beurt, Grote beurt, Banden, Reparatie, APK
  final String description;
  final double cost;

  MaintenanceEntry({
    this.id,
    required this.carId,
    required this.date,
    required this.odometer,
    required this.type,
    required this.description,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'type': type,
      'description': description,
      'cost': cost,
    };
  }

  factory MaintenanceEntry.fromMap(Map<String, dynamic> map) {
    return MaintenanceEntry(
      id: map['id'],
      carId: map['car_id'],
      date: DateTime.parse(map['date']),
      odometer: map['odometer'],
      type: map['type'],
      description: map['description'],
      cost: map['cost'],
    );
  }
}