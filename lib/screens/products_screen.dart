import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_page_editor.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'inventory_control_screen.dart';
import 'profile_screen.dart';
import 'cashbox_screen.dart';
import '../../models/product.dart';
import '../../data/db_helper.dart';
// Product model is imported from lib/models/product.dart

// Helper function to detect if screen is mobile
bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 800;
}

// ----------------- ProductsScreen -----------------
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<OrderLine> orderItems = [];
  String _searchQuery = '';
  String _currentUser = '';
  String _currentUserRole = '';
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // runtime list of products
  final List<Product> products = [];
  // current order items (with quantity)
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
    _loadUserAndProducts();
  }

  Future<void> _loadUserAndProducts() async {
    final sp = await SharedPreferences.getInstance();
    _currentUser = sp.getString('currentUser') ?? '';
    final user = await DbHelper.instance.getUserByName(_currentUser);
    _currentUserRole = user?['role'] ?? 'cashier';
    await _loadProducts();
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

  Future<void> _printReceiptPdf() async {
    if (orderItems.isEmpty) return;

    final pdf = pw.Document();
    final now = DateTime.now();
    final receiptNumber = now.microsecondsSinceEpoch.toString();
    final orderTotal = orderItems.fold<double>(
      0.0,
      (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('POS System', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Receipt #: $receiptNumber'),
              pw.Text('Date: ${now.toLocal()}'.split('.')[0]),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...orderItems.map(
                (ol) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${ol.product?.name ?? 'Unknown'} x${ol.quantity ?? 0}'),
                    pw.Text('  ${((ol.product?.price ?? 0) * (ol.quantity ?? 0)).toStringAsFixed(2)} EGP'),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${orderTotal.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Thank you!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'POS Receipt',
    );
  }

  Future<void> _finalizeSale() async {
    if (orderItems.isEmpty) return;

    final now = DateTime.now();
    final receiptNumber = now.microsecondsSinceEpoch.toString();
    final orderTotal = orderItems.fold<double>(
      0.0,
      (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0),
    );

    final items = orderItems
        .map(
          (ol) => {
            'productId': ol.product?.id,
            'name': ol.product?.name ?? 'Unknown',
            'qty': ol.quantity ?? 0,
            'price': ol.product?.price ?? 0,
            'total': (ol.product?.price ?? 0) * (ol.quantity ?? 0),
          },
        )
        .toList();

    final db = await DbHelper.instance.database;

    await db.transaction((txn) async {
      // Validate and decrement stock
      for (final ol in orderItems) {
        if (ol.product?.id == null) continue;
        
        final rows = await txn.query(
          DbHelper.tableProducts,
          columns: ['id', 'quantity'],
          where: 'id = ?',
          whereArgs: [ol.product!.id],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw Exception('Product not found: ${ol.product?.name ?? 'Unknown'}');
        }

        final currentQty = (rows.first['quantity'] as num?)?.toInt() ?? 0;
        final newQty = currentQty - (ol.quantity ?? 0);
        if (newQty < 0) {
          throw Exception('Insufficient stock for ${ol.product?.name ?? 'Unknown'}');
        }

        await txn.update(
          DbHelper.tableProducts,
          {'quantity': newQty},
          where: 'id = ?',
          whereArgs: [ol.product!.id],
        );
      }

      await txn.insert(DbHelper.tableInvoices, {
        'receiptNumber': receiptNumber,
        'date': now.toIso8601String(),
        'total': orderTotal,
        'itemsJson': jsonEncode(items),
        'userId': null,
      });
    });

    await _loadProducts();

    if (!mounted) return;
    setState(() => orderItems.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale saved')),
    );
  }

  // show dialog to add product (admin only)
  void _showAddProductDialog() {
    if (_currentUserRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied: Admin only')),
      );
      return;
    }
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
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
    final receiptLines = [
      '========== RECEIPT ==========',
      DateTime.now().toString(),
      '================================',
      ...orderItems.map((ol) => '${ol.product?.name ?? 'Unknown'}\n  ${ol.quantity ?? 0}x ${(ol.product?.price ?? 0).toStringAsFixed(2)} EGP = ${((ol.product?.price ?? 0) * (ol.quantity ?? 0)).toStringAsFixed(2)} EGP'),
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
          if (!isMobile(context) && _currentUserRole == 'admin')
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _printReceiptPdf();
                  await _finalizeSale();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error printing/saving sale: $e')),
                  );
                }
              },
              child: const Text('Print & Save'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _finalizeSale();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving sale: $e')),
                );
              }
            },
            child: const Text('Save Only'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPaymentPanel() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
    return SizedBox(
      width: 350,
      child: Column(
        children: [
          // Title
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: const Text(
              'Order Summary',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Items list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
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
                          title: Text(ol.product?.name ?? 'Unknown'),
                          subtitle: Text('${(ol.product?.price ?? 0).toStringAsFixed(2)} EGP'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    if ((ol.quantity ?? 0) > 1) {
                                      ol.quantity = (ol.quantity ?? 0) - 1;
                                    } else {
                                      orderItems.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text('${ol.quantity ?? 0}'),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    ol.quantity = (ol.quantity ?? 0) + 1;
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
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
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
            if (orderItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No items to print')),
              );
              return;
            }
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => DraggableScrollableSheet(
                initialChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (_, controller) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                            Text('${ol.product?.name ?? 'Unknown'} × ${ol.quantity ?? 0}'),
                            Text('${((ol.product?.price ?? 0) * (ol.quantity ?? 0)).toStringAsFixed(2)} EGP'),
                          ],
                        ),
                      )),
                      const Divider(),
                      Text(
                        'Total: ${orderTotal.toStringAsFixed(2)} EGP',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: const Text(
            'Pay Now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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

          final query = _searchController.text.trim().toLowerCase();
          final filteredProducts = query.isEmpty
              ? products
              : products.where((product) {
                  final name = product.name.toLowerCase();
                  final category = (product.category ?? '').toLowerCase();
                  return name.contains(query) || category.contains(query);
                }).toList();

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
                              } else if (value == 'profile') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              } else if (value == 'inventory') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const InventoryControlScreen()),
                                );
                                setState(() {});
                              } else if (value == 'cashbox') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CashboxScreen()),
                                );
                              } else if (value == 'edit_quantity') {
                                await _showEditQuantityDialog();
                              } else if (value == 'add_product') {
                                await _showAddProductDialogForCashier();
                              } else if (value == 'edit_price') {
                                await _showEditPriceDialog();
                              }
                            },
                            itemBuilder: (context) {
                              List<PopupMenuEntry<String>> items = [
                                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                              ];
                              
                              // Add admin-only options
                              if (_currentUserRole == 'admin') {
                                items.addAll([
                                  const PopupMenuItem(value: 'reports', child: Text('Reports')),
                                  const PopupMenuItem(value: 'inventory', child: Text('Inventory Control')),
                                  const PopupMenuItem(value: 'cashbox', child: Text('Cashbox')),
                                  const PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                  const PopupMenuItem(value: 'edit_quantity', child: Text('Edit Quantity')),
                                ]);
                              } else if (_currentUserRole == 'cashier') {
                                // Cashier can only access basic functions
                                items.addAll([
                                  const PopupMenuItem(value: 'add_product', child: Text('Add Product')),
                                  const PopupMenuItem(value: 'edit_price', child: Text('Edit Prices')),
                                ]);
                              }
                              
                              return items;
                            },
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
                      // Products list (mobile)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: products.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade100,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          fixedSize: const Size(80, 80),
                                        ),
                                        onPressed: _showAddProductDialog,
                                        child: const Icon(Icons.add, size: 32, color: Colors.blue),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No products yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      elevation: 1,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${product.price.toStringAsFixed(2)} EGP',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (product.quantity > 0)
                                              Text(
                                                'Stock: ${product.quantity}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_shopping_cart,
                                                color: Colors.green.shade600,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  final idx = orderItems.indexWhere((ol) => ol.product?.name == product.name);
                                                  if (idx >= 0) {
                                                    orderItems[idx].quantity = (orderItems[idx].quantity ?? 0) + 1;
                                                  } else {
                                                    orderItems.add(OrderLine(product: product, quantity: 1));
                                                  }
                                                });
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('${product.name} added to cart'),
                                                      duration: const Duration(seconds: 1),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.info_outline,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text(product.name),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Price: ${product.price.toStringAsFixed(2)} EGP'),
                                                        if (product.category != null) Text('Category: ${product.category}'),
                                                        if (product.description != null && product.description!.isNotEmpty) 
                                                          Text('Description: ${product.description}'),
                                                        Text('Stock: ${product.quantity}'),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: const Text('Close'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
                                    } else if (value == 'profile') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                      );
                                    } else if (value == 'inventory') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const InventoryControlScreen()),
                                      );
                                      setState(() {});
                                    } else if (value == 'cashbox') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CashboxScreen()),
                                      );
                                    } else if (value == 'edit_quantity') {
                                      await _showEditQuantityDialog();
                                    } else if (value == 'add_product') {
                                      await _showAddProductDialogForCashier();
                                    } else if (value == 'edit_price') {
                                      await _showEditPriceDialog();
                                    }
                                  },
                                  itemBuilder: (context) {
                                    List<PopupMenuEntry<String>> items = [
                                      const PopupMenuItem(value: 'settings', child: Text('Settings')),
                                      const PopupMenuItem(value: 'profile', child: Text('Profile')),
                                    ];
                                    
                                    // Add admin-only options
                                    if (_currentUserRole == 'admin') {
                                      items.addAll([
                                        const PopupMenuItem(value: 'reports', child: Text('Reports')),
                                        const PopupMenuItem(value: 'inventory', child: Text('Inventory Control')),
                                        const PopupMenuItem(value: 'cashbox', child: Text('Cashbox')),
                                        const PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                        const PopupMenuItem(value: 'edit_quantity', child: Text('Edit Quantity')),
                                      ]);
                                    } else if (_currentUserRole == 'cashier') {
                                      // Cashier can only access basic functions
                                      items.addAll([
                                        const PopupMenuItem(value: 'add_product', child: Text('Add Product')),
                                        const PopupMenuItem(value: 'edit_price', child: Text('Edit Prices')),
                                      ]);
                                    }
                                    
                                    return items;
                                  },
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
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: products.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade100,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  fixedSize: const Size(100, 100),
                                                ),
                                                onPressed: _showAddProductDialog,
                                                child: const Icon(Icons.add, size: 40, color: Colors.blue),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No products yet',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Add your first product to get started',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: filteredProducts.length,
                                          itemBuilder: (context, index) {
                                            final product = filteredProducts[index];
                                            return Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          final idx = orderItems.indexWhere((ol) => ol.product?.name == product.name);
                                                          if (idx >= 0) {
                                                            orderItems[idx].quantity = (orderItems[idx].quantity ?? 0) + 1;
                                                          } else {
                                                            orderItems.add(OrderLine(product: product, quantity: 1));
                                                          }
                                                        });
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('${product.name} added to cart'),
                                                              duration: const Duration(seconds: 1),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(12),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              product.name,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const Spacer(),
                                                            Text(
                                                              '${product.price.toStringAsFixed(2)} EGP',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.blue.shade700,
                                                              ),
                                                            ),
                                                            if (product.quantity > 0)
                                                              Padding(
                                                                padding: const EdgeInsets.only(top: 4),
                                                                child: Text(
                                                                  'Stock: ${product.quantity}',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  ButtonBar(
                                                    buttonPadding: EdgeInsets.zero,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.info_outline,
                                                          size: 18,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        onPressed: () {
                                                          // Show product details
                                                          showDialog(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              title: Text(product.name),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text('Price: ${product.price.toStringAsFixed(2)} EGP'),
                                                                  if (product.category != null) Text('Category: ${product.category}'),
                                                                  if (product.description != null && product.description!.isNotEmpty) 
                                                                    Text('Description: ${product.description}'),
                                                                  Text('Stock: ${product.quantity}'),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(ctx),
                                                                  child: const Text('Close'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
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
                      if (!isMobile(context)) _buildDesktopPaymentPanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _showEditQuantityDialog() async {
    final TextEditingController quantityController = TextEditingController();
    Product? selectedProduct;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Product Quantity'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product selection dropdown
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProduct,
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text('${product.name} (Current: ${product.quantity})'),
                    );
                  }).toList(),
                  onChanged: (Product? product) {
                    setState(() {
                      selectedProduct = product;
                      if (product != null) {
                        quantityController.text = product.quantity.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Quantity input
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct != null) {
                  final newQuantity = int.tryParse(quantityController.text);
                  if (newQuantity != null && newQuantity >= 0) {
                    try {
                      await DbHelper.instance.updateProductQuantity(
                        selectedProduct!.id.toString(),
                        newQuantity,
                      );
                      
                      // Refresh the products list
                      await _loadProducts();
                      
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Quantity updated for ${selectedProduct!.name}')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating quantity: $e')),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid quantity')),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // show dialog to add product (cashier version)
  Future<void> _showAddProductDialogForCashier() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController barcodeController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Product'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final cost = double.tryParse(costController.text);
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final barcode = barcodeController.text.trim();
              final category = categoryController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isNotEmpty && price != null && price > 0) {
                try {
                  final product = Product(
                    name: name,
                    price: price,
                    cost: cost ?? 0.0,
                    quantity: quantity,
                    barcode: barcode.isEmpty ? null : barcode,
                    category: category.isEmpty ? null : category,
                    description: description.isEmpty ? null : description,
                  );

                  await DbHelper.instance.insertProduct(product);
                  await _loadProducts();

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product "$name" added successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding product: $e')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid name and price')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPriceDialog() async {
    final TextEditingController priceController = TextEditingController();
    Product? selectedProduct;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Product Price'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProduct,
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text('${product.name} (Current: ${product.price.toStringAsFixed(2)} EGP)'),
                    );
                  }).toList(),
                  onChanged: (Product? product) {
                    setState(() {
                      selectedProduct = product;
                      if (product != null) {
                        priceController.text = product.price.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Price',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct != null) {
                  final newPrice = double.tryParse(priceController.text);
                  if (newPrice != null && newPrice > 0) {
                    try {
                      await DbHelper.instance.updateProductPrice(
                        selectedProduct!.id.toString(),
                        newPrice,
                      );
                      
                      await _loadProducts();
                      
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Price updated for ${selectedProduct!.name}')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating price: $e')),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid price')),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // kept empty constructor removed (not needed)

}

// Order line model (top-level) to track product + quantity in the current order
class OrderLine {
  final Product? product;
  int quantity;
  OrderLine({required this.product, this.quantity = 1});
}