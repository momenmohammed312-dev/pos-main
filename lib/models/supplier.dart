// Supplier model
import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double outstanding; // outstanding invoices total
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.outstanding = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Supplier.fromMap(Map<String, dynamic> map, String id) {
    return Supplier(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      outstanding: map['outstanding'] is String ? double.tryParse(map['outstanding'] as String) ?? 0.0 : (map['outstanding'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'outstanding': outstanding,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
