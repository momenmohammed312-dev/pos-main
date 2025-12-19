class Product {
  final String? id;
  final String name;
  final String? barcode;
  final double price;
  final double cost;
  final int quantity;
  final String? category;
  final String? description;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.cost,
    required this.quantity,
    this.category,
    this.description,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'cost': cost,
      'quantity': quantity,
    };
    if (id != null) map['id'] = id;
    if (barcode != null) map['barcode'] = barcode;
    if (category != null) map['category'] = category;
    if (description != null) map['description'] = description;
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id']?.toString(),
        name: m['name'] as String,
        barcode: m['barcode'] as String?,
        price: m['price'] is String ? double.tryParse(m['price'] as String) ?? 0.0 : (m['price'] as num).toDouble(),
        cost: m['cost'] is String ? double.tryParse(m['cost'] as String) ?? 0.0 : (m['cost'] as num?)?.toDouble() ?? 0.0,
        quantity: m['quantity'] is String ? int.tryParse(m['quantity'] as String) ?? 0 : (m['quantity'] as num?)?.toInt() ?? 0,
        category: m['category'] as String?,
        description: m['description'] as String?,
      );

  factory Product.fromFirebase(Map<String, dynamic> data, String documentId) => Product(
        id: documentId,
        name: data['name'] ?? '',
        barcode: data['barcode'],
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        category: data['category'],
        description: data['description'],
      );

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    double? cost,
    int? quantity,
    String? category,
    String? description,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        quantity: quantity ?? this.quantity,
        category: category ?? this.category,
        description: description ?? this.description,
      );
}
