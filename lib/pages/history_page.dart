import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';
import '../services/csv_export_service.dart';

class HistoryPage extends StatefulWidget {
  final InventoryService inventoryService;

  const HistoryPage({super.key, required this.inventoryService});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.inventoryService,
      builder: (context, _) {
        final movements = widget.inventoryService.movements;
        final items = widget.inventoryService.items;

        // Filter by date
        final filteredMovements = _selectedDateRange == null
            ? movements
            : movements.where((m) {
                // Inclusive filter
                final start = _selectedDateRange!.start.subtract(
                  const Duration(seconds: 1),
                );
                final end = _selectedDateRange!.end.add(
                  const Duration(days: 1),
                );
                return m.date.isAfter(start) && m.date.isBefore(end);
              }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Historique du Stock'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter CSV',
                onPressed: () async {
                  if (filteredMovements.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune donnée à exporter')),
                    );
                    return;
                  }
                  await CsvExportService().exportHistory(
                    filteredMovements,
                    items,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDateRange = picked;
                    });
                  }
                },
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDateRange = null),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete_all') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer tout?'),
                        content: const Text(
                          'Voulez-vous vraiment supprimer tout l\'historique? Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await widget.inventoryService.deleteAllMovements();
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Text(
                      'Tout Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: filteredMovements.isEmpty
              ? const Center(child: Text('Aucun historique trouvé.'))
              : ListView.builder(
                  itemCount: filteredMovements.length,
                  itemBuilder: (context, index) {
                    final m = filteredMovements[index];
                    final item = items.firstWhere(
                      (i) => i.id == m.itemId,
                      orElse: () => Item(
                        barcode: '',
                        name: 'Article Supprimé',
                        quantity: 0,
                        createdDate: DateTime.now(),
                        updatedDate: DateTime.now(),
                      ),
                    );

                    return Dismissible(
                      key: Key(m.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer?'),
                            content: const Text(
                              'Voulez-vous supprimer ce mouvement de l\'historique?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Non'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Oui'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        await widget.inventoryService.deleteMovement(m.id!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mouvement supprimé')),
                          );
                        }
                      },
                      child: ListTile(
                        leading: Icon(
                          m.type == MovementType.IN
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: m.type == MovementType.IN
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(m.date),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${m.type == MovementType.IN ? '+' : '-'}${m.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.type == MovementType.IN
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            if (m.note != null && m.note!.isNotEmpty)
                              Text(
                                m.note!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
