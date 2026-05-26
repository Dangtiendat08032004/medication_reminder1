import 'package:flutter/material.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/views/user_management_screen.dart';
import 'package:medication_reminder/views/medication_summary_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cài đặt'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Chế độ tối'),
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeNotifier.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Quản lý người dùng'),
                subtitle: const Text('Thêm hoặc xóa người dùng thuốc'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Tổng kết thuốc đã uống'),
                subtitle: const Text('Thống kê tổng số lần đã uống của từng loại'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicationSummaryScreen(),
                    ),
                  );
                },
              ),
              
              const Divider(),
            ],
          ),
        );
      },
    );
  }
}
