import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/sprint_review_repository.dart';
import '../../../data/repositories/sprint_retro_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../task_board/screens/task_board_screen.dart';
import '../bloc/sprint_bloc.dart';
import '../bloc/sprint_event.dart';
import '../bloc/sprint_state.dart';
import '../widgets/burndown_chart_widget.dart';
import '../widgets/close_sprint_dialog.dart';
import '../widgets/sprint_review_dialog.dart';
import '../widgets/start_sprint_dialog.dart';
import 'sprint_retro_screen.dart';

class SprintDetailScreen extends StatelessWidget {
  final String projectId;
  final String projectName;
  final String sprintId;

  const SprintDetailScreen({
	super.key,
	required this.projectId,
	required this.projectName,
	required this.sprintId,
  });

  @override
  Widget build(BuildContext context) {
	return StreamBuilder(
	  stream: context.read<ProjectMemberRepository>().streamCurrentUserRole(projectId),
	  builder: (context, roleSnapshot) {
		final canManage = hasPermission(roleSnapshot.data, Permission.manageSprint);
		return BlocConsumer<SprintBloc, SprintState>(
		  listener: (context, state) {
			if (state is SprintError || state is SprintActionCompleted) {
			  final message = state is SprintError
				  ? state.message
				  : (state as SprintActionCompleted).message;
			  ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(message)),
			  );
			}
		  },
		  builder: (context, state) {
			final sprints = switch (state) {
			  SprintLoaded(:final sprints) => sprints,
			  SprintActionCompleted(:final sprints) => sprints,
			  SprintError(:final sprints) => sprints,
			  _ => const <SprintModel>[],
			};
			if (state is SprintInitial || state is SprintLoading) {
			  return const Scaffold(
				body: Center(child: CircularProgressIndicator()),
			  );
			}
			final matches = sprints.where((sprint) => sprint.id == sprintId);
			if (matches.isEmpty) {
			  return Scaffold(
				appBar: AppBar(title: Text(projectName)),
				body: const Center(child: Text('Sprint không tồn tại hoặc đã bị xóa.')),
			  );
			}
			final sprint = matches.first;
			return Scaffold(
			  backgroundColor: AppColors.canvas,
			  appBar: AppBar(
				title: Text(sprint.name),
				actions: [
				  // ── US-049: Nút Bắt đầu Sprint (chỉ hiện khi Planned & canManage) ──
				  if (canManage && sprint.status.toLowerCase() == 'planned')
					FilledButton.icon(
					  key: const Key('sprintDetail_startSprint'),
					  onPressed: () => showStartSprintDialog(
						context: context,
						sprint: sprint,
						projectId: projectId,
					  ),
					  style: FilledButton.styleFrom(
						backgroundColor: AppColors.primary,
						shape: RoundedRectangleBorder(
						  borderRadius: BorderRadius.circular(10),
						),
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
					  ),
					  icon: const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
					  label: Text(
						'Bắt đầu',
						style: GoogleFonts.plusJakartaSans(
						  fontSize: 13,
						  fontWeight: FontWeight.w700,
						  color: Colors.white,
						),
					  ),
					),
				  // ── US-050: Nút Đóng Sprint (chỉ hiện khi Active & canManage) ──
				  if (canManage && sprint.status.toLowerCase() == 'active')
					FilledButton.icon(
					  key: const Key('sprintDetail_closeSprint'),
					  onPressed: () => _showCloseSprintDialog(context, sprint, sprints),
					  style: FilledButton.styleFrom(
						backgroundColor: const Color(0xFFDC2626),
						shape: RoundedRectangleBorder(
						  borderRadius: BorderRadius.circular(10),
						),
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
					  ),
					  icon: const Icon(Icons.flag_rounded, size: 16, color: Colors.white),
					  label: Text(
						'Đóng Sprint',
						style: GoogleFonts.plusJakartaSans(
						  fontSize: 13,
						  fontWeight: FontWeight.w700,
						  color: Colors.white,
						),
					  ),
					),
				  // Nút mở Sprint Board theo Sprint (US-055)
				  IconButton(
					key: const Key('sprintDetail_openTaskBoard'),
					icon: const Icon(Icons.view_kanban_outlined),
					tooltip: 'Xem Sprint Board',
					onPressed: () {
					  Navigator.of(context).push(
						MaterialPageRoute(
						  builder: (_) => TaskBoardScreen(
							projectId: projectId,
							projectName: projectName,
							initialSprintId: sprint.id,
						  ),
						),
					  );
					},
				  ),
				  const SizedBox(width: 4),
				],
			  ),
			  floatingActionButton: canManage
				  ? FloatingActionButton.extended(
					  onPressed: () => _showBacklogPicker(context, sprint),
					  icon: const Icon(Icons.add),
					  label: const Text('Thêm từ backlog'),
					)
				  : null,
			  body: ListView(
				padding: const EdgeInsets.all(16),
				children: [
				  Card(
					child: Padding(
					  padding: const EdgeInsets.all(16),
					  child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
						  Text('Mục tiêu Sprint', style: Theme.of(context).textTheme.titleMedium),
						  const SizedBox(height: 8),
						  Text(sprint.goal.isEmpty ? 'Chưa có mục tiêu.' : sprint.goal),
						  const SizedBox(height: 12),
						  Text('${_format(sprint.startDate)} – ${_format(sprint.endDate)} · ${sprint.status}'),
						],
					  ),
					),
				  ),
				  const SizedBox(height: 16),
				  // Nút mở Sprint Board dạng banner (US-055)
				  InkWell(
					borderRadius: BorderRadius.circular(14),
					onTap: () {
					  Navigator.of(context).push(
						MaterialPageRoute(
						  builder: (_) => TaskBoardScreen(
							projectId: projectId,
							projectName: projectName,
							initialSprintId: sprint.id,
						  ),
						),
					  );
					},
					child: Container(
					  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
					  decoration: BoxDecoration(
						gradient: AppColors.cardAccentGradient,
						borderRadius: BorderRadius.circular(14),
						boxShadow: [
						  BoxShadow(
							color: AppColors.primary.withValues(alpha: 0.2),
							blurRadius: 8,
							offset: const Offset(0, 3),
						  ),
						],
					  ),
					  child: Row(
						children: [
						  const Icon(Icons.view_kanban_rounded, color: Colors.white, size: 22),
						  const SizedBox(width: 12),
						  Expanded(
							child: Column(
							  crossAxisAlignment: CrossAxisAlignment.start,
							  children: [
								Text(
								  'Mở Sprint Board',
								  style: GoogleFonts.plusJakartaSans(
									fontSize: 14,
									fontWeight: FontWeight.w800,
									color: Colors.white,
								  ),
								),
								Text(
								  'Xem Kanban theo trạng thái (To Do / In Progress / Done)',
								  style: GoogleFonts.plusJakartaSans(
									fontSize: 11,
									color: Colors.white.withValues(alpha: 0.8),
									fontWeight: FontWeight.w500,
								  ),
								),
							  ],
							),
						  ),
						  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
						],
					  ),
					),
				  ),
				  const SizedBox(height: 12),

				  // ── Bento Hàng đôi: Sprint Review (US-023) & Sprint Retrospective (US-024) ──
				  Row(
					children: [
					  // 1. Sprint Review Bento Button
					  Expanded(
						child: Material(
						  color: Colors.transparent,
						  child: InkWell(
							borderRadius: BorderRadius.circular(16),
							onTap: () {
							  final authState = context.read<AuthBloc>().state;
							  String? uid;
							  String? name;
							  if (authState is AuthAuthenticated) {
								uid = authState.user.id;
								name = authState.user.fullName;
							  }

							  context.read<BacklogRepository>().getStoriesByIds(
									projectId,
									sprint.storyIds,
								  ).then((stories) {
								if (!context.mounted) return;
								SprintReviewDialog.show(
								  context: context,
								  projectId: projectId,
								  sprint: sprint,
								  stories: stories,
								  repository: SprintReviewRepository(),
								  canEdit: canManage,
								  currentUserId: uid,
								  currentUserName: name,
								);
							  });
							},
							child: Container(
							  padding: const EdgeInsets.all(14),
							  decoration: BoxDecoration(
								color: const Color(0xFFF0FDF4),
								borderRadius: BorderRadius.circular(16),
								border: Border.all(color: const Color(0xFFBBF7D0)),
							  ),
							  child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
								  Row(
									children: [
									  Container(
										padding: const EdgeInsets.all(6),
										decoration: BoxDecoration(
										  color: const Color(0xFFDCFCE7),
										  borderRadius: BorderRadius.circular(8),
										),
										child: const Icon(Icons.rate_review_rounded,
											size: 16, color: Color(0xFF16A34A)),
									  ),
									  const Spacer(),
									  const Icon(Icons.arrow_forward_rounded,
										  size: 16, color: Color(0xFF16A34A)),
									],
								  ),
								  const SizedBox(height: 8),
								  Text(
									'Sprint Review',
									style: GoogleFonts.plusJakartaSans(
									  fontWeight: FontWeight.w700,
									  fontSize: 13,
									  color: const Color(0xFF14532D),
									),
								  ),
								  Text(
									'Nghiệm thu demo & feedback',
									style: GoogleFonts.inter(
									  fontSize: 10,
									  color: const Color(0xFF166534),
									),
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
								  ),
								],
							  ),
							),
						  ),
						),
					  ),
					  const SizedBox(width: 10),

					  // 2. Sprint Retrospective Bento Button
					  Expanded(
						child: Material(
						  color: Colors.transparent,
						  child: InkWell(
							borderRadius: BorderRadius.circular(16),
							onTap: () {
							  Navigator.of(context).push(
								MaterialPageRoute(
								  builder: (_) => SprintRetroScreen(
									projectId: projectId,
									sprint: sprint,
									repository: SprintRetroRepository(),
								  ),
								),
							  );
							},
							child: Container(
							  padding: const EdgeInsets.all(14),
							  decoration: BoxDecoration(
								color: const Color(0xFFF5F3FF),
								borderRadius: BorderRadius.circular(16),
								border: Border.all(color: const Color(0xFFDDD6FE)),
							  ),
							  child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
								  Row(
									children: [
									  Container(
										padding: const EdgeInsets.all(6),
										decoration: BoxDecoration(
										  color: const Color(0xFFEDE9FE),
										  borderRadius: BorderRadius.circular(8),
										),
										child: const Icon(Icons.forum_rounded,
											size: 16, color: Color(0xFF7C3AED)),
									  ),
									  const Spacer(),
									  const Icon(Icons.arrow_forward_rounded,
										  size: 16, color: Color(0xFF7C3AED)),
									],
								  ),
								  const SizedBox(height: 8),
								  Text(
									'Retrospective',
									style: GoogleFonts.plusJakartaSans(
									  fontWeight: FontWeight.w700,
									  fontSize: 13,
									  color: const Color(0xFF4C1D95),
									),
								  ),
								  Text(
									'Họp cải tiến 3 cột Scrum',
									style: GoogleFonts.inter(
									  fontSize: 10,
									  color: const Color(0xFF5B21B6),
									),
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
								  ),
								],
							  ),
							),
						  ),
						),
					  ),
					],
				  ),
				  const SizedBox(height: 16),

