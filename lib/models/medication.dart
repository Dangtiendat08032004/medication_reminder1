import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String dosage; // Liều uống mỗi lần (ví dụ: 1 viên, 5ml)

  @HiveField(3)
  final List<DateTime> times;

  @HiveField(4)
  final Map<DateTime, bool> takenStatus;

  @HiveField(5)
  final Map<DateTime, bool> skippedStatus;

  @HiveField(6)
  final DateTime startDate;

  @HiveField(7)
  final DateTime? endDate;

  @HiveField(8)
  final String? notes; // Ghi chú mới

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    Map<DateTime, bool>? takenStatus,
    Map<DateTime, bool>? skippedStatus,
  })  : takenStatus = takenStatus ?? {},
        skippedStatus = skippedStatus ?? {};

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<DateTime>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    Map<DateTime, bool>? takenStatus,
    Map<DateTime, bool>? skippedStatus,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      takenStatus: takenStatus ?? this.takenStatus,
      skippedStatus: skippedStatus ?? this.skippedStatus,
    );
  }
}
