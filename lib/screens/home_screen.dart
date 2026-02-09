import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'input_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const InputScreen(),      // Index 0: Tanken
    const DashboardScreen(),   // Index 1: Dashboard
    const HistoryScreen(),     // Index 2: Historie
    const SettingsScreen(),    // Index 3: Instellingen
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _screens[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Tanken'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historie'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Instellingen'),
        ],
      ),
    );
  }
}