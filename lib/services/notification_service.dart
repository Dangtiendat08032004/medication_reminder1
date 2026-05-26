import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medication_reminder/core/constants.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/medication_service.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  
  final notificationService = NotificationService();
  final medicationService = MedicationService(HiveService(), notificationService);
  notificationService.setMedicationService(medicationService);

  await notificationService.handleNotificationAction(response);
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  MedicationService? _medicationService;

  void setMedicationService(MedicationService service) {
    _medicationService = service;
  }

  NotificationService() {
    tz.initializeTimeZones();
  }

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> handleNotificationAction(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null && _medicationService != null) {
      try {
        final parts = payload.split('|');
        if (parts.length == 2) {
          final medicationId = parts[0];
          final timeFromPayload = DateTime.parse(parts[1]);
          final medications = await _medicationService!.getAllMedications();
          
          if (medications.isEmpty) return;

          final medication = medications.cast<Medication?>().firstWhere(
            (m) => m?.id == medicationId,
            orElse: () => null,
          );

          if (medication == null) return;

          final exactTime = medication.times.firstWhere(
            (t) => t.hour == timeFromPayload.hour && t.minute == timeFromPayload.minute,
            orElse: () => timeFromPayload,
          );

          if (response.actionId == 'take') {
            await _medicationService!.markAsTaken(medication, exactTime);
          } else if (response.actionId == 'skip') {
            await _medicationService!.snoozeMedication(medication, exactTime);
          }
        }
      } catch (e) {
        debugPrint('Error handling notification action: $e');
      }
    }
  }

  Future<void> scheduleMedicationNotification(Medication medication, DateTime scheduledTime, {DateTime? actualTime}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      if (!_shouldSchedule(medication, scheduledTime)) return;

      final details = _buildDetails();
      final tz.TZDateTime tzTime;
      
      if (actualTime != null) {
        tzTime = tz.TZDateTime.from(actualTime, tz.local);
      } else {
        tzTime = _buildTzTime(scheduledTime);
      }

      int id = generateId(medication, scheduledTime);
      if (actualTime != null) id += 1;

      final body = _buildBody(medication);
      final payload = '${medication.id}|${scheduledTime.toIso8601String()}';

      await _notificationsPlugin.zonedSchedule(
        id,
        actualTime != null ? 'Nhắc lại: Đến giờ uống thuốc!' : 'Đến giờ uống thuốc!',
        body,
        tzTime,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: actualTime != null ? null : DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> scheduleAllMedicationNotifications(Medication medication) async {
    for (final time in medication.times) {
      await scheduleMedicationNotification(medication, time);
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotificationsForMedication(Medication medication) async {
    for (final time in medication.times) {
      final id = generateId(medication, time);
      await cancelNotification(id - 2);
      await cancelNotification(id);
      await cancelNotification(id + 1);
    }
  }

  int generateId(Medication medication, DateTime time) {
    final baseId = medication.id.hashCode.abs() % 100000;
    final timeId = (time.hour * 60 + time.minute);
    return (baseId + timeId) * 10;
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all: $e');
    }
  }

  Future<void> rescheduleAllNotifications(List<Medication> medications) async {
    await cancelAllNotifications();
    for (final medication in medications) {
      await scheduleAllMedicationNotifications(medication);
    }
  }

  bool _shouldSchedule(Medication m, DateTime time) {
    final now = DateTime.now();
    if (m.endDate != null && now.isAfter(m.endDate!)) return false;
    final taken = m.takenStatus[time] ?? false;
    final skipped = m.skippedStatus[time] ?? false;
    return !(taken || skipped);
  }

  tz.TZDateTime _buildTzTime(DateTime time) {
    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return tz.TZDateTime.from(
      scheduled.isBefore(now) ? scheduled.add(const Duration(days: 1)) : scheduled,
      tz.local,
    );
  }

  NotificationDetails _buildDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'take',
          'Đã uống',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip',
          'Nhắc lại sau 5p',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    return const NotificationDetails(android: androidDetails);
  }

  String _buildBody(Medication m) {
    return 'Đến giờ uống ${m.name} - ${m.dosage}${m.notes != null ? "\nGhi chú: ${m.notes}" : ""}';
  }
}
