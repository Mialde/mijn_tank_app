import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- NIEUWE IMPORT
import 'data_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
      create: (context) => DataProvider()..loadData(), 
      child: const TankBuddyApp()));
}

class TankBuddyApp extends StatelessWidget {
  const TankBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardColor: Colors.white,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TankBuddy',
      themeMode: data.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      // --- LOCALIZATION SETUP ---
      supportedLocales: const [Locale('nl')], // We ondersteunen Nederlands
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // --------------------------
      home: const HomeScreen(),
    );
  }
}