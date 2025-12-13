import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/items_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/expenses_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => LoginScreen(),
        '/suppliers': (_) => SuppliersScreen(),
        '/customers': (_) => CustomersScreen(),
        '/items': (_) => ItemsScreen(),
        '/sales': (_) => SalesScreen(),
        '/payments': (_) => PaymentsScreen(),
        '/expenses': (_) => ExpensesScreen(),
      },
    );
  }
}
