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
      version: 4, // Incrementamos la versión para la nueva tabla de compras
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE repairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        deviceType TEXT NOT NULL,
        repairType TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        description TEXT,
        cost REAL NOT NULL,
        imageUrl TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_repair_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceType TEXT NOT NULL,
        repairType TEXT NOT NULL,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(deviceType, repairType)
      )
    ''');

    // Crear tabla de refacciones usando el método de SparePartsDB
    await SparePartsDB.createTable(db);
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
      // Add spare_parts table if upgrading from version 2
      await SparePartsDB.createTable(db);
    }
    
    if (oldVersion < 4) {
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
    return await db.insert('repairs', repair);
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
}