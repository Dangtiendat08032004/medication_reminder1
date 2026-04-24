import 'package:equatable/equatable.dart';
import 'package:medication_reminder/models/medication.dart';

sealed class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object> get props => [];
}

final class MedicationInitial extends MedicationState {}

final class MedicationLoading extends MedicationState {}

final class MedicationLoaded extends MedicationState {
  final List<Medication> medications;

  const MedicationLoaded(this.medications);

  @override
  List<Object> get props => [medications];
}

final class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object> get props => [message];
}
