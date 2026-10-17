import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../app/utils/work_log_validator.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/work_log_repository.dart';
import '../bloc/log_work_cubit.dart';
import '../bloc/log_work_state.dart';

/// Hiển thị BottomSheet ghi nhận thời gian làm việc (Work Log) cho Task (US-066).
Future<void> showLogWorkBottomSheet(
  BuildContext context, {
  required TaskModel task,
  required String projectId,
}) {
  final repository = context.read<WorkLogRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => LogWorkCubit(
        repository: repository,
        task: task,
        projectId: projectId,
      ),
      child: LogWorkBottomSheet(task: task, projectId: projectId),
    ),
  );
}

/// Widget BottomSheet ghi nhận thời gian làm việc.
class LogWorkBottomSheet extends StatefulWidget {
  final TaskModel task;
  final String projectId;

  const LogWorkBottomSheet({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  State<LogWorkBottomSheet> createState() => _LogWorkBottomSheetState();
}

class _LogWorkBottomSheetState extends State<LogWorkBottomSheet> {
  final _hoursController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _workDate = DateUtils.dateOnly(DateTime.now());

  String? _localError;
  double? _submittedHours;

  static const List<double> _quickHours = [0.5, 1.0, 2.0, 4.0];

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
      helpText: 'Chọn ngày làm việc',
    );
    if (picked != null) {
      setState(() => _workDate = picked);
    }
  }

  void _submit() {
    final rawHours = _hoursController.text;
    final hours = WorkLogValidator.parseHours(rawHours);
    final hoursError = WorkLogValidator.validateHours(hours);
    if (hoursError != null) {
      setState(() => _localError = hoursError);
      return;
    }

    final note = _noteController.text;
    final noteError = WorkLogValidator.validateNote(note);
    if (noteError != null) {
      setState(() => _localError = noteError);
      return;
    }

    final dateError = WorkLogValidator.validateWorkDate(_workDate);
    if (dateError != null) {
      setState(() => _localError = dateError);
      return;
    }

    setState(() {
      _localError = null;
      _submittedHours = hours;
    });

    context.read<LogWorkCubit>().submit(
          hours: hours,
          note: note,
          workDate: _workDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<LogWorkCubit, LogWorkState>(
      listener: (context, state) {
        if (state is LogWorkSuccess) {
          final messenger = ScaffoldMessenger.of(context);
          final hoursText = _submittedHours != null
              ? WorkLogValidator.formatHours(_submittedHours!)
              : '0';
          Navigator.of(context).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Đã ghi $hoursText giờ'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is LogWorkSubmitting;
        final inlineError = _localError ??
            (state is LogWorkFailure ? state.message : null);

        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 20 + bottomInset,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tiêu đề & Tên Task
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi giờ làm việc',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Chọn nhanh số giờ
                Text(
                  'Chọn nhanh số giờ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _quickHours.map((h) {
                    final label = WorkLogValidator.formatHours(h);
                    final isSelected =
                        _hoursController.text.trim() == label ||
                            _hoursController.text.trim() == h.toString();
                    return ChoiceChip(
                      key: Key('quick_hours_$label'),
                      label: Text('${label}h'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvas,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outline.withValues(alpha: 0.2),
                      ),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color: isSelected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: isSubmitting
                          ? null
                          : (_) {
                              setState(() {
                                _hoursController.text = label;
                                _localError = null;
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Ô nhập số giờ
                TextField(
                  key: const Key('log_work_hours_input'),
                  controller: _hoursController,
                  enabled: !isSubmitting,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Số giờ làm việc *',
                    hintText: 'VD: 1.5 hoặc 2',
                    prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                    suffixText: 'giờ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) {
                    if (_localError != null) {
                      setState(() => _localError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Chọn ngày làm việc
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('log_work_date_picker'),
                        onPressed: isSubmitting ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          'Ngày: ${formatDateVi(_workDate)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ghi chú
                TextField(
                  key: const Key('log_work_note_input'),
                  controller: _noteController,
                  enabled: !isSubmitting,
                  maxLength: 500,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú công việc',
                    hintText: 'Mô tả tóm tắt nội dung đã thực hiện...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                // Hiển thị lỗi inline
                if (inlineError != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inlineError,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Nút Bỏ qua & Lưu
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const Key('log_work_cancel_button'),
                      onPressed:
                          isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Bỏ qua',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('log_work_submit_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Lưu',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
