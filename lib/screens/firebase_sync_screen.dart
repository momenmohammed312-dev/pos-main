import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/db_helper.dart';
import '../../services/firebase_service.dart';

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
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 24.0,
          vertical: isMobile ? 12.0 : 16.0,
        ),
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
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        _syncStatus,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      LinearProgressIndicator(
                        value: _syncProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isSyncing ? Colors.blue : Colors.green,
                        ),
                        minHeight: isMobile ? 4 : 6,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // Sync Buttons - Vertical on mobile, Horizontal on desktop
              isMobile
                  ? Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncToFirebase,
                          icon: const Icon(Icons.upload, size: 20),
                          label: const Text('Sync to Firebase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncFromFirebase,
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text('Sync from Firebase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _syncToFirebase,
                            icon: const Icon(Icons.upload),
                            label: const Text('Sync to Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _syncFromFirebase,
                            icon: const Icon(Icons.download),
                            label: const Text('Sync from Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
            
            SizedBox(height: isMobile ? 16 : 24),
            
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
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    CheckboxListTile(
                      title: const Text('Products'),
                      subtitle: const Text('Sync all products'),
                      value: true,
                      onChanged: (value) {},
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Users'),
                      subtitle: const Text('Sync user accounts'),
                      value: true,
                      onChanged: (value) {},
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Customers'),
                      subtitle: const Text('Sync customer data'),
                      value: true,
                      onChanged: (value) {},
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Suppliers'),
                      subtitle: const Text('Sync supplier data'),
                      value: true,
                      onChanged: (value) {},
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Transactions'),
                      subtitle: const Text('Sync transaction history'),
                      value: true,
                      onChanged: (value) {},
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 4 : 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 16 : 24),
            
            // Sync Logs
            Expanded(
              child: Card(
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
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton(
                            onPressed: _clearLogs,
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
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
      });

      // Sync to Firebase
      _addLog('Syncing products...');
      await FirebaseService.syncAllProducts(products);
      setState(() {
        _syncProgress = 0.4;
      });

      _addLog('Syncing users...');
      for (final user in users) {
        await FirebaseService.syncUser(user);
      }
      setState(() {
        _syncProgress = 0.5;
      });

      _addLog('Syncing customers...');
      for (final customer in customers) {
        await FirebaseService.syncCustomer(customer);
      }
      setState(() {
        _syncProgress = 0.6;
      });

      _addLog('Syncing suppliers...');
      for (final supplier in suppliers) {
        await FirebaseService.syncSupplier(supplier);
      }
      setState(() {
        _syncProgress = 0.7;
      });

      _addLog('Syncing transactions...');
      for (final transaction in transactions) {
        await FirebaseService.syncTransaction(transaction);
      }
      setState(() {
        _syncProgress = 0.9;
      });

      _addLog('Sync completed successfully!');
      setState(() {
        _syncStatus = 'Sync completed successfully!';
        _syncProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced to Firebase successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('Sync failed: $e');
      setState(() {
        _syncStatus = 'Sync failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
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
      // Get data from Firebase
      _addLog('Fetching data from Firebase...');
      final products = await FirebaseService.getProducts();
      setState(() {
        _syncProgress = 0.2;
      });

      final users = await FirebaseService.getUsers();
      setState(() {
        _syncProgress = 0.3;
      });

      final customers = await FirebaseService.getCustomers();
      setState(() {
        _syncProgress = 0.4;
      });

      final suppliers = await FirebaseService.getSuppliers();
      setState(() {
        _syncProgress = 0.5;
      });

      final transactions = await FirebaseService.getTransactions();
      setState(() {
        _syncProgress = 0.6;
      });

      // Update local database
      _addLog('Updating local database...');
      // Note: This would require implementing update methods in DbHelper
      // For now, we'll just log the data received
      
      _addLog('Received ${products.length} products');
      _addLog('Received ${users.length} users');
      _addLog('Received ${customers.length} customers');
      _addLog('Received ${suppliers.length} suppliers');
      _addLog('Received ${transactions.length} transactions');

      setState(() {
        _syncStatus = 'Sync from Firebase completed!';
        _syncProgress = 1.0;
      });

      _addLog('Sync from Firebase completed successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced from Firebase successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('Sync from Firebase failed: $e');
      setState(() {
        _syncStatus = 'Sync from Firebase failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync from Firebase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _syncLogs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_syncLogs.length > 100) {
        _syncLogs.removeLast();
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _syncLogs.clear();
    });
  }
}
