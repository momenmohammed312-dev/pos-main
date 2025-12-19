import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/db_helper.dart';

class FirebaseSyncScreen extends StatefulWidget {
  const FirebaseSyncScreen({super.key});

  @override
  State<FirebaseSyncScreen> createState() => _FirebaseSyncScreenState();
}

class _FirebaseSyncScreenState extends State<FirebaseSyncScreen> {
  bool _isSyncing = false;
  String _syncStatus = 'Ready to sync';
  double _syncProgress = 0.0;
  List<String> _syncLogs = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Sync'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - (isMobile ? 120 : 160),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sync Status Card
              Card(
                elevation: isMobile ? 2 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Progress indicator
                      if (_isSyncing) ...[
                        LinearProgressIndicator(
                          value: _syncProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                      ],
                      
                      // Status text
                      Text(
                        _syncStatus,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: _isSyncing ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Sync Actions
              Card(
                elevation: isMobile ? 2 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Actions',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Sync buttons
                      if (isMobile) ...[
                        // Mobile layout - vertical buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSyncing ? null : _syncToFirebase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                            ),
                            child: Text(
                              'Sync to Firebase',
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSyncing ? null : _syncFromFirebase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                            ),
                            child: Text(
                              'Sync from Firebase',
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Desktop layout - horizontal buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSyncing ? null : _syncToFirebase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                                ),
                                child: const Text('Sync to Firebase'),
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSyncing ? null : _syncFromFirebase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                                ),
                                child: const Text('Sync from Firebase'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Sync Options
              Card(
                elevation: isMobile ? 2 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Options',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Sync checkboxes
                      CheckboxListTile(
                        title: Text(
                          'Products',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        value: true,
                        onChanged: (value) {},
                      ),
                      CheckboxListTile(
                        title: Text(
                          'Users',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        value: true,
                        onChanged: (value) {},
                      ),
                      CheckboxListTile(
                        title: Text(
                          'Customers',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        value: true,
                        onChanged: (value) {},
                      ),
                      CheckboxListTile(
                        title: Text(
                          'Suppliers',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        value: true,
                        onChanged: (value) {},
                      ),
                      CheckboxListTile(
                        title: Text(
                          'Transactions',
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Sync Logs
              Card(
                elevation: isMobile ? 2 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sync Logs',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton(
                            onPressed: _clearLogs,
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Logs list
                      Expanded(
                        child: _syncLogs.isEmpty
                            ? Center(
                                child: Text(
                                  'No sync logs yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _syncLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _syncLogs[index];
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 8 : 12,
                                      vertical: isMobile ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        fontFamily: 'monospace',
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncToFirebase() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing to Firebase...';
      _syncProgress = 0.0;
      _addLog('Starting sync to Firebase...');
    });

    try {
      // Get all local data
      _addLog('Fetching local data...');
      final products = await DbHelper.instance.getProducts();
      final users = await DbHelper.instance.getAllUsers();
      final customers = await DbHelper.instance.getAllCustomers();
      final suppliers = await DbHelper.instance.getAllSuppliers();
      final transactions = await DbHelper.instance.getAllTransactions();

      setState(() {
        _syncProgress = 0.2;
        _syncStatus = 'Uploading to Firebase...';
      });
      _addLog('Uploading data to Firebase...');

      // Upload to Firebase
      final firestore = FirebaseFirestore.instance;
      
      // Upload products
      if (products.isNotEmpty) {
        final productsRef = firestore.collection('products');
        for (final product in products) {
          await productsRef.doc(product.id.toString()).set(product.toMap());
        }
        _addLog('Uploaded ${products.length} products');
      }

      setState(() => _syncProgress = 0.4);

      // Upload users
      if (users.isNotEmpty) {
        final usersRef = firestore.collection('users');
        for (final user in users) {
          await usersRef.doc(user.id.toString()).set(user.toMap());
        }
        _addLog('Uploaded ${users.length} users');
      }

      setState(() => _syncProgress = 0.6);

      // Upload customers
      if (customers.isNotEmpty) {
        final customersRef = firestore.collection('customers');
        for (final customer in customers) {
          await customersRef.doc(customer.id.toString()).set(customer.toMap());
        }
        _addLog('Uploaded ${customers.length} customers');
      }

      setState(() => _syncProgress = 0.8);

      // Upload suppliers
      if (suppliers.isNotEmpty) {
        final suppliersRef = firestore.collection('suppliers');
        for (final supplier in suppliers) {
          await suppliersRef.doc(supplier.id.toString()).set(supplier.toMap());
        }
        _addLog('Uploaded ${suppliers.length} suppliers');
      }

      // Upload transactions
      if (transactions.isNotEmpty) {
        final transactionsRef = firestore.collection('transactions');
        for (final transaction in transactions) {
          await transactionsRef.doc(transaction.id.toString()).set(transaction.toMap());
        }
        _addLog('Uploaded ${transactions.length} transactions');
      }

      setState(() {
        _syncProgress = 1.0;
        _syncStatus = 'Sync completed successfully!';
        _isSyncing = false;
      });
      _addLog('Sync to Firebase completed successfully!');

    } catch (e) {
      setState(() {
        _syncStatus = 'Sync failed: $e';
        _isSyncing = false;
      });
      _addLog('Sync failed: $e');
    }
  }

  Future<void> _syncFromFirebase() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing from Firebase...';
      _syncProgress = 0.0;
      _addLog('Starting sync from Firebase...');
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final db = await DbHelper.instance.database;

      setState(() {
        _syncProgress = 0.2;
        _syncStatus = 'Downloading from Firebase...';
      });
      _addLog('Downloading data from Firebase...');

      // Download products
      final productsSnapshot = await firestore.collection('products').get();
      for (final doc in productsSnapshot.docs) {
        await db.insert(
          DbHelper.tableProducts,
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _addLog('Downloaded ${productsSnapshot.docs.length} products');

      setState(() => _syncProgress = 0.4);

      // Download users
      final usersSnapshot = await firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        await db.insert(
          DbHelper.tableUsers,
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _addLog('Downloaded ${usersSnapshot.docs.length} users');

      setState(() => _syncProgress = 0.6);

      // Download customers
      final customersSnapshot = await firestore.collection('customers').get();
      for (final doc in customersSnapshot.docs) {
        await db.insert(
          DbHelper.tableCustomers,
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _addLog('Downloaded ${customersSnapshot.docs.length} customers');

      setState(() => _syncProgress = 0.8);

      // Download suppliers
      final suppliersSnapshot = await firestore.collection('suppliers').get();
      for (final doc in suppliersSnapshot.docs) {
        await db.insert(
          DbHelper.tableSuppliers,
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _addLog('Downloaded ${suppliersSnapshot.docs.length} suppliers');

      // Download transactions
      final transactionsSnapshot = await firestore.collection('transactions').get();
      for (final doc in transactionsSnapshot.docs) {
        await db.insert(
          DbHelper.tableInvoices,
          Map<String, dynamic>.from(doc.data()),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      _addLog('Downloaded ${transactionsSnapshot.docs.length} transactions');

      setState(() {
        _syncProgress = 1.0;
        _syncStatus = 'Sync completed successfully!';
        _isSyncing = false;
      });
      _addLog('Sync from Firebase completed successfully!');

    } catch (e) {
      setState(() {
        _syncStatus = 'Sync failed: $e';
        _isSyncing = false;
      });
      _addLog('Sync failed: $e');
    }
  }

  void _addLog(String log) {
    setState(() {
      _syncLogs.add('${DateTime.now().toString().substring(0, 19)}: $log');
    });
  }

  void _clearLogs() {
    setState(() {
      _syncLogs.clear();
    });
  }
}
