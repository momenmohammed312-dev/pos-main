import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/firestore_customer_service.dart';

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final svc = FirestoreCustomerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customers')),
      body: StreamBuilder<List<Customer>>(
        stream: svc.streamCustomers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Text('No customers yet'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, i) {
              final c = list[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.phone),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('Balance'), Text(c.balance.toStringAsFixed(2))],
                ),
                onTap: () {},
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addCustomer, child: Icon(Icons.add)),
    );
  }

  void _addCustomer() {
    final name = TextEditingController();
    final phone = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Customer'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: InputDecoration(labelText: 'Name')), TextField(controller: phone, decoration: InputDecoration(labelText: 'Phone'))]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final c = Customer(id: '', name: name.text.trim(), phone: phone.text.trim());
              await svc.addCustomer(c);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
