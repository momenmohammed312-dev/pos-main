import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale.dart';

class FirestoreSaleService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('sales');
  final itemsCol = FirebaseFirestore.instance.collection('items');

  Future<String> createSale(Sale s) async {
    // Use transaction: create sale doc and decrease item stock
    final db = FirebaseFirestore.instance;
    final docRef = _col.doc();
    final itemIdToQty = <String, int>{};
    for (final it in s.items) {
      itemIdToQty[it['itemId'] as String] = (itemIdToQty[it['itemId']] ?? 0) + (it['qty'] as int);
    }

    await db.runTransaction((tx) async {
      // check stock
      for (final entry in itemIdToQty.entries) {
        final itemRef = itemsCol.doc(entry.key);
        final snap = await tx.get(itemRef);
        if (!snap.exists) throw Exception('Item not found: ${entry.key}');
        final data = snap.data() as Map<String, dynamic>;
        final current = (data['quantity'] ?? 0) as int;
        final newQty = current - entry.value;
        if (newQty < 0) throw Exception('Insufficient stock for item ${entry.key}');
        tx.update(itemRef, {'quantity': newQty, 'updatedAt': DateTime.now()});
      }

      tx.set(docRef, s.toMap());
    });

    return docRef.id;
  }
}
