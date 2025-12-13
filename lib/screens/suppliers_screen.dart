import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';
import '../services/firestore_supplier_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _service = FirestoreSupplierService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      body: StreamBuilder<List<Supplier>>(
        stream: _service.streamSuppliers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: \\${snapshot.error}'));
          }
          final suppliers = snapshot.data ?? [];
          if (suppliers.isEmpty) {
            return const Center(child: Text('لا يوجد موردين بعد'));
          }
          return ListView.separated(
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.phone + (s.email != null ? ' • ' + s.email! : '')),
                trailing: Text(s.outstanding.toStringAsFixed(2)),
                onTap: () => _showEditDialog(s),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _showAddDialog,
      ),
    );
  }

  void _showAddDialog() {
    final _nameCtrl = TextEditingController();
    final _phoneCtrl = TextEditingController();
    final _emailCtrl = TextEditingController();
    final _addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مورد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final s = Supplier(
                id: '',
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
              );
              await _service.addSupplier(s);
              Navigator.of(context).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Supplier s) {
    final _nameCtrl = TextEditingController(text: s.name);
    final _phoneCtrl = TextEditingController(text: s.phone);
    final _emailCtrl = TextEditingController(text: s.email ?? '');
    final _addressCtrl = TextEditingController(text: s.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل مورد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _service.deleteSupplier(s.id);
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final updated = Supplier(
                id: s.id,
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                outstanding: s.outstanding,
                createdAt: s.createdAt,
              );
              await _service.updateSupplier(updated);
              Navigator.of(context).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
