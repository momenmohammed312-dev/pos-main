import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class FirestoreCustomerService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('customers');

  Stream<List<Customer>> streamCustomers() {
    return _col.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return Customer.fromMap(data, d.id);
      }).toList();
    });
  }

  Future<String> addCustomer(Customer c) async {
    final doc = await _col.add(c.toMap());
    return doc.id;
  }

  Future<void> updateCustomer(Customer c) async {
    await _col.doc(c.id).update({
      ...c.toMap(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteCustomer(String id) async {
    await _col.doc(id).delete();
  }

  Future<Customer?> getCustomerById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return Customer.fromMap(data, doc.id);
  }
}
