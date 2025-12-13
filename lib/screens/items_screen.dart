import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_item_service.dart';

class ItemsScreen extends StatefulWidget {
  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final svc = FirestoreItemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Items')),
      body: StreamBuilder<List<Item>>(
        stream: svc.streamItems(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Text('No items'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, i) {
              final it = list[i];
              final low = it.quantity <= it.threshold;
              return ListTile(
                title: Text(it.name),
                subtitle: Text('Qty: ${it.quantity} • Price: ${it.price.toStringAsFixed(2)}'),
                trailing: low ? Icon(Icons.warning, color: Colors.red) : null,
                onTap: () {},
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addItem, child: Icon(Icons.add)),
    );
  }

  void _addItem() {
    final name = TextEditingController();
    final price = TextEditingController();
    final qty = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Item'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: InputDecoration(labelText: 'Name')), TextField(controller: price, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number), TextField(controller: qty, decoration: InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final it = Item(id: '', name: name.text.trim(), price: double.tryParse(price.text) ?? 0.0, quantity: int.tryParse(qty.text) ?? 0);
              await svc.addItem(it);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
