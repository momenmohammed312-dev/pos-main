import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db_helper.dart';
import '../../helpers/dialog_helper.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableSounds = false;
  bool _useThermalPrinter = false;
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _enableSounds = sp.getBool('enableSounds') ?? false;
      _useThermalPrinter = sp.getBool('useThermalPrinter') ?? false;
      _currentUser = sp.getString('currentUser');
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, value);
  }

  Future<void> _clearProducts() async {
    final confirm = await showConfirmDialog(context, title: 'Confirm', message: 'Delete all products from local DB?');
    if (!confirm) return;
    await DbHelper.instance.clearProducts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All products deleted')));
  }

  Future<void> _logout() async {
    final confirm = await showConfirmDialog(context, title: 'Logout', message: 'Are you sure you want to logout?');
    if (!confirm) return;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('currentUser');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current user info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current User', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(_currentUser ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // User Management button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Manage Users'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings toggles
              const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable sounds'),
                value: _enableSounds,
                onChanged: (v) {
                  setState(() => _enableSounds = v);
                  _setBool('enableSounds', v);
                },
              ),
              SwitchListTile(
                title: const Text('Use thermal printer'),
                value: _useThermalPrinter,
                onChanged: (v) {
                  setState(() => _useThermalPrinter = v);
                  _setBool('useThermalPrinter', v);
                },
              ),
              const SizedBox(height: 16),
              
              // Danger zone
              const Text('Danger Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _clearProducts,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear all products'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 32),
              
              // App info
              Center(
                child: Column(
                  children: [
                    Text('App version: 1.0.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
