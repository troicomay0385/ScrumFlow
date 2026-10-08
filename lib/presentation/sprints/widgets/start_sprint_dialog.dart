import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../bloc/sprint_bloc.dart';
import '../bloc/sprint_event.dart';

/// US-049: Dialog xác nhận bắt đầu Sprint.
///
/// Hiển thị tên Sprint, ngày bắt đầu (hôm nay) và ngày kết thúc dự kiến.
/// User có thể điều chỉnh ngày kết thúc trước khi xác nhận.
Future<void> showStartSprintDialog({
  required BuildContext context,
  required SprintModel sprint,
  required String projectId,
}) async {
  final sprintBloc = context.read<SprintBloc>();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _StartSprintDialog(
      sprint: sprint,
      projectId: projectId,
      sprintBloc: sprintBloc,
    ),
  );
}

class _StartSprintDialog extends StatefulWidget {
  final SprintModel sprint;
  final String projectId;
  final SprintBloc sprintBloc;

  const _StartSprintDialog({
    required this.sprint,
    required this.projectId,
    required this.sprintBloc,
  });

  @override
  State<_StartSprintDialog> createState() => _StartSprintDialogState();
}

class _StartSprintDialogState extends State<_StartSprintDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    // Ưu tiên ngày kết thúc từ sprint đã lên kế hoạch, hoặc mặc định 2 tuần
    final planned = widget.sprint.endDate;
    _endDate = planned.isAfter(_startDate)
        ? planned
        : _startDate.add(const Duration(days: 14));
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày kết thúc Sprint',
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  void _confirm() {
    if (!_endDate.isAfter(_startDate)) return;
    setState(() => _isLoading = true);
    widget.sprintBloc.add(
      SprintStartRequested(
        projectId: widget.projectId,
        sprintId: widget.sprint.id,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEndValid = _endDate.isAfter(_startDate);
    final durationDays = _endDate.difference(_startDate).inDays;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bắt đầu Sprint',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'US-049 · Chuyển Planned → Active',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // ── Tên Sprint ───────────────────────────────────────────
            _InfoRow(
              icon: Icons.directions_run_rounded,
              label: 'Sprint',
              value: widget.sprint.name,
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: 12),

            // ── Mục tiêu ─────────────────────────────────────────────
            if (widget.sprint.goal.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.flag_rounded,
                label: 'Mục tiêu',
                value: widget.sprint.goal,
                iconColor: AppColors.success,
              ),
              const SizedBox(height: 12),
            ],

            // ── Số User Story ────────────────────────────────────────
            _InfoRow(
              icon: Icons.bookmark_rounded,
              label: 'User Stories',
              value: '${widget.sprint.storyIds.length} story',
              iconColor: AppColors.warning,
            ),
            const SizedBox(height: 20),

            // ── Ngày bắt đầu (cố định = hôm nay) ───────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày bắt đầu',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatDate(_startDate),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Hôm nay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Ngày kết thúc (có thể chọn lại) ─────────────────────
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isEndValid
                      ? AppColors.surfaceContainerLow
                      : AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEndValid ? AppColors.outlineVariant : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 18,
                      color: isEndValid ? AppColors.primary : AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày kết thúc dự kiến',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDate(_endDate),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isEndValid ? AppColors.onSurface : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEndValid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$durationDays ngày',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            if (!isEndValid) ...[
              const SizedBox(height: 6),
              Text(
                'Ngày kết thúc phải sau ngày bắt đầu.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: (_isLoading || !isEndValid) ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text(
                      'Bắt đầu Sprint',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
