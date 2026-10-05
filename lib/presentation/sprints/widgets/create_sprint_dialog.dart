import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/app_colors.dart';
import '../bloc/sprint_bloc.dart';
import '../bloc/sprint_event.dart';

Future<void> showCreateSprintDialog({
  required BuildContext context,
  required String projectId,
}) async {
  final sprintBloc = context.read<SprintBloc>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateSprintDialog(
      projectId: projectId,
      sprintBloc: sprintBloc,
    ),
  );
}

class _CreateSprintDialog extends StatefulWidget {
  final String projectId;
  final SprintBloc sprintBloc;

  const _CreateSprintDialog({
    required this.projectId,
    required this.sprintBloc,
  });

  @override
  State<_CreateSprintDialog> createState() => _CreateSprintDialogState();
}

class _CreateSprintDialogState extends State<_CreateSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = _startDate.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo Sprint mới'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên Sprint'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên Sprint.'
                    : null,
              ),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: 'Mục tiêu Sprint'),
                minLines: 2,
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập mục tiêu Sprint.'
                    : null,
              ),
              const SizedBox(height: 12),
              _dateButton(
                context,
                label: 'Bắt đầu',
                date: _startDate,
                onPicked: (date) => setState(() => _startDate = date),
              ),
              _dateButton(
                context,
                label: 'Kết thúc',
                date: _endDate,
                onPicked: (date) => setState(() => _endDate = date),
              ),
              if (!_endDate.isAfter(_startDate))
                const Text(
                  'Ngày kết thúc phải sau ngày bắt đầu.',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate() ||
                !_endDate.isAfter(_startDate)) {
              return;
            }
            widget.sprintBloc.add(SprintCreateRequested(
              projectId: widget.projectId,
              name: _nameController.text,
              goal: _goalController.text,
              startDate: _startDate,
              endDate: _endDate,
            ));
            Navigator.pop(context);
          },
          child: const Text('Tạo Sprint'),
        ),
      ],
    );
  }
}

Widget _dateButton(
  BuildContext context, {
  required String label,
  required DateTime date,
  required ValueChanged<DateTime> onPicked,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text('$label: ${date.day}/${date.month}/${date.year}'),
    trailing: const Icon(Icons.calendar_month_outlined),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) onPicked(picked);
    },
  );
}

