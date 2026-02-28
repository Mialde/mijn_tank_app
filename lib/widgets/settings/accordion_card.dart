// lib/widgets/settings/accordion_card.dart

import 'package:flutter/material.dart';

class AccordionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color appColor;
  final List<Widget> children;

  const AccordionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.appColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          minTileHeight: 72,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(icon, color: appColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: children,
        ),
      ),
    );
  }
}