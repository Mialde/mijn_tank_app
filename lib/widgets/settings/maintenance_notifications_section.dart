// lib/widgets/settings/maintenance_notifications_section.dart
import 'package:flutter/material.dart';
import '../../models/user_settings.dart';
import '../../models/car.dart';
import '../../data_provider.dart';
import 'accordion_card.dart';

class MaintenanceNotificationsSection extends StatelessWidget {
  final Color appColor;
  final UserSettings settings;
  final DataProvider provider;

  const MaintenanceNotificationsSection({
    super.key,
    required this.appColor,
    required this.settings,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccordionCard(
      title: 'Onderhoudsherinneringen',
      icon: Icons.notifications_outlined,
      appColor: appColor,
      children: [
          Text(
            'Ontvang een melding in de app als onderhoud bijna nodig is. '
            'Stel per type in of je meldingen wilt ontvangen.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 16),
          ...kDefaultIntervals.keys.map((type) {
            final enabled = settings.isMaintenanceEnabled(type);
            return _NotificationToggleRow(
              type: type,
              enabled: enabled,
              appColor: appColor,
              isDark: isDark,
              onChanged: (val) {
                final updated = Map<String, bool>.from(settings.maintenanceNotifications);
                updated[type] = val;
                provider.updateSettings(settings.copyWith(maintenanceNotifications: updated));
              },
            );
          }),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14,
                  color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Intervallen per auto stel je in via Auto beheren → Onderhoud intervallen',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ],
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  final String type;
  final bool enabled;
  final Color appColor;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleRow({
    required this.type,
    required this.enabled,
    required this.appColor,
    required this.isDark,
    required this.onChanged,
  });

  IconData _iconFor(String type) {
    switch (type) {
      case 'Kleine beurt': return Icons.build_outlined;
      case 'Grote beurt':  return Icons.construction_outlined;
      case 'Banden':       return Icons.tire_repair_outlined;
      case 'APK':          return Icons.assignment_outlined;
      default:             return Icons.notifications_outlined;
    }
  }

  String _subtitleFor(String type) {
    final interval = kDefaultIntervals[type]!;
    final parts = <String>[];
    if (interval.kmInterval != null) parts.add('${(interval.kmInterval! / 1000).toStringAsFixed(0)}k km');
    if (interval.dayInterval != null) {
      final days = interval.dayInterval!;
      if (days >= 365) {
        final years = (days / 365).round();
        parts.add('$years jaar');
      } else {
        parts.add('$days dagen');
      }
    }
    return parts.join(' / ') + ' (standaard)';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enabled
                  ? appColor.withValues(alpha: 0.12)
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(type),
              size: 18,
              color: enabled ? appColor : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _subtitleFor(type),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: appColor,
          ),
        ],
      ),
    );
  }
}