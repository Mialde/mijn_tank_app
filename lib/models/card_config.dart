// Card configuration model - SIMPLIFIED: XL (100%) and M (50%) only

enum CardSize { xl, m }

class DashboardCardConfig {
  final String id;
  final String title;
  final String subtitle;
  final bool isVisible;
  final CardSize size;
  
  const DashboardCardConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isVisible = true,
    this.size = CardSize.xl,
  });
  
  DashboardCardConfig copyWith({
    bool? isVisible,
    CardSize? size,
  }) {
    return DashboardCardConfig(
      id: id,
      title: title,
      subtitle: subtitle,
      isVisible: isVisible ?? this.isVisible,
      size: size ?? this.size,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'isVisible': isVisible ? 1 : 0,
      'size': size.name,
    };
  }
  
  factory DashboardCardConfig.fromMap(Map<String, dynamic> map) {
    return DashboardCardConfig(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      isVisible: map['isVisible'] == 1,
      size: CardSize.values.firstWhere(
        (s) => s.name == map['size'],
        orElse: () => CardSize.xl,
      ),
    );
  }
  
  // Get width percentage for this size
  double get widthPercentage {
    switch (size) {
      case CardSize.xl:
        return 1.0; // 100%
      case CardSize.m:
        return 0.5; // 50%
    }
  }
}

// Predefined cards - all support XL and M
class DashboardCards {
  static const distance = DashboardCardConfig(
    id: 'distance_consumption',
    title: 'Afstand & Verbruik',
    subtitle: 'Gereden kilometers en verbruik',
  );
  
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
    distance,
    costs,
    priceTracker,
    efficiency,
    costPerKm,
    timeline,
  ];
}