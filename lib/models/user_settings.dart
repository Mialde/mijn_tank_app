class UserSettings {
  final int id;
  final String firstName;
  final String themeMode;
  final String accentColor; // NIEUW
  final bool useGreeting;
  final bool showQuotes;

  UserSettings({
    required this.id,
    required this.firstName,
    required this.themeMode,
    required this.accentColor,
    required this.useGreeting,
    required this.showQuotes,
  });

  UserSettings copyWith({
    int? id,
    String? firstName,
    String? themeMode,
    String? accentColor,
    bool? useGreeting,
    bool? showQuotes,
  }) {
    return UserSettings(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      useGreeting: useGreeting ?? this.useGreeting,
      showQuotes: showQuotes ?? this.showQuotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'theme_mode': themeMode,
      'accent_color': accentColor, // NIEUW
      'use_greeting': useGreeting ? 1 : 0,
      'show_quotes': showQuotes ? 1 : 0,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'],
      firstName: map['first_name'] ?? 'Gebruiker',
      themeMode: map['theme_mode'] ?? 'System',
      accentColor: map['accent_color'] ?? 'Mint', // Default
      useGreeting: map['use_greeting'] == 1,
      showQuotes: map['show_quotes'] == 1,
    );
  }
}