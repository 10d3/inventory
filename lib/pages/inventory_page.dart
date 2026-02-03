import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_service.dart';
import 'stock_movement_dialog.dart';
import 'package:esteban_inventory/pages/item_form_page.dart';
import '../services/csv_export_service.dart';
import 'dart:io';

class InventoryPage extends StatefulWidget {
  final InventoryService inventoryService;

  const InventoryPage({super.key, required this.inventoryService});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.inventoryService,
      builder: (context, child) {
        if (widget.inventoryService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final items = widget.inventoryService.items;
        final categories = widget.inventoryService.categories;

        // Filtering
        final filteredItems = items.where((item) {
          final matchesSearch =
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.barcode.contains(_searchQuery);
          final matchesCategory =
              _selectedCategoryId == null ||
              item.categoryId == _selectedCategoryId;
          return matchesSearch && matchesCategory;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventaire'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter CSV',
                onPressed: () async {
                  if (widget.inventoryService.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune donnée à exporter')),
                    );
                    return;
                  }
                  await CsvExportService().exportInventory(
                    widget.inventoryService.items,
                    widget.inventoryService.categories,
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                120,
              ), // Height for Search + Chips
              child: _buildFilterBar(categories),
            ),
          ),
          body: filteredItems.isEmpty
              ? const Center(child: Text('Aucun article trouvé.'))
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final category = categories.firstWhere(
                      (c) => c.id == item.categoryId,
                      orElse: () =>
                          Category(name: 'Inconnu', color: 0xFF9E9E9E),
                    );

                    final isLowStock = item.quantity <= item.minStock;

                    return ListTile(
                      leading: item.imagePath != null
                          ? Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: item.imagePath!.startsWith('http')
                                      ? NetworkImage(item.imagePath!)
                                      : FileImage(File(item.imagePath!))
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                              // Fallback if image fails to load? decoration image handles it roughly or needs errorBuilder which is for Image widget.
                              // DecorationImage onError doesn't render backup widget easily in boxdecoration.
                              // Let's use ClipOval + Image widget for better error handling.
                              child: null,
                            )
                          : CircleAvatar(
                              backgroundColor: Color(category.color),
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Code: ${item.barcode}'),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: Color(category.color),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Qté: ${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? Colors.red : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              if (isLowStock)
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 14,
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_vert_circle),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => StockMovementDialog(
                                  inventoryService: widget.inventoryService,
                                  item: item,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // Edit item
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemFormPage(
                              inventoryService: widget.inventoryService,
                              item: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ItemFormPage(inventoryService: widget.inventoryService),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(List<Category> categories) {
    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        // Category Chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: const Text('Tout'),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) =>
                      setState(() => _selectedCategoryId = null),
                ),
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat.name),
                    selected: _selectedCategoryId == cat.id,
                    backgroundColor: Color(cat.color).withOpacity(0.2),
                    selectedColor: Color(cat.color),
                    onSelected: (selected) => setState(
                      () => _selectedCategoryId = selected ? cat.id : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
