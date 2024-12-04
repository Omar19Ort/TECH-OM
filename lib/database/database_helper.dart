import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  email $textType UNIQUE,
  password $textType,
  phone TEXT
)
''');

    await db.execute('''
CREATE TABLE repairs (
  id $idType,
  userId $integerType,
  deviceType $textType,
  repairType $textType,
  brand $textType,
  model $textType,
  description TEXT,
  cost $realType,
  imageUrl TEXT,
  FOREIGN KEY (userId) REFERENCES users (id)
)
''');
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> insertRepair(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('repairs', row);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<List<Map<String, dynamic>>> getRepairs() async {
    final db = await instance.database;
    return await db.query('repairs');
  }

  Future<List<Map<String, dynamic>>> getRepairsByUserId(int userId) async {
    final db = await instance.database;
    return await db.query(
      'repairs',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = row['id'];
    return await db.update(
      'users',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateRepair(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'repairs',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
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

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Nuevo método para establecer el usuario actual
  static void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  // Método actualizado para obtener el usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserId == null) {
      return null;
    }
    return await getUserById(_currentUserId!);
  }
}

