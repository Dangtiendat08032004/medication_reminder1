import 'package:hive_flutter/hive_flutter.dart';
import 'package:medication_reminder/core/constants.dart';
import 'package:medication_reminder/models/medication.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicationAdapter());
    await Hive.openBox<Medication>(AppConstants.hiveBoxName);
  }

  Box<Medication> get medicationsBox =>
      Hive.box<Medication>(AppConstants.hiveBoxName);

  Future<void> saveMedication(Medication medication) async {
    await medicationsBox.put(medication.id, medication);
  }

  Future<void> deleteMedication(String id) async {
    await medicationsBox.delete(id);
  }

  List<Medication> getAllMedications() {
    return medicationsBox.values.toList();
  }
}
