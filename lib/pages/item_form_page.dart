import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ItemFormPage extends StatefulWidget {
  final InventoryService inventoryService;
  final Item? item;

  const ItemFormPage({super.key, required this.inventoryService, this.item});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late TextEditingController _minStockController;
  late TextEditingController _priceController;

  int? _selectedCategoryId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameController = TextEditingController(text: i?.name ?? '');
    _barcodeController = TextEditingController(text: i?.barcode ?? '');
    _descController = TextEditingController(text: i?.description ?? '');
    _qtyController = TextEditingController(text: i?.quantity.toString() ?? '0');
    _minStockController = TextEditingController(
      text: i?.minStock.toString() ?? '5',
    );
    _priceController = TextEditingController(
      text: i?.price.toString() ?? '0.0',
    );
    _selectedCategoryId = i?.categoryId;
    _imagePath = i?.imagePath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Copy to local app directory to ensure persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  //...

  // Scanner functionality disabled
  // Future<void> _scanBarcode() async {
  //   // Scanner removed to avoid charges
  // }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      String barcode = _barcodeController.text.trim();
      if (barcode.isEmpty) {
        barcode = 'GEN-${DateTime.now().millisecondsSinceEpoch}';
      }
      final desc = _descController.text;
      final qty = int.tryParse(_qtyController.text) ?? 0;
      final minStock = int.tryParse(_minStockController.text) ?? 5;

      final price = double.tryParse(_priceController.text) ?? 0.0;
      if (widget.item == null || widget.item!.id == null) {
        // Create
        final newItem = Item(
          barcode: barcode,
          name: name,
          description: desc,
          quantity: qty,
          price: price,
          categoryId: _selectedCategoryId,
          minStock: minStock,
          imagePath: _imagePath,
          createdDate: DateTime.now(),
          updatedDate: DateTime.now(),
        );
        await widget.inventoryService.addItem(newItem);
      } else {
        // Update
        final updatedItem = Item(
          id: widget.item!.id,
          barcode: barcode,
          name: name,
          description: desc,
          quantity:
              qty, // Note: Direct edit of quantity here. Ideally use adjustments for history.
          price: price,
          categoryId: _selectedCategoryId,
          minStock: minStock,
          createdDate: widget.item!.createdDate,
          updatedDate: DateTime.now(),
          imagePath: _imagePath,
        );

        // If Logic requires recording movement for quantity change during Edit, we should calculate diff.
        // For simplicity, we assume "Edit" overwrites state, but "stock adjustment" is separate.
        // However, user said "edit items".

        await widget.inventoryService.updateItem(updatedItem);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Ajouter un article' : 'Modifier l\'article',
        ),
        actions: [
          if (widget.item != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Supprimer l\'article ?'),
                    content: const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await widget.inventoryService.deleteItem(widget.item!.id!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.inventoryService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Image Preview & Picker
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galerie'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Caméra'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _imagePath == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _imagePath!.startsWith('http')
                                  ? Image.network(
                                      _imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image),
                                    )
                                  : Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barcode Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Code-barres',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => null, // Optional
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scanner button disabled
                      // IconButton.filled(
                      //   onPressed: _scanBarcode,
                      //   icon: const Icon(Icons.qr_code_scanner),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.inventoryService.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          decoration: const InputDecoration(
                            labelText: 'Quantité',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled:
                              widget.item ==
                              null, // Disable direct qty edit if enforcing history? Or allow correction?
                          // Let's allow correction.
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Min',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Field
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
