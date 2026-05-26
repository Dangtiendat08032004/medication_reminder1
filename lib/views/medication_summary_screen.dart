import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/medication.dart';

class MedicationSummaryScreen extends StatelessWidget {
  const MedicationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng kết thuốc đã uống'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoaded) {
            final summaryData = _calculateSummary(state.medications);

            if (summaryData.isEmpty) {
              return const Center(
                child: Text('Chưa có dữ liệu tổng kết.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaryData.length,
              itemBuilder: (context, index) {
                final item = summaryData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.summarize, color: Colors.white),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Đã uống tổng cộng: ${item.count} lần'),
                    trailing: Text(
                      '${item.dosage}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  List<_MedSummary> _calculateSummary(List<Medication> medications) {
    final List<_MedSummary> summary = [];

    for (var med in medications) {
      int takenCount = 0;
      med.takenStatus.forEach((_, isTaken) {
        if (isTaken) takenCount++;
      });

      if (takenCount > 0) {
        summary.add(_MedSummary(
          name: med.name,
          count: takenCount,
          dosage: med.dosage,
        ));
      }
    }

    // Sắp xếp theo số lần uống giảm dần
    summary.sort((a, b) => b.count.compareTo(a.count));
    return summary;
  }
}

class _MedSummary {
  final String name;
  final int count;
  final String dosage;

  _MedSummary({
    required this.name,
    required this.count,
    required this.dosage,
  });
}
