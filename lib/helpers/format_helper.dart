import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final nf = NumberFormat.currency(locale: 'en_US', symbol: 'EGP ', decimalDigits: 2);
  return nf.format(value);
}

String formatDate(DateTime d) {
  final df = DateFormat('yyyy-MM-dd HH:mm');
  return df.format(d);
}
