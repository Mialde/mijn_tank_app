// LAATST BIJGEWERKT: 2026-02-14 08:30 UTC
// WIJZIGING: Styled migration dialog voor oude database imports
// REDEN: Gebruiksvriendelijke UI voor het aanvullen van ontbrekende data

import 'package:flutter/material.dart';
import '../services/database_importer.dart';

class MigrationDialog extends StatefulWidget {
  final ImportAnalysis analysis;
  final Function(MigrationChoice choice) onChoice;
  
  const MigrationDialog({
    super.key,
    required this.analysis,
    required this.onChoice,
  });

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oude Backup Gedetecteerd',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.analysis.totalCars} auto\'s gevonden',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ontbrekende gegevens:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.analysis.missingFuelType > 0)
                    _InfoRow(
                      icon: Icons.local_gas_station,
                      label: 'Brandstoftype',
                      value: '${widget.analysis.missingFuelType} auto\'s',
                    ),
                  if (widget.analysis.missingOwner > 0)
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Eigenaar (laatste tenaamstelling)',
                      value: '${widget.analysis.missingOwner} auto\'s',
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Hoe wil je deze gegevens aanvullen?',
              style: theme.textTheme.titleSmall,
            ),
            
            const SizedBox(height: 16),
            
            // Opties
            _ChoiceButton(
              icon: Icons.search,
              title: 'Automatisch via RDW',
              subtitle: 'Haal gegevens op via kenteken',
              color: Colors.green,
              onTap: () => widget.onChoice(MigrationChoice.autoRdw),
            ),
            
            const SizedBox(height: 12),
            
            _ChoiceButton(
              icon: Icons.edit,
              title: 'Handmatig invullen',
              subtitle: 'Vul zelf per auto in',
              color: Colors.blue,
              onTap: () => widget.onChoice(MigrationChoice.manual),
            ),
            
            const SizedBox(height: 12),
            
            _ChoiceButton(
              icon: Icons.skip_next,
              title: 'Later invullen',
              subtitle: 'Importeer nu, vul later aan',
              color: Colors.grey,
              onTap: () => widget.onChoice(MigrationChoice.skip),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  
  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

enum MigrationChoice {
  autoRdw,
  manual,
  skip,
}