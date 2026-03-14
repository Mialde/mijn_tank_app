// Gedeelde empty state widgets voor alle dashboard cards
import 'package:flutter/material.dart';

/// XL card empty state — volledige breedte, vaste hoogte
class EmptyCardXL extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDarkMode;

  const EmptyCardXL({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = 'Voeg een tankbeurt toe om te beginnen',
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

/// M card empty state — vierkant, AspectRatio 1:1
class EmptyCardM extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDarkMode;

  const EmptyCardM({
    super.key,
    required this.icon,
    required this.title,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}