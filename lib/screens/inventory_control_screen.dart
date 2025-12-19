import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../data/db_helper.dart';
import '../screens/login_screen.dart';

class InventoryControlScreen extends StatefulWidget {
  const InventoryControlScreen({super.key});

  @override
  State<InventoryControlScreen> createState() => _InventoryControlScreenState();
}

class _InventoryControlScreenState extends State<InventoryControlScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String _currentUser = '';
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndProducts();
  }

  Future<void> _loadUserAndProducts() async {
    final sp = await SharedPreferences.getInstance();
    _currentUser = sp.getString('currentUser') ?? '';
    _currentUserRole = sp.getString('userRole') ?? 'cashier';
    if (_currentUserRole != 'admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied: Admin only')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
        return;
      }
    }
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final products = await DbHelper.instance.queryAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String productId, int newQty) async {
    try {
      await DbHelper.instance.updateProductQuantity(productId, newQty);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  void _showEditDialog(Product product) {
    final controller = TextEditingController(text: product.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Quantity: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty == null || newQty < 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter valid quantity')),
                );
                return;
              }
              Navigator.pop(ctx);
              _updateQuantity(product.id!, newQty);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Control (Admin)'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Logged in as: $_currentUser ($_currentUserRole)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text('Price: ${product.price} EGP'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Qty: ${product.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _currentUserRole == 'admin' ? FloatingActionButton(
        onPressed: _loadProducts,
        child: const Icon(Icons.refresh),
      ) : null,
    );
  }
}
