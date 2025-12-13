class Product {
  final int? id;
  final String name;
  final double price;
  final String category;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'category': category,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        category: m['category'] as String? ?? '',
      );
}
