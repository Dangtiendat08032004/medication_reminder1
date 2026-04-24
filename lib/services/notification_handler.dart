import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:medication_reminder/services/notification_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  unawaited(NotificationHandler.instance.handleNotificationAction(response));
}

class NotificationHandler {
  NotificationHandler._internal();

  static final NotificationHandler instance = NotificationHandler._internal();

  final NotificationService _notificationService = NotificationService();
  final HiveService _hiveService = HiveService();

  Future<void> handleNotificationAction(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == null || payload == null || payload.isEmpty) {
      return;
    }

    await HiveService.init();

    final parts = payload.split('|');
    if (parts.length != 2) return;

    final medicationId = parts[0];
    final timeMillis = int.tryParse(parts[1]);
    if (timeMillis == null) return;

    final time = DateTime.fromMillisecondsSinceEpoch(timeMillis);
    final medication = _findMedicationById(medicationId);
    if (medication == null) return;

    switch (actionId) {
      case 'taken':
        await _markAsTaken(medication, time);
        await _cancelPendingNotifications(medication, time);
        break;
      case 'skipped':
        await _markAsSkipped(medication, time);
        await _cancelPendingNotifications(medication, time);
        break;
      case 'remind_later':
        await _remindLater(medication, time);
        await _cancelPendingNotifications(medication, time);
        break;
      default:
        if (kDebugMode) {
          debugPrint('Unhandled notification action: $actionId');
        }
    }
  }

  Medication? _findMedicationById(String medicationId) {
    final box = _hiveService.medicationsBox;

    final byKey = box.get(medicationId);
    if (byKey != null) return byKey;

    for (final item in box.values) {
      if (item.id == medicationId) {
        return item;
      }
    }

    return null;
  }

  Future<void> _markAsTaken(Medication medication, DateTime time) async {
    final updated = medication.copyWith(
      takenStatus: {
        ...medication.takenStatus,
        time: true,
      },
      skippedStatus: {
        ...medication.skippedStatus,
      }..remove(time),
    );

    await _hiveService.saveMedication(updated);
  }

  Future<void> _markAsSkipped(Medication medication, DateTime time) async {
    final updated = medication.copyWith(
      skippedStatus: {
        ...medication.skippedStatus,
        time: true,
      },
      takenStatus: {
        ...medication.takenStatus,
      }..remove(time),
    );

    await _hiveService.saveMedication(updated);
  }

  Future<void> _remindLater(Medication medication, DateTime time) async {
    final newTime = DateTime.now().add(const Duration(minutes: 30));
    await _notificationService.scheduleMedicationNotification(
      medication,
      newTime,
    );
  }

  Future<void> _cancelPendingNotifications(
    Medication medication,
    DateTime time,
  ) async {
    final id = _notificationService.generateId(medication, time);
    await _notificationService.cancelNotification(id);
    await _notificationService.cancelNotification(id + 1);
  }
}