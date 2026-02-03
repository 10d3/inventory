import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN price REAL DEFAULT 0.0');
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    await db.execute('''
    CREATE TABLE categories (
      id $idType,
      name $textType,
      color $intType
    )
    ''');

    await db.execute('''
    CREATE TABLE items (
      id $idType,
      barcode $textType,
      name $textType,
      description $textNullable,
      quantity $intType,
      price REAL,
      categoryId $intNullable,
      minStock $intType,
      imagePath $textNullable,
      createdDate $textType,
      updatedDate $textType,
      FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE movements (
      id $idType,
      itemId $intType,
      quantity $intType,
      type $textType,
      date $textType,
      note $textNullable,
      FOREIGN KEY (itemId) REFERENCES items (id) ON DELETE CASCADE
    )
    ''');

    // Insert default category
    await db.insert('categories', {
      'name': 'General',
      'color': 0xFF9E9E9E, // Colors.grey
    });
  }

  // --- Categories ---
  Future<Category> createCategory(Category category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return Category(id: id, name: category.name, color: category.color);
  }

  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // --- Items ---
  Future<Item> createItem(Item item) async {
    final db = await instance.database;
    final id = await db.insert('items', item.toMap());
    return Item(
      id: id,
      barcode: item.barcode,
      name: item.name,
      description: item.description,
      quantity: item.quantity,
      categoryId: item.categoryId,
      minStock: item.minStock,
      imagePath: item.imagePath,
      createdDate: item.createdDate,
      updatedDate: item.updatedDate,
    );
  }

  Future<Item?> readItem(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'items',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Item?> readItemByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'items',
      columns: null,
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Item>> readAllItems() async {
    final db = await instance.database;
    final result = await db.query('items', orderBy: 'updatedDate DESC');
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<List<Item>> readItemsByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'updatedDate DESC',
    );
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Movements ---
  Future<StockMovement> createMovement(StockMovement movement) async {
    final db = await instance.database;
    final id = await db.insert('movements', movement.toMap());
    return StockMovement(
      id: id,
      itemId: movement.itemId,
      quantity: movement.quantity,
      type: movement.type,
      date: movement.date,
      note: movement.note,
    );
  }

  Future<List<StockMovement>> readAllMovements() async {
    final db = await instance.database;
    final result = await db.query('movements', orderBy: 'date DESC');
    return result.map((json) => StockMovement.fromMap(json)).toList();
  }

  Future<List<StockMovement>> readMovementsByItem(int itemId) async {
    final db = await instance.database;
    final result = await db.query(
      'movements',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return result.map((json) => StockMovement.fromMap(json)).toList();
  }

  Future<int> deleteMovement(int id) async {
    final db = await instance.database;
    return await db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllMovements() async {
    final db = await instance.database;
    return await db.delete('movements');
  }
}
