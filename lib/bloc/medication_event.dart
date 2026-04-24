import 'package:equatable/equatable.dart';
import 'package:medication_reminder/models/medication.dart';

sealed class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object> get props => [];
}

class LoadMedications extends MedicationEvent {}

class AddMedication extends MedicationEvent {
  final Medication medication;

  const AddMedication(this.medication);

  @override
  List<Object> get props => [medication];
}

class UpdateMedication extends MedicationEvent {
  final Medication medication;

  const UpdateMedication(this.medication);

  @override
  List<Object> get props => [medication];
}

class DeleteMedication extends MedicationEvent {
  final String id;

  const DeleteMedication(this.id);

  @override
  List<Object> get props => [id];
}

class MarkAsTaken extends MedicationEvent {
  final Medication medication;
  final DateTime time;

  const MarkAsTaken(this.medication, this.time);

  @override
  List<Object> get props => [medication, time];
}

class MarkAsSkipped extends MedicationEvent {
  final Medication medication;
  final DateTime time;

  const MarkAsSkipped(this.medication, this.time);

  @override
  List<Object> get props => [medication, time];
}
