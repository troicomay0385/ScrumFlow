import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';
import '../bloc/sprint_bloc.dart';
import '../bloc/sprint_event.dart';

/// US-050: Dialog đóng Sprint.
///
/// Hiển thị thống kê User Stories Done vs. chưa xong.
/// Cho phép chọn:
/// - Chuyển story chưa xong về Product Backlog (targetSprintId = null)
/// - Chuyển sang Sprint tiếp theo
Future<void> showCloseSprintDialog({
  required BuildContext context,
  required SprintModel sprint,
  required String projectId,
  required List<UserStoryModel> allStories,
  required List<SprintModel> otherPlannedSprints,
}) async {
  final sprintBloc = context.read<SprintBloc>();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CloseSprintDialog(
      sprint: sprint,
      projectId: projectId,
      allStories: allStories,
      otherPlannedSprints: otherPlannedSprints,
      sprintBloc: sprintBloc,
    ),
  );
}

class _CloseSprintDialog extends StatefulWidget {
  final SprintModel sprint;
  final String projectId;
  final List<UserStoryModel> allStories;
  final List<SprintModel> otherPlannedSprints;
  final SprintBloc sprintBloc;

  const _CloseSprintDialog({
    required this.sprint,
    required this.projectId,
    required this.allStories,
    required this.otherPlannedSprints,
    required this.sprintBloc,
  });

  @override
  State<_CloseSprintDialog> createState() => _CloseSprintDialogState();
}

class _CloseSprintDialogState extends State<_CloseSprintDialog> {
  /// null = về Product Backlog; non-null = ID của sprint tiếp theo
  String? _targetSprintId;
  bool _isLoading = false;

  List<UserStoryModel> get _doneStories =>
      widget.allStories.where((s) => s.status == 'Done').toList();

  List<UserStoryModel> get _incompleteStories =>
      widget.allStories.where((s) => s.status != 'Done').toList();

  void _confirm() {
    setState(() => _isLoading = true);
    final incompleteIds = _incompleteStories.map((s) => s.id).toList();
    widget.sprintBloc.add(
      SprintCloseRequested(
        projectId: widget.projectId,
        sprintId: widget.sprint.id,
        targetSprintId: _targetSprintId,
        incompleteStoryIds: incompleteIds,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final done = _doneStories;
    final incomplete = _incompleteStories;
    final total = widget.allStories.length;
    final donePercent = total == 0 ? 0.0 : done.length / total;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đóng Sprint',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'US-050 · Chuyển Active → Completed',
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

              // ── Tên Sprint ─────────────────────────────────────────
              Text(
                widget.sprint.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              if (widget.sprint.goal.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.sprint.goal,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),

              // ── Thống kê Done / Chưa xong ─────────────────────────
              Text(
                'Thống kê User Stories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: donePercent,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.check_circle_rounded,
                    label: '${done.length} Hoàn thành',
                    color: AppColors.success,
                    bgColor: AppColors.success.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.pending_rounded,
                    label: '${incomplete.length} Chưa xong',
                    color: AppColors.warning,
                    bgColor: AppColors.warning.withValues(alpha: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Xử lý story chưa xong ─────────────────────────────
              if (incomplete.isNotEmpty) ...[
                Text(
                  'Chuyển ${incomplete.length} Story chưa hoàn thành sang:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Lựa chọn: Product Backlog
                _DestinationOption(
                  isSelected: _targetSprintId == null,
                  onTap: () => setState(() => _targetSprintId = null),
                  icon: Icons.inbox_rounded,
                  title: 'Product Backlog',
                  subtitle: 'Story trở về danh sách backlog chờ xử lý',
                  iconColor: AppColors.secondary,
                ),
                const SizedBox(height: 6),

                // Lựa chọn: Sprint tiếp theo (nếu có)
                ...widget.otherPlannedSprints.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _DestinationOption(
                      isSelected: _targetSprintId == s.id,
                      onTap: () => setState(() => _targetSprintId = s.id),
                      icon: Icons.directions_run_rounded,
                      title: s.name,
                      subtitle: 'Sprint đang lên kế hoạch (Planned)',
                      iconColor: AppColors.primary,
                    ),
                  ),
                ),
              ] else ...[
                // Tất cả story đã Done
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tuyệt vời! Tất cả User Stories đã hoàn thành! 🎉',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Actions ────────────────────────────────────────────
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
                      onPressed: _isLoading ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
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
                          : const Icon(Icons.flag_rounded, size: 18),
                      label: Text(
                        'Đóng Sprint',
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
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationOption extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _DestinationOption({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withValues(alpha: 0.08)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? iconColor : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: iconColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }
}
