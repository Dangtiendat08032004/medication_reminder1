import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/services/medication_service.dart';
import 'package:medication_reminder/services/notification_service.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationService _medicationService;
  final NotificationService _notificationService;

  MedicationBloc(this._medicationService, this._notificationService)
      : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<UpdateMedication>(_onUpdateMedication);
    on<DeleteMedication>(_onDeleteMedication);
    on<MarkAsTaken>(_onMarkAsTaken);
    on<MarkAsSkipped>(_onMarkAsSkipped);
  }

  Future<void> _onLoadMedications(LoadMedications event, Emitter<MedicationState> emit) async {
    emit(MedicationLoading());
    try {
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
      
      // Chạy ngầm việc đăng ký lại thông báo, không chặn UI
      _notificationService.rescheduleAllNotifications(medications).catchError((e) {
        debugPrint('Lỗi thông báo: $e');
      });
    } catch (e) {
      emit(const MedicationError('Không thể tải danh sách thuốc. Vui lòng thử lại.'));
    }
  }

  Future<void> _onAddMedication(AddMedication event, Emitter<MedicationState> emit) async {
    try {
      await _medicationService.addMedication(event.medication);
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
    } catch (e) {
      emit(const MedicationError('Lỗi khi thêm thuốc mới'));
    }
  }

  Future<void> _onUpdateMedication(UpdateMedication event, Emitter<MedicationState> emit) async {
    try {
      await _medicationService.updateMedication(event.medication);
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
    } catch (e) {
      debugPrint('Update error: $e');
      emit(const MedicationError('Lỗi khi cập nhật thông tin thuốc'));
    }
  }

  Future<void> _onDeleteMedication(DeleteMedication event, Emitter<MedicationState> emit) async {
    try {
      await _medicationService.deleteMedication(event.id);
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
    } catch (e) {
      debugPrint('Delete error: $e');
      emit(const MedicationError('Lỗi khi xóa thuốc khỏi danh sách'));
    }
  }

  Future<void> _onMarkAsTaken(MarkAsTaken event, Emitter<MedicationState> emit) async {
    try {
      await _medicationService.markAsTaken(event.medication, event.time);
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
    } catch (e) {
      emit(const MedicationError('Không thể cập nhật trạng thái đã uống'));
    }
  }

  Future<void> _onMarkAsSkipped(MarkAsSkipped event, Emitter<MedicationState> emit) async {
    try {
      await _medicationService.markAsSkipped(event.medication, event.time);
      final medications = await _medicationService.getAllMedications();
      emit(MedicationLoaded(List.from(medications)));
    } catch (e) {
      emit(const MedicationError('Không thể cập nhật trạng thái bỏ qua'));
    }
  }
}
