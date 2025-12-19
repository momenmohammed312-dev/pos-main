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
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final productsFromDb = await DbHelper.instance.getProducts();
      setState(() {
        widget.products.clear();
        widget.products.addAll(productsFromDb);
      });
    } catch (e) {
      print('Error loading products in OrderPageEditor: $e');
    }
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
        backgroundColor: Colors.white,
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController, 
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController, 
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ), 
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController, 
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), 
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
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
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue.shade600),
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
                        backgroundColor: Colors.white,
                        title: const Text(
                          'Edit Product',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _nameController, 
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _priceController, 
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                              ), 
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _categoryController, 
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(), 
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
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
                            }, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save'),
                          ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit Products'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
        child: Column(
          children: [
            // Top navigation row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProducts,
                  tooltip: 'Refresh Products',
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddProductDialog,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search products',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: isMobile ? 8 : 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 16),
            // Products grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cross = isMobile ? 2 : (width < 900 ? 3 : 4);
                  return GridView.builder(
                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: isMobile ? 8 : 12,
                      mainAxisSpacing: isMobile ? 8 : 12,
                    ),
                    itemCount: widget.products.length,
                    itemBuilder: (context, i) {
                      final p = widget.products[i];
                      final searchQuery = _searchController.text.toLowerCase().trim();
                      if (searchQuery.isNotEmpty && 
                          !p.name.toLowerCase().contains(searchQuery) &&
                          !(p.category?.toLowerCase().contains(searchQuery) ?? false)) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        elevation: isMobile ? 2 : 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: InkWell(
                          onTap: () => _showEditDeleteMenu(i),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.category != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p.category!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isMobile ? 10 : 12,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  '${p.price.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
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
