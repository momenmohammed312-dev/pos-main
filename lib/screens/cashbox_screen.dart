import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';
import '../../models/invoice.dart';

class CashboxScreen extends StatefulWidget {
  const CashboxScreen({super.key});

  @override
  State<CashboxScreen> createState() => _CashboxScreenState();
}

class _CashboxScreenState extends State<CashboxScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Invoice> _dailyInvoices = [];
  double _dailySales = 0.0;
  double _openingBalance = 0.0;
  double _closingBalance = 0.0;
  double _expenses = 0.0;
  double _cashHandover = 0.0;
  bool _isLoading = true;
  final TextEditingController _openingBalanceController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _handoverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await DbHelper.instance.database;
      
      // Get invoices for selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final invoiceMaps = await db.query(
        DbHelper.tableInvoices,
        where: 'date >= ? AND date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'date DESC',
      );
      
      _dailyInvoices = invoiceMaps.map((map) => Invoice.fromMap(map)).toList();
      
      // Calculate daily sales
      _dailySales = _dailyInvoices.fold(0.0, (sum, invoice) => sum + invoice.total);
      
      // Load cashbox data for the day
      final cashboxMaps = await db.query(
        'cashbox',
        where: 'date = ?',
        whereArgs: [startOfDay.toIso8601String()],
      );
      
      if (cashboxMaps.isNotEmpty) {
        final cashbox = cashboxMaps.first;
        _openingBalance = (cashbox['opening_balance'] as num?)?.toDouble() ?? 0.0;
        _closingBalance = (cashbox['closing_balance'] as num?)?.toDouble() ?? 0.0;
        _expenses = (cashbox['expenses'] as num?)?.toDouble() ?? 0.0;
        _cashHandover = (cashbox['cash_handover'] as num?)?.toDouble() ?? 0.0;
        
        _openingBalanceController.text = _openingBalance.toStringAsFixed(2);
        _expensesController.text = _expenses.toStringAsFixed(2);
        _handoverController.text = _cashHandover.toStringAsFixed(2);
      } else {
        // Default values for new day
        _openingBalance = 0.0;
        _expenses = 0.0;
        _cashHandover = 0.0;
        _closingBalance = _openingBalance + _dailySales - _expenses;
        
        _openingBalanceController.text = _openingBalance.toStringAsFixed(2);
        _expensesController.text = _expenses.toStringAsFixed(2);
        _handoverController.text = _cashHandover.toStringAsFixed(2);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCashboxData() async {
    try {
      final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
      final expenses = double.tryParse(_expensesController.text) ?? 0.0;
      final handover = double.tryParse(_handoverController.text) ?? 0.0;
      
      final closingBalance = openingBalance + _dailySales - expenses - handover;
      
      final db = await DbHelper.instance.database;
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      // Check if record exists
      final existing = await db.query(
        'cashbox',
        where: 'date = ?',
        whereArgs: [startOfDay.toIso8601String()],
      );
      
      if (existing.isNotEmpty) {
        // Update existing record
        await db.update(
          'cashbox',
          {
            'opening_balance': openingBalance,
            'closing_balance': closingBalance,
            'expenses': expenses,
            'cash_handover': handover,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'date = ?',
          whereArgs: [startOfDay.toIso8601String()],
        );
      } else {
        // Insert new record
        await db.insert('cashbox', {
          'date': startOfDay.toIso8601String(),
          'opening_balance': openingBalance,
          'closing_balance': closingBalance,
          'expenses': expenses,
          'cash_handover': handover,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      setState(() {
        _openingBalance = openingBalance;
        _expenses = expenses;
        _cashHandover = handover;
        _closingBalance = closingBalance;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cashbox data saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbox Management'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                });
                                _loadDailyData();
                              }
                            },
                            icon: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Daily Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Sales:'),
                              Text(
                                '${_dailySales.toStringAsFixed(2)} EGP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Number of Transactions:'),
                              Text(
                                '${_dailyInvoices.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cashbox Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cashbox Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Opening Balance
                          TextField(
                            controller: _openingBalanceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Opening Balance (EGP)',
                              border: OutlineInputBorder(),
                              prefixText: 'EGP ',
                            ),
                            onChanged: (value) {
                              final opening = double.tryParse(value) ?? 0.0;
                              final expenses = double.tryParse(_expensesController.text) ?? 0.0;
                              final handover = double.tryParse(_handoverController.text) ?? 0.0;
                              setState(() {
                                _closingBalance = opening + _dailySales - expenses - handover;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Expenses
                          TextField(
                            controller: _expensesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Expenses (EGP)',
                              border: OutlineInputBorder(),
                              prefixText: 'EGP ',
                            ),
                            onChanged: (value) {
                              final opening = double.tryParse(_openingBalanceController.text) ?? 0.0;
                              final expenses = double.tryParse(value) ?? 0.0;
                              final handover = double.tryParse(_handoverController.text) ?? 0.0;
                              setState(() {
                                _expenses = expenses;
                                _closingBalance = opening + _dailySales - expenses - handover;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Cash Handover
                          TextField(
                            controller: _handoverController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Cash Handover (EGP)',
                              border: OutlineInputBorder(),
                              prefixText: 'EGP ',
                            ),
                            onChanged: (value) {
                              final opening = double.tryParse(_openingBalanceController.text) ?? 0.0;
                              final expenses = double.tryParse(_expensesController.text) ?? 0.0;
                              final handover = double.tryParse(value) ?? 0.0;
                              setState(() {
                                _cashHandover = handover;
                                _closingBalance = opening + _dailySales - expenses - handover;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Calculated Closing Balance
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Expected Closing Balance:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_closingBalance.toStringAsFixed(2)} EGP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveCashboxData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Save Cashbox Data',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Transactions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_dailyInvoices.isEmpty)
                            const Text('No transactions for this day')
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dailyInvoices.length,
                              itemBuilder: (context, index) {
                                final invoice = _dailyInvoices[index];
                                return ListTile(
                                  leading: const Icon(Icons.receipt),
                                  title: Text('Receipt #${invoice.receiptNumber}'),
                                  subtitle: Text(
                                    DateFormat('HH:mm').format(invoice.date),
                                  ),
                                  trailing: Text(
                                    '${invoice.total.toStringAsFixed(2)} EGP',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
