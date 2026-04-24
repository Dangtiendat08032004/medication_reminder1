import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:intl/intl.dart';

class MedicationWidget extends StatelessWidget {
  const MedicationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationBloc, MedicationState>(
      builder: (context, state) {
        Medication? nextMedication;
        DateTime? nextTime;

        if (state is MedicationLoaded && state.medications.isNotEmpty) {
          final now = DateTime.now();

          for (final medication in state.medications) {
            for (final time in medication.times) {
              DateTime medicationTime = DateTime(
                now.year,
                now.month,
                now.day,
                time.hour,
                time.minute,
              );

              // Nếu giờ đã qua → chuyển sang ngày mai
              if (medicationTime.isBefore(now)) {
                medicationTime = medicationTime.add(const Duration(days: 1));
              }

              if (nextTime == null || medicationTime.isBefore(nextTime)) {
                nextTime = medicationTime;
                nextMedication = medication;
              }
            }
          }
        }

        return _buildContainer(nextMedication, nextTime);
      },
    );
  }

  Widget _buildContainer(Medication? medication, DateTime? time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: medication != null && time != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thuốc tiếp theo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Liều: ${medication.dosage}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Thời gian: ${DateFormat.Hm().format(time)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thuốc tiếp theo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Không có thuốc nào sắp tới',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
    );
  }
}