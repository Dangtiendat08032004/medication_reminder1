import 'package:flutter/foundation.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:medication_reminder/services/notification_service.dart';

class MedicationService {
  final HiveService _hiveService;
  final NotificationService _notificationService;

  MedicationService(this._hiveService, this._notificationService);

  Future<List<Medication>> getAllMedications() async {
    try {
      return _hiveService.getAllMedications();
    } catch (e) {
      debugPrint('Error getting all medications: $e');
      return [];
    }
  }

  Future<void> addMedication(Medication medication) async {
    await _hiveService.saveMedication(medication);
    try {
      await _notificationService.scheduleAllMedicationNotifications(medication);
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> updateMedication(Medication medication) async {
    // Luôn cố gắng lưu vào database trước
    await _hiveService.saveMedication(medication);

    // Xử lý thông báo sau và không để lỗi làm dừng tiến trình
    try {
      await _notificationService.cancelAllNotificationsForMedication(medication);
      await _notificationService.scheduleAllMedicationNotifications(medication);
    } catch (e) {
      debugPrint('Error updating notifications: $e');
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      final medication = _hiveService.medicationsBox.get(id);
      if (medication != null) {
        await _notificationService.cancelAllNotificationsForMedication(medication);
      }
    } catch (e) {
      debugPrint('Error canceling notifications during delete: $e');
    }

    await _hiveService.deleteMedication(id);
  }

  Future<void> markAsTaken(Medication medication, DateTime time) async {
    final updated = medication.copyWith(
      takenStatus: {...medication.takenStatus, time: true},
      skippedStatus: {...medication.skippedStatus}..remove(time),
    );

    await _hiveService.saveMedication(updated);

    try {
      final id = _notificationService.generateId(medication, time);
      await _notificationService.cancelNotification(id - 2);
      await _notificationService.cancelNotification(id);
      await _notificationService.cancelNotification(id + 1);
    } catch (e) {
      debugPrint('Error canceling notification after taken: $e');
    }
  }

  Future<void> markAsSkipped(Medication medication, DateTime time) async {
    final updated = medication.copyWith(
      skippedStatus: {...medication.skippedStatus, time: true},
      takenStatus: {...medication.takenStatus}..remove(time),
    );

    await _hiveService.saveMedication(updated);

    try {
      final id = _notificationService.generateId(medication, time);
      await _notificationService.cancelNotification(id - 2);
      await _notificationService.cancelNotification(id);
      await _notificationService.cancelNotification(id + 1);
    } catch (e) {
      debugPrint('Error canceling notification after skipped: $e');
    }
  }

  Future<void> snoozeMedication(Medication medication, DateTime time) async {
    try {
      // Hủy thông báo hiện tại
      final id = _notificationService.generateId(medication, time);
      await _notificationService.cancelNotification(id);
      
      // Lên lịch nhắc lại sau 5 phút
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      await _notificationService.scheduleMedicationNotification(medication, snoozeTime);
    } catch (e) {
      debugPrint('Error snoozing medication: $e');
    }
  }
}
