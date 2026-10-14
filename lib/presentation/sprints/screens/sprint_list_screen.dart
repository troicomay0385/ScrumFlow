import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/authorization/permission.dart';
import '../../../app/authorization/role_permissions.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../data/models/sprint_model.dart';
// SprintModel import confirmed — no changes required
import '../../../data/repositories/sprint_repository.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../app/services/connectivity_service.dart';
import '../../common/utils/provider_utils.dart';
import '../../common/widgets/app_state_views.dart';
import '../../common/widgets/skeleton_list.dart';
import 'sprint_detail_screen.dart';
import '../../task_board/screens/task_board_screen.dart';
import '../widgets/create_sprint_dialog.dart';
import '../bloc/sprint_bloc.dart';
import '../bloc/sprint_event.dart';
import '../bloc/sprint_state.dart';

class SprintListScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const SprintListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SprintBloc(
        repository: context.read<SprintRepository>(),
        connectivityService: maybeRead<ConnectivityService>(context),
      )..add(SprintSubscriptionRequested(projectId)),
      child: _SprintListView(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}

class _SprintListView extends StatelessWidget {
  final String projectId;
  final String projectName;

  const _SprintListView({
    required this.projectId,
    required this.projectName,
  });

  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'active':
        textColor = const Color(0xFF047857);
        bgColor = const Color(0xFFD1FAE5);
        borderColor = const Color(0xFFA7F3D0);
        break;
      case 'planned':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      case 'closed':
      default:
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách Sprint',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              projectName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Nút mở Sprint Board (US-055)
          IconButton(
            key: const Key('sprintList_openTaskBoard'),
            tooltip: 'Sprint Board',
            icon: const Icon(Icons.view_kanban_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskBoardScreen(
                    projectId: projectId,
                    projectName: projectName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: StreamBuilder(
        stream: context
            .read<ProjectMemberRepository>()
            .streamCurrentUserRole(projectId),
        builder: (context, snapshot) {
          if (!hasPermission(snapshot.data, Permission.manageSprint)) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => showCreateSprintDialog(
              context: context,
              projectId: projectId,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tạo Sprint'),
          );
        },
      ),
      body: BlocConsumer<SprintBloc, SprintState>(
        listener: (context, state) {
          if (state is SprintError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is SprintActionCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is SprintLoading || state is SprintInitial) {
            return const SkeletonList(itemCount: 4, itemHeight: 110);
          }

          if (state is SprintLoadFailure) {
            return AppErrorView.fromFailure(
              state.failure,
              onRetry: () => context
                  .read<SprintBloc>()
                  .add(SprintSubscriptionRequested(projectId)),
            );
          }

          final sprints = switch (state) {
            SprintLoaded(:final sprints) => sprints,
            SprintActionCompleted(:final sprints) => sprints,
            SprintError(:final sprints) => sprints,
            _ => const <SprintModel>[],
          };
          if (state is SprintLoaded || state is SprintActionCompleted || state is SprintError) {

            if (sprints.isEmpty) {
              return const AppEmptyView(
                icon: Icons.directions_run_rounded,
                title: 'Chưa có Sprint nào',
                message:
                    'Bấm nút dấu cộng (+) ở góc dưới để tạo Sprint mới thủ công.',
              );
            }

            return ListView.separated(
              // Chừa khoảng dưới để nút "Tạo Sprint" không che thẻ cuối (US-055).
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: sprints.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sprint = sprints[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SprintBloc>(),
                        child: SprintDetailScreen(
                          projectId: projectId,
                          projectName: projectName,
                          sprintId: sprint.id,
                        ),
                      ),
                    ),
                  ),
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.1),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên dài tự xuống dòng (tối đa 2 dòng) thay vì
                          // đẩy badge trạng thái ra ngoài màn hình (US-055).
                          Expanded(
                            child: Text(
                              sprint.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(sprint.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sprint.goal,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.date_range_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${formatDateVi(sprint.startDate)} - ${formatDateVi(sprint.endDate)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
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

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
