import 'package:intl/intl.dart';

String formatTime(DateTime time) {
  return DateFormat.jm().format(time);
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}
