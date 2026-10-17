import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';
import '../bloc/project_members_state.dart';
import '../../common/widgets/app_state_views.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/change_role_dialog.dart';
import '../widgets/member_list_tile.dart';

class ProjectMembersScreen extends StatelessWidget {
  final String projectId;

  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectMembersBloc(
        context.read<ProjectMemberRepository>(),
      )..add(ProjectMembersStarted(projectId)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Quản lý thành viên',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocConsumer<ProjectMembersBloc, ProjectMembersState>(
          listenWhen: (previous, current) =>
              current is ProjectMembersLoaded &&
              current.actionStatus != MemberActionStatus.idle &&
              current.actionStatus != MemberActionStatus.inProgress,
          listener: (context, state) {
            if (state is! ProjectMembersLoaded) return;
            final message = state.actionMessage;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor:
                      state.actionStatus == MemberActionStatus.success
                          ? AppColors.success
                          : AppColors.error,
                ),
              );
            }
            context
                .read<ProjectMembersBloc>()
                .add(ProjectMemberActionAcknowledged());
          },
          builder: (context, state) {
            if (state is ProjectMembersLoading) {
              return const AppLoadingView(
                message: 'Đang tải danh sách thành viên...',
              );
            }

            if (state is ProjectMembersError) {
              return AppErrorView.fromFailure(
                state.failure,
                onRetry: () => context
                    .read<ProjectMembersBloc>()
                    .add(ProjectMembersStarted(projectId)),
              );
            }

            if (state is ProjectMembersAccessDenied) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 48, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Bạn không có quyền xem danh sách thành viên của project này.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state as ProjectMembersLoaded;
            final canChangeRole =
                hasPermission(loaded.currentUserRole, Permission.changeMemberRole);
            final canManageMembers =
                hasPermission(loaded.currentUserRole, Permission.manageMembers);
            String? currentUid;
            try {
              currentUid = FirebaseAuth.instance.currentUser?.uid;
            } catch (_) {}
            final bloc = context.read<ProjectMembersBloc>();

            if (loaded.members.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_off_outlined,
                        size: 56, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có thành viên nào trong dự án',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Member count header banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Tổng cộng: ${loaded.members.length} thành viên',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'RBAC Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),

                    // Member list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: loaded.members.length,
                        itemBuilder: (context, index) {
                          final member = loaded.members[index];
                          final isSelf = member.userId == currentUid;
                          return MemberListTile(
                            member: member,
                            onTapRole: canChangeRole
                                ? () => showChangeRoleDialog(
                                      context: context,
                                      member: member,
                                      bloc: bloc,
                                    )
                                : null,
                            // US-041: nút xoá chỉ hiện khi có quyền VÀ không phải chính mình
                            onRemove: (canManageMembers && !isSelf)
                                ? () => bloc.add(
                                      ProjectMemberRemoveRequested(member.userId),
                                    )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (loaded.actionStatus == MemberActionStatus.inProgress)
                  Container(
                    color: AppColors.overlay,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Đang cập nhật quyền thành viên...',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final state = context.watch<ProjectMembersBloc>().state;
            if (state is! ProjectMembersLoaded) return const SizedBox.shrink();
            if (!hasPermission(state.currentUserRole, Permission.manageMembers)) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              onPressed: () => showAddMemberDialog(
                context: context,
                bloc: context.read<ProjectMembersBloc>(),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(
                'Thêm thành viên',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


