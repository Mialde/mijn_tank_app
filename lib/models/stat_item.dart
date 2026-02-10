import 'package:flutter/material.dart';

class StatItem {
  final String title;
  final double value;
  final Color color;
  final double percentage;
  final bool isFuelGroup;
  
  // NIEUW: Voor de sortering
  final int sortOrder; // 0 = Tanken, 1 = Onderhoud, 2 = Vaste Lasten
  final DateTime? date; // Om tankbeurten op datum te sorteren

  StatItem({
    required this.title,
    required this.value,
    required this.color,
    required this.percentage,
    this.isFuelGroup = false,
    this.sortOrder = 99,
    this.date,
  });
}