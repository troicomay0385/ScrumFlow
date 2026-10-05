import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../app/constants/app_colors.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskBoardScreen extends StatelessWidget {
  final String storyId;
  final String storyTitle;

  const TaskBoardScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskBloc(
        repository: context.read<TaskRepository>(),
      )..add(TaskSubscriptionRequested(storyId)),
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
        body: _TaskBoardView(storyId: storyId),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  bloc.add(TaskCreated(
                    storyId: storyId,
                    title: title,
                    description: descController.text.trim(),
                  ));
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
  const _TaskBoardView({required this.storyId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading || state is TaskInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TaskError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        } else if (state is TaskLoaded) {
          final tasks = state.tasks;
          final todoTasks = tasks.where((t) => t.status == 'To Do').toList();
          final inProgressTasks = tasks.where((t) => t.status == 'In Progress').toList();
          final doneTasks = tasks.where((t) => t.status == 'Done').toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox.expand(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TaskColumn(title: 'To Do', status: 'To Do', tasks: todoTasks)),
                  const SizedBox(width: 10),
                  Expanded(child: _TaskColumn(title: 'In Progress', status: 'In Progress', tasks: inProgressTasks)),
                  const SizedBox(width: 10),
                  Expanded(child: _TaskColumn(title: 'Done', status: 'Done', tasks: doneTasks)),
                ],
              ),
            ),
          );
        }
        // TaskInitial fallback
        return const SizedBox.shrink();
      },
    );
  }
}

class _TaskColumn extends StatelessWidget {
  final String title;
  final String status;
  final List<TaskModel> tasks;

  const _TaskColumn({
    required this.title,
    required this.status,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
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
              color: isHovering ? AppColors.primary : AppColors.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.1))),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<TaskModel>(
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
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _TaskCard(task: task),
                      ),
                      child: _TaskCard(task: task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (task.assigneeName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  task.assigneeName!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
