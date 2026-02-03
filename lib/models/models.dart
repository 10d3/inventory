class Category {
  final int? id;
  final String name;
  final int color; // ARGB int

  Category({this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'], name: map['name'], color: map['color']);
  }
}

class Item {
  final int? id;
  final String barcode;
  final String name;
  final String? description;
  final int quantity;
  final double price; // Changed from costPrice to price per user request
  final int? categoryId;
  final int minStock;
  final String? imagePath;
  final DateTime createdDate;
  final DateTime updatedDate;

  Item({
    this.id,
    required this.barcode,
    required this.name,
    this.description,
    this.quantity = 0,
    this.price = 0.0,
    this.categoryId,
    this.minStock = 5,
    this.imagePath,
    required this.createdDate,
    required this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
      'categoryId': categoryId,
      'minStock': minStock,
      'imagePath': imagePath,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      description: map['description'],
      quantity: map['quantity'],
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0,
      categoryId: map['categoryId'],
      minStock: map['minStock'],
      imagePath: map['imagePath'],
      createdDate: DateTime.parse(map['createdDate']),
      updatedDate: DateTime.parse(map['updatedDate']),
    );
  }
}

enum MovementType { IN, OUT }

class StockMovement {
  final int? id;
  final int itemId;
  final int quantity; // Positive number
  final MovementType type;
  final DateTime date;
  final String? note;

  StockMovement({
    this.id,
    required this.itemId,
    required this.quantity,
    required this.type,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'quantity': quantity,
      'type': type.toString().split('.').last, // "IN" or "OUT"
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      itemId: map['itemId'],
      quantity: map['quantity'],
      type: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
