// Card configuration model for showing/hiding dashboard cards

class DashboardCardConfig {
  final String id;
  final String title;
  final String subtitle;
  final bool isVisible;
  
  const DashboardCardConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isVisible = true,
  });
  
  DashboardCardConfig copyWith({bool? isVisible}) {
    return DashboardCardConfig(
      id: id,
      title: title,
      subtitle: subtitle,
      isVisible: isVisible ?? this.isVisible,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'isVisible': isVisible ? 1 : 0,
    };
  }
  
  factory DashboardCardConfig.fromMap(Map<String, dynamic> map) {
    return DashboardCardConfig(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      isVisible: map['isVisible'] == 1,
    );
  }
}

// Predefined cards
class DashboardCards {
  static const costs = DashboardCardConfig(
    id: 'costs_overview',
    title: 'Kosten Overzicht',
    subtitle: 'Verdeling per categorie',
  );
  
  static const priceTracker = DashboardCardConfig(
    id: 'price_tracker',
    title: 'Prijs Tracker',
    subtitle: 'Brandstofprijs trend',
  );
  
  static const efficiency = DashboardCardConfig(
    id: 'efficiency_monitor',
    title: 'Efficiency Monitor',
    subtitle: 'Verbruik in km/L',
  );
  
  static const costPerKm = DashboardCardConfig(
    id: 'cost_per_km',
    title: 'Cost Per KM',
    subtitle: 'Kosten per kilometer',
  );
  
  static const timeline = DashboardCardConfig(
    id: 'timeline_heatmap',
    title: 'Tank Kalender',
    subtitle: 'Tankfrequentie heatmap',
  );
  
  static List<DashboardCardConfig> get allCards => [
    costs,
    priceTracker,
    efficiency,
    costPerKm,
    timeline,
  ];
}