import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SparePartsDB {
  static final SparePartsDB instance = SparePartsDB._init();

  SparePartsDB._init();

  // Método para crear la tabla de refacciones
  static Future<void> createTable(Database db) async {
    // Verificar si la tabla spare_parts existe antes de crearla
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='spare_parts'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS spare_parts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          partType TEXT NOT NULL,
          brand TEXT NOT NULL,
          model TEXT NOT NULL,
          price REAL NOT NULL,
          deviceType TEXT NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    
    // Verificar si la tabla purchases existe antes de crearla
    final purchasesTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='purchases'");
    if (purchasesTables.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          refaccionId INTEGER NOT NULL,
          precio REAL NOT NULL,
          fecha TEXT NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (refaccionId) REFERENCES spare_parts (id)
        )
      ''');
    }
  }

  // Método para insertar una nueva refacción
  Future<int> insertSparePart(Map<String, dynamic> sparePart) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('spare_parts', sparePart);
  }

  // Método para obtener todas las refacciones
  Future<List<Map<String, dynamic>>> getAllSpareParts() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      orderBy: 'deviceType ASC, partType ASC, brand ASC, model ASC',
    );
  }

  // Método para obtener refacciones por tipo de dispositivo
  Future<List<Map<String, dynamic>>> getSparePartsByDeviceType(String deviceType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      where: 'deviceType = ?',
      whereArgs: [deviceType],
      orderBy: 'partType ASC, brand ASC, model ASC',
    );
  }

  // Método para obtener refacciones por tipo de parte
  Future<List<Map<String, dynamic>>> getSparePartsByPartType(String partType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      where: 'partType = ?',
      whereArgs: [partType],
      orderBy: 'brand ASC, model ASC',
    );
  }

  // Método para obtener refacciones por tipo de dispositivo y tipo de parte
  Future<List<Map<String, dynamic>>> getSparePartsByDeviceAndPartType(
      String deviceType, String partType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      where: 'deviceType = ? AND partType = ?',
      whereArgs: [deviceType, partType],
      orderBy: 'brand ASC, model ASC',
    );
  }

  // Método para obtener tipos de partes distintos
  Future<List<String>> getDistinctPartTypes() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT DISTINCT partType FROM spare_parts ORDER BY partType ASC');
    return result.map((map) => map['partType'] as String).toList();
  }

  // Método para obtener marcas distintas
  Future<List<String>> getDistinctBrands() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT DISTINCT brand FROM spare_parts ORDER BY brand ASC');
    return result.map((map) => map['brand'] as String).toList();
  }

  // Método para actualizar una refacción
  Future<int> updateSparePart(Map<String, dynamic> sparePart) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'spare_parts',
      sparePart,
      where: 'id = ?',
      whereArgs: [sparePart['id']],
    );
  }

  // Método para eliminar una refacción
  Future<int> deleteSparePart(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'spare_parts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para buscar refacciones
  Future<List<Map<String, dynamic>>> searchSpareParts(String query) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      where: 'partType LIKE ? OR brand LIKE ? OR model LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'deviceType ASC, partType ASC, brand ASC, model ASC',
    );
  }

  // Método para obtener refacciones por rango de precio
  Future<List<Map<String, dynamic>>> getSparePartsByPriceRange(
      double minPrice, double maxPrice) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'spare_parts',
      where: 'price >= ? AND price <= ?',
      whereArgs: [minPrice, maxPrice],
      orderBy: 'price ASC',
    );
  }

  // Método para obtener el precio promedio por tipo de parte
  Future<Map<String, double>> getAveragePriceByPartType() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT partType, AVG(price) as avgPrice FROM spare_parts GROUP BY partType');
    
    Map<String, double> averagePrices = {};
    for (var row in result) {
      averagePrices[row['partType'] as String] = row['avgPrice'] as double;
    }
    
    return averagePrices;
  }

  // Método para contar refacciones por tipo de dispositivo
  Future<Map<String, int>> countSparePartsByDeviceType() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT deviceType, COUNT(*) as count FROM spare_parts GROUP BY deviceType');
    
    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['deviceType'] as String] = row['count'] as int;
    }
    
    return counts;
  }

  // NUEVOS MÉTODOS PARA GESTIONAR COMPRAS DE REFACCIONES

  // Método para insertar una nueva compra
  Future<int> insertPurchase(Map<String, dynamic> purchase) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('purchases', purchase);
  }

  // Método para obtener todas las compras
  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'purchases',
      orderBy: 'fecha DESC',
    );
  }

  // Método para obtener compras por ID de refacción
  Future<List<Map<String, dynamic>>> getPurchasesByRefaccionId(int refaccionId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'purchases',
      where: 'refaccionId = ?',
      whereArgs: [refaccionId],
      orderBy: 'fecha DESC',
    );
  }

  // Método para obtener compras con detalles de refacción
  Future<List<Map<String, dynamic>>> getPurchasesWithDetails() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT p.*, s.partType, s.brand, s.model, s.deviceType
      FROM purchases p
      JOIN spare_parts s ON p.refaccionId = s.id
      ORDER BY p.fecha DESC
    ''');
  }

  // Método para obtener compras por rango de fechas
  Future<List<Map<String, dynamic>>> getPurchasesByDateRange(
      String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'purchases',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'fecha DESC',
    );
  }

  // Método para actualizar una compra
  Future<int> updatePurchase(Map<String, dynamic> purchase) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'purchases',
      purchase,
      where: 'id = ?',
      whereArgs: [purchase['id']],
    );
  }

  // Método para eliminar una compra
  Future<int> deletePurchase(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para obtener el total gastado en compras
  Future<double> getTotalPurchasesAmount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT SUM(precio) as total FROM purchases');
    return result.first['total'] as double? ?? 0.0;
  }

  // Método para obtener el total gastado por tipo de refacción
  Future<Map<String, double>> getTotalPurchasesByPartType() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT s.partType, SUM(p.precio) as total
      FROM purchases p
      JOIN spare_parts s ON p.refaccionId = s.id
      GROUP BY s.partType
    ''');
    
    Map<String, double> totals = {};
    for (var row in result) {
      totals[row['partType'] as String] = row['total'] as double? ?? 0.0;
    }
    
    return totals;
  }
}
