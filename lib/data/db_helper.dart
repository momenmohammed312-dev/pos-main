import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/product.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();

  static const String _databaseName = 'app_database.db';
  static const int _databaseVersion = 2;
  static const String tableProducts = 'products';
  static const String tableInvoices = 'invoices';
  static const String tableUsers = 'users';

  Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    // Initialize demo users on first run
    await _ensureDemoUsers();
    return _database!;
  }

  Future<void> _ensureDemoUsers() async {
    final db = await database;
    final users = await db.query(tableUsers);
    
    // If no users exist, create demo users
    if (users.isEmpty) {
      await db.insert(tableUsers, {
        'name': 'admin',
        'pin': '1234',
        'role': 'admin'
      });
      await db.insert(tableUsers, {
        'name': 'cashier',
        'pin': '0000',
        'role': 'cashier'
      });
    }
  }

  Future<Database> _initDB(String filePath) async {
    // On desktop (Windows/Linux/macOS) use the ffi implementation and set
    // the global databaseFactory so that openDatabase() works as expected.
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (e) {
      // Fallback for web or if FFI is not available
      debugPrint('FFI initialization failed: $e');
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: _databaseVersion, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migrate from v1 to v2: Add invoices and users tables if they don't exist
    if (oldVersion < 2) {
      try {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableInvoices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          receiptNumber TEXT UNIQUE NOT NULL,
          date TEXT NOT NULL,
          total REAL NOT NULL,
          itemsJson TEXT,
          userId INTEGER
        )
        ''');
      } catch (e) {
        debugPrint('Error creating invoices table: $e');
      }

      try {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          pin TEXT NOT NULL,
          role TEXT DEFAULT 'cashier'
        )
        ''');
      } catch (e) {
        debugPrint('Error creating users table: $e');
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $tableProducts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      category TEXT
    )
    ''');
    await db.execute('''
    CREATE TABLE $tableInvoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      receiptNumber TEXT UNIQUE NOT NULL,
      date TEXT NOT NULL,
      total REAL NOT NULL,
      itemsJson TEXT,
      userId INTEGER
    )
    ''');
    await db.execute('''
    CREATE TABLE $tableUsers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      pin TEXT NOT NULL,
      role TEXT DEFAULT 'cashier'
    )
    ''');
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert(tableProducts, product.toMap());
    return id;
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query(tableProducts, orderBy: 'id DESC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    if (product.id == null) return 0;
    return await db.update(tableProducts, product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<List<Product>> queryAllProducts() async {
    final db = await database;
    final maps = await db.query(tableProducts, orderBy: 'name');
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<int> deleteAllProducts() async {
    final db = await database;
    return await db.delete(tableProducts);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(tableProducts, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProductById(String id) async {
    final db = await database;
    return await db.delete(tableProducts, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearProducts() async {
    final db = await database;
    return await db.delete(tableProducts);
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }

  // ============ Invoice operations ============
  Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.insert(tableInvoices, invoice);
  }

  Future<List<Map<String, dynamic>>> getInvoicesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final maps = await db.query(
      tableInvoices,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps;
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query(tableInvoices, orderBy: 'date DESC');
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete(tableInvoices, where: 'id = ?', whereArgs: [id]);
  }

  // ============ User operations ============
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(tableUsers, user);
  }

  Future<Map<String, dynamic>?> getUserByName(String name) async {
    final db = await database;
    final maps = await db.query(tableUsers, where: 'name = ?', whereArgs: [name]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(tableUsers);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(tableUsers, where: 'id = ?', whereArgs: [id]);
  }
}
