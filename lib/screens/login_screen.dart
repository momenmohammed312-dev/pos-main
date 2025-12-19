import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'products_screen.dart';
import 'inventory_control_screen.dart';
import '../../data/db_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl =
      TextEditingController(); // username
  final TextEditingController _passwordCtrl =
      TextEditingController(); // password
  bool _keepMeLoggedIn = false; // لل ال check box
  bool _obscurePassword = true; // عشان نعرف الباسود مختفي ولا

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  void tryLogin(String username, String pin) async {
    // Simple demo login - in real app use AuthService
    print('Login attempt: $username');
  }


  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final pin = _passwordCtrl.text.trim();

    if (username.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and PIN')),
      );
      return;
    }

    try {
      // Verify user in DB
      final user = await DbHelper.instance.getUserByName(username);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      if (user['pin'] != pin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid PIN')),
          );
        }
        return;
      }

      // Save current user
      final sp = await SharedPreferences.getInstance();
      await sp.setString('currentUser', username);
      await sp.setString('userRole', user['role'] ?? 'cashier');

      // Navigate to products screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProductsScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
      debugPrint('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: isMobileScreen
            ? _buildMobileLayout(screenHeight, screenWidth)
            : _buildDesktopLayout(screenHeight, screenWidth),
      ),
    );
  }

  Widget _buildMobileLayout(double screenHeight, double screenWidth) {
    final isMobileScreen = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      child: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobileScreen ? 16.0 : 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.08),
              // Logo/Icon area
              Center(
                child: Container(
                  width: isMobileScreen ? 70 : 80,
                  height: isMobileScreen ? 70 : 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(isMobileScreen ? 18 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront,
                    size: isMobileScreen ? 35 : 40,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              const Text(
                "POS System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Login to access your system",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: screenHeight * 0.06),
              _buildLoginForm(isMobileScreen: true),
              SizedBox(height: screenHeight * 0.04),
              // Mobile contact info
              Center(
                child: Text(
                  "developed by MO2",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isMobileScreen ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double screenHeight, double screenWidth) {
    final isMobileScreen = MediaQuery.of(context).size.width < 600;
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.storefront,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "POS System",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Point of Sale Management",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Secure • Fast • Reliable",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "developed by MO2",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Login Form
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey.shade50,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginForm(isMobileScreen: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isMobileScreen}) {
    return Card(
      elevation: isMobileScreen ? 4 : 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobileScreen ? 16 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobileScreen ? 24.0 : 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMobileScreen) ...[
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login to access your POS system",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _usernameCtrl,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isMobileScreen ? 14 : 16,
                ),
                prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600, size: isMobileScreen ? 20 : 24),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(isMobileScreen ? 14 : 12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  borderRadius: BorderRadius.circular(isMobileScreen ? 14 : 12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.symmetric(horizontal: isMobileScreen ? 16 : 16, vertical: isMobileScreen ? 14 : 16),
              ),
            ),
            SizedBox(height: isMobileScreen ? 16 : 20),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isMobileScreen ? 14 : 16,
                ),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600, size: isMobileScreen ? 20 : 24),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                    size: isMobileScreen ? 20 : 24,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(isMobileScreen ? 14 : 12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  borderRadius: BorderRadius.circular(isMobileScreen ? 14 : 12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.symmetric(horizontal: isMobileScreen ? 16 : 16, vertical: isMobileScreen ? 14 : 16),
              ),
            ),
                SizedBox(height: isMobileScreen ? 12 : 16),
                Row(
                  children: [
                    Transform.scale(
                      scale: isMobileScreen ? 0.9 : 1.0,
                      child: Checkbox(
                        value: _keepMeLoggedIn,
                        activeColor: Colors.blue.shade600,
                        onChanged: (v) => setState(() => _keepMeLoggedIn = v ?? false),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Keep me logged in",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: isMobileScreen ? 13 : 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobileScreen ? 20 : 24),
            SizedBox(
              width: double.infinity,
              height: isMobileScreen ? 48 : 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobileScreen ? 14 : 12),
                  ),
                  elevation: 2,
                ),
                onPressed: _login,
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontSize: isMobileScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (!isMobileScreen) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(
                      "developed by MO2",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Secure login powered by POS System",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
