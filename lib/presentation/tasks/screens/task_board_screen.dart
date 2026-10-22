import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../app/utils/work_log_validator.dart';
import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../ai/bloc/sprint_risk_cubit.dart';
import '../../ai/bloc/sprint_risk_state.dart';
import '../../ai/widgets/risk_badge.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/log_work_bottom_sheet.dart';
import '../widgets/swipeable_task_card.dart';
import 'task_detail_screen.dart';

T? _maybeRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}

class TaskBoardScreen extends StatelessWidget {
  final String storyId;
  final String storyTitle;

  /// Project chứa User Story — dùng để lấy danh sách thành viên khi đổi
  /// người phụ trách và để gắn task/bình luận vào đúng project.
  final String projectId;
  final RiskPredictionService? riskPredictionService;

  const TaskBoardScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.projectId,
    this.riskPredictionService,
  });

  @override
  Widget build(BuildContext context) {
    final taskRepo = context.read<TaskRepository>();
    final memberRepo = _maybeRead<ProjectMemberRepository>(context);
    final aiService =
        riskPredictionService ??
        _maybeRead<RiskPredictionService>(context) ??
        RiskPredictionService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              TaskBloc(repository: taskRepo)
                ..add(TaskSubscriptionRequested(storyId)),
        ),
        BlocProvider(
          create: (_) => SprintRiskCubit(
            projectId: projectId,
            predictionService: aiService,
            taskRepository: taskRepo,
            memberRepository: memberRepo,
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Board',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                storyTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (innerContext) => FloatingActionButton.extended(
            onPressed: () => _showCreateTaskDialog(innerContext),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              'Tạo Task',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        body: _TaskBoardView(storyId: storyId, projectId: projectId),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final bloc = context.read<TaskBloc>(); // lấy bloc TRƯỚC khi mở dialog
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tạo Task mới',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Tên Task *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  bloc.add(
                    TaskCreated(
                      storyId: storyId,
                      title: title,
                      description: descController.text.trim(),
                      projectId: projectId,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}

class _TaskBoardView extends StatelessWidget {
  final String storyId;
  final String projectId;
  const _TaskBoardView({required this.storyId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final memberRepo = _maybeRead<ProjectMemberRepository>(context);
    final roleStream = memberRepo?.streamCurrentUserRole(projectId) ??
        Stream<ProjectRole?>.value(null);

    return StreamBuilder<ProjectRole?>(
      stream: roleStream,
      builder: (context, roleSnapshot) {
        final canViewAi = hasPermission(
          roleSnapshot.data,
          Permission.viewAiInsights,
        );

        return MultiBlocListener(
          listeners: [
            BlocListener<TaskBloc, TaskState>(
              listenWhen: (previous, current) => current is TaskError,
              listener: (context, state) {
                if (state is TaskError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            BlocListener<TaskBloc, TaskState>(
              listenWhen: (previous, current) => current is TaskLoaded,
              listener: (context, state) {
                if (state is TaskLoaded) {
                  context.read<SprintRiskCubit>().evaluateTasksList(
                    tasks: state.tasks,
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<TaskBloc, TaskState>(
            buildWhen: (previous, current) =>
                current is! TaskError || previous is! TaskLoaded,
            builder: (context, state) {
              if (state is TaskLoading || state is TaskInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TaskError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Lỗi: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              } else if (state is TaskLoaded) {
                final tasks = state.tasks;
                final todoTasks = tasks
                    .where((t) => t.status == 'To Do')
                    .toList();
                final inProgressTasks = tasks
                    .where((t) => t.status == 'In Progress')
                    .toList();
                final doneTasks = tasks
                    .where((t) => t.status == 'Done')
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox.expand(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TaskColumn(
                            title: 'To Do',
                            status: 'To Do',
                            tasks: todoTasks,
                            projectId: projectId,
                            canViewAi: canViewAi,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TaskColumn(
                            title: 'In Progress',
                            status: 'In Progress',
                            tasks: inProgressTasks,
                            projectId: projectId,
                            canViewAi: canViewAi,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TaskColumn(
                            title: 'Done',
                            status: 'Done',
                            tasks: doneTasks,
                            projectId: projectId,
                            canViewAi: canViewAi,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

class _TaskColumn extends StatelessWidget {
  final String title;
  final String status;
  final List<TaskModel> tasks;
  final String projectId;
  final bool canViewAi;

  const _TaskColumn({
    required this.title,
    required this.status,
    required this.tasks,
    required this.projectId,
    this.canViewAi = false,
  });

  @override
  Widget build(BuildContext context) {
    final riskCubit = _maybeRead<SprintRiskCubit>(context);

    return DragTarget<TaskModel>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.status != status) {
          context.read<TaskBloc>().add(TaskStatusUpdated(task.id, status));
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.primaryContainer.withValues(alpha: 0.2)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering
                  ? AppColors.primary
                  : AppColors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Text(
                  '$title (${tasks.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: riskCubit != null
                    ? BlocBuilder<SprintRiskCubit, SprintRiskState>(
                        builder: (context, riskState) =>
                            _buildList(context, riskState),
                      )
                    : _buildList(context, null),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, SprintRiskState? riskState) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final prediction = canViewAi
            ? riskState?.predictionForTask(task.id)
            : null;

        return SwipeableTaskCard(
          task: task,
          onStatusChange: (newStatus) {
            context.read<TaskBloc>().add(TaskStatusUpdated(task.id, newStatus));

            final columnContext = context;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!columnContext.mounted) return;
              showLogWorkBottomSheet(
                columnContext,
                task: task.copyWith(status: newStatus),
                projectId: projectId,
              );
            });
          },
          child: LongPressDraggable<TaskModel>(
            data: task,
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  task.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: TaskCard(task: task, riskPrediction: prediction),
            ),
            // Bấm vào thẻ → Task Detail (assignee, deadline, bình luận).
            child: GestureDetector(
              key: Key('task_card_${task.id}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailScreen(task: task, projectId: projectId),
                ),
              ),
              child: TaskCard(task: task, riskPrediction: prediction),
            ),
          ),
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskRiskPrediction? riskPrediction;

  const TaskCard({
    super.key,
    required this.task,
    this.riskPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final deadline = task.deadline;
    final isOverdue =
        deadline != null &&
        task.status != 'Done' &&
        deadline.isBefore(DateUtils.dateOnly(DateTime.now()));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (riskPrediction != null && riskPrediction!.isPredictable) ...[
            const SizedBox(height: 6),
            TaskCardRiskChip(prediction: riskPrediction),
          ],
          if (task.assigneeName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.assigneeName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (deadline != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: isOverdue
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formatDateVi(deadline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isOverdue
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (task.loggedHours > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    key: Key('task_logged_hours_chip_${task.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${WorkLogValidator.formatHours(task.loggedHours)}h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
