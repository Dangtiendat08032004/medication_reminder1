import 'package:flutter/material.dart';
import 'package:medication_reminder/core/theme/colors.dart';

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
            title: const Text('Settings'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
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
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle:
                    const Text('Medication Reminder App v1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Medication Reminder',
                    applicationVersion: '1.0.0',
                    applicationIcon:
                        const Icon(Icons.medication, size: 48),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}