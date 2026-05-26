import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:intl/intl.dart';
import 'package:medication_reminder/views/add_edit_medication_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  final Map<String, List<Medication>> _medicationCache = {};
  List<Medication> _allMedications = [];

  String _key(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

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
        title: const Text('Lịch uống thuốc'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDay,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setState(() {
                  _selectedDay = picked;
                });
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoaded) {
            _allMedications = state.medications;
            _medicationCache.clear();
            
            return Column(
              children: [
                _buildCalendar(),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<MedicationBloc>().add(LoadMedications());
                    },
                    child: _buildMedicationList(),
                  ),
                ),
              ],
            );
          } else if (state is MedicationError) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<MedicationBloc>()
                          .add(LoadMedications());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
                child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDay = _selectedDay
                          .subtract(
                              const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy')
                      .format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDay =
                          _selectedDay.add(
                              const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEEE, d MMMM')
                  .format(_selectedDay),
              style:
                  const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    final key = _key(_selectedDay);

    if (!_medicationCache.containsKey(key)) {
      _medicationCache[key] =
          _getMedicationsForDay(
              _allMedications, _selectedDay);
    }

    final medicationsForDay =
        _medicationCache[key]!;

    if (medicationsForDay.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: Text(
                'Không có thuốc trong ngày này'),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: medicationsForDay.length,
      itemBuilder: (context, index) {
        final medication =
            medicationsForDay[index];

        return Card(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.medication, color: Colors.white),
            ),
            title: Text(medication.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(medication.dosage),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _openEditScreen(context, medication),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, medication),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    _buildDetailRow(Icons.access_time, 'Lịch nhắc hàng ngày:', 
                        medication.times.map((t) => DateFormat('HH:mm').format(t)).join(', ')),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.calendar_today, 'Thời gian điều trị:', 
                        '${DateFormat('dd/MM/yyyy').format(medication.startDate)} - ${medication.endDate != null ? DateFormat('dd/MM/yyyy').format(medication.endDate!) : 'Dài hạn'}'),
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

  void _confirmDelete(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thuốc "${medication.name}" và toàn bộ lịch nhắc không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationBloc>().add(DeleteMedication(medication.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa ${medication.name}')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Medication> _getMedicationsForDay(
    List<Medication> medications,
    DateTime selectedDay,
  ) {
    final day = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    return medications.where((medication) {
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

      final isAfterStart =
          !day.isBefore(start);
      final isBeforeEnd =
          end == null || !day.isAfter(end);

      return isAfterStart &&
          isBeforeEnd;
    }).toList();
  }
}
