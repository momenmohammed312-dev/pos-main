import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db_helper.dart';

class SalesDetailsScreen extends StatefulWidget {
  const SalesDetailsScreen({super.key});

  @override
  State<SalesDetailsScreen> createState() => _SalesDetailsScreenState();
}

class _SalesDetailsScreenState extends State<SalesDetailsScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _transactions = [];
  String _currentUserRole = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sp = await SharedPreferences.getInstance();
    final username = sp.getString('currentUser') ?? '';
    _currentUserRole = sp.getString('userRole') ?? 'cashier';

    final customers = await DbHelper.instance.getAllCustomers();
    final suppliers = await DbHelper.instance.getAllSuppliers();
    
    setState(() {
      _customers = customers;
      _suppliers = suppliers;
    });
    
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    // Load transactions from database (you'll need to implement this table)
    final transactions = await DbHelper.instance.getAllTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) => 
      customer['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> get _filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    return _suppliers.where((supplier) => 
      supplier['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Details'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers and suppliers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Tabs for Customers and Suppliers
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.blue.shade600,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue.shade600,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person),
                        text: 'Customers',
                      ),
                      Tab(
                        icon: Icon(Icons.inventory),
                        text: 'Suppliers',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCustomersList(),
                        _buildSuppliersList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    if (_filteredCustomers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No customers found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        final customerTransactions = _transactions.where((t) => 
          t['customer_id'] == customer['id'] || t['customer_name'] == customer['name']
        ).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, color: Colors.green.shade700),
            ),
            title: Text(
              customer['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Phone: ${customer['phone']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer info
                    _buildInfoRow('Email', customer['email'] ?? 'N/A'),
                    _buildInfoRow('Balance', '${customer['balance'] ?? 0.0}'),
                    _buildInfoRow('Credit', '${customer['credit'] ?? 0.0}'),
                    _buildInfoRow('Debt', '${customer['debt'] ?? 0.0}'),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Purchase history
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Purchase History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${customerTransactions.length} transactions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (customerTransactions.isEmpty)
                      const Text('No purchases yet', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customerTransactions.length,
                        itemBuilder: (context, tIndex) {
                          final transaction = customerTransactions[tIndex];
                          return _buildTransactionItem(transaction);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuppliersList() {
    if (_filteredSuppliers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No suppliers found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSuppliers.length,
      itemBuilder: (context, index) {
        final supplier = _filteredSuppliers[index];
        final supplierTransactions = _transactions.where((t) => 
          t['supplier_id'] == supplier['id'] || t['supplier_name'] == supplier['name']
        ).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.inventory, color: Colors.orange.shade700),
            ),
            title: Text(
              supplier['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Phone: ${supplier['phone']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier info
                    _buildInfoRow('Email', supplier['email'] ?? 'N/A'),
                    _buildInfoRow('Balance', '${supplier['balance'] ?? 0.0}'),
                    _buildInfoRow('Credit', '${supplier['credit'] ?? 0.0}'),
                    _buildInfoRow('Debt', '${supplier['debt'] ?? 0.0}'),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Transaction history
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${supplierTransactions.length} transactions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (supplierTransactions.isEmpty)
                      const Text('No transactions yet', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: supplierTransactions.length,
                        itemBuilder: (context, tIndex) {
                          final transaction = supplierTransactions[tIndex];
                          return _buildTransactionItem(transaction);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = transaction['created_at'] ?? 'Unknown date';
    final amount = transaction['total_amount'] ?? '0.0';
    final items = transaction['items'] ?? 'No items';
    final paymentMethod = transaction['payment_method'] ?? 'cash';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount: $amount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentMethod == 'cash' ? Colors.green.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: paymentMethod == 'cash' ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date.toString().substring(0, 10),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Items: $items',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Sales Details Report'),
              ),
              pw.SizedBox(height: 20),
              
              // Customers Section
              pw.Header(
                level: 1,
                child: pw.Text('Customers'),
              ),
              pw.SizedBox(height: 10),
              ..._filteredCustomers.map((customer) {
                final customerTransactions = _transactions.where((t) => 
                  t['customer_id'] == customer['id'] || t['customer_name'] == customer['name']
                ).toList();
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      customer['name'],
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Phone: ${customer['phone']}'),
                    pw.Text('Balance: ${customer['balance']}'),
                    pw.Text('Credit: ${customer['credit']}'),
                    pw.Text('Debt: ${customer['debt']}'),
                    pw.Text('Transactions: ${customerTransactions.length}'),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),
              
              pw.SizedBox(height: 20),
              
              // Suppliers Section
              pw.Header(
                level: 1,
                child: pw.Text('Suppliers'),
              ),
              pw.SizedBox(height: 10),
              ..._filteredSuppliers.map((supplier) {
                final supplierTransactions = _transactions.where((t) => 
                  t['supplier_id'] == supplier['id'] || t['supplier_name'] == supplier['name']
                ).toList();
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      supplier['name'],
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Phone: ${supplier['phone']}'),
                    pw.Text('Balance: ${supplier['balance']}'),
                    pw.Text('Credit: ${supplier['credit']}'),
                    pw.Text('Debt: ${supplier['debt']}'),
                    pw.Text('Transactions: ${supplierTransactions.length}'),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'sales_details_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
