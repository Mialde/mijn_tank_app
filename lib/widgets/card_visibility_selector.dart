// CARD VISIBILITY & SIZE SELECTOR - Simplified
// Simple XL/M toggle (no complex size picker)

import 'package:flutter/material.dart';
import '../models/card_config.dart';

void showCardVisibilitySelector({
  required BuildContext context,
  required List<DashboardCardConfig> cards,
  required Function(List<DashboardCardConfig>) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CardVisibilitySelector(
      cards: cards,
      onSave: onSave,
    ),
  );
}

class _CardVisibilitySelector extends StatefulWidget {
  final List<DashboardCardConfig> cards;
  final Function(List<DashboardCardConfig>) onSave;

  const _CardVisibilitySelector({
    required this.cards,
    required this.onSave,
  });

  @override
  State<_CardVisibilitySelector> createState() => _CardVisibilitySelectorState();
}

class _CardVisibilitySelectorState extends State<_CardVisibilitySelector> {
  late List<DashboardCardConfig> _cards;

  @override
  void initState() {
    super.initState();
    _cards = widget.cards.map((c) => c).toList();
  }

  void _saveChanges() {
    widget.onSave(_cards);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Cards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Houd vast om volgorde te wijzigen',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _cards.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final card = _cards.removeAt(oldIndex);
                  _cards.insert(newIndex, card);
                  _saveChanges();
                });
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Container(
                  key: ValueKey(card.id),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Material(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Drag handle
                          Icon(
                            Icons.drag_indicator,
                            color: Theme.of(context).hintColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          
                          // Title + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Size toggle (XL/M)
                          _buildSizeToggle(card, index, isDarkMode),
                          
                          const SizedBox(width: 12),
                          
                          // Visibility switch
                          Switch(
                            value: card.isVisible,
                            onChanged: (value) {
                              setState(() {
                                _cards[index] = card.copyWith(isVisible: value);
                                _saveChanges();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSizeToggle(DashboardCardConfig card, int index, bool isDarkMode) {
    final isXL = card.size == CardSize.xl;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XL button
          GestureDetector(
            onTap: () {
              setState(() {
                _cards[index] = card.copyWith(size: CardSize.xl);
                _saveChanges();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isXL 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'XL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isXL
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
          
          // M button
          GestureDetector(
            onTap: () {
              setState(() {
                _cards[index] = card.copyWith(size: CardSize.m);
                _saveChanges();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !isXL 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: !isXL
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}