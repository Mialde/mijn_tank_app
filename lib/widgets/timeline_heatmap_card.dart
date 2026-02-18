// TIMELINE HEATMAP CARD
// GitHub-style contributions calendar for fuel fill-ups

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class TimelineHeatmapCard extends StatefulWidget {
  final Color appColor;
  final bool isDarkMode;
  
  const TimelineHeatmapCard({
    super.key,
    required this.appColor,
    required this.isDarkMode,
  });

  @override
  State<TimelineHeatmapCard> createState() => _TimelineHeatmapCardState();
}

class _TimelineHeatmapCardState extends State<TimelineHeatmapCard> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Scroll to end (newest data) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final entries = provider.entries;
    
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }
    
    final heatmapData = <DateTime, double>{};
    double maxLiters = 0;
    
    for (final entry in entries) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final existing = heatmapData[dateKey] ?? 0;
      heatmapData[dateKey] = existing + entry.liters;
      
      if (heatmapData[dateKey]! > maxLiters) {
        maxLiters = heatmapData[dateKey]!;
      }
    }
    
    final normalizedData = <DateTime, double>{};
    for (final entry in heatmapData.entries) {
      normalizedData[entry.key] = entry.value / maxLiters;
    }
    
    final sortedEntries = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    double totalDaysBetween = 0;
    for (int i = 1; i < sortedEntries.length; i++) {
      final daysBetween = sortedEntries[i].date.difference(sortedEntries[i - 1].date).inDays;
      totalDaysBetween += daysBetween;
    }
    final avgDaysBetween = sortedEntries.length > 1 
        ? totalDaysBetween / (sortedEntries.length - 1) 
        : 0.0;
    
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;
    
    for (final entry in sortedEntries) {
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final daysDiff = entry.date.difference(lastDate).inDays;
        if (daysDiff <= 1) {
          currentStreak++;
        } else {
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
          currentStreak = 1;
        }
      }
      lastDate = entry.date;
    }
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
    
    final daysSinceLastFill = DateTime.now().difference(sortedEntries.last.date).inDays;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
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
              
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: _buildMonthLabels(context),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildDayLabels(context),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 100,
                          child: _buildHeatmapGrid(normalizedData),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Minder',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForIntensity(i / 4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    'Meer',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '⏱️ Gemiddeld',
                      avgDaysBetween > 0 ? 'Elke ${avgDaysBetween.toInt()} dagen' : 'N/A',
                      widget.appColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '🏆 Streak',
                      '$longestStreak ${longestStreak == 1 ? "dag" : "dagen"}',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.appColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📅 Laatste tankbeurt',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      daysSinceLastFill == 0 
                          ? 'Vandaag'
                          : daysSinceLastFill == 1
                              ? '1 dag geleden'
                              : '$daysSinceLastFill dagen geleden',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nog geen tankbeurten',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voeg tankbeurten toe om je tankfrequentie te zien',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildMonthLabels(BuildContext context) {
    final labels = <Widget>[];
    final now = DateTime.now();
    
    // Generate last 12 months in chronological order
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      labels.add(
        SizedBox(
          width: 40,
          child: Text(
            DateFormat('MMM').format(month),
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }
    
    return labels;
  }
  
  List<Widget> _buildDayLabels(BuildContext context) {
    return [
      _dayLabel(context, 'Ma'),
      const SizedBox(height: 14),
      _dayLabel(context, 'Wo'),
      const SizedBox(height: 14),
      _dayLabel(context, 'Vr'),
    ];
  }
  
  Widget _dayLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        color: Theme.of(context).hintColor,
      ),
    );
  }
  
  Widget _buildHeatmapGrid(Map<DateTime, double> data) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 364));
    final weeks = <List<DateTime>>[];
    
    // Build weeks from oldest to newest
    DateTime current = startDate;
    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      final weekStart = current.subtract(Duration(days: current.weekday - 1));
      final week = List.generate(7, (i) => weekStart.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }
    
    return Row(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Column(
            children: week.map((day) {
              final intensity = data[DateTime(day.year, day.month, day.day)] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _getColorForIntensity(intensity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
  
  Color _getColorForIntensity(double intensity) {
    if (intensity == 0) {
      return widget.isDarkMode 
          ? Colors.grey.shade800.withValues(alpha: 0.3)
          : Colors.grey.shade200;
    }
    return widget.appColor.withValues(alpha: 0.2 + (intensity * 0.8));
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Container(
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}