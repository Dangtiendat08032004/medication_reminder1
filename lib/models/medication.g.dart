// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 0;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      dosage: fields[2] as String,
      times: (fields[3] as List).cast<DateTime>(),
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime?,
      notes: fields[8] as String?,
      takenStatus: (fields[4] as Map?)?.cast<DateTime, bool>(),
      skippedStatus: (fields[5] as Map?)?.cast<DateTime, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.times)
      ..writeByte(4)
      ..write(obj.takenStatus)
      ..writeByte(5)
      ..write(obj.skippedStatus)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
