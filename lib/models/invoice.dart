import 'product.dart';

class InvoiceLine {
  final int productId;
  final String name;
  final int quantity;
  final double price;

  InvoiceLine({required this.productId, required this.name, required this.quantity, required this.price});

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
      };
}

class Invoice {
  final int? id;
  final DateTime date;
  final List<InvoiceLine> items;
  final double total;
  final String? paymentMethod;

  Invoice({this.id, required this.date, required this.items, required this.total, this.paymentMethod});

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'total': total,
        'paymentMethod': paymentMethod,
      };
}
