import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../data/models/project_summary.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/sprint_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../common/utils/provider_utils.dart';
import '../../common/widgets/app_state_views.dart';
import '../../sprints/bloc/sprint_bloc.dart';
import '../../sprints/bloc/sprint_event.dart';
import '../../sprints/screens/sprint_detail_screen.dart';
import '../../tasks/utils/task_status_style.dart';
import '../bloc/sprint_dashboard_cubit.dart';
import '../bloc/sprint_dashboard_state.dart';
import 'doughnut_chart.dart';

/// Card Bento hiển thị tiến độ Sprint đang chạy (US-065).
///
/// - Hỗ trợ đa dự án qua hàng chip cuộn ngang.
/// - Hiển thị tên Sprint, số ngày còn lại / quá hạn.
/// - Doughnut Chart trực quan với chú giải 3 trạng thái (Done, In Progress, To Do).
/// - Nhấn vào card mở [SprintDetailScreen].
class SprintDashboardCard extends StatefulWidget {
  final List<ProjectSummary> projects;
  final SprintDashboardCubit? cubit;
  final void Function(SprintModel sprint)? onSprintTap;

  const SprintDashboardCard({
    super.key,
    required this.projects,
    this.cubit,
    this.onSprintTap,
  });

  @override
  State<SprintDashboardCard> createState() => _SprintDashboardCardState();
}

