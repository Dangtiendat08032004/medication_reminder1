import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/hive_service.dart';
import 'package:medication_reminder/services/notification_service.dart';

class MedicationService {
  final HiveService _hiveService;
  final NotificationService _notificationService;

  MedicationService(this._hiveService, this._notificationService);

  Future<List<Medication>> getAllMedications() async {
    return _hiveService.getAllMedications();
  }

  Future<void> addMedication(Medication medication) async {
    await _hiveService.saveMedication(medication);
    await _notificationService
        .scheduleAllMedicationNotifications(medication);
  }

  Future<void> updateMedication(Medication medication) async {
    // FIX: cancel notification cũ trước
    await _notificationService
        .cancelAllNotificationsForMedication(medication);

    await _hiveService.saveMedication(medication);

    await _notificationService
        .scheduleAllMedicationNotifications(medication);
  }

  Future<void> deleteMedication(String id) async {
    final medication = _hiveService.medicationsBox.get(id);

    if (medication != null) {
      await _notificationService
          .cancelAllNotificationsForMedication(medication);
    }

    await _hiveService.deleteMedication(id);
  }

  Future<void> markAsTaken(
    Medication medication,
    DateTime time,
  ) async {
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

    final id = _notificationService.generateId(medication, time);

    await _notificationService.cancelNotification(id - 2);
    await _notificationService.cancelNotification(id);
    await _notificationService.cancelNotification(id + 1);
  }

  Future<void> markAsSkipped(
    Medication medication,
    DateTime time,
  ) async {
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

    final id = _notificationService.generateId(medication, time);

    await _notificationService.cancelNotification(id - 2);
    await _notificationService.cancelNotification(id);
    await _notificationService.cancelNotification(id + 1);
  }
}