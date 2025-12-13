import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class FirestoreExpenseService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('expenses');

  Future<String> addExpense(Expense e) async {
    final doc = await _col.add(e.toMap());
    return doc.id;
  }

  Stream<List<Expense>> streamExpensesForPeriod(DateTime from, DateTime to) {
    return _col.where('date', isGreaterThanOrEqualTo: from).where('date', isLessThanOrEqualTo: to).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return Expense(id: d.id, type: data['type'] ?? '', amount: (data['amount'] ?? 0).toDouble(), date: (data['date'] as Timestamp).toDate(), note: data['note']);
      }).toList();
    });
  }
}