class _SprintDashboardCardState extends State<SprintDashboardCard> {
  late final SprintDashboardCubit _cubit;
  late final bool _isExternalCubit;
  late String _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId =
        widget.projects.isNotEmpty ? widget.projects.first.project.id : '';

    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _isExternalCubit = true;
    } else {
      _cubit = SprintDashboardCubit(
        context.read<SprintRepository>(),
        context.read<TaskRepository>(),
        connectivity: maybeRead<ConnectivityService>(context),
      );
      _isExternalCubit = false;
    }

    if (_selectedProjectId.isNotEmpty) {
      _cubit.load(_selectedProjectId);
    }
  }

  @override
  void didUpdateWidget(covariant SprintDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects && widget.projects.isNotEmpty) {
      final exists =
          widget.projects.any((p) => p.project.id == _selectedProjectId);
      if (!exists) {
        _selectedProjectId = widget.projects.first.project.id;
        _cubit.load(_selectedProjectId);
      }
    }
  }

  @override
  void dispose() {
    if (!_isExternalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _onProjectSelected(String projectId) {
    if (_selectedProjectId == projectId) return;
    setState(() {
      _selectedProjectId = projectId;
    });
    _cubit.load(projectId);
  }

  String _formatRemainingDays(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return 'Đã quá hạn';
    } else if (diff == 0) {
      return 'Hạn chót hôm nay';
    } else {
      return 'Còn $diff ngày';
    }
  }

  bool _isOverdue(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(endDate.year, endDate.month, endDate.day);
    return target.difference(today).inDays < 0;
  }

  void _handleCardTap(SprintModel sprint) {
    if (widget.onSprintTap != null) {
      widget.onSprintTap!(sprint);
      return;
    }

    final project = widget.projects.firstWhere(
      (p) => p.project.id == sprint.projectId,
      orElse: () => widget.projects.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (navContext) {
          final sprintRepo = maybeRead<SprintRepository>(context);
          final memberRepo = maybeRead<ProjectMemberRepository>(context);
          final sprintBloc = maybeRead<SprintBloc>(context);

          Widget screen = SprintDetailScreen(
            projectId: sprint.projectId,
            projectName: project.project.name,
            sprintId: sprint.id,
          );

          if (sprintBloc == null && sprintRepo != null) {
            screen = BlocProvider<SprintBloc>(
              create: (c) => SprintBloc(
                repository: sprintRepo,
                connectivityService: maybeRead<ConnectivityService>(c),
              )..add(SprintSubscriptionRequested(sprint.projectId)),
              child: screen,
            );
          } else if (sprintBloc != null) {
            screen = BlocProvider<SprintBloc>.value(
              value: sprintBloc,
              child: screen,
            );
          }

          if (memberRepo != null) {
            screen = RepositoryProvider<ProjectMemberRepository>.value(
              value: memberRepo,
              child: screen,
            );
          }

          return screen;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerTheme.color ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return BlocBuilder<SprintDashboardCubit, SprintDashboardState>(
      bloc: _cubit,
      builder: (context, state) {
        final sprint = state.sprint;
        final isLoaded = state.status == SprintDashboardStatus.loaded &&
            sprint != null &&
            state.progress != null;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoaded ? () => _handleCardTap(sprint) : null,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chip chọn dự án (nếu có từ 2 dự án trở lên)
                    if (widget.projects.length > 1) ...[
                      _buildProjectChips(context, isDark, borderColor),
                      const SizedBox(height: 12),
                    ],

                    // Header: Tên Sprint + thời hạn
                    _buildHeader(context, sprint, isLoaded),
                    const SizedBox(height: 14),

                    // Body: phụ thuộc vào State
                    _buildBody(context, state, isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectChips(
    BuildContext context,
    bool isDark,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: widget.projects.map((p) {
          final isSelected = p.project.id == _selectedProjectId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                p.project.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryContainer,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : borderColor,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  _onProjectSelected(p.project.id);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SprintModel? sprint,
    bool isLoaded,
  ) {
    final title = sprint != null ? sprint.name : 'Tiến độ Sprint';
    final remainingText =
        sprint != null ? _formatRemainingDays(sprint.endDate) : null;
    final overdue = sprint != null && _isOverdue(sprint.endDate);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.donut_large_rounded,
            color: AppColors.primaryContainer,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (remainingText != null) ...[
                const SizedBox(height: 2),
                Text(
                  remainingText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: overdue ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isLoaded)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    SprintDashboardState state,
    bool isDark,
  ) {
    switch (state.status) {
      case SprintDashboardStatus.loading:
        return _buildLoadingSkeleton(context, isDark);
      case SprintDashboardStatus.noSprint:
        return _buildNoSprint(context);
      case SprintDashboardStatus.error:
        return _buildError(context, state);
      case SprintDashboardStatus.loaded:
        if (state.progress != null && state.sprint != null) {
          return _buildLoadedContent(context, state);
        }
        return _buildLoadingSkeleton(context, isDark);
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context, bool isDark) {
    final placeholderColor = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: placeholderColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 110,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: 130,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSprint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed_rounded,
            size: 28,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            'Chưa có Sprint đang chạy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, SprintDashboardState state) {
    final failure = state.failure ?? const AppFailure.unknown();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: AppErrorView.fromFailure(
        failure,
        onRetry: _cubit.retry,
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    SprintDashboardState state,
  ) {
    final progress = state.progress!;
    final doneColor = taskStatusColor(context, 'Done');
    final inProgressColor = taskStatusColor(context, 'In Progress');
    final todoColor = taskStatusColor(context, 'To Do');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Doughnut Chart
            DoughnutChart(
              todo: progress.todo,
              inProgress: progress.inProgress,
              done: progress.done,
              centerTitle: '${progress.donePercent}%',
              centerSubtitle: '${progress.done}/${progress.total} task',
              size: 104,
            ),
            const SizedBox(width: 16),

            // Chú giải 3 dòng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendRow(
                    context,
                    label: 'Done',
                    count: progress.done,
                    color: doneColor,
                  ),
                  const SizedBox(height: 6),
                  _buildLegendRow(
                    context,
                    label: 'In Progress',
                    count: progress.inProgress,
                    color: inProgressColor,
                  ),
                  const SizedBox(height: 6),
                  _buildLegendRow(
                    context,
                    label: 'To Do',
                    count: progress.todo,
                    color: todoColor,
                  ),
                  if (progress.total == 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Sprint chưa có task',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendRow(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
