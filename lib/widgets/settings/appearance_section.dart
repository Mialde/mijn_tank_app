// lib/widgets/settings/appearance_section.dart

import 'package:flutter/material.dart';
import '../../models/user_settings.dart';
import '../../data_provider.dart';
import 'accordion_card.dart';

class AppearanceSection extends StatelessWidget {
  final Color appColor;
  final UserSettings settings;
  final DataProvider provider;

  const AppearanceSection({
    super.key,
    required this.appColor,
    required this.settings,
    required this.provider,
  });

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kies Accentkleur'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: DataProvider.colorOptions.length,
            itemBuilder: (context, index) {
              final entry = DataProvider.colorOptions.entries.elementAt(index);
              final isSelected = settings.accentColor == entry.key;
              return GestureDetector(
                onTap: () {
                  provider.updateSettings(settings.copyWith(accentColor: entry.key));
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border.all(
                      color: isSelected ? entry.value : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? entry.value : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kies Thema'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThemeOption(context, 'Licht', 'Light', Icons.wb_sunny_outlined),
            _buildThemeOption(context, 'Donker', 'Dark', Icons.nights_stay_outlined),
            _buildThemeOption(context, 'Systeem', 'System', Icons.smartphone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, String value, IconData icon) {
    final isSelected = settings.themeMode == value;
    return GestureDetector(
      onTap: () {
        provider.updateSettings(settings.copyWith(themeMode: value));
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? appColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? appColor : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? appColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccordionCard(
      title: 'Weergave-instellingen',
      icon: Icons.palette_outlined,
      appColor: appColor,
      children: [
        ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.brush, color: appColor),
          title: const Text('Accentkleur'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: appColor,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showColorPicker(context),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.contrast, color: appColor),
          title: const Text('Thema'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.themeMode,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
          onTap: () => _showThemePicker(context),
        ),
      ],
    );
  }
}