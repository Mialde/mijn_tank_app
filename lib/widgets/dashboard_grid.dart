// DASHBOARD GRID LAYOUT ENGINE
// Handles mixed card sizes with consistent 24px edge + 16px gap spacing

import 'package:flutter/material.dart';
import '../models/card_config.dart';

class DashboardGrid extends StatelessWidget {
  final List<Widget> cards;
  final List<DashboardCardConfig> configs;
  
  const DashboardGrid({
    super.key,
    required this.cards,
    required this.configs,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    
    final rows = _buildRows();
    
    return Column(
      children: rows.map((row) => _buildRow(row)).toList(),
    );
  }
  
  List<List<int>> _buildRows() {
    final rows = <List<int>>[];
    var currentRow = <int>[];
    var currentRowWidth = 0.0;
    
    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      final cardWidth = config.widthPercentage;
      
      if (currentRowWidth + cardWidth <= 1.0) {
        currentRow.add(i);
        currentRowWidth += cardWidth;
        
        if (currentRowWidth >= 1.0) {
          rows.add(currentRow);
          currentRow = [];
          currentRowWidth = 0.0;
        }
      } else {
        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
        }
        currentRow = [i];
        currentRowWidth = cardWidth;
      }
    }
    
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }
    
    return rows;
  }
  
  Widget _buildRow(List<int> cardIndices) {
    if (cardIndices.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildRowCards(cardIndices),
      ),
    );
  }
  
  List<Widget> _buildRowCards(List<int> cardIndices) {
    final widgets = <Widget>[];
    
    for (int idx = 0; idx < cardIndices.length; idx++) {
      final i = cardIndices[idx];
      final config = configs[i];
      final card = cards[i];
      final isLast = idx == cardIndices.length - 1;
      
      // Calculate flex based on width percentage
      final flex = (config.widthPercentage * 100).toInt();
      
      widgets.add(
        Expanded(
          flex: flex,
          child: card,
        ),
      );
      
      // Add gap between cards (but not after last card)
      if (!isLast) {
        widgets.add(const SizedBox(width: 16));
      }
    }
    
    return widgets;
  }
}