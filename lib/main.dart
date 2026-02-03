import 'package:flutter/material.dart';
import 'package:esteban_inventory/services/inventory_service.dart';
import 'package:esteban_inventory/pages/home-page.dart';
import 'package:esteban_inventory/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final inventoryService = InventoryService();
  await inventoryService.loadData();

  runApp(MyApp(inventoryService: inventoryService));
}

class MyApp extends StatelessWidget {
  final InventoryService inventoryService;

  const MyApp({super.key, required this.inventoryService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventaire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashPage(inventoryService: inventoryService),
    );
  }
}
