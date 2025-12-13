import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String? id; // required – بقى optional
  final String? customerId;
  final DateTime date;
  final double totalAmount;
  final List<Map<String, dynamic>> items;
  final String status; // paid / partial / unpaid

  Sale({
    this.id,
    this.customerId,
    required this.date,
    required this.totalAmount,
    required this.items,
    this.status = 'unpaid',
  });

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    return Sale(
      id: id,
      customerId: map['customerId'],
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      status: map['status'] ?? 'unpaid',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'date': date,
      'totalAmount': totalAmount,
      'items': items,
      'status': status,
    };
  }
}
