import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';

class FirestoreSupplierService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('suppliers');

  Stream<List<Supplier>> streamSuppliers() {
    return _col.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return Supplier.fromMap(data, d.id);
      }).toList();
    });
  }

  Future<String> addSupplier(Supplier s) async {
    final doc = await _col.add(s.toMap());
    return doc.id;
  }

  Future<void> updateSupplier(Supplier s) async {
    await _col.doc(s.id).update({
      ...s.toMap(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteSupplier(String id) async {
    await _col.doc(id).delete();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return Supplier.fromMap(data, doc.id);
  }
}
