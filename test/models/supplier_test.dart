import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_disck/models/supplier.dart';

void main() {
  group('Supplier Model Tests', () {
    test('Supplier creation with all fields', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
        email: 'test@supplier.com',
        address: '123 Test Street, City',
        outstanding: 1000.0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.email, 'test@supplier.com');
      expect(supplier.address, '123 Test Street, City');
      expect(supplier.outstanding, 1000.0);
      expect(supplier.createdAt, createdAt);
      expect(supplier.updatedAt, updatedAt);
    });

    test('Supplier creation with default values', () {
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
      );

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.email, isNull);
      expect(supplier.address, isNull);
      expect(supplier.outstanding, 0.0); // default
      expect(supplier.createdAt, isA<DateTime>());
      expect(supplier.updatedAt, isA<DateTime>());
    });

    test('Supplier toMap conversion', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
        email: 'test@supplier.com',
        address: '123 Test Street, City',
        outstanding: 1000.0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = supplier.toMap();

      expect(map['name'], 'Test Supplier');
      expect(map['phone'], '+1234567890');
      expect(map['email'], 'test@supplier.com');
      expect(map['address'], '123 Test Street, City');
      expect(map['outstanding'], 1000.0);
      expect(map['createdAt'], createdAt);
      expect(map['updatedAt'], updatedAt);
      expect(map.containsKey('id'), false); // id is not included in toMap
    });

    test('Supplier toMap conversion with null optional fields', () {
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
      );

      final map = supplier.toMap();

      expect(map['name'], 'Test Supplier');
      expect(map['phone'], '+1234567890');
      expect(map.containsKey('email'), true); // email is null but key exists
      expect(map.containsKey('address'), true); // address is null but key exists
      expect(map.containsKey('outstanding'), true); // outstanding is 0.0 but key exists
      expect(map.containsKey('createdAt'), true); // createdAt is set
      expect(map.containsKey('updatedAt'), true); // updatedAt is set
    });

    test('Supplier fromMap conversion', () {
      final timestamp = Timestamp.now();
      
      final map = {
        'name': 'Test Supplier',
        'phone': '+1234567890',
        'email': 'test@supplier.com',
        'address': '123 Test Street, City',
        'outstanding': 1000.0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      final supplier = Supplier.fromMap(map, 'test-id');

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.email, 'test@supplier.com');
      expect(supplier.address, '123 Test Street, City');
      expect(supplier.outstanding, 1000.0);
      expect(supplier.createdAt, timestamp.toDate());
      expect(supplier.updatedAt, timestamp.toDate());
    });

    test('Supplier fromMap conversion with null optional fields', () {
      final map = {
        'name': 'Test Supplier',
        'phone': '+1234567890',
        'outstanding': 1000.0,
      };

      final supplier = Supplier.fromMap(map, 'test-id');

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.email, isNull);
      expect(supplier.address, isNull);
      expect(supplier.outstanding, 1000.0);
      expect(supplier.createdAt, isA<DateTime>());
      expect(supplier.updatedAt, isA<DateTime>());
    });

    test('Supplier fromMap with null values in map', () {
      final map = {
        'name': null,
        'phone': null,
        'email': null,
        'address': null,
        'outstanding': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final supplier = Supplier.fromMap(map, 'test-id');

      expect(supplier.id, 'test-id');
      expect(supplier.name, ''); // null safety fallback
      expect(supplier.phone, ''); // null safety fallback
      expect(supplier.email, isNull);
      expect(supplier.address, isNull);
      expect(supplier.outstanding, 0.0); // null safety fallback
      expect(supplier.createdAt, isA<DateTime>());
      expect(supplier.updatedAt, isA<DateTime>());
    });

    test('Supplier fromMap with numeric string values', () {
      final map = {
        'name': 'Test Supplier',
        'phone': '+1234567890',
        'outstanding': '1000.50',
      };

      final supplier = Supplier.fromMap(map, 'test-id');

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.outstanding, 1000.50);
    });

    test('Supplier fromMap with integer values', () {
      final map = {
        'name': 'Test Supplier',
        'phone': '+1234567890',
        'outstanding': 1000,
      };

      final supplier = Supplier.fromMap(map, 'test-id');

      expect(supplier.id, 'test-id');
      expect(supplier.name, 'Test Supplier');
      expect(supplier.phone, '+1234567890');
      expect(supplier.outstanding, 1000.0);
    });

    test('Supplier creation with negative outstanding', () {
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
        outstanding: -500.0, // Supplier is owed money
      );

      expect(supplier.outstanding, -500.0);
    });

    test('Supplier creation with zero outstanding', () {
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
        outstanding: 0.0,
      );

      expect(supplier.outstanding, 0.0);
    });

    test('Supplier creation with large outstanding', () {
      final supplier = Supplier(
        id: 'test-id',
        name: 'Test Supplier',
        phone: '+1234567890',
        outstanding: 999999.99,
      );

      expect(supplier.outstanding, 999999.99);
    });
  });
}
