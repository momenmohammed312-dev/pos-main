import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple login by staff number. There should be a 'staff' collection in Firestore with documents containing:
// { number: '1234', role: 'admin' } or { number: '5678', role: 'cashier' }
// The app will read the matching doc and route the user based on role. This is a lightweight approach per request.

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _numberCtrl = TextEditingController();
  bool _loading = false;

  void _login() async {
    final number = _numberCtrl.text.trim();
    if (number.isEmpty) return;
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance.collection('staff').where('number', isEqualTo: number).limit(1).get();
    setState(() => _loading = false);
    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Staff number not found')));
      return;
    }
    final doc = snap.docs.first;
    final role = (doc.data()['role'] ?? 'cashier') as String;
    // save role in memory or use a simple provider later. For now route based on role.
    if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/suppliers');
    } else {
      Navigator.of(context).pushReplacementNamed('/sales');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('POS Login')),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter staff number'),
                SizedBox(height: 8),
                TextField(controller: _numberCtrl, decoration: InputDecoration(labelText: 'Number')),
                SizedBox(height: 16),
                _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: Text('Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
