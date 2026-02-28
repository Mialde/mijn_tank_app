// TIMELINE HEATMAP CARD - M: [Laatste] [Gemiddeld]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class TimelineHeatmapCard extends StatefulWidget {
  final CardSize size;
  const TimelineHeatmapCard({super.key, this.size = CardSize.xl});
  @override
  State<TimelineHeatmapCard> createState() => _TimelineHeatmapCardState();
}

class _TimelineHeatmapCardState extends State<TimelineHeatmapCard> {
  bool _showLatest = true;
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  Widget _buildXL(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final daysSinceFirst = now.difference(sorted.first.date).inDays;
    final daysSinceLast = now.difference(sorted.last.date).inDays;
    
    // Calculate intervals
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
    }
    
    final avgInterval = intervals.isNotEmpty 
        ? intervals.reduce((a, b) => a + b) / intervals.length 
        : 0;
    final minInterval = intervals.isNotEmpty 
        ? intervals.reduce((a, b) => a < b ? a : b) 
        : 0;
    final maxInterval = intervals.isNotEmpty 
        ? intervals.reduce((a, b) => a > b ? a : b) 
        : 0;
    
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TANK KALENDER",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildCalendarHeatmap(context, sorted, appColor, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildStats(context, daysSinceLast, avgInterval.round(), minInterval, maxInterval, appColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeatmap(BuildContext context, List entries, Color appColor, bool isDarkMode) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90)); // Last 90 days
    
    // Create map of dates with entries
    final entryDates = <String, int>{};
    for (var entry in entries) {
      if (entry.date.isAfter(startDate)) {
        final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
        entryDates[dateKey] = (entryDates[dateKey] ?? 0) + 1;
      }
    }
    
    // Build grid of last 13 weeks (91 days)
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 13,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 91,
      itemBuilder: (context, index) {
        final date = now.subtract(Duration(days: 90 - index));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final hasEntry = entryDates.containsKey(dateKey);
        
        return Container(
          decoration: BoxDecoration(
            color: hasEntry 
                ? appColor.withValues(alpha: 0.8)
                : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: hasEntry 
              ? Center(
                  child: Text(
                    '${entryDates[dateKey]}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, int daysSince, int avg, int min, int max, Color appColor) {
    return Row(
      children: [
        _buildStatItem(context, 'Sinds laatst', '$daysSince dagen', appColor),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Gemiddeld', '$avg dagen', Colors.blue),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Kortste', '$min dagen', Colors.green),
        const SizedBox(width: 12),
        _buildStatItem(context, 'Langste', '$max dagen', Colors.red),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Nog geen timeline gegevens',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    if (entries.isEmpty) return _buildEmpty(context, isDarkMode);
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final now = DateTime.now();
    final daysSince = now.difference(sorted.last.date).inDays;
    
    double avgInterval = 0;
    if (sorted.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < sorted.length; i++) {
        intervals.add(sorted[i].date.difference(sorted[i-1].date).inDays);
      }
      avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    }
    
    final val = _showLatest ? daysSince : avgInterval.round();
    final lbl = _showLatest ? 'dagen geleden' : 'gemiddeld interval';

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: Offset(0, 5))],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: appColor, size: 40),
            SizedBox(height: 12),
            Text('$val', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: appColor, height: 1.0)),
            SizedBox(height: 2),
            Text(lbl, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
            Spacer(),
            _buildSelector(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(context, Icons.access_time, 'Laatste', _showLatest, isDarkMode, () => setState(() => _showLatest = true)),
          _buildBtn(context, Icons.calendar_month, 'Gem.', !_showLatest, isDarkMode, () => setState(() => _showLatest = false)),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, IconData icon, String label, bool sel, bool dark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? (dark ? Colors.white : Colors.black) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor),
              SizedBox(width: 3),
              Flexible(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? (dark ? Colors.black : Colors.white) : Theme.of(context).hintColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05), blurRadius: 20, offset: Offset(0, 5))],
        ),
        child: Center(child: Icon(Icons.calendar_today_outlined, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
      ),
    );
  }
}