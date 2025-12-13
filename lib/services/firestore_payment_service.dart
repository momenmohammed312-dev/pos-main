import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class FirestorePaymentService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('payments');
  final customersCol = FirebaseFirestore.instance.collection('customers');

  Future<String> addPayment(Payment p) async {
    final db = FirebaseFirestore.instance;
    final docRef = _col.doc();
    await db.runTransaction((tx) async {
      tx.set(docRef, p.toMap());

      if (p.customerId != null) {
        final customerRef = customersCol.doc(p.customerId);
        final snap = await tx.get(customerRef);
        if (!snap.exists) throw Exception('Customer not found');
        final data = snap.data() as Map<String, dynamic>;
        final currentBalance = (data['balance'] ?? 0).toDouble();
        final totalPaid = (data['totalPaid'] ?? 0).toDouble();
        final newBalance = currentBalance - p.amount;
        final newTotalPaid = totalPaid + p.amount;
        tx.update(customerRef, {'balance': newBalance, 'totalPaid': newTotalPaid, 'updatedAt': DateTime.now()});
      }
    });
    return docRef.id;
  }
}
