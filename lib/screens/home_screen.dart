import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import '../widgets/easter_egg.dart';
import '../widgets/bug_easter_egg.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _curr = 0;
  
  // AANGEPAST: String status voor welk type ei actief is
  String? _activeEgg; // 'bug', 'rocket' of null
  bool _isTimeMachine = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.read<DataProvider>();

    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _curr = i),
          children: [
            const TankbeurtScreen(), 
            const DashboardScreen(),     
            SettingsScreen(          
              onBugEgg: () => setState(() => _activeEgg = 'bug'),
              onRocketEgg: (isTimeMachine) => setState(() {
                _isTimeMachine = isTimeMachine;
                _activeEgg = 'rocket';
              }),
            )
          ],
        ),
        
        // DE RAKET / DELOREAN (Oud)
        if (_activeEgg == 'rocket') 
          ZoomCarEasterEgg(
            isTimeMachine: _isTimeMachine, 
            onFinished: () => setState(() => _activeEgg = null)
          ),

        // DE BUG (Nieuw)
        if (_activeEgg == 'bug')
          BugOverlay(
            onFinished: () => setState(() => _activeEgg = null),
            onSecretUnlocked: () {
              data.unlockSecret();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🎉 GEHEIME OPTIE ONTGRENDELD! 🎉\nKijk in instellingen bij Systeem."),
                  backgroundColor: Colors.amber,
                  duration: Duration(seconds: 4),
                )
              );
            },
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