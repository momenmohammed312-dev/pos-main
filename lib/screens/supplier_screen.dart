import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db_helper.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'inventory_control_screen.dart';
import 'profile_screen.dart';
import 'cashbox_screen.dart';
import 'supplier_products_screen.dart';
import '../theme/app_theme.dart';

// Helper function to detect if screen is mobile
bool isScreenMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 800;
}

// ----------------- SupplierScreen -----------------
class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  String _searchQuery = '';
  String _currentUser = '';
  String _currentUserRole = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    _creditController.dispose();
    _debtController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndSuppliers();
  }

  Future<void> _loadUserAndSuppliers() async {
    final sp = await SharedPreferences.getInstance();
    _currentUser = sp.getString('currentUser') ?? '';
    _currentUserRole = sp.getString('userRole') ?? 'cashier';
    await _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final suppliers = await DbHelper.instance.getAllSuppliers();
    setState(() {
      _suppliers = suppliers;
      _filteredSuppliers = suppliers;
    });
  }

  Future<void> _showAddSupplierDialog() async {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _balanceController.clear();
    _creditController.clear();
    _debtController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: _balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: _creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: _debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.insertSupplier({
                'name': _nameController.text,
                'phone': _phoneController.text,
                'email': _emailController.text,
                'balance': double.tryParse(_balanceController.text) ?? 0.0,
                'credit': double.tryParse(_creditController.text) ?? 0.0,
                'debt': double.tryParse(_debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _loadSuppliers();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSupplierDialog(Map<String, dynamic> supplier) async {
    _nameController.text = supplier['name'];
    _phoneController.text = supplier['phone'];
    _emailController.text = supplier['email'];
    _balanceController.text = supplier['balance'].toString();
    _creditController.text = supplier['credit'].toString();
    _debtController.text = supplier['debt'].toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: _balanceController, decoration: const InputDecoration(labelText: 'Balance'), keyboardType: TextInputType.number),
              TextField(controller: _creditController, decoration: const InputDecoration(labelText: 'Credit'), keyboardType: TextInputType.number),
              TextField(controller: _debtController, decoration: const InputDecoration(labelText: 'Debt'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.instance.updateSupplier({
                'id': supplier['id'],
                'name': _nameController.text,
                'phone': _phoneController.text,
                'email': _emailController.text,
                'balance': double.tryParse(_balanceController.text) ?? 0.0,
                'credit': double.tryParse(_creditController.text) ?? 0.0,
                'debt': double.tryParse(_debtController.text) ?? 0.0,
              });
              Navigator.pop(context);
              _loadSuppliers();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(int id) async {
    await DbHelper.instance.deleteSupplier(id);
    _loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool mobile = isScreenMobile(context);

    final query = _searchController.text.trim().toLowerCase();
    _filteredSuppliers = query.isEmpty
        ? _suppliers
        : _suppliers.where((supplier) {
            final name = supplier['name'].toString().toLowerCase();
            final phone = supplier['phone'].toString().toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text('Suppliers Management'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary),
            ),
            onSelected: (value) async {
              if (value == 'supplier_products') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierProductsScreen()),
                );
              } else if (value == 'add_supplier') {
                await _showAddSupplierDialog();
              } else if (value == 'settings') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'profile') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else if (value == 'reports') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              } else if (value == 'inventory') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryControlScreen()),
                );
              } else if (value == 'cashbox') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CashboxScreen()),
                );
              }
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [
                PopupMenuItem(
                  value: 'supplier_products',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.getAccentColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.inventory_2, color: AppTheme.getAccentColor(), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier Products',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Manage product inventory',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'add_supplier',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.getSuccessColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.person_add, color: AppTheme.getSuccessColor(), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Supplier',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reports',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.getErrorColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.bar_chart, color: AppTheme.getErrorColor(), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'inventory',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Inventory Control',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cashbox',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cashbox',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
              return items;
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 16.0 : screenWidth * 0.025,
              vertical: mobile ? 12.0 : screenHeight * 0.03,
            ),
            child: mobile
                ? _buildMobileLayout(screenWidth, screenHeight)
                : _buildDesktopLayout(screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          width: double.infinity,
          height: screenHeight * 0.05,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color.fromARGB(199, 207, 205, 205),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search suppliers...',
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
        const SizedBox(height: 12),
        // Suppliers list
        Expanded(
          child: _filteredSuppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No suppliers found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      if (_currentUserRole == 'admin')
                        ElevatedButton(
                          onPressed: _showAddSupplierDialog,
                          child: const Text('Add First Supplier'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredSuppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _filteredSuppliers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(supplier['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone: ${supplier['phone']}'),
                            Text('Email: ${supplier['email']}'),
                            Text('Balance: ${supplier['balance']}'),
                            Text('Credit: ${supplier['credit']}'),
                            Text('Debt: ${supplier['debt']}'),
                          ],
                        ),
                        trailing: _currentUserRole == 'admin'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditSupplierDialog(supplier),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSupplier(supplier['id']),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: screenWidth * 0.2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ],
              ),
            ),
            child: Column(
              children: [
                // Logo area
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.inventory, size: 40, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'POS System',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Supplier Management',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Navigation menu
                if (_currentUserRole == 'admin')
                  Column(
                    children: [
                      _buildSidebarItem(Icons.people, 'Customers', () {
                        Navigator.pop(context);
                      }),
                      _buildSidebarItem(Icons.inventory, 'Suppliers', () {}),
                      _buildSidebarItem(Icons.person, 'Users', () {
                        Navigator.pop(context);
                      }),
                      _buildSidebarItem(Icons.report, 'Reports', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReportsScreen()),
                        );
                      }),
                      _buildSidebarItem(Icons.settings, 'Settings', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      }),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Main content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Suppliers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentUserRole == 'admin')
                      ElevatedButton.icon(
                        onPressed: _showAddSupplierDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Supplier'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search bar
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search suppliers...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                const SizedBox(height: 20),
                // Suppliers grid
                Expanded(
                  child: _filteredSuppliers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No suppliers found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              if (_currentUserRole == 'admin')
                                ElevatedButton(
                                  onPressed: _showAddSupplierDialog,
                                  child: const Text('Add First Supplier'),
                                ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.0,
                          ),
                          itemCount: _filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = _filteredSuppliers[index];
                            return Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            supplier['name'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (_currentUserRole == 'admin')
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _showEditSupplierDialog(supplier),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () => _deleteSupplier(supplier['id']),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Phone: ${supplier['phone']}'),
                                    Text('Email: ${supplier['email']}'),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Balance: ${supplier['balance']}'),
                                        Text('Credit: ${supplier['credit']}'),
                                      ],
                                    ),
                                    Text('Debt: ${supplier['debt']}'),
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
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
