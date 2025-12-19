import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_page_editor.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'inventory_control_screen.dart';
import 'profile_screen.dart';
import 'cashbox_screen.dart';
import 'supplier_screen.dart';
import 'sales_details_screen.dart';
import 'comprehensive_sales_screen.dart';
import 'firebase_sync_screen.dart';
import '../../models/product.dart';
import '../../data/db_helper.dart';
// Product model is imported from lib/models/product.dart

// Helper function to detect if screen is mobile
bool isScreenMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 800;
}

// ----------------- ProductsScreen -----------------
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with WidgetsBindingObserver {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<OrderLine> orderItems = [];
  String _searchQuery = '';
  String _currentUser = '';
  String _currentUserRole = '';
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedSupplier;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserAndProducts();
  }

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _loadProducts();
    }
  }

  @override
  void didUpdateWidget(ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when returning to this screen
    _loadProducts();
  }

  Future<void> _loadUserAndProducts() async {
    final sp = await SharedPreferences.getInstance();
    _currentUser = sp.getString('currentUser') ?? '';
    _currentUserRole = sp.getString('userRole') ?? 'cashier';
    await _loadProducts();
    
    // Show customer/supplier selection popup after a short delay
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          print('DEBUG: Showing initial customer/supplier selection popup');
          _showInitialCustomerSupplierSelection();
        }
      });
    }
  }

  Future<void> _loadProducts() async {
    final productsList = await DbHelper.instance.getProducts();
    setState(() {
      _products = productsList;
      _filteredProducts = productsList;
      _checkLowStock();
    });
    
    // Setup real-time Firebase listener
    _setupFirebaseListener();
  }

  // Error popup helper method
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'خطأ',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'موافق',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setupFirebaseListener() {
    try {
      FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
        if (mounted) {
          // Convert Firebase documents to Product objects
          final firebaseProducts = snapshot.docs.map((doc) {
            return Product.fromFirebase(doc.data(), doc.id);
          }).toList();
          
          setState(() {
            _products = firebaseProducts;
            _filteredProducts = firebaseProducts;
            _checkLowStock();
          });
        }
      });
    } catch (e) {
      debugPrint('Firebase listener error: $e');
    }
  }

  void _checkLowStock() {
    final lowStockProducts = _products.where((product) => product.quantity <= 5).toList();
    if (lowStockProducts.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: ${lowStockProducts.length} product(s) are low on stock (≤5 items)'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Filter to show only low stock products
              _searchController.text = '';
              setState(() {});
            },
          ),
        ),
      );
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

  Future<void> _finalizeSaleWithPayment(String paymentMethod) async {
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
        'paymentMethod': paymentMethod, // Add payment method to the invoice
      });
    });

    await _loadProducts();

    if (!mounted) return;
    setState(() => orderItems.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale completed with $paymentMethod')),
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

  // Show payment method selection dialog directly
  void _showPaymentMethodDialog() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          String selectedPaymentMethod = 'Cash';
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.45,
              constraints: const BoxConstraints(maxWidth: 550, minWidth: 400),
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Select Payment Method',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade50, Colors.grey.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.shopping_cart,
                                          color: Colors.blue.shade600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Order Items',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${orderItems.length}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Colors.grey),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.attach_money,
                                          color: Colors.green.shade600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Total Amount',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${orderTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Payment Methods Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.credit_card,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Choose Payment Method',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Payment Method Cards
                        Column(
                          children: [
                            _buildEnhancedPaymentOption(
                              title: 'Cash',
                              subtitle: 'Pay with cash',
                              icon: Icons.money,
                              color: Colors.green,
                              value: 'Cash',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentMethod = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedPaymentOption(
                              title: 'Card',
                              subtitle: 'Credit/Debit card',
                              icon: Icons.credit_card,
                              color: Colors.blue,
                              value: 'Card',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentMethod = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedPaymentOption(
                              title: 'Mobile Wallet',
                              subtitle: 'Mobile payment',
                              icon: Icons.phone_android,
                              color: Colors.purple,
                              value: 'Mobile Wallet',
                              groupValue: selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentMethod = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade400),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await _finalizeSaleWithPayment(selectedPaymentMethod);
                                      _showPrintPreviewAfterPayment();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error processing payment: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle, size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Process Payment',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show print preview after successful payment (simplified version)
  void _showPrintPreviewAfterPayment() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.receipt, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Success message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Payment processed successfully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${orderTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Show full print preview with receipt
                        _showPrintPreview();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Print Receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show print preview dialog with receipt and payment methods
  void _showPrintPreview() {
    final double orderTotal = orderItems.fold(0.0, (sum, ol) => sum + (ol.product?.price ?? 0) * (ol.quantity ?? 0));
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          String selectedPaymentMethod = 'Cash';
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: isScreenMobile(context) ? MediaQuery.of(context).size.width * 0.9 : 450,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${orderTotal.toStringAsFixed(2)} EGP',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Items
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Items',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...orderItems.map((ol) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${ol.product?.name ?? 'Unknown'} x${ol.quantity ?? 0}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        '${((ol.product?.price ?? 0) * (ol.quantity ?? 0)).toStringAsFixed(2)} EGP',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${orderTotal.toStringAsFixed(2)} EGP',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Payment Methods
                          Text(
                            'Select Payment Method',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Payment Method Cards
                          Column(
                            children: [
                              _buildPaymentOption(
                                context,
                                title: 'Cash',
                                icon: Icons.money,
                                value: 'Cash',
                                groupValue: selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentOption(
                                context,
                                title: 'Card',
                                icon: Icons.credit_card,
                                value: 'Card',
                                groupValue: selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentOption(
                                context,
                                title: 'Mobile Wallet',
                                icon: Icons.phone_android,
                                value: 'Mobile Wallet',
                                groupValue: selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!isScreenMobile(context) && _currentUserRole == 'admin')
                          Expanded(
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Print & Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (!isScreenMobile(context) && _currentUserRole == 'admin')
                          const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await _finalizeSaleWithPayment(selectedPaymentMethod);
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving sale: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Complete Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: groupValue == value ? color : Colors.grey.shade300,
            width: groupValue == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: groupValue == value ? color.withOpacity(0.1) : Colors.white,
          boxShadow: [
            if (groupValue == value)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: groupValue == value 
                    ? color.withOpacity(0.2) 
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: groupValue == value ? color : color.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: groupValue == value ? color : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: groupValue == value 
                          ? color.withOpacity(0.8) 
                          : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: groupValue == value ? color : Colors.grey.shade400,
                  width: 2,
                ),
                color: groupValue == value ? color : Colors.transparent,
              ),
              child: groupValue == value
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade800,
              ),
            ),
          ],
        ),
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
                      _showPaymentMethodDialog();
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
                            _showPaymentMethodDialog();
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double screenHeight = constraints.maxHeight;
            bool mobile = isScreenMobile(context);

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
              horizontal: mobile ? 16.0 : screenWidth * 0.015,
              vertical: mobile ? 12.0 : screenHeight * 0.02,
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
                              } else if (value == 'manage_users') {
                                await _showManageUsersDialog();
                              } else if (value == 'supplier_screen') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SupplierScreen()),
                                );
                              } else if (value == 'sales_details') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SalesDetailsScreen()),
                                );
                              } else if (value == 'comprehensive_sales') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ComprehensiveSalesScreen()),
                                );
                              } else if (value == 'edit_customer_supplier') {
                                await _showEditCustomerSupplierDialog();
                              } else if (value == 'firebase_sync') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FirebaseSyncScreen()),
                                );
                              } else if (value == 'manage_customers') {
                                await _showManageCustomersDialog();
                              } else if (value == 'manage_suppliers') {
                                await _showManageSuppliersDialog();
                              } else if (value == 'select_customer') {
                                await _showSelectCustomerDialog();
                              } else if (value == 'select_supplier') {
                                await _showSelectSupplierDialog();
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
                                  const PopupMenuItem(value: 'manage_users', child: Text('Manage Users')),
                                  const PopupMenuItem(value: 'supplier_screen', child: Text('Supplier Management')),
                                  const PopupMenuItem(value: 'manage_customers', child: Text('Manage Customers')),
                                  const PopupMenuItem(value: 'manage_suppliers', child: Text('Manage Suppliers')),
                                  const PopupMenuItem(value: 'firebase_sync', child: Text('Firebase Sync')),
                                  const PopupMenuItem(value: 'reports', child: Text('Reports')),
                                  const PopupMenuItem(value: 'inventory', child: Text('Inventory Control')),
                                  const PopupMenuItem(value: 'cashbox', child: Text('Cashbox')),
                                  const PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                ]);
                              } else if (_currentUserRole == 'cashier') {
                                // Cashier can access basic functions and edit
                                items.addAll([
                                  const PopupMenuItem(value: 'select_customer', child: Text('Select Customer')),
                                  const PopupMenuItem(value: 'select_supplier', child: Text('Select Supplier')),
                                  const PopupMenuItem(value: 'add_product', child: Text('Add Product')),
                                  const PopupMenuItem(value: 'edit_price', child: Text('Edit Prices')),
                                  const PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                  const PopupMenuItem(value: 'sales_details', child: Text('Sales Details')),
                                  const PopupMenuItem(value: 'comprehensive_sales', child: Text('Comprehensive Sales')),
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
                                        onPressed: () => setState(() {
                                          _searchController.clear();
                                          _filteredProducts = _products;
                                        }),
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                    setState(() {
                                      final query = value.toLowerCase();
                                      _filteredProducts = _products.where((product) =>
                                        product.name.toLowerCase().contains(query) ||
                                        (product.category?.toLowerCase().contains(query) ?? false) ||
                                        (product.description?.toLowerCase().contains(query) ?? false)
                                      ).toList();
                                    });
                                  },
                                  onSubmitted: (value) {
                                    if (value.isEmpty) {
                                      _showErrorPopup('يرجى إدخال اسم منتج للبحث');
                                    }
                                  },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Selected Customer/Supplier Display
                      if (_selectedCustomer != null || _selectedSupplier != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _selectedCustomer != null ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedCustomer != null ? Colors.green.shade300 : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedCustomer != null ? Icons.person : Icons.inventory,
                                color: _selectedCustomer != null ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCustomer != null 
                                    ? 'Customer: ${_selectedCustomer!['name']}'
                                    : 'Supplier: ${_selectedSupplier!['name']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCustomer != null ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedCustomer = null;
                                    _selectedSupplier = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      // Quick Add Customer/Supplier Buttons (for admin)
                      if (_currentUserRole == 'admin')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showQuickAddCustomerDialog,
                                icon: const Icon(Icons.person_add, size: 20),
                                label: const Text('Quick Add Customer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade100,
                                  foregroundColor: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showQuickAddSupplierDialog,
                                icon: const Icon(Icons.inventory_2, size: 20),
                                label: const Text('Quick Add Supplier'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade700,
                                ),
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
                          child: _products.isEmpty
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
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
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
                                            if (_currentUserRole == 'admin')
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.blue.shade600,
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  // Show quantity edit dialog for this product
                                                  await _showEditQuantityDialogForProduct(product);
                                                },
                                                tooltip: 'Edit Quantity',
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.add_shopping_cart,
                                                color: Colors.green.shade600,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  final idx = orderItems.indexWhere((ol) => ol.product?.name == product.name);
                                                  if (idx >= 0) {
                                                    final currentQuantity = orderItems[idx].quantity ?? 0;
                                                    if (currentQuantity < 0) {
                                                      _showErrorPopup('الكمية الحالية غير صالحة');
                                                      return;
                                                    }
                                                    orderItems[idx].quantity = currentQuantity + 1;
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
                                              tooltip: 'Add to Cart',
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
                                    } else if (value == 'Edit_Customers_or_Suppliers') {
                                      await _showEditCustomerSupplierDialog();
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
                                        const PopupMenuItem(value: 'manage_customers', child: Text('Manage Customers')),
                                        const PopupMenuItem(value: 'manage_suppliers', child: Text('Manage Suppliers')),
                                        const PopupMenuItem(value: 'firebase_sync', child: Text('Firebase Sync')),
                                        const PopupMenuItem(value: 'reports', child: Text('Reports')),
                                        const PopupMenuItem(value: 'inventory', child: Text('Inventory Control')),
                                        const PopupMenuItem(value: 'cashbox', child: Text('Cashbox')),
                                        const PopupMenuItem(value: 'edite', child: Text('Edit Items')),
                                      ]);
                                    } else if (_currentUserRole == 'cashier') {
                                      // Cashier can only access basic functions
                                      items.addAll([
                                        const PopupMenuItem(value: 'select_customer', child: Text('Select Customer')),
                                        const PopupMenuItem(value: 'select_supplier', child: Text('Select Supplier')),
                                        const PopupMenuItem(value: 'add_product', child: Text('Add Product')),
                                        const PopupMenuItem(value: 'edit_price', child: Text('Edit Prices')),
                                        const PopupMenuItem(value: 'sales_details', child: Text('Sales Details')),
                                        const PopupMenuItem(value: 'comprehensive_sales', child: Text('Comprehensive Sales')),
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
                                              onPressed: () => setState(() {
                                                _searchController.clear();
                                                _filteredProducts = _products;
                                              }),
                                            )
                                          : null,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        final query = value.toLowerCase();
                                        _filteredProducts = _products.where((product) =>
                                          product.name.toLowerCase().contains(query) ||
                                          (product.category?.toLowerCase().contains(query) ?? false) ||
                                          (product.description?.toLowerCase().contains(query) ?? false)
                                        ).toList();
                                      });
                                    },
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
                                  child: _products.isEmpty
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
                                          itemCount: _filteredProducts.length,
                                          itemBuilder: (context, index) {
                                            final product = _filteredProducts[index];
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
                                                      onTap: () async {
                                                        // Check if customer or supplier is selected
                                                        if (_selectedCustomer == null && _selectedSupplier == null) {
                                                          await _showCustomerSupplierSelectionDialog();
                                                          return;
                                                        }
                                                        
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
                                                              content: Text('${product.name} added to cart${_selectedCustomer != null ? ' for ${_selectedCustomer!['name']}' : _selectedSupplier != null ? ' from ${_selectedSupplier!['name']}' : ''}'),
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
                      if (!isScreenMobile(context)) _buildDesktopPaymentPanel(),
                    ],
                  ),
          );
        },
      ),
      ),
    );
  }

  Future<void> _showEditQuantityDialogForProduct(Product product) async {
    final TextEditingController quantityController = TextEditingController(text: product.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Quantity - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${product.quantity}'),
            const SizedBox(height: 16),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity != null && newQuantity >= 0) {
                try {
                  await DbHelper.instance.updateProductQuantity(
                    product.id.toString(),
                    newQuantity,
                  );
                  
                  // Refresh the products list
                  await _loadProducts();
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Quantity updated for ${product.name}')),
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
            },
            child: const Text('Update'),
          ),
        ],
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

  // Customer management methods
  Future<void> _showManageCustomersDialog() async {
    final customers = await DbHelper.instance.getAllCustomers();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Customers'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                // Add new customer button
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomerDialog(setState),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Customer'),
                ),
                const SizedBox(height: 10),
                // Customers list
                Expanded(
                  child: ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        child: ListTile(
                          title: Text(customer['name']),
                          subtitle: Text('Phone: ${customer['phone']}\nBalance: ${customer['balance']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditCustomerDialog(customer, setState),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCustomer(customer['id'], setState),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCustomerDialog(StateSetter setState) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final balanceController = TextEditingController();
    final creditController = TextEditingController();
    final debtController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.insertCustomer({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': double.tryParse(balanceController.text) ?? 0.0,
                'credit': double.tryParse(creditController.text) ?? 0.0,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _showManageCustomersDialog(); // Refresh dialog
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCustomerDialog(Map<String, dynamic> customer, StateSetter setState) async {
    final nameController = TextEditingController(text: customer['name']);
    final phoneController = TextEditingController(text: customer['phone']);
    final emailController = TextEditingController(text: customer['email']);
    final balanceController = TextEditingController(text: customer['balance'].toString());
    final creditController = TextEditingController(text: customer['credit'].toString());
    final debtController = TextEditingController(text: customer['debt'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.updateCustomer({
                'id': customer['id'],
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': double.tryParse(balanceController.text) ?? 0.0,
                'credit': double.tryParse(creditController.text) ?? 0.0,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _showManageCustomersDialog(); // Refresh dialog
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(int id, StateSetter setState) async {
    await DbHelper.instance.deleteCustomer(id);
    _showManageCustomersDialog(); // Refresh dialog
  }

  // Supplier management methods
  Future<void> _showManageSuppliersDialog() async {
    final suppliers = await DbHelper.instance.getAllSuppliers();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Suppliers'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                // Add new supplier button
                ElevatedButton.icon(
                  onPressed: () => _showAddSupplierDialog(setState),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Supplier'),
                ),
                const SizedBox(height: 10),
                // Suppliers list
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return Card(
                        child: ListTile(
                          title: Text(supplier['name']),
                          subtitle: Text('Phone: ${supplier['phone']}\nBalance: ${supplier['balance']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditSupplierDialog(supplier, setState),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSupplier(supplier['id'], setState),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSupplierDialog(StateSetter setState) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final balanceController = TextEditingController();
    final creditController = TextEditingController();
    final debtController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.insertSupplier({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': double.tryParse(balanceController.text) ?? 0.0,
                'credit': double.tryParse(creditController.text) ?? 0.0,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _showManageSuppliersDialog(); // Refresh dialog
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSupplierDialog(Map<String, dynamic> supplier, StateSetter setState) async {
    final nameController = TextEditingController(text: supplier['name']);
    final phoneController = TextEditingController(text: supplier['phone']);
    final emailController = TextEditingController(text: supplier['email']);
    final balanceController = TextEditingController(text: supplier['balance'].toString());
    final creditController = TextEditingController(text: supplier['credit'].toString());
    final debtController = TextEditingController(text: supplier['debt'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.updateSupplier({
                'id': supplier['id'],
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': double.tryParse(balanceController.text) ?? 0.0,
                'credit': double.tryParse(creditController.text) ?? 0.0,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _showManageSuppliersDialog(); // Refresh dialog
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(int id, StateSetter setState) async {
    await DbHelper.instance.deleteSupplier(id);
    _showManageSuppliersDialog(); // Refresh dialog
  }

  // Customer/Supplier selection dialog
  Future<void> _showCustomerSupplierSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer or Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select a customer or supplier before adding products to the order.'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSelectCustomerDialog();
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('Select Customer'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSelectSupplierDialog();
                  },
                  icon: const Icon(Icons.inventory),
                  label: const Text('Select Supplier'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Customer selection dialog for cashier
  Future<void> _showSelectCustomerDialog() async {
    final customers = await DbHelper.instance.getAllCustomers();
    
    if (customers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customers Available'),
          content: const Text('There are no customers in the system. Please ask an admin to add customers first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                child: ListTile(
                  title: Text(customer['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${customer['phone']}'),
                      Text('Balance: ${customer['balance']}'),
                      Text('Credit: ${customer['credit']}'),
                      Text('Debt: ${customer['debt']}'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _selectedSupplier = null; // Clear supplier when customer is selected
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Customer ${customer['name']} selected')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Supplier selection dialog for cashier
  Future<void> _showSelectSupplierDialog() async {
    final suppliers = await DbHelper.instance.getAllSuppliers();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Supplier'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return Card(
                child: ListTile(
                  title: Text(supplier['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${supplier['phone']}'),
                      Text('Balance: ${supplier['balance']}'),
                      Text('Credit: ${supplier['credit']}'),
                      Text('Debt: ${supplier['debt']}'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSupplier = supplier;
                      _selectedCustomer = null; // Clear customer when supplier is selected
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Supplier ${supplier['name']} selected')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // User management methods
  Future<void> _showManageUsersDialog() async {
    final users = await DbHelper.instance.getAllUsers();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Users'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                // Add new user button
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(setState),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New User'),
                ),
                const SizedBox(height: 10),
                // Users list
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: ListTile(
                          title: Text(user['name']),
                          subtitle: Text('Role: ${user['role']}\nUsername: ${user['username']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditUserDialog(user, setState),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user['id'], setState),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddUserDialog(StateSetter setState) async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final pinController = TextEditingController();
    String selectedRole = 'cashier';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Add New User'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                TextField(controller: pinController, decoration: const InputDecoration(labelText: 'PIN'), obscureText: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  ],
                  onChanged: (value) {
                    dialogSetState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await DbHelper.instance.insertUser({
                  'name': nameController.text,
                  'username': usernameController.text,
                  'pin': pinController.text,
                  'role': selectedRole,
                });
                Navigator.pop(context);
                _showManageUsersDialog(); // Refresh dialog
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user, StateSetter setState) async {
    final nameController = TextEditingController(text: user['name']);
    final usernameController = TextEditingController(text: user['username']);
    final pinController = TextEditingController(text: user['pin']);
    String selectedRole = user['role'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Edit User'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                TextField(controller: pinController, decoration: const InputDecoration(labelText: 'PIN'), obscureText: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  ],
                  onChanged: (value) {
                    dialogSetState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await DbHelper.instance.updateUser({
                  'id': user['id'],
                  'name': nameController.text,
                  'username': usernameController.text,
                  'pin': pinController.text,
                  'role': selectedRole,
                });
                Navigator.pop(context);
                _showManageUsersDialog(); // Refresh dialog
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(int id, StateSetter setState) async {
    await DbHelper.instance.deleteUser(id);
    _showManageUsersDialog(); // Refresh dialog
  }

  // Quick add customer dialog
  Future<void> _showQuickAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Customer'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.insertCustomer({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': 0.0,
                'credit': 0.0,
                'debt': 0.0,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Quick add supplier dialog
  Future<void> _showQuickAddSupplierDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.insertSupplier({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'balance': 0.0,
                'credit': 0.0,
                'debt': 0.0,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supplier added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show initial customer/supplier selection popup
  Future<void> _showInitialCustomerSupplierSelection() async {
    print('DEBUG: _showInitialCustomerSupplierSelection called');
    showDialog(
      context: context,
      barrierDismissible: false, // User must select
      builder: (context) {
        print('DEBUG: Building dialog');
        return AlertDialog(
          title: const Text('Select Customer or Supplier'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please select a customer or supplier to start adding products:'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSelectCustomerDialog();
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('Select Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSelectSupplierDialog();
                        },
                        icon: const Icon(Icons.inventory),
                        label: const Text('Select Supplier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit Customer/Supplier dialog
  Future<void> _showEditCustomerSupplierDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer or Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose what you want to edit:'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManageCustomersDialog();
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Edit Customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManageSuppliersDialog();
                      },
                      icon: const Icon(Icons.inventory),
                      label: const Text('Edit Supplier'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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