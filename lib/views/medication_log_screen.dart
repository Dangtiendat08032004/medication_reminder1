import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/medication.dart';

class MedicationLogScreen extends StatelessWidget {
  const MedicationLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký uống thuốc'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoaded) {
            final logEntries = <_LogEntry>[];

            for (var medication in state.medications) {
              medication.takenStatus.forEach((time, isTaken) {
                if (isTaken) {
                  logEntries.add(_LogEntry(
                    medication: medication,
                    takenTime: time,
                  ));
                }
              });
            }

            // Sắp xếp nhật ký theo thời gian mới nhất lên đầu
            logEntries.sort((a, b) => b.takenTime.compareTo(a.takenTime));

            if (logEntries.isEmpty) {
              return const Center(
                child: Text('Chưa có nhật ký uống thuốc.'),
              );
            }

            return ListView.builder(
              itemCount: logEntries.length,
              itemBuilder: (context, index) {
                final entry = logEntries[index];
                final medication = entry.medication;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(
                      medication.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Đã uống lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(entry.takenTime)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin chi tiết thuốc:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                                fontSize: 16,
                              ),
                            ),
                            const Divider(),
                            _buildDetailRow(Icons.info_outline, 'Liều dùng:', medication.dosage),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.calendar_today, 'Ngày bắt đầu:', 
                                DateFormat('dd/MM/yyyy').format(medication.startDate)),
                            if (medication.endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildDetailRow(Icons.event_available, 'Ngày kết thúc:',
                                    DateFormat('dd/MM/yyyy').format(medication.endDate!)),
                              ),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.access_time, 'Lịch nhắc hàng ngày:', 
                                medication.times.map((t) => DateFormat('HH:mm').format(t)).join(', ')),
                            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.note_alt_outlined, 'Ghi chú:', medication.notes!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('Có lỗi xảy ra khi tải nhật ký.'));
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogEntry {
  final Medication medication;
  final DateTime takenTime;

  _LogEntry({
    required this.medication,
    required this.takenTime,
  });
}
