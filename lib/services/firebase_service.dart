import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'error_handler.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Products
  static Future<void> syncProduct(Product product, {BuildContext? context}) async {
    try {
      final docId = product.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('products').doc(docId).set({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'category': product.category,
        'description': product.description,
        'cost': product.cost,
        'barcode': product.barcode,
        'updatedAt': Timestamp.now(),
      });
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة المنتج بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing product: ${product.name}');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة المنتج', context: context);
      }
    }
  }
  
  static Future<void> syncAllProducts(List<Product> products, {BuildContext? context}) async {
    try {
      final batch = _firestore.batch();
      for (final product in products) {
        final docId = product.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final docRef = _firestore.collection('products').doc(docId);
        batch.set(docRef, {
          'name': product.name,
          'price': product.price,
          'quantity': product.quantity,
          'category': product.category,
          'description': product.description,
          'cost': product.cost,
          'barcode': product.barcode,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة جميع المنتجات بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing all products');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة المنتجات', context: context);
      }
    }
  }
  
  static Future<List<Product>> getProducts({BuildContext? context}) async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) {
        return Product.fromFirebase(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error getting products from Firebase');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في جلب المنتجات من قاعدة البيانات', context: context);
      }
      return [];
    }
  }
  
  // Users
  static Future<void> syncUser(Map<String, dynamic> user, {BuildContext? context}) async {
    try {
      await _firestore.collection('users').doc(user['id'].toString()).set({
        'id': user['id'],
        'name': user['name'],
        'pin': user['pin'],
        'role': user['role'],
        'updatedAt': Timestamp.now(),
      });
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة المستخدم بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing user: ${user['name']}');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة المستخدم', context: context);
      }
    }
  }
  
  static Future<List<Map<String, dynamic>>> getUsers({BuildContext? context}) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error getting users from Firebase');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في جلب المستخدمين من قاعدة البيانات', context: context);
      }
      return [];
    }
  }
  
  // Customers
  static Future<void> syncCustomer(Map<String, dynamic> customer, {BuildContext? context}) async {
    try {
      await _firestore.collection('customers').doc(customer['id'].toString()).set({
        'id': customer['id'],
        'name': customer['name'],
        'phone': customer['phone'],
        'email': customer['email'],
        'balance': customer['balance'],
        'credit': customer['credit'],
        'debt': customer['debt'],
        'updatedAt': Timestamp.now(),
      });
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة العميل بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing customer: ${customer['name']}');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة العميل', context: context);
      }
    }
  }
  
  static Future<List<Map<String, dynamic>>> getCustomers({BuildContext? context}) async {
    try {
      final snapshot = await _firestore.collection('customers').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error getting customers from Firebase');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في جلب العملاء من قاعدة البيانات', context: context);
      }
      return [];
    }
  }
  
  // Suppliers
  static Future<void> syncSupplier(Map<String, dynamic> supplier, {BuildContext? context}) async {
    try {
      await _firestore.collection('suppliers').doc(supplier['id'].toString()).set({
        'id': supplier['id'],
        'name': supplier['name'],
        'phone': supplier['phone'],
        'email': supplier['email'],
        'balance': supplier['balance'],
        'credit': supplier['credit'],
        'debt': supplier['debt'],
        'updatedAt': Timestamp.now(),
      });
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة المورد بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing supplier: ${supplier['name']}');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة المورد', context: context);
      }
    }
  }
  
  static Future<List<Map<String, dynamic>>> getSuppliers({BuildContext? context}) async {
    try {
      final snapshot = await _firestore.collection('suppliers').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error getting suppliers from Firebase');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في جلب الموردين من قاعدة البيانات', context: context);
      }
      return [];
    }
  }
  
  // Invoices
  static Future<void> syncInvoice(Map<String, dynamic> invoice, {BuildContext? context}) async {
    try {
      await _firestore.collection('invoices').doc(invoice['receiptNumber']).set({
        'receiptNumber': invoice['receiptNumber'],
        'date': invoice['date'],
        'total': invoice['total'],
        'itemsJson': invoice['itemsJson'],
        'userId': invoice['userId'],
        'paymentMethod': invoice['paymentMethod'] ?? 'Cash',
        'createdAt': Timestamp.now(),
      });
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم مزامنة الفاتورة بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error syncing invoice: ${invoice['receiptNumber']}');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في مزامنة الفاتورة', context: context);
      }
    }
  }
  
  static Future<List<Map<String, dynamic>>> getInvoices({BuildContext? context}) async {
    try {
      final snapshot = await _firestore.collection('invoices').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error getting invoices from Firebase');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في جلب الفواتير من قاعدة البيانات', context: context);
      }
      return [];
    }
  }
  
  // Delete operations
  static Future<void> deleteProduct(String productId, {BuildContext? context}) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم حذف المنتج بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error deleting product: $productId');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في حذف المنتج', context: context);
      }
    }
  }
  
  static Future<void> deleteCustomer(String customerId, {BuildContext? context}) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم حذف العميل بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error deleting customer: $customerId');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في حذف العميل', context: context);
      }
    }
  }
  
  static Future<void> deleteSupplier(String supplierId, {BuildContext? context}) async {
    try {
      await _firestore.collection('suppliers').doc(supplierId).delete();
      
      if (context != null) {
        ErrorHandler.showSuccessSnackBar('تم حذف المورد بنجاح', context: context);
      }
    } catch (e) {
      ErrorHandler.handleFirebaseError(e, customMessage: 'Error deleting supplier: $supplierId');
      if (context != null) {
        ErrorHandler.showErrorSnackBar('فشل في حذف المورد', context: context);
      }
    }
  }
  
  // Transactions
  static Future<void> syncTransaction(Map<String, dynamic> transaction) async {
    try {
      await _firestore.collection('transactions').add({
        'customer_name': transaction['customer_name'],
        'supplier_name': transaction['supplier_name'],
        'total_amount': transaction['total_amount'],
        'items': transaction['items'],
        'payment_method': transaction['payment_method'],
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error syncing transaction: $e');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final snapshot = await _firestore.collection('transactions')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['created_at'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        return data;
      }).toList();
    } catch (e) {
      print('Error getting transactions from Firebase: $e');
      return [];
    }
  }
  
  // Sync all local data to Firebase
  static Future<void> syncAllData({
    required List<Product> products,
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> suppliers,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      await Future.wait([
        syncAllProducts(products),
        _syncBatch('users', users),
        _syncBatch('customers', customers),
        _syncBatch('suppliers', suppliers),
        _syncBatch('transactions', transactions),
      ]);
      print('All data synced to Firebase successfully');
    } catch (e) {
      print('Error syncing all data: $e');
    }
  }
  
  static Future<void> _syncBatch(String collection, List<Map<String, dynamic>> items) async {
    try {
      final batch = _firestore.batch();
      for (final item in items) {
        final docRef = _firestore.collection(collection).doc(item['id'].toString());
        final data = Map<String, dynamic>.from(item);
        data['updatedAt'] = Timestamp.now();
        if (collection == 'transactions') {
          data['createdAt'] = Timestamp.now();
        }
        batch.set(docRef, data);
      }
      await batch.commit();
    } catch (e) {
      print('Error syncing batch for $collection: $e');
    }
  }
}
