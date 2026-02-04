import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import '../widgets/easter_egg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _curr = 0;
  bool _showEgg = false;
  bool _isTimeMachine = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _curr = i),
          children: [
            const TankbeurtScreen(), // Deze komt in input_screen.dart
            const StatsScreen(),     // Deze komt in dashboard_screen.dart
            SettingsScreen(          // Deze komt in settings_screen.dart
              onEasterEgg: (isTimeMachine) => setState(() { 
                _isTimeMachine = isTimeMachine; 
                _showEgg = true; 
              })
            )
          ],
        ),
        if (_showEgg) 
          ZoomCarEasterEgg(
            isTimeMachine: _isTimeMachine, 
            onFinished: () => setState(() => _showEgg = false)
          ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _curr,
        onDestinationSelected: (i) {
          setState(() => _curr = i);
          _pageController.animateToPage(
            i, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_gas_station_rounded), label: 'Tanken'),
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overzicht'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Instellingen'),
        ],
      ),
    );
  }
}