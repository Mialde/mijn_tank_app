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
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: Container(height: 200, padding: EdgeInsets.all(24), child: Center(child: Text("Timeline XL - TODO"))),
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