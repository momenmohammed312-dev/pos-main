import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'products_screen.dart';
import '../../models/product.dart';
import '../../data/db_helper.dart';

/// Clean editor page used instead of the corrupted file. Allows Add/Edit/Delete
/// on the shared products list (mutates the list so changes are visible in caller).
class OrderPageEditor extends StatefulWidget {
  final List<Product> products;
  const OrderPageEditor({Key? key, required this.products}) : super(key: key);

  @override
  State<OrderPageEditor> createState() => _OrderPageEditorState();
}

class _OrderPageEditorState extends State<OrderPageEditor> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String _currentUserRole = 'cashier'; // Default to cashier

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'cashier';
    setState(() {
      _currentUserRole = role;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    _nameController.clear();
    _priceController.clear();
    _categoryController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
            final category = _categoryController.text.trim();
            if (name.isEmpty) return;
            // persist to DB and reload
            final newProduct = Product(name: name, price: price, category: category, cost: 0.0, quantity: 0);
            await DbHelper.instance.insertProduct(newProduct);
            final list = await DbHelper.instance.getProducts();
            setState(() {
              widget.products.clear();
              widget.products.addAll(list);
            });
            Navigator.of(ctx).pop();
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _showEditDeleteMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  final p = widget.products[index];
                  _nameController.text = p.name;
                  _priceController.text = p.price.toString();
                  _categoryController.text = p.category ?? '';

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Edit Product'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                          TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                          TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () async {
                          final name = _nameController.text.trim();
                          final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                          final category = _categoryController.text.trim();
                          if (name.isEmpty) return;
                          final current = widget.products[index];
                          final updated = Product(id: current.id, name: name, price: price, category: category, cost: current.cost, quantity: current.quantity);
                          await DbHelper.instance.updateProduct(updated);
                          final list = await DbHelper.instance.getProducts();
                          setState(() {
                            widget.products.clear();
                            widget.products.addAll(list);
                          });
                          Navigator.of(ctx).pop();
                        }, child: const Text('Save')),
                      ],
                    ),
                  );
                },
              ),
              // Only show delete option for admin users
              if (_currentUserRole == 'admin')
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final p = widget.products[index];
                    if (p.id != null) {
                      await DbHelper.instance.deleteProductById(p.id!);
                      final list = await DbHelper.instance.getProducts();
                      setState(() {
                        widget.products.clear();
                        widget.products.addAll(list);
                      });
                    } else {
                      setState(() => widget.products.removeAt(index));
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(title: const Text('Edit Products')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  ProductsScreen()))),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showAddProductDialog),
                Expanded(
                  child: TextField(controller: _searchController, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products'), onChanged: (_) => setState(() {})),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cross = width < 600 ? 2 : 6;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, childAspectRatio: 1.3),
                    itemCount: widget.products.length,
                    itemBuilder: (context, i) {
                      final p = widget.products[i];
                      if (_searchController.text.isNotEmpty && !p.name.toLowerCase().contains(_searchController.text.toLowerCase())) return const SizedBox.shrink();
                      return Card(
                        child: InkWell(
                          onTap: () => _showEditDeleteMenu(i),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${p.price.toStringAsFixed(2)} EGP', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
