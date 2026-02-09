class Car {
  final int? id;
  final String name;
  final String licensePlate;
  final String type;
  final DateTime? apkDate;
  final double insurance;
  final double roadTax;
  final String roadTaxFreq;

  Car({
    this.id,
    required this.name,
    required this.licensePlate,
    required this.type,
    this.apkDate,
    required this.insurance,
    required this.roadTax,
    required this.roadTaxFreq,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license_plate': licensePlate, // snake_case voor DB
      'type': type,
      'apk_date': apkDate?.toIso8601String(), // snake_case voor DB
      'insurance': insurance,
      'road_tax': roadTax, // snake_case voor DB
      'road_tax_freq': roadTaxFreq, // snake_case voor DB
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      name: map['name'],
      licensePlate: map['license_plate'], // snake_case uit DB
      type: map['type'],
      apkDate: map['apk_date'] != null ? DateTime.parse(map['apk_date']) : null,
      insurance: map['insurance'],
      roadTax: map['road_tax'],
      roadTaxFreq: map['road_tax_freq'],
    );
  }
}