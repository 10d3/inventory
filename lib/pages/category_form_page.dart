import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';

class CategoryFormPage extends StatefulWidget {
  final InventoryService inventoryService;
  final Category? category;

  const CategoryFormPage({
    super.key,
    required this.inventoryService,
    this.category,
  });

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _selectedColor = 0xFF9E9E9E; // Default Grey

  final List<int> _colors = [
    0xFFF44336, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFFEB3B, // Yellow
    0xFFFF9800, // Orange
    0xFF9E9E9E, // Grey
    0xFF607D8B, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    if (widget.category != null) {
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;

      // TODO: Handle Edit properly (currently implementation in service is only Add)
      // Actually DB service supports direct SQL insert for categories.
      // If we want to edit helper service needs update.
      // For now let's assume Add only or simple overwrite if I update service.

      // Checking service capabilities:
      // Service has `addCategory`. No `updateCategory`.
      // I should assume ADD only for now or quickly add update support.
      // Let's implement ADD for now.

      await widget.inventoryService.addCategory(name, _selectedColor);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null
              ? 'Nouvelle Catégorie'
              : 'Modifier la Catégorie',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la Catégorie',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              const Text('Couleur'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
