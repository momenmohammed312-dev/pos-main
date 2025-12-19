import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? _currentUser;
  String _currentUserRole = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final sp = await SharedPreferences.getInstance();
    final username = sp.getString('currentUser') ?? '';
    final user = await DbHelper.instance.getUserByName(username);
    
    if (user != null) {
      setState(() {
        _currentUser = user;
        _currentUserRole = user['role'] ?? 'cashier';
      });
    }
    
    if (_currentUserRole == 'admin') {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    final list = await DbHelper.instance.getAllUsers();
    setState(() => users = list);
  }

  void _addUser() {
    _nameController.clear();
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _pinController, decoration: const InputDecoration(labelText: 'PIN'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final pin = _pinController.text.trim();
              if (name.isEmpty || pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
                return;
              }
              await DbHelper.instance.insertUser({'name': name, 'pin': pin, 'role': 'cashier'});
              await _loadUsers();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirm == true) {
      await DbHelper.instance.deleteUser(id);
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUserRole == 'admin' ? 'User Management' : 'My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: _currentUserRole == 'admin' ? _buildAdminView() : _buildCashierView(),
        ),
      ),
    );
  }

  Widget _buildCashierView() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[100],
                      ),
                      child: const Icon(Icons.person, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!['role']?.toString().toUpperCase() ?? 'CASHIER',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow('Username', _currentUser!['username'] ?? 'N/A'),
                _buildInfoRow('Role', _currentUser!['role'] ?? 'N/A'),
                _buildInfoRow('PIN', '••••'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Info message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'For profile changes, please contact your administrator.',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _addUser,
          icon: const Icon(Icons.add),
          label: const Text('Add New User'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Total Users: ${users.length}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: users.isEmpty
              ? const Center(child: Text('No users yet'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue[100],
                          ),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text('Role: ${user['role'] ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user['id'], user['name'] ?? 'Unknown'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _editUser(Map<String, dynamic> user) {
    _nameController.text = user['name'] ?? '';
    _pinController.text = user['pin'] ?? '';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _pinController, decoration: const InputDecoration(labelText: 'PIN'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final pin = _pinController.text.trim();
              if (name.isEmpty || pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
                return;
              }
              
              await DbHelper.instance.updateUser({
                'id': user['id'],
                'name': name,
                'pin': pin,
                'role': user['role'] ?? 'cashier',
              });
              
              Navigator.pop(ctx);
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
