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
  bool _isDayClosed = false;
  String _notes = '';
  final TextEditingController _openingBalanceController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _handoverController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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
        _notes = cashbox['notes'] as String? ?? '';
        _isDayClosed = cashbox['is_closed'] == 1;
        
        _openingBalanceController.text = _openingBalance.toStringAsFixed(2);
        _expensesController.text = _expenses.toStringAsFixed(2);
        _handoverController.text = _cashHandover.toStringAsFixed(2);
        _notesController.text = _notes;
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
      final notes = _notesController.text;
      
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
            'notes': notes,
            'is_closed': 1,
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
          'notes': notes,
          'is_closed': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      setState(() {
        _openingBalance = openingBalance;
        _expenses = expenses;
        _cashHandover = handover;
        _closingBalance = closingBalance;
        _notes = notes;
        _isDayClosed = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day closed successfully!'),
            backgroundColor: Colors.green,
          ),
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbox Management'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selector
                  Card(
                    elevation: isMobile ? 2 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.blue.shade600,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
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
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Daily Summary
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
                            'Daily Summary',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Sales Summary
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Sales:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_dailySales.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 8 : 12),
                          
                          // Transactions Count
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Number of Transactions:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_dailyInvoices.length}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Cashbox Form
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
                            'Cashbox Details',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Opening Balance
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _openingBalanceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              enabled: !_isDayClosed,
                              decoration: InputDecoration(
                                labelText: 'Opening Balance (EGP)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                                prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[600]),
                              ),
                              onChanged: (value) {
                                if (!_isDayClosed) {
                                  final opening = double.tryParse(value) ?? 0.0;
                                  final expenses = double.tryParse(_expensesController.text) ?? 0.0;
                                  final handover = double.tryParse(_handoverController.text) ?? 0.0;
                                  setState(() {
                                    _closingBalance = opening + _dailySales - expenses - handover;
                                  });
                                }
                              },
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Expenses
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _expensesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              enabled: !_isDayClosed,
                              decoration: InputDecoration(
                                labelText: 'Expenses (EGP)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                                prefixIcon: Icon(Icons.money_off, color: Colors.grey[600]),
                              ),
                              onChanged: (value) {
                                if (!_isDayClosed) {
                                  final opening = double.tryParse(_openingBalanceController.text) ?? 0.0;
                                  final expenses = double.tryParse(value) ?? 0.0;
                                  final handover = double.tryParse(_handoverController.text) ?? 0.0;
                                  setState(() {
                                    _expenses = expenses;
                                    _closingBalance = opening + _dailySales - expenses - handover;
                                  });
                                }
                              },
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Cash Handover
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _handoverController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              enabled: !_isDayClosed,
                              decoration: InputDecoration(
                                labelText: 'Cash Handover (EGP)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                                prefixIcon: Icon(Icons.swap_horiz, color: Colors.grey[600]),
                              ),
                              onChanged: (value) {
                                if (!_isDayClosed) {
                                  final opening = double.tryParse(_openingBalanceController.text) ?? 0.0;
                                  final expenses = double.tryParse(_expensesController.text) ?? 0.0;
                                  final handover = double.tryParse(value) ?? 0.0;
                                  setState(() {
                                    _cashHandover = handover;
                                    _closingBalance = opening + _dailySales - expenses - handover;
                                  });
                                }
                              },
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Notes Section
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _notesController,
                              enabled: !_isDayClosed,
                              maxLines: isMobile ? 3 : 4,
                              decoration: InputDecoration(
                                labelText: 'ملاحظات / أخرى',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                                prefixIcon: Icon(Icons.note_alt, color: Colors.grey[600]),
                                alignLabelWithHint: true,
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onChanged: (value) {
                                if (!_isDayClosed) {
                                  setState(() {
                                    _notes = value;
                                  });
                                }
                              },
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Calculated Closing Balance
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50, Colors.blue.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                              border: Border.all(color: Colors.blue.shade200, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expected Closing Balance',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 4 : 8),
                                Text(
                                  '${_closingBalance.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 16 : 20),
                          
                          // Save Button
                          if (_isDayClosed)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: isMobile ? 48 : 56,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Text(
                                    'Day Closed',
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  Text(
                                    'This day has been closed and cannot be modified',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveCashboxData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                                  ),
                                  elevation: 3,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_clock,
                                      size: isMobile ? 18 : 20,
                                    ),
                                    SizedBox(width: isMobile ? 8 : 12),
                                    Text(
                                      'Close Day',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.bold,
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
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Recent Transactions
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
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Colors.blue.shade600,
                                size: isMobile ? 20 : 24,
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          if (_dailyInvoices.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: isMobile ? 48 : 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Text(
                                    'No transactions for this day',
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dailyInvoices.length,
                              itemBuilder: (context, index) {
                                final invoice = _dailyInvoices[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 12 : 16,
                                      vertical: isMobile ? 4 : 6,
                                    ),
                                    leading: Container(
                                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                      ),
                                      child: Icon(
                                        Icons.receipt,
                                        color: Colors.blue.shade600,
                                        size: isMobile ? 18 : 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Receipt #${invoice.receiptNumber}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat('HH:mm:ss').format(invoice.date),
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 8 : 12,
                                        vertical: isMobile ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                      ),
                                      child: Text(
                                        '${invoice.total.toStringAsFixed(2)} EGP',
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
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
