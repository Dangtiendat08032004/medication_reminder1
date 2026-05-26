import 'package:flutter/material.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/user.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final HiveService _hiveService = HiveService();
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _users = _hiveService.getAllUsers();
    });
  }

  void _showUserDialog({User? user}) {
    final bool isEditing = user != null;
    final TextEditingController nameController =
        TextEditingController(text: user?.name);
    final TextEditingController heightController =
        TextEditingController(text: user?.height?.toString());
    final TextEditingController weightController =
        TextEditingController(text: user?.weight?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Sửa người dùng' : 'Thêm người dùng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng *',
                  hintText: 'Nhập tên...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  hintText: 'Ví dụ: 170',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  hintText: 'Ví dụ: 65',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newUser = User(
                  id: isEditing ? user.id : const Uuid().v4(),
                  name: nameController.text,
                  height: double.tryParse(heightController.text),
                  weight: double.tryParse(weightController.text),
                );
                await _hiveService.saveUser(newUser);
                _loadUsers();
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _users.isEmpty
          ? const Center(child: Text('Chưa có người dùng nào.'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Chiều cao: ${user.height?.toString() ?? "--"} cm | Cân nặng: ${user.weight?.toString() ?? "--"} kg',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUserDialog(user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận'),
                                content: Text('Xóa người dùng ${user.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _hiveService.deleteUser(user.id);
                              _loadUsers();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
