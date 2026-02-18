// CARD VISIBILITY SELECTOR
// Bottom sheet voor het tonen/verbergen van dashboard cards

import 'package:flutter/material.dart';
import '../models/card_config.dart';

class CardVisibilitySelector extends StatefulWidget {
  final List<DashboardCardConfig> cards;
  final Function(List<DashboardCardConfig>) onSave;
  
  const CardVisibilitySelector({
    super.key,
    required this.cards,
    required this.onSave,
  });

  @override
  State<CardVisibilitySelector> createState() => _CardVisibilitySelectorState();
}

class _CardVisibilitySelectorState extends State<CardVisibilitySelector> {
  late List<DashboardCardConfig> _workingCards;
  
  @override
  void initState() {
    super.initState();
    _workingCards = widget.cards.map((c) => c).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kaarten Weergave',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onSave(_workingCards);
                      Navigator.pop(context);
                    },
                    child: const Text('Opslaan'),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Card list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _workingCards.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final card = _workingCards[index];
                  return SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      card.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(card.subtitle),
                    value: card.isVisible,
                    onChanged: (value) {
                      setState(() {
                        _workingCards[index] = card.copyWith(isVisible: value);
                      });
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the modal
void showCardVisibilitySelector({
  required BuildContext context,
  required List<DashboardCardConfig> cards,
  required Function(List<DashboardCardConfig>) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CardVisibilitySelector(
      cards: cards,
      onSave: onSave,
    ),
  );
}