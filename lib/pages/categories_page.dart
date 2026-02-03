import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import 'category_form_page.dart';

class CategoriesPage extends StatelessWidget {
  final InventoryService inventoryService;

  const CategoriesPage({super.key, required this.inventoryService});

  @override
  Widget build(BuildContext context) {
    // Using simple ListenableBuilder to rebuild when service notifies
    return ListenableBuilder(
      listenable: inventoryService,
      builder: (context, child) {
        if (inventoryService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = inventoryService.categories;

        return Scaffold(
          appBar: AppBar(title: const Text('Catégories')),
          body: categories.isEmpty
              ? const Center(child: Text('Aucune catégorie.'))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Color(cat.color)),
                      title: Text(cat.name),
                      // Edit not fully implemented in service yet
                      // onTap: () => Navigator.push(...),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryFormPage(inventoryService: inventoryService),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
