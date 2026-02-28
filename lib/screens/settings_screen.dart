// lib/screens/settings_screen.dart
// REFACTORED: Split into modular sections

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../widgets/pole_position_game.dart';
import '../widgets/settings/user_profile_section.dart';
import '../widgets/settings/car_management_section.dart';
import '../widgets/settings/appearance_section.dart';
import '../widgets/settings/data_management_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _vehicleTypes = [
    'Auto',
    'Motor',
    'Vrachtwagen',
    'Scooter',
    'Bus',
    'Camper',
    'Tractor',
    'Bestelwagen'
  ];
  final String _version = "v1.1.0 (Beta)";

  // Easter Egg
  int _versionTapCount = 0;
  DateTime? _lastTap;

  void _handleVersionTap(BuildContext context, Color appColor) {
    final now = DateTime.now();

    if (_lastTap != null && now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 0;
    }

    _lastTap = now;
    _versionTapCount++;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _launchPolePosition(context, appColor);
    }
  }

  void _launchPolePosition(BuildContext context, Color appColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolePositionGame(themeColor: appColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final settings = provider.settings;
    final Color appColor = provider.themeColor;

    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        centerTitle: false,
        titleSpacing: 24,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. User Profile
                UserProfileSection(
                  appColor: appColor,
                  settings: settings,
                  provider: provider,
                ),
                const SizedBox(height: 16),

                // 2. Car Management
                CarManagementSection(
                  appColor: appColor,
                  provider: provider,
                  vehicleTypes: _vehicleTypes,
                ),
                const SizedBox(height: 16),

                // 3. Appearance
                AppearanceSection(
                  appColor: appColor,
                  settings: settings,
                  provider: provider,
                ),
                const SizedBox(height: 16),

                // 4. Data Management
                DataManagementSection(
                  appColor: appColor,
                  provider: provider,
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Version footer
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 24),
                child: GestureDetector(
                  onTap: () => _handleVersionTap(context, appColor),
                  child: Text(
                    'TankAppie $_version',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}