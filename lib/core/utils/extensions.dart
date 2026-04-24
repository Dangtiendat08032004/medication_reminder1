import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  DateTime get withoutSeconds => DateTime(year, month, day, hour, minute);
}

extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
