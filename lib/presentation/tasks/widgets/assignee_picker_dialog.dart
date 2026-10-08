import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/performance_score_model.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/performance_score_service.dart';
import '../../project_members/widgets/role_badge.dart';
import '../bloc/task_detail_cubit.dart' show memberDisplayName;

/// Kết quả chọn người phụ trách. `userId == null` = bỏ phân công.
class AssigneeSelection {
  final String? userId;
  const AssigneeSelection(this.userId);
}

/// Dialog chọn người phụ trách task (US-043) tích hợp Trợ lý AI gợi ý phân công (US-057)
/// và tính điểm hiệu suất (US-058).
Future<AssigneeSelection?> showAssigneePickerDialog({
  required BuildContext context,
  required List<ProjectMemberDisplay> members,
  required String? currentAssigneeId,
  String? projectId,
  TaskRepository? taskRepository,
  List<TaskModel>? preloadedTasks,
}) {
  return showDialog<AssigneeSelection>(
    context: context,
    builder: (_) => _AssigneePickerDialog(
      members: members,
      currentAssigneeId: currentAssigneeId,
      projectId: projectId,
      taskRepository: taskRepository,
      preloadedTasks: preloadedTasks,
    ),
  );
}

class _AssigneePickerDialog extends StatefulWidget {
  final List<ProjectMemberDisplay> members;
  final String? currentAssigneeId;
  final String? projectId;
  final TaskRepository? taskRepository;
  final List<TaskModel>? preloadedTasks;

  const _AssigneePickerDialog({
    required this.members,
    required this.currentAssigneeId,
    this.projectId,
    this.taskRepository,
    this.preloadedTasks,
  });

  @override
  State<_AssigneePickerDialog> createState() => _AssigneePickerDialogState();
}

class _AssigneePickerDialogState extends State<_AssigneePickerDialog> {
  late String? _selectedId = widget.currentAssigneeId;
  final _scoreService = const PerformanceScoreService();
  Map<String, MemberPerformanceScore> _scores = {};
  MemberPerformanceScore? _topPick;
  bool _isLoadingScores = false;

  @override
  void initState() {
    super.initState();
    _loadPerformanceScores();
  }

  Future<void> _loadPerformanceScores() async {
    if (widget.members.isEmpty) return;

    if (widget.preloadedTasks != null) {
      final list = _scoreService.calculateScores(
        members: widget.members,
        allProjectTasks: widget.preloadedTasks!,
      );
      if (mounted) {
        setState(() {
          _scores = {for (final s in list) s.userId: s};
          _topPick = list.isNotEmpty ? list.first : null;
        });
      }
      return;
    }

    if (widget.projectId != null && widget.taskRepository != null) {
      setState(() => _isLoadingScores = true);
      try {
        final tasks =
            await widget.taskRepository!.getTasksByProject(widget.projectId!);
        final list = _scoreService.calculateScores(
          members: widget.members,
          allProjectTasks: tasks,
        );
        if (mounted) {
          setState(() {
            _scores = {for (final s in list) s.userId: s};
            _topPick = list.isNotEmpty ? list.first : null;
            _isLoadingScores = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingScores = false);
      }
    }
  }

  Widget _buildAiRecommendationBanner() {
    final top = _topPick;
    if (top == null) return const SizedBox.shrink();

    final isSelected = _selectedId == top.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gợi ý phân công AI (US-057)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF6D28D9),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(top.finalScore * 100).round()}% Điểm',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🌟 Đề xuất: ${top.userName}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            top.recommendationReason.replaceFirst('🌟 Đề xuất tốt nhất: ', ''),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _selectedId = top.userId),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.bolt_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isSelected
                          ? 'Đã chọn thành viên này'
                          : 'Chọn nhanh ${top.userName}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color:
                            isSelected ? Colors.white : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(MemberPerformanceScore? score) {
    if (score == null) return const SizedBox.shrink();

    final pct = (score.finalScore * 100).round();
    final Color badgeColor = pct >= 80
        ? AppColors.success
        : pct >= 50
            ? const Color(0xFFD97706) // Vàng cam
            : AppColors.outline;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, size: 12, color: badgeColor),
                const SizedBox(width: 3),
                Text(
                  '$pct% hiệu suất',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 12,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  score.workloadText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required Key key,
    required String? userId,
    required String title,
    String? subtitle,
    Widget? trailing,
    MemberPerformanceScore? score,
  }) {
    final selected = _selectedId == userId;

    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedId = userId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.outline,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (score?.isTopPick == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AI Top 1',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(width: 6),
                        trailing,
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (score != null) ...[
                    const SizedBox(height: 3),
                    _buildScoreBadge(score),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changed = _selectedId != widget.currentAssigneeId;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Chọn người phụ trách',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
          if (_isLoadingScores)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAiRecommendationBanner(),
              _option(
                key: const Key('assignee_option_none'),
                userId: null,
                title: 'Chưa phân công',
              ),
              const Divider(height: 8),
              for (final member in widget.members)
                _option(
                  key: Key('assignee_option_${member.userId}'),
                  userId: member.userId,
                  title: memberDisplayName(member),
                  subtitle: member.user?.email,
                  score: _scores[member.userId],
                  trailing: RoleBadge(role: member.membership.role),
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
        ElevatedButton(
          key: const Key('assignee_save_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: changed
              ? () => Navigator.pop(context, AssigneeSelection(_selectedId))
              : null,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
