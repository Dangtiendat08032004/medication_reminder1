import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/medication_service.dart';
import 'package:medication_reminder/services/notification_service.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationService _medicationService;
  final NotificationService _notificationService;

  MedicationBloc(
    this._medicationService,
    this._notificationService,
  ) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<UpdateMedication>(_onUpdateMedication);
    on<DeleteMedication>(_onDeleteMedication);
    on<MarkAsTaken>(_onMarkAsTaken);
    on<MarkAsSkipped>(_onMarkAsSkipped);
  }

  Future<void> _onLoadMedications(
    LoadMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final medications = await _medicationService.getAllMedications();

      if (isClosed) return;
      emit(MedicationLoaded(medications));

      // Không để lỗi notification làm hỏng màn hình
      try {
        await _notificationService.rescheduleAllNotifications(medications);
      } catch (_) {
        // Bỏ qua lỗi notification để app vẫn chạy bình thường
      }
    } catch (e) {
      emit(MedicationError('Failed to load medications'));
    }
  }

  Future<void> _refreshAndEmitLoaded(Emitter<MedicationState> emit) async {
    final medications = await _medicationService.getAllMedications();
    if (isClosed) return;
    emit(MedicationLoaded(medications));
  }

  Future<void> _onAddMedication(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.addMedication(event.medication);

      await _refreshAndEmitLoaded(emit);

      try {
        await _notificationService.scheduleAllMedicationNotifications(
          event.medication,
        );
      } catch (_) {}
    } catch (e) {
      emit(MedicationError('Failed to add medication'));
    }
  }

  Future<void> _onUpdateMedication(
    UpdateMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      try {
        await _notificationService
            .cancelAllNotificationsForMedication(event.medication);
      } catch (_) {}

      await _medicationService.updateMedication(event.medication);

      await _refreshAndEmitLoaded(emit);

      try {
        await _notificationService.scheduleAllMedicationNotifications(
          event.medication,
        );
      } catch (_) {}
    } catch (e) {
      emit(MedicationError('Failed to update medication'));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final medications = await _medicationService.getAllMedications();
      Medication? medicationToDelete;

      try {
        medicationToDelete =
            medications.firstWhere((e) => e.id == event.id);
      } catch (_) {
        medicationToDelete = null;
      }

      if (medicationToDelete != null) {
        try {
          await _notificationService
              .cancelAllNotificationsForMedication(medicationToDelete);
        } catch (_) {}
      }

      await _medicationService.deleteMedication(event.id);
      await _refreshAndEmitLoaded(emit);
    } catch (e) {
      emit(MedicationError('Failed to delete medication'));
    }
  }

  Future<void> _onMarkAsTaken(
    MarkAsTaken event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.markAsTaken(event.medication, event.time);

      final baseId = _notificationService.generateId(
        event.medication,
        event.time,
      );

      try {
        await _notificationService.cancelNotification(baseId - 2);
        await _notificationService.cancelNotification(baseId);
        await _notificationService.cancelNotification(baseId + 1);
      } catch (_) {}

      await _refreshAndEmitLoaded(emit);
    } catch (e) {
      emit(MedicationError('Failed to mark as taken'));
    }
  }

  Future<void> _onMarkAsSkipped(
    MarkAsSkipped event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.markAsSkipped(event.medication, event.time);

      final baseId = _notificationService.generateId(
        event.medication,
        event.time,
      );

      try {
        await _notificationService.cancelNotification(baseId - 2);
        await _notificationService.cancelNotification(baseId);
        await _notificationService.cancelNotification(baseId + 1);
      } catch (_) {}

      await _refreshAndEmitLoaded(emit);
    } catch (e) {
      emit(MedicationError('Failed to mark as skipped'));
    }
  }
}