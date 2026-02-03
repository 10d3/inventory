import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import 'database_service.dart';

class InventoryService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Category> _categories = [];
  List<Item> _items = [];
  List<StockMovement> _movements = [];

  List<Category> get categories => _categories;
  List<Item> get items => _items;
  List<StockMovement> get movements => _movements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Initialization ---
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadItems();
    await loadMovements();

    _isLoading = false;
    notifyListeners();
  }

  // --- Categories ---
  Future<void> loadCategories() async {
    _categories = await _db.readAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name, int color) async {
    final category = Category(name: name, color: color);
    await _db.createCategory(category);
    await loadCategories();
  }

  // --- Items ---
  Future<void> loadItems() async {
    _items = await _db.readAllItems();
    notifyListeners();
  }

  Future<void> addItem(Item item) async {
    await _db.createItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await loadItems();
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    return await _db.readItemByBarcode(barcode);
  }

  // --- Movements & Stock Management ---
  Future<void> loadMovements() async {
    _movements = await _db.readAllMovements();
    notifyListeners();
  }

  Future<void> addStock(int itemId, int quantity, {String? note}) async {
    final item = await _db.readItem(itemId);
    if (item == null) return;

    // Update item quantity
    final updatedItem = Item(
      id: item.id,
      barcode: item.barcode,
      name: item.name,
      description: item.description,
      quantity: item.quantity + quantity,
      categoryId: item.categoryId,
      minStock: item.minStock,
      price: item.price,
      imagePath: item.imagePath,
      createdDate: item.createdDate,
      updatedDate: DateTime.now(),
    );
    await _db.updateItem(updatedItem);

    // Record movement
    final movement = StockMovement(
      itemId: itemId,
      quantity: quantity,
      type: MovementType.IN,
      date: DateTime.now(),
      note: note,
    );
    await _db.createMovement(movement);

    await loadData();
  }

  Future<void> removeStock(int itemId, int quantity, {String? note}) async {
    final item = await _db.readItem(itemId);
    if (item == null) return;

    // Check if enough stock? (Optional, but good practice. currently allowing negative for flexibility or blocking?)
    // Let's allow negative for now but maybe warn? Or just clamped to 0?
    // User requirement: "manage entrance and sortie... see stock low alert".
    // Usually inventory systems allow negative if physical count is ahead of system, but implies data error.
    // Let's just do math.

    final newQuantity = item.quantity - quantity;

    final updatedItem = Item(
      id: item.id,
      barcode: item.barcode,
      name: item.name,
      description: item.description,
      quantity: newQuantity,
      categoryId: item.categoryId,
      minStock: item.minStock,
      price: item.price,
      imagePath: item.imagePath,
      createdDate: item.createdDate,
      updatedDate: DateTime.now(),
    );
    await _db.updateItem(updatedItem);

    // Record movement
    final movement = StockMovement(
      itemId: itemId,
      quantity: quantity,
      type: MovementType.OUT,
      date: DateTime.now(),
      note: note,
    );
    await _db.createMovement(movement);

    await loadData();
  }

  Future<void> deleteMovement(int id) async {
    await _db.deleteMovement(id);
    await loadMovements();
  }

  Future<void> deleteAllMovements() async {
    await _db.deleteAllMovements();
    await loadMovements();
  }
}
