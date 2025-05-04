import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'spare_parts_db.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static int? _currentUserId;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tech_om.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Incrementamos la versión para la nueva tabla de pagos
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      phone TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS repairs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      deviceType TEXT NOT NULL,
      repairType TEXT NOT NULL,
      brand TEXT NOT NULL,
      model TEXT NOT NULL,
      description TEXT,
      cost REAL NOT NULL,
      partCost REAL,
      laborCost REAL,
      sparePartId INTEGER,
      imageUrl TEXT,
      paymentStatus TEXT DEFAULT 'pendiente',
      createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (userId) REFERENCES users (id)
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS custom_repair_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      deviceType TEXT NOT NULL,
      repairType TEXT NOT NULL,
      createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(deviceType, repairType)
    )
  ''');

    // Verificar si la tabla spare_parts existe antes de crearla
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='spare_parts'");
    if (tables.isEmpty) {
      // Crear tabla de refacciones usando el método de SparePartsDB
      await SparePartsDB.createTable(db);
    }

    // Verificar si la tabla payments existe antes de crearla
    final paymentsTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='payments'");
    if (paymentsTables.isEmpty) {
      // Crear tabla de pagos
      await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repair_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (repair_id) REFERENCES repairs (id)
      )
    ''');
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add custom_repair_types table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_repair_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deviceType TEXT NOT NULL,
          repairType TEXT NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(deviceType, repairType)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Verificar si la tabla spare_parts existe antes de crearla
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='spare_parts'");
      if (tables.isEmpty) {
        // Add spare_parts table if upgrading from version 2
        await SparePartsDB.createTable(db);
      }
    }
    
    if (oldVersion < 4) {
      // Verificar si la tabla purchases existe antes de crearla
      final purchasesTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='purchases'");
      if (purchasesTables.isEmpty) {
        // Add purchases table if upgrading from version 3
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

    if (oldVersion < 5) {
      // Añadir campos de costo de partes y mano de obra a la tabla repairs
      try {
        await db.execute('ALTER TABLE repairs ADD COLUMN partCost REAL');
      } catch (e) {
        print('Error al añadir columna partCost: $e');
        // La columna podría ya existir, continuamos
      }
      
      try {
        await db.execute('ALTER TABLE repairs ADD COLUMN laborCost REAL');
      } catch (e) {
        print('Error al añadir columna laborCost: $e');
        // La columna podría ya existir, continuamos
      }
      
      try {
        await db.execute('ALTER TABLE repairs ADD COLUMN sparePartId INTEGER');
      } catch (e) {
        print('Error al añadir columna sparePartId: $e');
        // La columna podría ya existir, continuamos
      }

      // Añadir campo de estado de pago a la tabla repairs
      try {
        await db.execute('ALTER TABLE repairs ADD COLUMN paymentStatus TEXT DEFAULT "pendiente"');
      } catch (e) {
        print('Error al añadir columna paymentStatus: $e');
        // La columna podría ya existir, continuamos
      }

      // Verificar si la tabla payments existe antes de crearla
      final paymentsTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='payments'");
      if (paymentsTables.isEmpty) {
        // Crear tabla de pagos
        await db.execute('''
          CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            repair_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            payment_date TEXT NOT NULL,
            notes TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (repair_id) REFERENCES repairs (id)
          )
        ''');
      }
    }
  }

  // User methods
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  // Current user methods
  static void setCurrentUserId(int id) {
    _currentUserId = id;
  }

  static int? getCurrentUserId() {
    return _currentUserId;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserId == null) return null;
    
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_currentUserId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Repair methods
  Future<int> insertRepair(Map<String, dynamic> repair) async {
    final db = await instance.database;
    
    // Asegurarse de que createdAt esté presente o usar el valor por defecto
    if (!repair.containsKey('createdAt')) {
      repair['createdAt'] = DateTime.now().toIso8601String();
    }
    
    try {
      return await db.insert('repairs', repair);
    } catch (e) {
      // Si falla porque la columna createdAt no existe, intentar sin ella
      if (e.toString().contains('no column named createdAt')) {
        // Crear una copia del mapa sin la clave createdAt
        final repairWithoutCreatedAt = Map<String, dynamic>.from(repair);
        repairWithoutCreatedAt.remove('createdAt');
        return await db.insert('repairs', repairWithoutCreatedAt);
      } else {
        rethrow; // Re-lanzar cualquier otro error
      }
    }
  }

  Future<List<Map<String, dynamic>>> getRepairs() async {
    final db = await instance.database;
    return await db.query('repairs', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getRepairsByUserId(int userId) async {
    final db = await instance.database;
    return await db.query(
      'repairs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateRepair(Map<String, dynamic> repair) async {
    final db = await instance.database;
    return await db.update(
      'repairs',
      repair,
      where: 'id = ?',
      whereArgs: [repair['id']],
    );
  }

  Future<int> deleteRepair(int id) async {
    final db = await instance.database;
    return await db.delete(
      'repairs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Custom repair types methods
  Future<int> saveCustomRepairType(String deviceType, String repairType) async {
    final db = await instance.database;
    return await db.insert(
      'custom_repair_types',
      {
        'deviceType': deviceType,
        'repairType': repairType,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Skip if already exists
    );
  }

  Future<List<Map<String, dynamic>>> getCustomRepairTypes(String deviceType) async {
    final db = await instance.database;
    return await db.query(
      'custom_repair_types',
      columns: ['id', 'repairType'],
      where: 'deviceType = ?',
      whereArgs: [deviceType],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteCustomRepairType(int id) async {
    final db = await instance.database;
    return await db.delete(
      'custom_repair_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para pagos
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await instance.database;
    
    // Insertar el pago
    int paymentId = await db.insert('payments', payment);
    
    if (paymentId > 0) {
      // Obtener la reparación
      final repair = await db.query(
        'repairs',
        where: 'id = ?',
        whereArgs: [payment['repair_id']],
      );
      
      if (repair.isNotEmpty) {
        // Obtener todos los pagos para esta reparación
        final payments = await db.query(
          'payments',
          where: 'repair_id = ?',
          whereArgs: [payment['repair_id']],
        );
        
        // Calcular el total pagado
        double totalPaid = 0;
        for (var p in payments) {
          totalPaid += p['amount'] is num ? 
              (p['amount'] as num).toDouble() : 
              double.tryParse(p['amount'].toString()) ?? 0.0;
        }
        
        // Obtener el costo total de la reparación
        double totalCost = repair.first['cost'] is num ? 
            (repair.first['cost'] as num).toDouble() : 
            double.tryParse(repair.first['cost'].toString()) ?? 0.0;
        
        // Actualizar el estado de pago
        String paymentStatus = 'pendiente';
        if (totalPaid >= totalCost) {
          paymentStatus = 'pagado';
        } else if (totalPaid > 0) {
          paymentStatus = 'parcial';
        }
        
        // Actualizar la reparación
        await db.update(
          'repairs',
          {'paymentStatus': paymentStatus},
          where: 'id = ?',
          whereArgs: [payment['repair_id']],
        );
      }
    }
    
    return paymentId;
  }

  Future<List<Map<String, dynamic>>> getPaymentsByRepairId(int repairId) async {
    final db = await instance.database;
    return await db.query(
      'payments',
      where: 'repair_id = ?',
      whereArgs: [repairId],
      orderBy: 'payment_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT p.*, r.repairType, r.deviceType, r.brand, r.model
      FROM payments p
      JOIN repairs r ON p.repair_id = r.id
      ORDER BY p.payment_date DESC
    ''');
  }

  Future<int> updateRepairPaymentStatus(int repairId, String status, double totalPaid) async {
    final db = await instance.database;
    return await db.update(
      'repairs',
      {'paymentStatus': status},
      where: 'id = ?',
      whereArgs: [repairId],
    );
  }
}
