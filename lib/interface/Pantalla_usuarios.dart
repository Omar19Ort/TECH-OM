import 'package:flutter/material.dart';
import 'package:tech_om/database/database_helper.dart';

class PantallaUsuarios extends StatefulWidget {
  const PantallaUsuarios({Key? key}) : super(key: key);

  @override
  _PantallaUsuariosState createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DatabaseHelper.instance.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email']),
                        Text(user['phone'] ?? 'No phone'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

