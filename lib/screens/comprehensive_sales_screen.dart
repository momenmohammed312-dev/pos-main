import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db_helper.dart';

class ComprehensiveSalesScreen extends StatefulWidget {
  const ComprehensiveSalesScreen({super.key});

  @override
  State<ComprehensiveSalesScreen> createState() => _ComprehensiveSalesScreenState();
}

class _ComprehensiveSalesScreenState extends State<ComprehensiveSalesScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String _currentUserRole = '';
  String _searchQuery = '';
  String? _selectedCustomer;
  String? _selectedSupplier;
  DateTime? _startDate;
  DateTime? _endDate;
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

    final transactions = await DbHelper.instance.getAllTransactions();
    final customers = await DbHelper.instance.getAllCustomers();
    final suppliers = await DbHelper.instance.getAllSuppliers();
    
    setState(() {
      _allTransactions = transactions;
      _filteredTransactions = transactions;
      _customers = customers;
      _suppliers = suppliers;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            (transaction['customer_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (transaction['supplier_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (transaction['items']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Customer filter
        bool matchesCustomer = _selectedCustomer == null ||
            transaction['customer_name'] == _selectedCustomer;

        // Supplier filter
        bool matchesSupplier = _selectedSupplier == null ||
            transaction['supplier_name'] == _selectedSupplier;

        // Date filter
        bool matchesDate = true;
        if (_startDate != null || _endDate != null) {
          final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '');
          if (transactionDate != null) {
            if (_startDate != null && transactionDate.isBefore(_startDate!)) {
              matchesDate = false;
            }
            if (_endDate != null && transactionDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
              matchesDate = false;
            }
          }
        }

        return matchesSearch && matchesCustomer && matchesSupplier && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Sales'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
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
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter chips
                Wrap(
                  spacing: 8,
                  children: [
                    // Customer filter
                    DropdownButton<String>(
                      hint: const Text('All Customers'),
                      value: _selectedCustomer,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Customers')),
                        ..._customers.map((customer) => DropdownMenuItem(
                          value: customer['name'],
                          child: Text(customer['name']),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCustomer = value);
                        _applyFilters();
                      },
                    ),
                    
                    // Supplier filter
                    DropdownButton<String>(
                      hint: const Text('All Suppliers'),
                      value: _selectedSupplier,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Suppliers')),
                        ..._suppliers.map((supplier) => DropdownMenuItem(
                          value: supplier['name'],
                          child: Text(supplier['name']),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSupplier = value);
                        _applyFilters();
                      },
                    ),
                    
                    // Date filter
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _selectDateRange(),
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${_startDate!.toString().substring(0, 10)} - ${_endDate!.toString().substring(0, 10)}'
                                : 'Select Date Range',
                          ),
                        ),
                        if (_startDate != null || _endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                              _applyFilters();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Transactions',
                    '${_filteredTransactions.length}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Amount',
                    '${_filteredTransactions.fold<double>(0.0, (sum, t) => sum + (t['total_amount'] ?? 0.0)).toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No transactions found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isCustomer = transaction['customer_name'] != null;
    final name = isCustomer ? transaction['customer_name'] : transaction['supplier_name'];
    final amount = transaction['total_amount'] ?? '0.0';
    final date = transaction['created_at'] ?? 'Unknown date';
    final items = transaction['items'] ?? 'No items';
    final paymentMethod = transaction['payment_method'] ?? 'cash';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isCustomer ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isCustomer ? Icons.person : Icons.inventory,
            color: isCustomer ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          date.toString().substring(0, 19),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: paymentMethod == 'cash' ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                paymentMethod.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: paymentMethod == 'cash' ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Type', isCustomer ? 'Customer Purchase' : 'Supplier Transaction'),
                _buildInfoRow('Payment Method', paymentMethod.toUpperCase()),
                _buildInfoRow('Amount', '$amount'),
                _buildInfoRow('Date', date.toString().substring(0, 10)),
                _buildInfoRow('Items', items),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
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
                child: pw.Text('Comprehensive Sales Report'),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Text('Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total Transactions: ${_filteredTransactions.length}'),
              pw.Text('Total Amount: ${_filteredTransactions.fold<double>(0.0, (sum, t) => sum + (t['total_amount'] ?? 0.0)).toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              
              // Transactions
              pw.Header(
                level: 1,
                child: pw.Text('Transactions'),
              ),
              pw.SizedBox(height: 10),
              ..._filteredTransactions.map((transaction) {
                final isCustomer = transaction['customer_name'] != null;
                final name = isCustomer ? transaction['customer_name'] : transaction['supplier_name'];
                final amount = transaction['total_amount'] ?? '0.0';
                final date = transaction['created_at'] ?? 'Unknown date';
                final items = transaction['items'] ?? 'No items';
                
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name ?? 'Unknown',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Type: ${isCustomer ? 'Customer' : 'Supplier'}'),
                      pw.Text('Amount: $amount'),
                      pw.Text('Date: ${date.toString().substring(0, 10)}'),
                      pw.Text('Items: $items'),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'comprehensive_sales_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
