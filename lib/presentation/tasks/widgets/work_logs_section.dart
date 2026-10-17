import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../app/utils/work_log_validator.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/work_log_model.dart';
import '../../../data/repositories/work_log_repository.dart';
import '../bloc/work_logs_cubit.dart';
import '../bloc/work_logs_state.dart';
import 'log_work_bottom_sheet.dart';

/// Card Bento hiển thị danh sách thời gian làm việc (Work Log) trong [TaskDetailScreen] (US-066).
class WorkLogsSection extends StatelessWidget {
  final TaskModel task;
  final String projectId;
  final WorkLogsCubit? cubit;

  const WorkLogsSection({
    super.key,
    required this.task,
    required this.projectId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<WorkLogsCubit>.value(
        value: cubit!,
        child: _WorkLogsCard(task: task, projectId: projectId),
      );
    }

    return BlocProvider(
      create: (ctx) => WorkLogsCubit(
        ctx.read<WorkLogRepository>(),
        taskId: task.id,
      ),
      child: _WorkLogsCard(task: task, projectId: projectId),
    );
  }
}

class _WorkLogsCard extends StatelessWidget {
  final TaskModel task;
  final String projectId;

  const _WorkLogsCard({
    required this.task,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkLogsCubit, WorkLogsState>(
      builder: (context, state) {
        final cubit = context.read<WorkLogsCubit>();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 14),
              _buildBody(context, state, onRetry: cubit.retry),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WorkLogsState state) {
    final totalHours = task.loggedHours > 0
        ? task.loggedHours
        : state.workLogs.fold<double>(0.0, (sum, l) => sum + l.hours);
    final hoursStr = '${WorkLogValidator.formatHours(totalHours)} giờ';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giờ làm việc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'Tổng: $hoursStr',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          key: const Key('work_logs_add_button'),
          onPressed: () => showLogWorkBottomSheet(
            context,
            task: task,
            projectId: projectId,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Ghi giờ'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WorkLogsState state, {
    required VoidCallback onRetry,
  }) {
    switch (state.status) {
      case WorkLogsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

      case WorkLogsStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.errorMessage ?? 'Không thể tải danh sách giờ làm việc',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              key: const Key('work_logs_retry_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        );

      case WorkLogsStatus.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Chưa có giờ làm việc nào',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        );

      case WorkLogsStatus.loaded:
        return Column(
          children: [
            for (var i = 0; i < state.workLogs.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _WorkLogItem(log: state.workLogs[i]),
            ],
          ],
        );
    }
  }
}

/// Widget hiển thị 1 bản ghi Work Log (không cho phép sửa/xoá để tuân thủ quy tắc).
class _WorkLogItem extends StatelessWidget {
  final WorkLogModel log;

  const _WorkLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final name =
        log.userName.trim().isEmpty ? 'Thành viên' : log.userName.trim();
    final hoursFormatted = WorkLogValidator.formatHours(log.hours);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    AppColors.primaryContainer.withValues(alpha: 0.15),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$hoursFormatted giờ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatDateVi(log.workDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatRelativeTimeVi(log.createdAt),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (log.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.note,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
