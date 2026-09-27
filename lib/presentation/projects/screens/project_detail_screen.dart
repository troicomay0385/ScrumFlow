import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/project_repository.dart';
import '../../backlog/screens/backlog_list_screen.dart';
import '../../project_members/widgets/role_badge.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../widgets/edit_project_dialog.dart';

/// Màn hình Chi tiết Project — không gian làm việc chính phong cách Kinetic Sprint Bento:
/// 1. Bento Header dự án: Tên, mục tiêu, role pill, action chỉnh sửa (PO).
/// 2. Bento Quick Action Modules: Product Backlog, Sprint & Kanban, Quản lý thành viên.
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
                backgroundColor: AppColors.canvas,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final project = projectSnapshot.data;
            if (project == null) {
              return Scaffold(
                backgroundColor: AppColors.canvas,
                appBar: AppBar(title: const Text('Chi tiết Project')),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_off_outlined,
                          size: 64, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Project không tồn tại hoặc đã bị xoá',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.canvas,
              appBar: AppBar(
                title: Text(
                  project.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // ── Hero Bento Header: Thông tin dự án & Mục tiêu ──────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag hàng đầu: Icon dự án + Role badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onSurface,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Agile Scrum Workspace',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentRole != null)
                              RoleBadge(role: currentRole),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Khung Mục tiêu / Mô tả dự án
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flag_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MỤC TIÊU & MÔ TẢ DỰ ÁN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                project.description.isEmpty
                                    ? 'Chưa thiết lập mục tiêu hoặc mô tả cụ thể cho dự án này.'
                                    : project.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: project.description.isEmpty
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (canManageProject) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => showEditProjectDialog(
                                context: context,
                                project: project,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: Text(
                                'Cập nhật mục tiêu',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Section Title: Không gian làm việc Scrum ───────────────
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Không gian làm việc Scrum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Bento Module 1: Product Backlog ────────────────────────
                  _buildBentoActionCard(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    iconBgColor: const Color(0xFFEEF2FF),
                    iconColor: AppColors.primary,
                    title: 'Product Backlog',
                    subtitle: 'Quản lý danh sách User Stories & độ ưu tiên',
                    tag: 'Sprint 1',
                    tagBgColor: AppColors.primary.withValues(alpha: 0.1),
                    tagTextColor: AppColors.primary,
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

                  const SizedBox(height: 12),

                  // ── Bento Module 2: Sprint & Kanban Board ──────────────────
                  _buildBentoActionCard(
                    context: context,
                    icon: Icons.speed_rounded,
                    iconBgColor: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFEA580C),
                    title: 'Sprint & Kanban Board',
                    subtitle: 'Lập kế hoạch Sprint & theo dõi tiến độ công việc',
                    tag: 'Kanban',
                    tagBgColor: const Color(0xFFFFEDD5),
                    tagTextColor: const Color(0xFFC2410C),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sprint Kanban Board đang được kết nối trong dự án này.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),

                  if (canViewMembers) ...[
                    const SizedBox(height: 28),

                    // ── Section Title: Đội ngũ & Phân quyền ────────────────────
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đội ngũ & Phân quyền',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Bento Module 3: Quản lý thành viên ────────────────────
                    _buildBentoActionCard(
                      context: context,
                      icon: Icons.group_rounded,
                      iconBgColor: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Thành viên dự án',
                      subtitle: 'Thêm thành viên, phân quyền PO / SM / Member',
                      tag: 'Roles',
                      tagBgColor: const Color(0xFFEDE9FE),
                      tagTextColor: const Color(0xFF6D28D9),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.projectMembers,
                        arguments: projectId,
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

  Widget _buildBentoActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagBgColor,
    required Color tagTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tagTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

