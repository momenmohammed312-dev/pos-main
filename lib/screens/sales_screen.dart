// lib/screens/sales_screen.dart

import 'package:flutter/material.dart';
import 'package:pos_disck/models/item.dart';
import '../services/firestore_item_service.dart';
import '../services/firestore_sale_service.dart';
import '../models/sale.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirestoreItemService _itemService = FirestoreItemService();
  final FirestoreSaleService _saleService = FirestoreSaleService();
  
  final Map<String, int> _cart = {}; // itemId -> quantity
  double _total = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
      ),
      body: Row(
        children: [
          Expanded(child: _buildItemsList()),
          const SizedBox(width: 16),
          SizedBox(
            width: 360,
            child: _buildCartPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return StreamBuilder(
      stream: _itemService.streamItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No items available'));
        }

        final items = snapshot.data!;

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemTile(item);
          },
        );
      },
    );
  }

  Widget _buildItemTile(Item item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        'Qty: ${item.quantity} • Price: \$${item.price.toStringAsFixed(2)}',
      ),
      trailing: ElevatedButton(
        onPressed: () => _addToCart(item),
        child: const Text('Add'),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Shopping Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final entry = _cart.entries.elementAt(index);
                    return _buildCartItemTile(entry.key, entry.value);
                  },
                ),
        ),
        _buildCartSummary(),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: _cart.isEmpty ? null : _checkout,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Checkout'),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemTile(String itemId, int quantity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(itemId),
        subtitle: Text('Quantity: $quantity'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              onPressed: () => _removeFromCart(itemId),
            ),
            const SizedBox(width: 8),
            Text('$quantity'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.green,
              onPressed: () => _increaseQuantity(itemId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Item item) {
    if (item.quantity <= 0) {
      _showSnackBar('Item ${item.name} is out of stock');
      return;
    }

    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
      _calculateTotal();
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId] != null) {
        if (_cart[itemId]! > 1) {
          _cart[itemId] = _cart[itemId]! - 1;
        } else {
          _cart.remove(itemId);
        }
        _calculateTotal();
      }
    });
  }

  void _increaseQuantity(String itemId) {
    setState(() {
      if (_cart[itemId] != null) {
        _cart[itemId] = _cart[itemId]! + 1;
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    // TODO: Implement actual price calculation based on item prices
    // For now, using a simple calculation
    _total = _cart.values.length * 10.0;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final sale = Sale(
      date: DateTime.now(),
      totalAmount: _total,
      items: _cart.entries
          .map((entry) => {'itemId': entry.key, 'qty': entry.value})
          .toList(),
      status: 'paid',
    );

    try {
      await _saleService.createSale(sale);
      
      setState(() {
        _cart.clear();
        _total = 0.0;
      });

      if (mounted) {
        _showSnackBar('Sale completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Checkout error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}