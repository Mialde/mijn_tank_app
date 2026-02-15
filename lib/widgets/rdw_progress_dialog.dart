// LAATST BIJGEWERKT: 2026-02-14 08:30 UTC
// WIJZIGING: Progress dialog voor RDW auto-fill tijdens import
// REDEN: Visuele feedback tijdens het ophalen van RDW gegevens

import 'package:flutter/material.dart';

class RdwProgressDialog extends StatelessWidget {
  final int current;
  final int total;
  final String currentCarName;
  
  const RdwProgressDialog({
    super.key,
    required this.current,
    required this.total,
    required this.currentCarName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Gegevens ophalen via RDW...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentCarName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '$current van $total auto\'s',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}