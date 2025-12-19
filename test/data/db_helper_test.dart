import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pos/data/db_helper.dart';
import 'package:pos/models/product.dart';

void main() {
  group('DbHelper Tests', () {
    late DbHelper dbHelper;
    late Database database;

    setUpAll(() async {
      // Initialize FFI
      sqfliteFfiInit();
      // Set database factory to FFI
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DbHelper.instance;
      database = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            cost REAL,
            quantity INTEGER,
            barcode TEXT,
            category TEXT,
            description TEXT
          )
        ''');
      });
      
      // Clear any existing data from the singleton database
      final db = await dbHelper.database;
      await db.delete('products');
    });

    tearDown(() async {
      await database.close();
    });

    test('DbHelper singleton instance', () {
      expect(DbHelper.instance, isA<DbHelper>());
      expect(DbHelper.instance, same(DbHelper.instance));
    });

    test('Insert product', () async {
      final product = Product(
        name: 'Test Product',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        barcode: '123456789',
        description: 'Test description',
      );

      final id = await dbHelper.insertProduct(product);
      expect(id, isA<int>());
      expect(id, greaterThan(0));

      // Verify product was inserted
      final products = await dbHelper.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Test Product');
      expect(products.first.price, 99.99);
    });

    test('Insert product without optional fields', () async {
      final product = Product(
        name: 'Simple Product',
        price: 49.99,
        cost: 25.0,
        quantity: 50,
      );

      final id = await dbHelper.insertProduct(product);
      expect(id, isA<int>());
      expect(id, greaterThan(0));

      final products = await dbHelper.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Simple Product');
      expect(products.first.category, isNull);
      expect(products.first.barcode, isNull);
      expect(products.first.description, isNull);
    });

    test('Get products when database is empty', () async {
      final products = await dbHelper.getProducts();
      expect(products, isEmpty);
    });

    test('Get multiple products', () async {
      // Insert multiple products
      final product1 = Product(
        name: 'Product 1',
        price: 10.0,
        cost: 5.0,
        quantity: 20,
      );

      final product2 = Product(
        name: 'Product 2',
        price: 20.0,
        cost: 10.0,
        quantity: 30,
      );

      await dbHelper.insertProduct(product1);
      await dbHelper.insertProduct(product2);

      final products = await dbHelper.getProducts();
      expect(products.length, 2);
      // Products are ordered by id DESC (most recent first)
      expect(products.first.name, 'Product 2');
      expect(products.last.name, 'Product 1');
    });

    test('Update product', () async {
      final product = Product(
        name: 'Original Product',
        price: 50.0,
        cost: 25.0,
        quantity: 100,
      );

      await dbHelper.insertProduct(product);
      
      // Update the product with a new ID
      final updatedProduct = Product(
        id: 'updated-id',
        name: 'Updated Product',
        price: 75.0,
        cost: 35.0,
        quantity: 150,
        category: 'Updated Category',
      );

      final rowsAffected = await dbHelper.updateProduct(updatedProduct);
      expect(rowsAffected, 0); // Should be 0 since ID doesn't match

      // Get the original product to verify it wasn't updated
      final products = await dbHelper.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Original Product');
    });

    test('Update product with matching ID', () async {
      final product = Product(
        name: 'Original Product',
        price: 50.0,
        cost: 25.0,
        quantity: 100,
      );

      final insertedId = await dbHelper.insertProduct(product);
      final insertedIdStr = insertedId.toString();
      
      // Update the product with the same ID
      final updatedProduct = Product(
        id: insertedIdStr,
        name: 'Updated Product',
        price: 75.0,
        cost: 35.0,
        quantity: 150,
        category: 'Updated Category',
      );

      final rowsAffected = await dbHelper.updateProduct(updatedProduct);
      expect(rowsAffected, 1);

      // Get the updated product to verify it was updated
      final products = await dbHelper.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Updated Product');
      expect(products.first.price, 75.0);
      expect(products.first.category, 'Updated Category');
    });

    test('Delete product by ID', () async {
      final product = Product(
        name: 'Test Product',
        price: 50.0,
        cost: 25.0,
        quantity: 100,
      );

      // Insert product first to get a valid ID
      final insertedId = await dbHelper.insertProduct(product);
      final insertedIdStr = insertedId.toString();

      // Delete by ID
      final rowsAffected = await dbHelper.deleteProductById(insertedIdStr);
      expect(rowsAffected, 1);

      // Verify deletion
      final products = await dbHelper.getProducts();
      expect(products, isEmpty);
    });

    test('Delete non-existent product by ID', () async {
      final rowsAffected = await dbHelper.deleteProductById('non-existent-id');
      expect(rowsAffected, 0);
    });

    test('Delete all products', () async {
      // Insert multiple products
      final product1 = Product(name: 'Product 1', price: 10.0, cost: 5.0, quantity: 20);
      final product2 = Product(name: 'Product 2', price: 20.0, cost: 10.0, quantity: 30);

      await dbHelper.insertProduct(product1);
      await dbHelper.insertProduct(product2);

      // Verify products exist
      final products = await dbHelper.getProducts();
      expect(products.length, 2);

      // Delete all
      final rowsAffected = await dbHelper.deleteAllProducts();
      expect(rowsAffected, 2);

      // Verify all are deleted
      final emptyProducts = await dbHelper.getProducts();
      expect(emptyProducts, isEmpty);
    });

    test('Query all products', () async {
      // Insert products in a specific order
      final productB = Product(name: 'Product B', price: 20.0, cost: 10.0, quantity: 30);
      final productA = Product(name: 'Product A', price: 10.0, cost: 5.0, quantity: 20);
      final productC = Product(name: 'Product C', price: 30.0, cost: 15.0, quantity: 40);

      await dbHelper.insertProduct(productB);
      await dbHelper.insertProduct(productA);
      await dbHelper.insertProduct(productC);

      final products = await dbHelper.queryAllProducts();
      expect(products.length, 3);
      // Should be ordered by name
      expect(products[0].name, 'Product A');
      expect(products[1].name, 'Product B');
      expect(products[2].name, 'Product C');
    });

    test('Clear products', () async {
      // Insert products
      final product1 = Product(name: 'Product 1', price: 10.0, cost: 5.0, quantity: 20);
      final product2 = Product(name: 'Product 2', price: 20.0, cost: 10.0, quantity: 30);

      await dbHelper.insertProduct(product1);
      await dbHelper.insertProduct(product2);

      // Clear products
      final rowsAffected = await dbHelper.clearProducts();
      expect(rowsAffected, 2);

      // Verify cleared
      final products = await dbHelper.getProducts();
      expect(products, isEmpty);
    });

    test('Database initialization', () async {
      // Test that the database is properly initialized
      final db = await dbHelper.database;
      expect(db, isA<Database>());
      expect(db.isOpen, isTrue);

      // Verify table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='products'"
      );
      expect(tables.length, 1);
      expect(tables.first['name'], 'products');
    });

    test('Product toMap and fromMap consistency', () async {
      final originalProduct = Product(
        name: 'Test Product',
        barcode: '123456789',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        description: 'Test description',
      );

      // Insert product
      await dbHelper.insertProduct(originalProduct);

      // Get products from database
      final products = await dbHelper.getProducts();
      expect(products.length, 1);

      final retrievedProduct = products.first;
      
      // Verify all fields match
      expect(retrievedProduct.name, originalProduct.name);
      expect(retrievedProduct.price, originalProduct.price);
      expect(retrievedProduct.cost, originalProduct.cost);
      expect(retrievedProduct.quantity, originalProduct.quantity);
      expect(retrievedProduct.barcode, originalProduct.barcode);
      expect(retrievedProduct.category, originalProduct.category);
      expect(retrievedProduct.description, originalProduct.description);
    });

    test('Handle database errors gracefully', () async {
      // Test with invalid data
      final invalidProduct = Product(
        name: '', // Empty name might cause issues
        price: -1.0, // Negative price
        cost: -1.0, // Negative cost
        quantity: -1, // Negative quantity
      );

      // This should not throw an exception
      expect(() async => await dbHelper.insertProduct(invalidProduct), returnsNormally);
    });
  });
}
