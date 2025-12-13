import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final double balance; // remaining amount customer owes
  final double totalPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
    this.totalPaid = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: map['balance'] is String ? double.tryParse(map['balance'] as String) ?? 0.0 : (map['balance'] ?? 0).toDouble(),
      totalPaid: map['totalPaid'] is String ? double.tryParse(map['totalPaid'] as String) ?? 0.0 : (map['totalPaid'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'balance': balance,
      'totalPaid': totalPaid,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
