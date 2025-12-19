import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product creation with all fields', () {
      final product = Product(
        id: 'test-id',
        name: 'Test Product',
        barcode: '123456789',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        description: 'Test description',
      );

      expect(product.id, 'test-id');
      expect(product.name, 'Test Product');
      expect(product.barcode, '123456789');
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
      expect(product.category, 'Electronics');
      expect(product.description, 'Test description');
    });

    test('Product creation with only required fields', () {
      final product = Product(
        name: 'Test Product',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
      );

      expect(product.id, isNull);
      expect(product.name, 'Test Product');
      expect(product.barcode, isNull);
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
      expect(product.category, isNull);
      expect(product.description, isNull);
    });

    test('Product toMap conversion', () {
      final product = Product(
        id: 'test-id',
        name: 'Test Product',
        barcode: '123456789',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        description: 'Test description',
      );

      final map = product.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Product');
      expect(map['barcode'], '123456789');
      expect(map['price'], 99.99);
      expect(map['cost'], 50.0);
      expect(map['quantity'], 100);
      expect(map['category'], 'Electronics');
      expect(map['description'], 'Test description');
    });

    test('Product toMap conversion with null optional fields', () {
      final product = Product(
        name: 'Test Product',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
      );

      final map = product.toMap();

      expect(map.containsKey('id'), false);
      expect(map['name'], 'Test Product');
      expect(map.containsKey('barcode'), false);
      expect(map['price'], 99.99);
      expect(map['cost'], 50.0);
      expect(map['quantity'], 100);
      expect(map.containsKey('category'), false);
      expect(map.containsKey('description'), false);
    });

    test('Product fromMap conversion', () {
      final map = {
        'id': 'test-id',
        'name': 'Test Product',
        'barcode': '123456789',
        'price': 99.99,
        'cost': 50.0,
        'quantity': 100,
        'category': 'Electronics',
        'description': 'Test description',
      };

      final product = Product.fromMap(map);

      expect(product.id, 'test-id');
      expect(product.name, 'Test Product');
      expect(product.barcode, '123456789');
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
      expect(product.category, 'Electronics');
      expect(product.description, 'Test description');
    });

    test('Product fromMap conversion with missing optional fields', () {
      final map = {
        'name': 'Test Product',
        'price': 99.99,
        'cost': 50.0,
        'quantity': 100,
      };

      final product = Product.fromMap(map);

      expect(product.id, isNull);
      expect(product.name, 'Test Product');
      expect(product.barcode, isNull);
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
      expect(product.category, isNull);
      expect(product.description, isNull);
    });

    test('Product fromMap conversion with null optional fields in map', () {
      final map = {
        'id': null,
        'name': 'Test Product',
        'barcode': null,
        'price': 99.99,
        'cost': 50.0,
        'quantity': 100,
        'category': null,
        'description': null,
      };

      final product = Product.fromMap(map);

      expect(product.id, isNull);
      expect(product.name, 'Test Product');
      expect(product.barcode, isNull);
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
      expect(product.category, isNull);
      expect(product.description, isNull);
    });

    test('Product copyWith method', () {
      final originalProduct = Product(
        id: 'test-id',
        name: 'Test Product',
        barcode: '123456789',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        description: 'Test description',
      );

      final updatedProduct = originalProduct.copyWith(
        name: 'Updated Product',
        price: 199.99,
        quantity: 50,
      );

      expect(updatedProduct.id, 'test-id'); // unchanged
      expect(updatedProduct.name, 'Updated Product');
      expect(updatedProduct.barcode, '123456789'); // unchanged
      expect(updatedProduct.price, 199.99);
      expect(updatedProduct.cost, 50.0); // unchanged
      expect(updatedProduct.quantity, 50);
      expect(updatedProduct.category, 'Electronics'); // unchanged
      expect(updatedProduct.description, 'Test description'); // unchanged
    });

    test('Product copyWith with all fields', () {
      final originalProduct = Product(
        id: 'test-id',
        name: 'Test Product',
        barcode: '123456789',
        price: 99.99,
        cost: 50.0,
        quantity: 100,
        category: 'Electronics',
        description: 'Test description',
      );

      final updatedProduct = originalProduct.copyWith(
        id: 'new-id',
        name: 'New Product',
        barcode: '987654321',
        price: 199.99,
        cost: 100.0,
        quantity: 200,
        category: 'Books',
        description: 'New description',
      );

      expect(updatedProduct.id, 'new-id');
      expect(updatedProduct.name, 'New Product');
      expect(updatedProduct.barcode, '987654321');
      expect(updatedProduct.price, 199.99);
      expect(updatedProduct.cost, 100.0);
      expect(updatedProduct.quantity, 200);
      expect(updatedProduct.category, 'Books');
      expect(updatedProduct.description, 'New description');
    });

    test('Product fromMap with numeric string values', () {
      final map = {
        'name': 'Test Product',
        'price': '99.99',
        'cost': '50.0',
        'quantity': '100',
      };

      final product = Product.fromMap(map);

      expect(product.name, 'Test Product');
      expect(product.price, 99.99);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
    });

    test('Product fromMap with integer values', () {
      final map = {
        'name': 'Test Product',
        'price': 99,
        'cost': 50,
        'quantity': 100,
      };

      final product = Product.fromMap(map);

      expect(product.name, 'Test Product');
      expect(product.price, 99.0);
      expect(product.cost, 50.0);
      expect(product.quantity, 100);
    });

    test('Product fromMap with missing cost and quantity', () {
      final map = {
        'name': 'Test Product',
        'price': 99.99,
      };

      final product = Product.fromMap(map);

      expect(product.name, 'Test Product');
      expect(product.price, 99.99);
      expect(product.cost, 0.0); // default value
      expect(product.quantity, 0); // default value
    });
  });
}
