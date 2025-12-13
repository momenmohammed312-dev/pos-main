class Expense {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String? note;

  Expense({required this.id, required this.type, required this.amount, DateTime? date, this.note}) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {'type': type, 'amount': amount, 'date': date, 'note': note};
  }
}
