import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data_provider.dart';

class DeveloperNotesScreen extends StatelessWidget {
  const DeveloperNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final notes = provider.notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Notities')),
      body: notes.isEmpty
          ? const Center(child: Text('Geen actieve notities.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    // GEFIKST: withOpacity -> withValues
                    color: note.isCompleted ? Colors.grey.withValues(alpha: 0.1) : appColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: note.isCompleted,
                      activeColor: appColor,
                      onChanged: (_) => provider.toggleNote(note),
                    ),
                    title: Text(
                      note.content,
                      style: TextStyle(
                        decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: note.isCompleted ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(DateFormat('dd MMM HH:mm').format(note.date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => provider.deleteNote(note.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNote(context, provider),
        backgroundColor: appColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddNote(BuildContext context, DataProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe Notitie'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Wat moet er gebeuren?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) provider.addNote(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
  }
}