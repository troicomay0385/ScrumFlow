import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/services/notification_service.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../data/models/attachment_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../attachments/widgets/attachments_section.dart';
import '../../comments/widgets/comments_section.dart';
import '../bloc/task_detail_cubit.dart';
import '../bloc/task_detail_state.dart';
import '../widgets/assignee_picker_dialog.dart';

/// Chi tiết 1 Task: thông tin, người phụ trách (US-043), deadline (US-044)
/// và bình luận (US-046).
class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  final String projectId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskDetailCubit(
        taskRepository: context.read<TaskRepository>(),
        memberRepository: context.read<ProjectMemberRepository>(),
        projectId: projectId,
        task: task,
      )..start(),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView();

  Future<void> _pickAssignee(BuildContext context, TaskDetailState state) async {
    final cubit = context.read<TaskDetailCubit>();
    final selection = await showAssigneePickerDialog(
      context: context,
      members: state.members,
      currentAssigneeId: state.task?.assigneeId,
      projectId: cubit.projectId,
      taskRepository: context.read<TaskRepository>(),
    );
    if (selection != null) await cubit.changeAssignee(selection.userId);
  }

  Future<void> _pickDeadline(BuildContext context, TaskModel task) async {
    final cubit = context.read<TaskDetailCubit>();
    final today = DateUtils.dateOnly(DateTime.now());
    final current = task.deadline;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today) ? current : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
      helpText: 'Chọn deadline',
    );
    if (picked != null) await cubit.setDeadline(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailCubit, TaskDetailState>(
      listenWhen: (previous, current) =>
          current.message != null &&
          (previous.status != current.status ||
              previous.message != current.message),
      listener: (context, state) {
        final isError = state.status == TaskDetailStatus.failure;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(state.message!),
            backgroundColor: isError ? AppColors.error : AppColors.success,
          ));
      },
      builder: (context, state) {
        final task = state.task;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: Text(
              'Chi tiết Task',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: task == null
              ? Center(
                  child: Text(
                    'Task này đã bị xoá.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(task),
                      const SizedBox(height: 16),
                      _buildAssignment(context, state, task),
                      const SizedBox(height: 16),
                      if (state.projectLinked) ...[
                        AttachmentsSection(
                          target: AttachmentTarget.task(
                            projectId:
                                context.read<TaskDetailCubit>().projectId,
                            taskId: task.id,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CommentsSection(
                          target: CommentTarget.task(
                            projectId:
                                context.read<TaskDetailCubit>().projectId,
                            taskId: task.id,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _buildHeader(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            task.description.isNotEmpty
                ? task.description
                : 'Chưa có mô tả cho task này.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: task.description.isNotEmpty
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignment(
    BuildContext context,
    TaskDetailState state,
    TaskModel task,
  ) {
    final assigneeName = task.assigneeName;
    final hasAssignee = assigneeName != null && assigneeName.isNotEmpty;
    final deadline = task.deadline;
    final isOverdue = deadline != null &&
        task.status != 'Done' &&
        deadline.isBefore(DateUtils.dateOnly(DateTime.now()));
    final busy = state.isSaving;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldTile(
            key: const Key('task_assignee_tile'),
            label: 'Người phụ trách',
            value: hasAssignee ? assigneeName : 'Chưa phân công',
            muted: !hasAssignee,
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            onTap: state.canAssign && state.membersLoaded && !busy
                ? () => _pickAssignee(context, state)
                : null,
          ),
          const SizedBox(height: 12),
          _FieldTile(
            key: const Key('task_deadline_tile'),
            label: 'Deadline',
            value: deadline != null
                ? '${formatDateVi(deadline)}${isOverdue ? ' · Quá hạn' : ''}'
                : 'Chưa đặt',
            muted: deadline == null,
            valueColor: isOverdue ? AppColors.error : null,
            icon: Icons.event_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBgColor: const Color(0xFFE0F2FE),
            trailing: deadline != null && state.canSetDeadline
                ? IconButton(
                    key: const Key('task_deadline_clear'),
                    tooltip: 'Xoá deadline',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: busy
                        ? null
                        : () =>
                            context.read<TaskDetailCubit>().setDeadline(null),
                  )
                : const Icon(
                    Icons.edit_calendar_outlined,
                    color: Color(0xFF0284C7),
                  ),
            onTap: state.canSetDeadline && !busy
                ? () => _pickDeadline(context, task)
                : null,
          ),
          if (deadline != null) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final diff = deadline.difference(DateTime.now());
                await NotificationService().showTaskDeadlineAlert(
                  taskTitle: task.title,
                  deadline: deadline,
                  hoursRemaining: diff.inHours > 0 ? diff.inHours : null,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 Đã kích hoạt Local Notification nhắc hạn chót trên thiết bị! (US-059)'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alarm_on_rounded,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhắc nhở hạn chót (US-059): Chạm để nhận thông báo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

/// 1 dòng thông tin bấm được (người phụ trách / deadline).
class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  final Color? valueColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _FieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.muted,
    this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBgColor,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                        color: valueColor ??
                            (muted
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
