import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/core/utils/time_utils.dart';
import 'package:medication_reminder/core/widgets/error_widget.dart';
import 'package:medication_reminder/core/widgets/loading_indicator.dart';
import 'package:medication_reminder/views/add_edit_medication_screen.dart';
import 'package:medication_reminder/views/widgets/medication_list_item.dart';
import 'package:medication_reminder/views/widgets/medication_widget.dart';
import 'package:medication_reminder/models/medication.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MedicationBloc>(),
          child: const AddEditMedicationScreen(),
        ),
      ),
    );
  }

  void _openEditScreen(BuildContext context, Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MedicationBloc>(),
          child: AddEditMedicationScreen(
            medication: medication,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminder'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddScreen(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: MedicationWidget(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Xin chào!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MedicationBloc, MedicationState>(
              builder: (context, state) {
                if (state is MedicationInitial || state is MedicationLoading) {
                  return const LoadingIndicator();
                } else if (state is MedicationError) {
                  return ErrorRetryWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<MedicationBloc>().add(LoadMedications()),
                  );
                } else if (state is MedicationLoaded) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  
                  final todayMedications = state.medications.where((medication) {
                    final start = DateTime(
                      medication.startDate.year,
                      medication.startDate.month,
                      medication.startDate.day,
                    );
                    final end = medication.endDate != null
                        ? DateTime(
                            medication.endDate!.year,
                            medication.endDate!.month,
                            medication.endDate!.day,
                          )
                        : null;

                    final isAfterStart = !today.isBefore(start);
                    final isBeforeEnd = end == null || !today.isAfter(end);

                    return isAfterStart && isBeforeEnd;
                  }).toList();

                  // ===== EMPTY STATE =====
                  if (todayMedications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.medication_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có thuốc, hãy thêm thuốc',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // ✅ FIX NÚT Ở ĐÂY
                          ElevatedButton(
                            onPressed: () => _openAddScreen(context),
                            child: const Text('Thêm thuốc ngay'),
                          ),
                        ],
                      ),
                    );
                  }

                  // ===== LIST =====
                  return ListView.builder(
                    itemCount: todayMedications.length,
                    itemBuilder: (context, index) {
                      final medication = todayMedications[index];

                      return MedicationListItem(
                        medication: medication,
                        onEdit: () =>
                            _openEditScreen(context, medication),
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content:
                                  Text('Xóa ${medication.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<MedicationBloc>()
                                        .add(DeleteMedication(
                                            medication.id));

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Đã xóa ${medication.name}'),
                                      ),
                                    );
                                  },
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                        },
                        onMarkTaken: (time) {
                          context.read<MedicationBloc>().add(
                              MarkAsTaken(medication, time));

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Đã đánh dấu ${medication.name} là đã uống'),
                            ),
                          );
                        },
                        onMarkSkipped: (time) {
                          context.read<MedicationBloc>().add(
                              MarkAsSkipped(medication, time));

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Đã bỏ qua ${medication.name}'),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return ErrorRetryWidget(
                    message: 'Unknown state',
                    onRetry: () {},
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}