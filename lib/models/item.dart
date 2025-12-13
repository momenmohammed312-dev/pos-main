import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String? barcode;
  final double price;
  final double costPrice;
  final int quantity;
  final int threshold;
  final String? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    this.barcode,
    this.price = 0.0,
    this.costPrice = 0.0,
    this.quantity = 0,
    this.threshold = 0,
    this.supplierId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Item.fromMap(Map<String, dynamic> map, String id) {
    return Item(
      id: id,
      name: map['name'] ?? '',
      barcode: map['barcode'],
      price: (map['price'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      threshold: (map['threshold'] ?? 0).toInt(),
      supplierId: map['supplierId'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'costPrice': costPrice,
      'quantity': quantity,
      'threshold': threshold,
      'supplierId': supplierId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
