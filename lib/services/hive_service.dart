import 'package:hive_flutter/hive_flutter.dart';
import 'package:medication_reminder/core/constants.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/models/user.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Đăng ký các adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserAdapter());
    }
    
    await Hive.openBox<Medication>(AppConstants.hiveBoxName);
    await Hive.openBox<User>(AppConstants.userBoxName);
  }

  Box<Medication> get medicationsBox =>
      Hive.box<Medication>(AppConstants.hiveBoxName);

  Box<User> get usersBox =>
      Hive.box<User>(AppConstants.userBoxName);

  // Medication methods
  Future<void> saveMedication(Medication medication) async {
    await medicationsBox.put(medication.id, medication);
  }

  Future<void> deleteMedication(String id) async {
    await medicationsBox.delete(id);
  }

  List<Medication> getAllMedications() {
    return medicationsBox.values.toList();
  }

  // User methods
  Future<void> saveUser(User user) async {
    await usersBox.put(user.id, user);
  }

  Future<void> deleteUser(String id) async {
    await usersBox.delete(id);
  }

  List<User> getAllUsers() {
    return usersBox.values.toList();
  }
}
