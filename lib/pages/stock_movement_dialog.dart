import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';

class StockMovementDialog extends StatefulWidget {
  final InventoryService inventoryService;
  final Item item;

  const StockMovementDialog({
    super.key,
    required this.inventoryService,
    required this.item,
  });

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  MovementType _selectedType = MovementType.IN;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quantité Invalide')));
      return;
    }

    if (_selectedType == MovementType.IN) {
      await widget.inventoryService.addStock(
        widget.item.id!,
        qty,
        note: _noteController.text,
      );
    } else {
      await widget.inventoryService.removeStock(
        widget.item.id!,
        qty,
        note: _noteController.text,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajuster le Stock: ${widget.item.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<MovementType>(
                    title: const Text('ENTRÉE'),
                    value: MovementType.IN,
                    groupValue: _selectedType,
                    onChanged: (v) => setState(() => _selectedType = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<MovementType>(
                    title: const Text('SORTIE'),
                    value: MovementType.OUT,
                    groupValue: _selectedType,
                    onChanged: (v) => setState(() => _selectedType = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Optionnel)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
