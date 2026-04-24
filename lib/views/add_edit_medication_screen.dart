import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medication_reminder/bloc/medication_bloc.dart';
import 'package:medication_reminder/bloc/medication_event.dart';
import 'package:medication_reminder/core/theme/colors.dart';
import 'package:medication_reminder/models/medication.dart';
import 'package:medication_reminder/views/widgets/schedule_time_picker.dart';

class AddEditMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddEditMedicationScreen({super.key, this.medication});

  @override
  State<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState
    extends State<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  List<DateTime> _times = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    if (widget.medication != null) {
      final m = widget.medication!;

      _nameController.text = m.name;
      _dosageController.text = m.dosage;
      _notesController.text = m.notes ?? '';
      _times = List.from(m.times);
      _startDate = m.startDate;
      _endDate = m.endDate; // FIX lỗi biến
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ??
          (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate() &&
        _times.isNotEmpty &&
        _startDate != null) {
      final medication = Medication(
        id: widget.medication?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        dosage: _dosageController.text,
        times: _times,
        startDate: _startDate!,
        endDate: _endDate,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        takenStatus: widget.medication?.takenStatus ?? {},
        skippedStatus: widget.medication?.skippedStatus ?? {},
      );

      final event = widget.medication == null
          ? AddMedication(medication)
          : UpdateMedication(medication); // FIX event

      context.read<MedicationBloc>().add(event);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.medication == null ? 'Đã thêm' : 'Đã cập nhật'} ${medication.name}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return date.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null
              ? 'Thêm thuốc'
              : 'Sửa thuốc',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên thuốc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Liều mỗi lần uống *',
                  hintText: 'Ví dụ: 1 viên, 5ml, 2 muỗng',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập liều lượng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              const Text(
                'Liều là số lượng thuốc uống mỗi lần',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'Ví dụ: Uống sau khi ăn',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startDate == null
                            ? 'Chọn ngày bắt đầu *'
                            : 'Bắt đầu: ${_formatDate(_startDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectStartDate(context),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endDate == null
                            ? 'Chọn ngày kết thúc'
                            : 'Kết thúc: ${_formatDate(_endDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectEndDate(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Thời gian uống *',
                style: TextStyle(
                  fontSize: 16, // FIX lỗi
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              ScheduleTimePicker(
                initialTimes: _times,
                onTimesChanged: (times) {
                  setState(() {
                    _times = times;
                  });
                },
              ),

              if (_times.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng thêm ít nhất một thời gian',
                  style: TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _saveMedication,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Lưu thuốc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}