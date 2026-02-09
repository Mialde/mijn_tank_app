import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data_provider.dart';

class DeveloperNotesScreen extends StatelessWidget {
  const DeveloperNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Notities'),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyMedium?.color), // Zorg dat back arrow zichtbaar is
      ),
      body: provider.notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('Geen notities. Tijd voor een goed idee!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: provider.notes.length,
              itemBuilder: (context, index) {
                final note = provider.notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const BehindMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (_) => provider.deleteNote(note.id!),
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.delete, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: note.isCompleted ? Colors.green.withOpacity(0.5) : Colors.transparent),
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            note.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            color: note.isCompleted ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => provider.toggleNote(note),
                        ),
                        title: Text(
                          note.content,
                          style: TextStyle(
                            decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                            color: note.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd-MM-yyyy HH:mm').format(note.date),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: appColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddNoteDialog(context, provider, appColor),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, DataProvider provider, Color color) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Nieuwe Notitie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Wat wil je onthouden?'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addNote(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}