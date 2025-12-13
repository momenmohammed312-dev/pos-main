import 'package:flutter/material.dart';
import 'order_page_editor.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import '../../models/product.dart';
import '../../data/db_helper.dart';
// Product model is imported from lib/models/product.dart

// Helper function to detect if screen is mobile
bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

// ----------------- ProductsScreen -----------------
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // runtime list of products
  final List<Product> products = [];
  // current order items (with quantity)
  final List<OrderLine> orderItems = [];
  final List<PopupMenuButton> popupMenuButton = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _searchController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final dbHelper = DbHelper.instance;
      final productList = await dbHelper.queryAllProducts();
      
      setState(() {
        products.clear();
        products.addAll(productList);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // show dialog to add product
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // just close without saving
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // validate minimal (name not empty)
                final name = _nameController.text.trim();
                final priceText = _priceController.text.trim();
                final category = _categoryController.text.trim();

                if (name.isEmpty) {
                  // simple feedback (you can improve later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter product name')),
                  );
                  return;
                }

                final price = double.tryParse(priceText) ?? 0.0;

                if (price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price must be greater than 0')),
                  );
                  return;
                }

                final newProduct = Product(name: name, price: price, category: category, cost: 0.0, quantity: 0);

                try {
                  await DbHelper.instance.insertProduct(newProduct);
                  await _loadProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product saved')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving product: $e')),
                  );
                }

                // clear fields and close dialog
                _nameController.clear();
                _priceController.clear();
                _categoryController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show print preview dialog with receipt
  void _showPrintPreview() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + ol.product.price * ol.quantity);
    
    final receiptLines = [
      '========== RECEIPT ==========',
      DateTime.now().toString(),
      '================================',
      ...orderItems.map((ol) => '${ol.product.name}\n  ${ol.quantity}x ${ol.product.price.toStringAsFixed(2)} EGP = ${(ol.product.price * ol.quantity).toStringAsFixed(2)} EGP'),
      '================================',
      'TOTAL: ${orderTotal.toStringAsFixed(2)} EGP',
      'Thank you!',
      '================================',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Print Preview'),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: receiptLines.map((line) => Text(line, style: const TextStyle(fontFamily: 'Courier', fontSize: 12))).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing receipt...')),
              );
              setState(() => orderItems.clear());
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  // Desktop payment panel (right side on large screens)
  Widget _buildDesktopPaymentPanel() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + ol.product.price * ol.quantity);
    
    return Container(
      width: 350,
      child: Column(
        children: [
          // Title
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.8),
            ),
            child: const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Order items list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.8),
              ),
              child: orderItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No items yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final ol = orderItems[index];
                        return ListTile(
                          title: Text(ol.product.name),
                          subtitle: Text('${ol.product.price.toStringAsFixed(2)} EGP'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    if (ol.quantity > 1) {
                                      ol.quantity -= 1;
                                    } else {
                                      orderItems.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text('${ol.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    ol.quantity += 1;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    orderItems.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Total & Pay button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${orderTotal.toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(217, 217, 217, 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(150, 50),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (orderItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No items to print')),
                        );
                        return;
                      }
                      _showPrintPreview();
                    },
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile payment button (bottom sheet on small screens)
  Widget _buildMobilePaymentButton() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + ol.product.price * ol.quantity);
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // Show order summary bottom sheet
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...orderItems.map((ol) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${ol.product.name} × ${ol.quantity}'),
                          Text('${(ol.product.price * ol.quantity).toStringAsFixed(2)} EGP'),
                        ],
                      ),
                    )),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${orderTotal.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        backgroundColor: Colors.black87,
                      ),
                      onPressed: () {
                        if (orderItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No items to print')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _showPrintPreview();
                      },
                      child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text(
            'Checkout',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          bool mobile = isMobile(context);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenHeight * 0.03,
            ),
            child: mobile
                // ========== MOBILE LAYOUT ==========
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menu + Search Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                              size: 28,
                            ),
                            onSelected: (value) async {
                              if (value == 'edite') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OrderPageEditor(products: products)),
                                );
                                setState(() {});
                              } else if (value == 'settings') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                              } else if (value == 'reports') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'settings', child: Text('Settings')),
                              PopupMenuItem(value: 'profile', child: Text('Profile')),
                              PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                              PopupMenuItem(value: 'reports', child: Text('Reports')),
                            ],
                          ),
                          Container(
                            width: screenWidth * 0.7,
                            height: screenHeight * 0.05,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: const Color.fromARGB(199, 207, 205, 205),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, color: Colors.grey),
                                        onPressed: () => setState(() => _searchController.clear()),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Products grid (mobile)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(210, 166, 166, 166).withValues(alpha: 0.6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          onPressed: _showAddProductDialog,
                                          child: const Icon(Icons.add, size: 32),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('No products yet', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      if (_searchController.text.isNotEmpty) {
                                        final query = _searchController.text.toLowerCase();
                                        if (!product.name.toLowerCase().contains(query) &&
                                            !(product.category?.toLowerCase().contains(query) ?? false)) {
                                          return const SizedBox.shrink();
                                        }
                                      }
                                      return Card(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              final idx = orderItems.indexWhere((ol) => ol.product.name == product.name);
                                              if (idx >= 0) {
                                                orderItems[idx].quantity += 1;
                                              } else {
                                                orderItems.add(OrderLine(product: product, quantity: 1));
                                              }
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${product.name} added'), duration: const Duration(seconds: 1)),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('${product.price.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      _buildMobilePaymentButton(),
                    ],
                  )
                // ========== DESKTOP LAYOUT ==========
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menu + Search Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PopupMenuButton(
                                  icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                                  onSelected: (value) async {
                                    if (value == 'edite') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => OrderPageEditor(products: products)),
                                      );
                                      setState(() {});
                                    } else if (value == 'settings') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                      );
                                    } else if (value == 'reports') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ReportsScreen()),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                                    PopupMenuItem(value: 'profile', child: Text('Profile')),
                                    PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                    PopupMenuItem(value: 'reports', child: Text('Reports')),
                                  ],
                                ),
                                Container(
                                  height: screenHeight * 0.05,
                                  width: screenWidth * 0.49,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: const Color.fromARGB(199, 207, 205, 205),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search Products',
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () => setState(() => _searchController.clear()),
                                            )
                                          : null,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Products grid (desktop)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: products.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color.fromARGB(210, 166, 166, 166).withValues(alpha: 0.6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  fixedSize: const Size(80, 80),
                                                ),
                                                onPressed: _showAddProductDialog,
                                                child: const Icon(Icons.add, size: 32),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text('No products yet', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        )
                                      : GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            childAspectRatio: 1.5,
                                          ),
                                          itemCount: products.length,
                                          itemBuilder: (context, index) {
                                            final product = products[index];
                                            if (_searchController.text.isNotEmpty) {
                                              final query = _searchController.text.toLowerCase();
                                              if (!product.name.toLowerCase().contains(query) &&
                                                  !(product.category?.toLowerCase().contains(query) ?? false)) {
                                                return const SizedBox.shrink();
                                              }
                                            }
                                            return Card(
                                              child: ListTile(
                                                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Text('${product.price.toStringAsFixed(2)} EGP'),
                                                onTap: () {
                                                  setState(() {
                                                    final idx = orderItems.indexWhere((ol) => ol.product.name == product.name);
                                                    if (idx >= 0) {
                                                      orderItems[idx].quantity += 1;
                                                    } else {
                                                      orderItems.add(OrderLine(product: product, quantity: 1));
                                                    }
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('${product.name} added'), duration: const Duration(seconds: 1)),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildDesktopPaymentPanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // kept empty constructor removed (not needed)

}

// Order line model (top-level) to track product + quantity in the current order
class OrderLine {
  final Product product;
  int quantity;
  OrderLine({required this.product, this.quantity = 1});
}