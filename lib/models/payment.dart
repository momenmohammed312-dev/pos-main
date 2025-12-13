import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String? customerId;
  final String? supplierId;
  final String? relatedSaleId;
  final double amount;
  final String type; // cash/card/other
  final DateTime date;
  final String? note;

  Payment({
    required this.id,
    this.customerId,
    this.supplierId,
    this.relatedSaleId,
    required this.amount,
    this.type = 'cash',
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'supplierId': supplierId,
      'relatedSaleId': relatedSaleId,
      'amount': amount,
      'type': type,
      'date': date,
      'note': note,
    };
  }
}
