import 'package:flutter/material.dart';
import 'package:pos_disck/models/product.dart';


class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null) ...[
              Text('Barcode: ${product.barcode}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
            ],
            if (product.category != null) ...[
              Text('Category: ${product.category}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
            ],
            Text('Price: ${product.price} EGP', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Cost: ${product.cost} EGP', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Quantity: ${product.quantity}', style: const TextStyle(fontSize: 18)),
            if (product.description != null) ...[
              const SizedBox(height: 10),
              Text('Description: ${product.description}', style: const TextStyle(fontSize: 18)),
            ],
          ],
        ),
      ),
    );
  }
}
