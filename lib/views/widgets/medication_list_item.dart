import 'package:flutter/material.dart';
import 'package:medication_reminder/core/utils/time_utils.dart';
import 'package:medication_reminder/models/medication.dart';

class MedicationListItem extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(DateTime) onMarkTaken;
  final Function(DateTime) onMarkSkipped;

  const MedicationListItem({
    super.key,
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkTaken, // FIX
    required this.onMarkSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTimes = List<DateTime>.from(medication.times)
      ..sort((a, b) => a.compareTo(b));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // FIX
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  medication.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),

            Text('Liều: ${medication.dosage}'),

            if (medication.notes != null &&
                medication.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú: ${medication.notes}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
              ),
            ],

            const SizedBox(height: 8),

            ...sortedTimes.map((time) {
              final isTaken = medication.takenStatus[time] ?? false;
              final isSkipped = medication.skippedStatus[time] ?? false;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isTaken
                      ? Icons.check_circle
                      : isSkipped
                          ? Icons.cancel
                          : Icons.access_time,
                  color: isTaken
                      ? Colors.green
                      : isSkipped
                          ? Colors.red
                          : Colors.orange,
                ),
                title: Text(formatTime(time)),

                trailing: (!isTaken && !isSkipped) // FIX
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => onMarkTaken(time),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => onMarkSkipped(time),
                          ),
                        ],
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}