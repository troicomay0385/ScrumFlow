import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';
import '../bloc/project_members_state.dart';
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
        appBar: AppBar(title: const Text('Quản lý thành viên')),
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
                  backgroundColor: state.actionStatus == MemberActionStatus.success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            }
            context.read<ProjectMembersBloc>().add(ProjectMemberActionAcknowledged());
          },
          builder: (context, state) {
            if (state is ProjectMembersLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tải thành viên...'),
                    ],
                  ),
                ),
              );
            }

            if (state is ProjectMembersError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }

            if (state is ProjectMembersAccessDenied) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Bạn không có quyền xem danh sách thành viên của project này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            final loaded = state as ProjectMembersLoaded;
            final canChangeRole =
                hasPermission(loaded.currentUserRole, Permission.changeMemberRole);
            final bloc = context.read<ProjectMembersBloc>();

            if (loaded.members.isEmpty) {
              return const Center(child: Text('Chưa có thành viên'));
            }

            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: loaded.members.length,
                  itemBuilder: (context, index) {
                    final member = loaded.members[index];
                    return MemberListTile(
                      member: member,
                      onTapRole: canChangeRole
                          ? () => showChangeRoleDialog(
                                context: context,
                                member: member,
                                bloc: bloc,
                              )
                          : null,
                    );
                  },
                ),
                if (loaded.actionStatus == MemberActionStatus.inProgress)
                  Container(
                    color: AppColors.overlay,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Đang cập nhật...'),
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
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm thành viên'),
            );
          },
        ),
      ),
    );
  }
}
