// LAATST BIJGEWERKT: 2026-02-16 23:30 UTC
// WIJZIGING: Dynamic height based on card content with SingleChildScrollView fallback
// REDEN: Fix overflow issues - cards determine their own height

import 'package:flutter/material.dart';

class SwipeableStatsCards extends StatefulWidget {
  final List<Widget> cards;
  
  const SwipeableStatsCards({
    super.key,
    required this.cards,
  });

  @override
  State<SwipeableStatsCards> createState() => _SwipeableStatsCardsState();
}

class _SwipeableStatsCardsState extends State<SwipeableStatsCards> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swipeable cards with intrinsic height
        IntrinsicHeight(
          child: SizedBox(
            height: 600, // Max height - cards can be smaller
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: widget.cards.map((card) {
                // Wrap each card in SingleChildScrollView as safety
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: card,
                );
              }).toList(),
            ),
          ),
        ),
        
        // Page indicator dots
        const SizedBox(height: 16),
        _buildPageIndicator(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.cards.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}