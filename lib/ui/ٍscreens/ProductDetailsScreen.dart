import 'package:flutter/material.dart';
import 'package:pos_disck/Models/product.dart';
import 'package:pos_disck/ui/%D9%8Dscreens/products_screen.dart';


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
            Text('Category: ${product.category}', style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 10),
            Text('Price: ${product.price} EGP', style: const TextStyle(fontSize: 25)),
          ],
        ),
      ),
    );
  }
}