				  // ── Burndown Chart (US-025) & Danh sách User Stories ───────
				  FutureBuilder<List<UserStoryModel>>(
					future: context.read<BacklogRepository>().getStoriesByIds(
						  projectId,
						  sprint.storyIds,
						),
					builder: (context, snapshot) {
					  if (snapshot.connectionState == ConnectionState.waiting) {
						return const Padding(
						  padding: EdgeInsets.all(24),
						  child: Center(child: CircularProgressIndicator()),
						);
					  }
					  final selected = snapshot.data ?? const <UserStoryModel>[];

					  return Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
						  // 1. Burndown Chart Widget (US-025)
						  BurndownChartWidget(sprint: sprint, stories: selected),
						  const SizedBox(height: 20),

						  // 2. Danh sách User Stories đã chọn
						  Text('User Stories đã chọn (${selected.length})',
							  style: GoogleFonts.plusJakartaSans(
								fontSize: 16,
								fontWeight: FontWeight.w800,
								color: AppColors.onSurface,
							  )),
						  const SizedBox(height: 8),

						  if (selected.isEmpty)
							const Card(
							  child: ListTile(title: Text('Chưa có User Story nào trong Sprint.')),
							)
						  else
							...selected.map(
							  (story) => Card(
								child: ListTile(
								  leading: const Icon(Icons.bookmark_border, color: AppColors.primary),
								  title: Text('${story.storyKey} · ${story.title}'),
								  subtitle: Text('${story.storyPoints} điểm · ${story.status}'),
								),
							  ),
							),
						],
					  );
					},
				  ),
				],
			  ),
			);
		  },
		);
	  },
	);
  }

  /// US-050: Mở CloseSprintDialog — load stories rồi hiện dialog
  Future<void> _showCloseSprintDialog(
    BuildContext context,
    SprintModel sprint,
    List<SprintModel> allSprints,
  ) async {
    final backlogRepo = context.read<BacklogRepository>();
    final stories = await backlogRepo.getStoriesByIds(projectId, sprint.storyIds);
    if (!context.mounted) return;

    // Chỉ lấy sprint Planned còn lại (không phải sprint đang đóng)
    final plannedSprints = allSprints
        .where((s) => s.id != sprint.id && s.status.toLowerCase() == 'planned')
        .toList();

    await showCloseSprintDialog(
      context: context,
      sprint: sprint,
      projectId: projectId,
      allStories: stories,
      otherPlannedSprints: plannedSprints,
    );
  }

  Future<void> _showBacklogPicker(BuildContext context, SprintModel sprint) async {
    final sprintBloc = context.read<SprintBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final stories = await context.read<BacklogRepository>().getUserStories(projectId);
    if (!context.mounted) return;

    final available = stories.where((story) => !sprint.storyIds.contains(story.id)).toList();
    if (available.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Không còn User Story nào trong backlog để thêm.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedIds = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isAllSelected = selectedIds.length == available.length && available.isNotEmpty;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(modalContext).height * 0.75,
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Top bar with select-all and submit button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isAllSelected,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIds.addAll(available.map((s) => s.id));
                              } else {
                                selectedIds.clear();
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Chọn User Story từ Backlog (${selectedIds.length}/${available.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () {
                                  final idsToAdd = selectedIds.toList();
                                  sprintBloc.add(
                                    SprintStoriesAddRequested(
                                      projectId: projectId,
                                      sprintId: sprint.id,
                                      storyIds: idsToAdd,
                                    ),
                                  );
                                  Navigator.pop(sheetContext);
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm ${idsToAdd.length} User Story vào Sprint.'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Thêm (${selectedIds.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Backlog items list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: available.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                      itemBuilder: (itemContext, index) {
                        final story = available[index];
                        final isChecked = selectedIds.contains(story.id);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIds.add(story.id);
                              } else {
                                selectedIds.remove(story.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  story.storyKey,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  story.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded, size: 14, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '${story.storyPoints} điểm',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(story.priority).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    story.priority,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _getPriorityColor(story.priority),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CAO':
      case 'HIGH':
        return Colors.red.shade700;
      case 'TRUNG BÌNH':
      case 'TB':
      case 'MEDIUM':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
