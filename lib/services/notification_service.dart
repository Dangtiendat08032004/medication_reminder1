import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medication_reminder/core/constants.dart';
import 'package:medication_reminder/models/medication.dart';

import 'package:medication_reminder/services/medication_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  MedicationService? _medicationService;

  // Setter để tránh vòng lặp phụ thuộc (circular dependency)
  void setMedicationService(MedicationService service) {
    _medicationService = service;
  }

  NotificationService() {
    tz.initializeTimeZones();
  }

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        if (payload != null && _medicationService != null) {
          try {
            // Tách payload để lấy ID thuốc và thời gian (định dạng: "id|timestamp")
            final parts = payload.split('|');
            if (parts.length == 2) {
              final medicationId = parts[0];
              final timeFromPayload = DateTime.parse(parts[1]);

              final medications = await _medicationService!.getAllMedications();
              // 1. Tìm thuốc trong cơ sở dữ liệu dựa trên ID
              final medication = medications.firstWhere((m) => m.id == medicationId);
              
              // 2. Tìm thời điểm uống thuốc chính xác để khớp với dữ liệu Map trạng thái
              final exactTime = medication.times.firstWhere(
                (t) => t.hour == timeFromPayload.hour && t.minute == timeFromPayload.minute,
                orElse: () => timeFromPayload,
              );

              // 3. Xử lý dựa trên nút người dùng bấm
              if (response.actionId == 'take') {
                // Đã uống: Cập nhật dữ liệu và dừng chuông
                await _medicationService!.markAsTaken(medication, exactTime);
              } else if (response.actionId == 'skip') {
                // Bỏ qua: Cập nhật dữ liệu và dừng chuông
                await _medicationService!.markAsSkipped(medication, exactTime);
              } else if (response.actionId == 'snooze') {
                // Nhắc lại sau (Snooze): Hủy thông báo hiện tại
                final id = generateId(medication, exactTime);
                await cancelNotification(id);
                await cancelNotification(id + 1);
              }
            }
          } catch (e) {
            debugPrint('Lỗi xử lý hành động thông báo: $e');
          }
        }
      },
    );

    // Yêu cầu quyền chính xác trên Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMedicationNotification(
    Medication medication,
    DateTime time,
  ) async {
    if (!_shouldSchedule(medication, time)) return;

    final details = _buildDetails();
    final tzTime = _buildTzTime(time);
    final id = generateId(medication, time);
    final body = _buildBody(medication);
    // Payload format: "medicationId|isoTimestamp"
    final payload = '${medication.id}|${time.toIso8601String()}';

    final preTime = tzTime.subtract(const Duration(minutes: 5));
    if (preTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notificationsPlugin.zonedSchedule(
        id - 2,
        'Sắp đến giờ uống thuốc',
        'Còn 5 phút nữa là đến giờ uống ${medication.name}',
        preTime,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. THÔNG BÁO ĐÚNG GIỜ
    await _notificationsPlugin.zonedSchedule(
      id,
      'Đến giờ uống thuốc rồi!',
      body,
      tzTime,
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // 3. THÔNG BÁO NHẮC LẠI SAU 15 PHÚT
    final reminderTime = tzTime.add(const Duration(minutes: 15));
    await _notificationsPlugin.zonedSchedule(
      id + 1,
      'Nhắc lại: Đừng quên uống thuốc!',
      body,
      reminderTime,
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleAllMedicationNotifications(
    Medication medication,
  ) async {
    for (final time in medication.times) {
      await scheduleMedicationNotification(medication, time);
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotificationsForMedication(
    Medication medication,
  ) async {
    for (final time in medication.times) {
      final id = generateId(medication, time);
      await cancelNotification(id - 2); // Cancel pre-reminder
      await cancelNotification(id);     // Cancel main notification
      await cancelNotification(id + 1); // Cancel snooze/reminder
    }
  }

  int generateId(Medication medication, DateTime time) {
    // Generate a unique ID based on medication ID hash and time
    // Ensure the ID is within a safe range for Android notifications
    final baseId = medication.id.hashCode.abs() % 100000;
    final timeId = (time.hour * 60 + time.minute);
    return (baseId + timeId) * 10;
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAllNotifications(
    List<Medication> medications,
  ) async {
    await cancelAllNotifications();
    for (final medication in medications) {
      await scheduleAllMedicationNotifications(medication);
    }
  }

  bool _shouldSchedule(Medication m, DateTime time) {
    final now = DateTime.now();

    if (now.isBefore(m.startDate)) return false;
    if (m.endDate != null && now.isAfter(m.endDate!)) return false;

    final taken = m.takenStatus[time] ?? false;
    final skipped = m.skippedStatus[time] ?? false;

    if (taken || skipped) return false;

    return true;
  }

  // FIX: sửa tên hàm + lỗi tz
  tz.TZDateTime _buildTzTime(DateTime time) {
    final now = DateTime.now();

    final scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return tz.TZDateTime.from(
      scheduled.isBefore(now)
          ? scheduled.add(const Duration(days: 1))
          : scheduled,
      tz.local,
    );
  }

  NotificationDetails _buildDetails() {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max, // Ưu tiên cao nhất, hiển thị ngay lập tức
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, // Cho phép hiện cửa sổ đè lên màn hình khóa như báo thức
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      
      // --- CẤU HÌNH ĐỔ CHUÔNG ---
      // FLAG_INSISTENT = 4: Lặp lại âm thanh liên tục cho đến khi người dùng nhấn nút
      additionalFlags: Int32List.fromList([4]),
      audioAttributesUsage: AudioAttributesUsage.alarm, // Sử dụng kênh âm thanh báo thức của hệ thống
      
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'take',
          'Đã uống',
          showsUserInterface: true,
          cancelNotification: true, // Nhấn nút sẽ tự động dừng chuông
        ),
        AndroidNotificationAction(
          'snooze',
          'Uống sau (15p)',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip',
          'Bỏ qua',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    return NotificationDetails(android: androidDetails);
  }

  String _buildBody(Medication m) {
    String body = 'Đã đến giờ uống ${m.name} - ${m.dosage}';

    if (m.notes != null && m.notes!.isNotEmpty) {
      body += '\nGhi chú: ${m.notes}';
    }

    return body;
  }
}