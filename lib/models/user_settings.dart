import 'dart:convert';

class UserSettings {
  final int id;
  final String firstName;
  final String themeMode;
  final String accentColor;
  final bool useGreeting;
  final bool showQuotes;
  /// Globale aan/uit per onderhoudstype — key = type naam, value = enabled
  final Map<String, bool> maintenanceNotifications;

  UserSettings({
    required this.id,
    required this.firstName,
    required this.themeMode,
    required this.accentColor,
    required this.useGreeting,
    required this.showQuotes,
    Map<String, bool>? maintenanceNotifications,
  }) : maintenanceNotifications = maintenanceNotifications ?? {
    'Kleine beurt': true,
    'Grote beurt':  true,
    'Banden':       true,
    'APK':          true,
  };

  bool isMaintenanceEnabled(String type) =>
      maintenanceNotifications[type] ?? true;

  UserSettings copyWith({
    int? id,
    String? firstName,
    String? themeMode,
    String? accentColor,
    bool? useGreeting,
    bool? showQuotes,
    Map<String, bool>? maintenanceNotifications,
  }) {
    return UserSettings(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      useGreeting: useGreeting ?? this.useGreeting,
      showQuotes: showQuotes ?? this.showQuotes,
      maintenanceNotifications: maintenanceNotifications ?? this.maintenanceNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'theme_mode': themeMode,
      'accent_color': accentColor,
      'use_greeting': useGreeting ? 1 : 0,
      'show_quotes': showQuotes ? 1 : 0,
      'maintenance_notifications': jsonEncode(maintenanceNotifications),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    Map<String, bool> notifications = {
      'Kleine beurt': true,
      'Grote beurt':  true,
      'Banden':       true,
      'APK':          true,
    };
    final raw = map['maintenance_notifications'];
    if (raw != null && raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        notifications = decoded.map((k, v) => MapEntry(k, v == true));
      } catch (_) {}
    }

    return UserSettings(
      id: map['id'],
      firstName: map['first_name'] ?? 'Gebruiker',
      themeMode: map['theme_mode'] ?? 'System',
      accentColor: map['accent_color'] ?? 'Mint',
      useGreeting: map['use_greeting'] == 1,
      showQuotes: map['show_quotes'] == 1,
      maintenanceNotifications: notifications,
    );
  }
}