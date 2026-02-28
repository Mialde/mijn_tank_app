// lib/widgets/settings/data_management_section.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data_provider.dart';
import '../../services/data_service.dart';
import '../../services/database_importer.dart';
import '../../screens/developer_notes_screen.dart';
import 'accordion_card.dart';

class DataManagementSection extends StatelessWidget {
  final Color appColor;
  final DataProvider provider;

  const DataManagementSection({
    super.key,
    required this.appColor,
    required this.provider,
  });

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color ?? Colors.grey),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _exportOptionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showActionChoice(
    BuildContext context,
    String title, {
    required VoidCallback onShare,
    required VoidCallback onSave,
  }) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: const Text('Wat wil je doen met het bestand?'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onShare();
            },
            icon: const Icon(Icons.share),
            label: const Text('Delen'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onSave();
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Kies export formaat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _exportOptionTile(
            context,
            'PDF Rapport',
            Icons.picture_as_pdf,
            () => _showActionChoice(
              context,
              'PDF Rapport',
              onShare: () => DataService.exportToPDF(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
              onSave: () => DataService.savePDFLocally(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
            ),
          ),
          _exportOptionTile(
            context,
            'Excel Lijst (.xlsx)',
            Icons.table_chart,
            () => _showActionChoice(
              context,
              'Excel Lijst',
              onShare: () => DataService.shareAsExcel(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
              onSave: () => DataService.saveExcelLocally(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
            ),
          ),
          _exportOptionTile(
            context,
            'CSV Bestand',
            Icons.description,
            () => _showActionChoice(
              context,
              'CSV Bestand',
              onShare: () => DataService.shareAsCSV(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
              onSave: () => DataService.saveCSVLocally(
                provider.cars,
                provider.entries,
                provider.maintenanceEntries,
              ),
            ),
          ),
          _exportOptionTile(
            context,
            'Volledige Backup (JSON)',
            Icons.settings_backup_restore,
            () => _showActionChoice(
              context,
              'JSON Backup',
              onShare: () => DataService.shareBackupJSON({
                'cars': provider.cars.map((c) => c.toMap()).toList(),
                'entries': provider.entries.map((e) => e.toMap()).toList(),
                'maintenance_entries': provider.maintenanceEntries.map((e) => e.toMap()).toList(),
                'user_settings': provider.settings?.toMap(),
              }),
              onSave: () => DataService.saveBackupJSON({
                'cars': provider.cars.map((c) => c.toMap()).toList(),
                'entries': provider.entries.map((e) => e.toMap()).toList(),
                'maintenance_entries': provider.maintenanceEntries.map((e) => e.toMap()).toList(),
                'user_settings': provider.settings?.toMap(),
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleImport(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Kies bron voor import',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.backup_outlined),
            title: const Text('TankAppie Backup (JSON)'),
            onTap: () async {
              Navigator.pop(context);
              final content = await DataService.pickFile(['json']);
              if (content == null) return;

              try {
                final json = jsonDecode(content) as Map<String, dynamic>;
                final analysis = DatabaseImporter.analyzeJson(json);

                if (analysis.needsMigration) {
                  print('⚠️ Oude backup - auto RDW fill starting...');
                  final migratedCars = await DatabaseImporter.fillFromRdw(
                    analysis.carsData,
                    null,
                  );
                  print('✓ RDW fill complete: ${migratedCars.length} cars');
                  json['cars'] = migratedCars.map((c) => c.toMap()).toList();
                }

                print('Starting database import...');
                provider.importJsonBackup(jsonEncode(json));
                print('✓ Import complete!');
              } catch (e) {
                print('❌ Import error: $e');
              }
            },
          ),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('CSV Lijst (Slimme Import)'),
            onTap: () async {
              Navigator.pop(context);
              final rows = await DataService.pickAndParseCSV();
              if (rows != null && context.mounted) {
                // TODO: Show mapping dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV mapping nog niet geïmplementeerd in module')),
                );
              }
            },
          ),
          ListTile(
            minTileHeight: 72,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.grid_on_outlined),
            title: const Text('Excel Lijst (.xlsx)'),
            onTap: () async {
              Navigator.pop(context);
              final rows = await DataService.pickAndParseExcel();
              if (rows != null && context.mounted) {
                // TODO: Show mapping dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel mapping nog niet geïmplementeerd in module')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🚨 Alles Wissen?'),
        content: const Text(
          'Dit verwijdert ALLE auto\'s, tankbeurten, en onderhoud PERMANENT.\n\nDeze actie kan NIET ongedaan gemaakt worden!\n\nWeet je het zeker?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.factoryReset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Alle gegevens gewist'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('JA, ALLES WISSEN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccordionCard(
      title: 'Opslag & Data',
      icon: Icons.cloud_upload_outlined,
      appColor: appColor,
      children: [
        _sectionHeader('Data Management'),
        _actionTile(
          'Gegevens Exporteren',
          Icons.upload_file_outlined,
          () => _handleExport(context),
        ),
        _actionTile(
          'Gegevens Importeren',
          Icons.download_for_offline_outlined,
          () => _handleImport(context),
          color: Colors.orange,
        ),
        const Divider(color: Colors.white10, height: 24),
        _sectionHeader('Gevaarlijke Zone'),
        _actionTile(
          'Gegevens wissen',
          Icons.delete_forever,
          () => _showResetDialog(context),
          color: Colors.red,
        ),
        const Divider(color: Colors.white10, height: 24),
        ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.developer_mode, color: Colors.grey, size: 20),
          ),
          title: const Text(
            'Developer Notities',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const DeveloperNotesScreen()),
          ),
        ),
      ],
    );
  }
}