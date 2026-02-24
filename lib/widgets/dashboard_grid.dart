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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: rows.map((row) => _buildRow(row, constraints.maxWidth)).toList(),
        );
      },
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
  
  Widget _buildRow(List<int> cardIndices, double maxWidth) {
    if (cardIndices.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildRowCards(cardIndices, maxWidth - 48), // maxWidth minus side padding
      ),
    );
  }
  
  List<Widget> _buildRowCards(List<int> cardIndices, double availableWidth) {
    final widgets = <Widget>[];
    
    for (int idx = 0; idx < cardIndices.length; idx++) {
      final i = cardIndices[idx];
      final config = configs[i];
      final card = cards[i];
      final isLast = idx == cardIndices.length - 1;
      
      // For M-size cards, use fixed width instead of Expanded
      if (config.widthPercentage == 0.5) {
        // Calculate exact M card width: (available - gaps) / 2
        final gapsWidth = 16.0; // one gap for 2 cards
        final cardWidth = (availableWidth - gapsWidth) / 2;
        
        widgets.add(
          SizedBox(
            width: cardWidth,
            child: card,
          ),
        );
      } else {
        // XL card gets full available width
        widgets.add(
          Expanded(
            child: card,
          ),
        );
      }
      
      // Add gap between cards (but not after last card)
      if (!isLast) {
        widgets.add(const SizedBox(width: 16));
      }
    }
    
    // If row doesn't fill 100%, add spacer to keep cards left-aligned
    final totalWidth = cardIndices.fold<double>(
      0, 
      (sum, i) => sum + configs[i].widthPercentage,
    );
    
    if (totalWidth < 1.0) {
      widgets.add(const Spacer());
    }
    
    return widgets;
  }
}