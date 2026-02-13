import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';

class ApkWarningBanner extends StatelessWidget {
  const ApkWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final status = provider.apkStatus;

    if (status['show'] == false) return const SizedBox.shrink();

    return Padding(
      // Bottom is 0, de ruimte eronder wordt geregeld in het volgende element
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), 
      child: Container(
        width: double.infinity,
        height: 72, // Vaste hoogte, gelijk aan de menu items en invulvelden
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: status['color'],
          borderRadius: BorderRadius.circular(24), // Gelijke thema afronding
          boxShadow: [
            BoxShadow(
              color: status['color'].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              status['urgent'] ? Icons.priority_high : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                status['text'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (status['dismissible'])
              GestureDetector(
                onTap: () => provider.dismissApkWarning(),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.transparent, // Transparant voor grotere klikzone
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}