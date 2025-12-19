import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/models/customer.dart';

void main() {
  group('Customer Model Tests', () {
    test('Customer creation with all fields', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
        balance: 100.0,
        totalPaid: 500.0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 100.0);
      expect(customer.totalPaid, 500.0);
      expect(customer.createdAt, createdAt);
      expect(customer.updatedAt, updatedAt);
    });

    test('Customer creation with default values', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
      );

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 0.0); // default
      expect(customer.totalPaid, 0.0); // default
      expect(customer.createdAt, isA<DateTime>());
      expect(customer.updatedAt, isA<DateTime>());
    });

    test('Customer toMap conversion', () {
      final createdAt = DateTime.now();
      final updatedAt = DateTime.now();
      
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
        balance: 100.0,
        totalPaid: 500.0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = customer.toMap();

      expect(map['name'], 'John Doe');
      expect(map['phone'], '+1234567890');
      expect(map['balance'], 100.0);
      expect(map['totalPaid'], 500.0);
      expect(map['createdAt'], createdAt);
      expect(map['updatedAt'], updatedAt);
      expect(map.containsKey('id'), false); // id is not included in toMap
    });

    test('Customer fromMap conversion with Timestamps', () {
      final timestamp = Timestamp.now();
      
      final map = {
        'name': 'John Doe',
        'phone': '+1234567890',
        'balance': 100.0,
        'totalPaid': 500.0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 100.0);
      expect(customer.totalPaid, 500.0);
      expect(customer.createdAt, timestamp.toDate());
      expect(customer.updatedAt, timestamp.toDate());
    });

    test('Customer fromMap conversion with null Timestamps', () {
      final map = {
        'name': 'John Doe',
        'phone': '+1234567890',
        'balance': 100.0,
        'totalPaid': 500.0,
        'createdAt': null,
        'updatedAt': null,
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 100.0);
      expect(customer.totalPaid, 500.0);
      expect(customer.createdAt, isA<DateTime>());
      expect(customer.updatedAt, isA<DateTime>());
    });

    test('Customer fromMap conversion with missing fields', () {
      final map = {
        'name': 'John Doe',
        'phone': '+1234567890',
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 0.0); // default
      expect(customer.totalPaid, 0.0); // default
      expect(customer.createdAt, isA<DateTime>());
      expect(customer.updatedAt, isA<DateTime>());
    });

    test('Customer fromMap with null values', () {
      final map = {
        'name': null,
        'phone': null,
        'balance': null,
        'totalPaid': null,
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, ''); // null safety fallback
      expect(customer.phone, ''); // null safety fallback
      expect(customer.balance, 0.0); // null safety fallback
      expect(customer.totalPaid, 0.0); // null safety fallback
      expect(customer.createdAt, isA<DateTime>());
      expect(customer.updatedAt, isA<DateTime>());
    });

    test('Customer fromMap with numeric string values', () {
      final map = {
        'name': 'John Doe',
        'phone': '+1234567890',
        'balance': '100.5',
        'totalPaid': '500.25',
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 100.5);
      expect(customer.totalPaid, 500.25);
    });

    test('Customer fromMap with integer values', () {
      final map = {
        'name': 'John Doe',
        'phone': '+1234567890',
        'balance': 100,
        'totalPaid': 500,
      };

      final customer = Customer.fromMap(map, 'test-id');

      expect(customer.id, 'test-id');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '+1234567890');
      expect(customer.balance, 100.0);
      expect(customer.totalPaid, 500.0);
    });

    test('Customer creation with negative balance', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
        balance: -50.0, // Customer owes money
        totalPaid: 200.0,
      );

      expect(customer.balance, -50.0);
      expect(customer.totalPaid, 200.0);
    });

    test('Customer creation with zero values', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
        balance: 0.0,
        totalPaid: 0.0,
      );

      expect(customer.balance, 0.0);
      expect(customer.totalPaid, 0.0);
    });

    test('Customer creation with large values', () {
      final customer = Customer(
        id: 'test-id',
        name: 'John Doe',
        phone: '+1234567890',
        balance: 999999.99,
        totalPaid: 999999.99,
      );

      expect(customer.balance, 999999.99);
      expect(customer.totalPaid, 999999.99);
    });
  });
}
