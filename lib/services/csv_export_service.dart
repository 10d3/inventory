import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class CsvExportService {
  Future<void> exportInventory(
    List<Item> items,
    List<Category> categories,
  ) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Date',
      'Barcode',
      'Name',
      'Category',
      'Quantity',
      'Price',
      'Min Stock',
      'Description',
    ]);

    // Data
    for (var item in items) {
      final categoryName = categories
          .firstWhere(
            (c) => c.id == item.categoryId,
            orElse: () => Category(name: 'Uncategorized', color: 0),
          )
          .name;

      rows.add([
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
        item.barcode,
        item.name,
        categoryName,
        item.quantity,
        item.price,
        item.minStock,
        item.description ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShare(
      csv,
      'inventory_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv',
    );
  }

  Future<void> exportHistory(
    List<StockMovement> movements,
    List<Item> items,
  ) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add(['Date', 'Type', 'Item Name', 'Barcode', 'Quantity', 'Note']);

    // Data
    for (var m in movements) {
      final item = items.firstWhere(
        (i) => i.id == m.itemId,
        orElse: () => Item(
          barcode: 'UNKNOWN',
          name: 'Deleted Item',
          quantity: 0,
          createdDate: DateTime.now(),
          updatedDate: DateTime.now(),
        ),
      );

      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(m.date),
        m.type == MovementType.IN ? 'ENTRANCE' : 'EXIT',
        item.name,
        item.barcode,
        m.quantity,
        m.note ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShare(
      csv,
      'history_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv',
    );
  }

  Future<void> _saveAndShare(String csvData, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Esteban Inventory Export');
    } catch (e) {
      print('Error exporting CSV: $e');
      // Handle error (maybe rethrow or show snackbar if context was passed, but service shouldn't know context ideally)
    }
  }
}
