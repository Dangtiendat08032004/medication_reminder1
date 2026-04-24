import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleTimePicker extends StatefulWidget {
  final List<DateTime> initialTimes;
  final ValueChanged<List<DateTime>> onTimesChanged;

  const ScheduleTimePicker({
    super.key,
    required this.initialTimes,
    required this.onTimesChanged,
  });

  @override
  State<ScheduleTimePicker> createState() => _ScheduleTimePickerState();
}

class _ScheduleTimePickerState extends State<ScheduleTimePicker> {
  late List<DateTime> _times;

  @override
  void initState() {
    super.initState();
    _times = List.from(widget.initialTimes);
  }

  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _times.add(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          picked.hour,
          picked.minute,
        ));
        widget.onTimesChanged(_times);
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
      widget.onTimesChanged(_times);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._times.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: Text(DateFormat.jm().format(time)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeTime(index),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _addTime,
          icon: const Icon(Icons.add),
          label: const Text('Add Time'),
        ),
      ],
    );
  }
}
