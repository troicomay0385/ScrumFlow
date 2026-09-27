import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/project_repository.dart';
import '../../backlog/screens/backlog_list_screen.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../widgets/edit_project_dialog.dart';

/// Màn hình Chi tiết Project — không gian làm việc chính để:
/// 1. Quản trị viên/PO chỉnh sửa thông tin, cập nhật mục tiêu hoặc mô tả dự án.
/// 2. Điều hướng và quản lý Product Backlog & Sprint.
/// 3. Quản lý và thêm thành viên vào project để cùng tham gia làm việc.
class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final projectRepository = context.read<ProjectRepository>();
    final memberRepository = context.read<ProjectMemberRepository>();

    return StreamBuilder<ProjectRole?>(
      stream: memberRepository.streamCurrentUserRole(projectId),
      builder: (context, roleSnapshot) {
        final currentRole = roleSnapshot.data;
        final canManageProject =
            hasPermission(currentRole, Permission.manageProject);
        final canViewMembers =
            hasPermission(currentRole, Permission.viewMembers);

        return StreamBuilder<ProjectModel?>(
          stream: projectRepository.streamProject(projectId),
          builder: (context, projectSnapshot) {
            if (projectSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final project = projectSnapshot.data;
            if (project == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chi tiết Project')),
                body: const Center(
                  child: Text('Project không tồn tại hoặc đã bị xoá'),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(project.name),
                actions: [
                  if (canManageProject)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Chỉnh sửa thông tin dự án',
                      onPressed: () => showEditProjectDialog(
                        context: context,
                        project: project,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Cài đặt bảo mật & Vân tay',
                    onPressed: () => SecuritySettingsDialog.show(context),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Card Thông tin & Mục tiêu dự án ───────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (currentRole != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    currentRole.displayName,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Mục tiêu & Mô tả:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.description.isEmpty
                                ? 'Chưa có mục tiêu hoặc mô tả cụ thể.'
                                : project.description,
                            style: TextStyle(
                              color: project.description.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          if (canManageProject) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => showEditProjectDialog(
                                  context: context,
                                  project: project,
                                ),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Cập nhật mục tiêu / mô tả'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Quản lý Backlog & Sprint ────────────────────────────────
                  const Text(
                    'Không gian làm việc Scrum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.view_list_rounded, color: Colors.green),
                      ),
                      title: const Text(
                        'Product Backlog',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Quản lý danh sách User Stories & độ ưu tiên',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BacklogListScreen(
                              projectId: project.id,
                              projectName: project.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.speed_rounded, color: Colors.orange),
                      ),
                      title: const Text(
                        'Sprint & Kanban Board',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Lập kế hoạch Sprint & theo dõi tiến độ công việc',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Quản lý Sprint sẵn sàng cho dự án này.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Thành viên & Tham gia làm việc ──────────────────────────
                  if (canViewMembers) ...[
                    const Text(
                      'Thành viên & Phân quyền',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEDE7F6),
                          child: Icon(Icons.group_rounded, color: AppColors.primary),
                        ),
                        title: const Text(
                          'Quản lý thành viên',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Thêm thành viên, phân quyền PO / SM / Member',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.projectMembers,
                          arguments: projectId,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
