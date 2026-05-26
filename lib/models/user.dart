import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? profilePicture;

  @HiveField(3)
  final double? height; // Chiều cao (cm)

  @HiveField(4)
  final double? weight; // Cân nặng (kg)

  User({
    required this.id,
    required this.name,
    this.profilePicture,
    this.height,
    this.weight,
  });
}
