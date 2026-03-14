// WARNINGS BANNER
// Toont APK én onderhoud herinneringen als gestapelde banners
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class WarningsBanner extends StatelessWidget {
  const WarningsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final apk = provider.apkStatus;
    final maintenance = provider.maintenanceWarnings;
    final goalKm = provider.goalMonthlyKm;
    final kmProgress = provider.monthlyKmProgress;
    final kmThisMonth = provider.kmThisMonth;

    final List<Map<String, dynamic>> all = [];
    if (apk['show'] == true) all.add(apk);
    all.addAll(maintenance);

    if (all.isEmpty && goalKm == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Km-doel voortgang
        if (goalKm != null)
          _KmGoalBanner(kmThisMonth: kmThisMonth, goalKm: goalKm, progress: kmProgress),
        ...all.map((status) => _WarningBannerItem(
          status: status,
          onDismiss: () {
            if (status['key'] == null) {
              provider.dismissApkWarning();
            } else {
              provider.dismissMaintenanceWarning(status['key'] as String);
            }
          },
        )),
      ],
    );
  }
}

class _WarningBannerItem extends StatelessWidget {
  final Map<String, dynamic> status;
  final VoidCallback onDismiss;

  const _WarningBannerItem({required this.status, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final Color color = status['color'] as Color;
    final bool urgent = status['urgent'] as bool;
    final bool dismissible = status['dismissible'] as bool? ?? false;
    final String text = status['text'] as String;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.priority_high : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (dismissible)
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.transparent,
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KmGoalBanner extends StatelessWidget {
  final double kmThisMonth;
  final int goalKm;
  final double progress;

  const _KmGoalBanner({
    required this.kmThisMonth,
    required this.goalKm,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isComplete = progress >= 1.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF272934) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isComplete ? Colors.green.withValues(alpha: 0.4) : appColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(
                    isComplete ? Icons.check_circle_outline : Icons.route_outlined,
                    size: 16,
                    color: isComplete ? Colors.green : appColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete ? 'Km-doel bereikt!' : 'Km-doel deze maand',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ]),
                Text(
                  '${kmThisMonth.toStringAsFixed(0)} / $goalKm km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? Colors.green : appColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 6,
                backgroundColor: appColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : appColor,
                ),
              ),
            ),
            if (!isComplete) ...[
              const SizedBox(height: 6),
              Text(
                'Nog ${(goalKm - kmThisMonth).clamp(0, goalKm).toStringAsFixed(0)} km te gaan',
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}