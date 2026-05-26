import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/core/theme/app_theme.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:medication_reminder/services/medication_service.dart';
import 'package:medication_reminder/services/notification_service.dart' as notif;
import 'package:medication_reminder/views/calendar_screen.dart';
import 'package:medication_reminder/views/home_screen.dart';
import 'package:medication_reminder/views/settings_screen.dart';
import 'package:medication_reminder/views/medication_log_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  final notificationService = notif.NotificationService();
  await notificationService.init();

  final hiveService = HiveService();
  final medicationService = MedicationService(
    hiveService,
    notificationService,
  );
  
  // Kết nối service để xử lý action từ notification
  notificationService.setMedicationService(medicationService);

  runApp(
    MedicationReminderApp(
      medicationService: medicationService,
      notificationService: notificationService,
    ),
  );
}

class MedicationReminderApp extends StatefulWidget {
  final MedicationService medicationService;
  final notif.NotificationService notificationService;

  const MedicationReminderApp({
    super.key,
    required this.medicationService,
    required this.notificationService,
  });

  @override
  State<MedicationReminderApp> createState() => _MedicationReminderAppState();
}

class _MedicationReminderAppState extends State<MedicationReminderApp> {
  final ValueNotifier<ThemeMode> _themeNotifier =
      ValueNotifier(ThemeMode.light);
  late final MedicationBloc _medicationBloc;

  @override
  void initState() {
    super.initState();
    _medicationBloc = MedicationBloc(
      widget.medicationService,
      widget.notificationService,
    )..add(LoadMedications());
  }

  @override
  void dispose() {
    _medicationBloc.close();
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _medicationBloc,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeNotifier,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Medication Reminder',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            locale: const Locale('vi', 'VN'),
            home: MainScreen(themeNotifier: _themeNotifier),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomeScreen(),
      const CalendarScreen(),
      const MedicationLogScreen(),
      SettingsScreen(themeNotifier: widget.themeNotifier),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Giúp hiển thị tốt hơn khi có > 3 items
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Thuốc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Nhật ký',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
