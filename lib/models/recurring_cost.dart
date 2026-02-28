// RECURRING COST MODEL
// For subscriptions, memberships, etc.

class RecurringCost {
  final int? id;
  final int carId;
  final String name;           // "ANWB Wegenwacht", "Flitsmeister Premium"
  final double amount;         // Monthly cost
  final String frequency;      // "monthly", "yearly", "quarterly"
  final String? description;
  final bool isActive;         // Can disable without deleting
  
  RecurringCost({
    this.id,
    required this.carId,
    required this.name,
    required this.amount,
    this.frequency = 'monthly',
    this.description,
    this.isActive = true,
  });
  
  // Convert to monthly cost for calculations
  double get monthlyCost {
    switch (frequency) {
      case 'yearly':
        return amount / 12;
      case 'quarterly':
        return amount / 3;
      case 'monthly':
      default:
        return amount;
    }
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'car_id': carId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }
  
  factory RecurringCost.fromMap(Map<String, dynamic> map) {
    return RecurringCost(
      id: map['id'],
      carId: map['car_id'],
      name: map['name'],
      amount: map['amount'],
      frequency: map['frequency'] ?? 'monthly',
      description: map['description'],
      isActive: map['is_active'] == 1,
    );
  }
  
  RecurringCost copyWith({
    int? id,
    int? carId,
    String? name,
    double? amount,
    String? frequency,
    String? description,
    bool? isActive,
  }) {
    return RecurringCost(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}