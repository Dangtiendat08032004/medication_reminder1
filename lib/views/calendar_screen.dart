import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/bloc/medication_state.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Calendar'),
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
            // Always clear cache on rebuild to ensure fresh data
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
              DateFormat('EEEE, MMMM d')
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
              horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(medication.name),
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(medication.dosage),
                if (medication.notes != null &&
                    medication
                        .notes!.isNotEmpty)
                  Text(
                    'Ghi chú: ${medication.notes}',
                    style: const TextStyle(
                        fontStyle:
                            FontStyle.italic),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medication.times
                      .map((time) =>
                          DateFormat.Hm()
                              .format(time))
                      .join(', '),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, medication),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thuốc "${medication.name}" và toàn bộ lịch nhắc không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationBloc>().add(DeleteMedication(medication.id));
              Navigator.pop(context);
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