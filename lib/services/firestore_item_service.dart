import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreItemService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('items');

  Stream<List<Item>> streamItems() {
    return _col.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) => Item.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  Future<String> addItem(Item it) async {
    final doc = await _col.add(it.toMap());
    return doc.id;
  }

  Future<void> updateItem(Item it) async {
    await _col.doc(it.id).update({
      ...it.toMap(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }

  Future<Item?> getItemById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Item.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Decrease stock using transaction. Throws if stock insufficient.
  Future<void> decreaseStock(Map<String, int> itemIdToQty) async {
    final db = FirebaseFirestore.instance;
    await db.runTransaction((tx) async {
      for (final entry in itemIdToQty.entries) {
        final docRef = _col.doc(entry.key);
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) throw Exception('Item not found: ${entry.key}');
        final data = snapshot.data() as Map<String, dynamic>;
        final current = (data['quantity'] ?? 0) as int;
        final newQty = current - entry.value;
        if (newQty < 0) throw Exception('Insufficient stock for item ${entry.key}');
        tx.update(docRef, {'quantity': newQty, 'updatedAt': DateTime.now()});
      }
    });
  }

  Future<void> increaseStock(Map<String, int> itemIdToQty) async {
    final db = FirebaseFirestore.instance;
    await db.runTransaction((tx) async {
      for (final entry in itemIdToQty.entries) {
        final docRef = _col.doc(entry.key);
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) throw Exception('Item not found: ${entry.key}');
        final data = snapshot.data() as Map<String, dynamic>;
        final current = (data['quantity'] ?? 0) as int;
        final newQty = current + entry.value;
        tx.update(docRef, {'quantity': newQty, 'updatedAt': DateTime.now()});
      }
    });
  }
}
