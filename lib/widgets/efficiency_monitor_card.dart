// EFFICIENCY MONITOR CARD - M: [Laatste] [Gemiddeld]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';

class EfficiencyMonitorCard extends StatefulWidget {
  final CardSize size;
  const EfficiencyMonitorCard({super.key, this.size = CardSize.xl});
  @override
  State<EfficiencyMonitorCard> createState() => _EfficiencyMonitorCardState();
}

class _EfficiencyMonitorCardState extends State<EfficiencyMonitorCard> {
  bool _showLatest = true;
  @override
  Widget build(BuildContext context) => widget.size == CardSize.xl ? _buildXL(context) : _buildM(context);

  Widget _buildXL(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: Container(height: 200, padding: EdgeInsets.all(24), child: Center(child: Text("Efficiency XL - TODO"))),
    );
  }

  Widget _buildM(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;
    if (entries.isEmpty) return _buildEmpty(context, isDarkMode);
    
    final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    double latest = 0, avg = 0;
    if (sorted.length >= 2) {
      final last = sorted.last;
      final prev = sorted[sorted.length - 2];
      final km = (last.odometer - prev.odometer).abs();
      latest = prev.liters > 0 ? (km / prev.liters) : 0;
    }
    final totalKm = sorted.last.odometer - sorted.first.odometer;
    final totalL = entries.fold<double>(0, (s, e) => s + e.liters);
    avg = totalL > 0 ? (totalKm / totalL) : 0;
    
    final val = _showLatest ? latest : avg;
    final lbl = _showLatest ? 'laatste rit' : 'gemiddeld';

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
            Icon(Icons.speed, color: appColor, size: 40),
            SizedBox(height: 12),
            Text('${val.toStringAsFixed(1)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: appColor, height: 1.0)),
            SizedBox(height: 2),
            Text('km/L $lbl', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
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
          _buildBtn(context, Icons.refresh, 'Laatste', _showLatest, isDarkMode, () => setState(() => _showLatest = true)),
          _buildBtn(context, Icons.show_chart, 'Gem.', !_showLatest, isDarkMode, () => setState(() => _showLatest = false)),
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
        child: Center(child: Icon(Icons.speed_outlined, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.3))),
      ),
    );
  }
}