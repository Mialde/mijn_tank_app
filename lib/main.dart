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

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B1C24),
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColor, 
          brightness: Brightness.dark, 
          primary: appColor, 
          surface: const Color(0xFF272934)
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF272934),
          selectedItemColor: appColor,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF272934),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: InputBorder.none,
          labelStyle: TextStyle(color: Colors.white70),
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