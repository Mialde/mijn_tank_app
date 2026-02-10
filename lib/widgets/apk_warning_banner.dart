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
      // AANGEPAST: Bottom is nu 0 (was 8)
      // De '16' pixels tussenruimte wordt nu geregeld door de padding van het volgende element.
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: status['color'],
          borderRadius: BorderRadius.circular(24),
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
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}