import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import 'categories_page.dart';
import 'package:esteban_inventory/pages/inventory_page.dart';
import 'package:esteban_inventory/pages/history_page.dart';

class HomePage extends StatelessWidget {
  final InventoryService inventoryService;

  const HomePage({super.key, required this.inventoryService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Stats Section
            ListenableBuilder(
              listenable: inventoryService,
              builder: (context, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total Articles',
                          value: inventoryService.items.length.toString(),
                        ),
                        // Calculate low stock?
                        _StatItem(
                          label: 'Stock Faible',
                          value: inventoryService.items
                              .where((i) => i.quantity <= i.minStock)
                              .length
                              .toString(),
                          isWarning: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Navigation Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _NavButton(
                    icon: Icons.inventory,
                    label: 'Inventaire',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InventoryPage(inventoryService: inventoryService),
                        ),
                      );
                    },
                  ),
                  _NavButton(
                    icon: Icons.category,
                    label: 'Catégories',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesPage(
                            inventoryService: inventoryService,
                          ),
                        ),
                      );
                    },
                  ),
                  _NavButton(
                    icon: Icons.history,
                    label: 'Historique',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HistoryPage(inventoryService: inventoryService),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _StatItem({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.red : null,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
