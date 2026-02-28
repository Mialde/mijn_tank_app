// RECURRING COSTS DIALOG
// Manage subscriptions and recurring costs for a car

import 'package:flutter/material.dart';
import '../models/recurring_cost.dart';
import '../services/database_helper.dart';

class RecurringCostsDialog extends StatefulWidget {
  final int carId;
  final Color appColor;
  
  const RecurringCostsDialog({
    super.key,
    required this.carId,
    required this.appColor,
  });

  @override
  State<RecurringCostsDialog> createState() => _RecurringCostsDialogState();
}

class _RecurringCostsDialogState extends State<RecurringCostsDialog> {
  List<RecurringCost> _costs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() => _loading = true);
    final costs = await DatabaseHelper.instance.getRecurringCostsByCar(widget.carId);
    setState(() {
      _costs = costs;
      _loading = false;
    });
  }

  void _showAddEditDialog({RecurringCost? cost}) {
    final nameController = TextEditingController(text: cost?.name);
    final amountController = TextEditingController(
      text: cost?.amount.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    final descController = TextEditingController(text: cost?.description);
    String frequency = cost?.frequency ?? 'monthly';
    bool isActive = cost?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(cost == null ? 'Nieuw Abonnement' : 'Wijzig Abonnement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naam *',
                    hintText: 'ANWB Wegenwacht, Flitsmeister',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Bedrag (€) *',
                    hintText: '0,00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequentie'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Per maand')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Per kwartaal')),
                    DropdownMenuItem(value: 'yearly', child: Text('Per jaar')),
                  ],
                  onChanged: (v) => setDialogState(() => frequency = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Omschrijving (optioneel)',
                    hintText: 'Notities over dit abonnement',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Actief'),
                  subtitle: const Text('Meenemen in berekeningen'),
                  value: isActive,
                  activeTrackColor: widget.appColor,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleer'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.appColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Validation
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naam is verplicht')),
                  );
                  return;
                }
                
                final amountStr = amountController.text.replaceAll(',', '.');
                final amount = double.tryParse(amountStr);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voer een geldig bedrag in')),
                  );
                  return;
                }

                final newCost = RecurringCost(
                  id: cost?.id,
                  carId: widget.carId,
                  name: nameController.text,
                  amount: amount,
                  frequency: frequency,
                  description: descController.text.isEmpty ? null : descController.text,
                  isActive: isActive,
                );

                if (cost == null) {
                  await DatabaseHelper.instance.insertRecurringCost(newCost);
                } else {
                  await DatabaseHelper.instance.updateRecurringCost(newCost);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadCosts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cost == null ? '✅ Abonnement toegevoegd' : '✅ Abonnement bijgewerkt'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(cost == null ? 'Toevoegen' : 'Opslaan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCost(RecurringCost cost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verwijderen?'),
        content: Text('Weet je zeker dat je "${cost.name}" wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteRecurringCost(cost.id!);
              if (context.mounted) {
                Navigator.pop(context);
                _loadCosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Abonnement verwijderd'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Verwijder'),
          ),
        ],
      ),
    );
  }

  String _getFrequencyLabel(String freq) {
    switch (freq) {
      case 'yearly':
        return '/jaar';
      case 'quarterly':
        return '/kwartaal';
      case 'monthly':
      default:
        return '/maand';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.subscriptions, color: widget.appColor, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abonnementen & Kosten',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Beheer terugkerende kosten',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _costs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.subscriptions_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nog geen abonnementen',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Voeg ANWB, Flitsmeister, etc. toe',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _costs.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final cost = _costs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cost.isActive
                                    ? widget.appColor.withValues(alpha: 0.1)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.euro,
                                  color: cost.isActive ? widget.appColor : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                cost.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: cost.isActive ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(
                                cost.description ?? 'Geen omschrijving',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '€${cost.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _getFrequencyLabel(cost.frequency),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Bewerken'),
                                          ],
                                        ),
                                        onTap: () => Future.delayed(
                                          Duration.zero,
                                          () => _showAddEditDialog(cost: cost),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Verwijderen', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () => Future.delayed(
                                          Duration.zero,
                                          () => _deleteCost(cost),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _showAddEditDialog(cost: cost),
                            );
                          },
                        ),
            ),
            
            const Divider(height: 1),
            
            // Footer with total
            if (_costs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: widget.appColor.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Totaal per maand:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '€${_costs.where((c) => c.isActive).fold<double>(0, (sum, c) => sum + c.monthlyCost).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.appColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nieuw Abonnement'),
                  onPressed: () => _showAddEditDialog(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}