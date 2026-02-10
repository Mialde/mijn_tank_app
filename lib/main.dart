import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/input_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()..initializeApp()),
      ],
      child: const MijnTankApp(),
    ),
  );
}

class MijnTankApp extends StatefulWidget {
  const MijnTankApp({super.key});

  @override
  State<MijnTankApp> createState() => _MijnTankAppState();
}

class _MijnTankAppState extends State<MijnTankApp> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final settings = provider.settings;
    final String themeModePref = settings?.themeMode ?? 'System';
    final Color appColor = provider.themeColor;

    return MaterialApp(
      title: 'TankAppie',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('nl', 'NL')],
      locale: const Locale('nl', 'NL'),
      themeMode: _getThemeMode(themeModePref),
      
      // --- LIGHT THEME ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
        colorScheme: ColorScheme.fromSeed(seedColor: appColor, primary: appColor, surface: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F9),
          elevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),

      // --- DARK THEME (NIEUWE KLEUREN) ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // NIEUW: Gunmetal achtergrond
        scaffoldBackgroundColor: const Color(0xFF1B1C24),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColor, 
          brightness: Brightness.dark, 
          primary: appColor, 
          // NIEUW: Kaart kleur als surface
          surface: const Color(0xFF272934)
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          // NIEUW: Matcht de kaartkleur voor een rustige navigatiebalk
          backgroundColor: const Color(0xFF272934),
          selectedItemColor: appColor,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: TextStyle(color: appColor, fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          selectedIconTheme: IconThemeData(color: appColor, size: 28),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

        appBarTheme: const AppBarTheme(
          // Transparant zodat de mooie achtergrondkleur zichtbaar blijft
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        cardTheme: CardThemeData(
          // NIEUW: De lichtere tint uit je screenshot
          color: const Color(0xFF272934),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide.none, // Geen rand meer nodig met dit contrast
          ),
        ),

        // NIEUW: Zorgt dat invulvelden mooi 'in' de kaart vallen
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B1C24), // De achtergrondkleur, zorgt voor diepte in de kaart
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: Colors.white70,
        ),
      ),

      home: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: const [
            InputScreen(),
            DashboardScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.local_gas_station_outlined), activeIcon: Icon(Icons.local_gas_station), label: 'Tanken'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overzicht'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Instellingen'),
          ],
        ),
      ),
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'Light': return ThemeMode.light;
      case 'Dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}