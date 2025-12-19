import 'package:flutter/material.dart';
import '../../data/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> invoices = [];
  double totalForDay = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    final list = await DbHelper.instance.getInvoicesByDateRange(start, end);
    double sum = 0;
    for (var inv in list) {
      sum += (inv['total'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      invoices = list;
      totalForDay = sum;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadInvoices();
    }
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receipt #${invoice['receiptNumber']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${invoice['date']}'),
              const SizedBox(height: 8),
              Text('Total: ${invoice['total']} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (invoice['itemsJson'] != null)
                Text('Items: ${invoice['itemsJson']}', style: const TextStyle(fontSize: 12))
              else
                const Text('No items data'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Invoices'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDate.toLocal().toString().split(' ')[0]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _loadInvoices,
                      child: const Text('Reload'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Summary cards
              isMobile
                  ? Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Invoices Today', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${invoices.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Revenue', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('${totalForDay.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Invoices Today', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('${invoices.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Revenue', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('${totalForDay.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              
              const SizedBox(height: 20),
              const Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              // Invoices list
              SizedBox(
                height: 400,
                child: invoices.isEmpty
                    ? const Center(child: Text('No invoices for this date'))
                    : ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, i) {
                          final inv = invoices[i];
                          return Card(
                            child: ListTile(
                              title: Text('Receipt #${inv['receiptNumber']}'),
                              subtitle: Text('${inv['date']}'),
                              trailing: Text('${inv['total']} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              onTap: () => _showInvoiceDetails(inv),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
