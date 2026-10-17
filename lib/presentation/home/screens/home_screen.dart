import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/project_summary.dart';
import '../../../data/repositories/project_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../projects/bloc/project_list_bloc.dart';
import '../../projects/bloc/project_list_event.dart';
import '../../projects/bloc/project_list_state.dart';
import '../../projects/widgets/project_list_tile.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../app/services/notification_service.dart';
import '../../common/utils/provider_utils.dart';
import '../../common/widgets/app_state_views.dart';
import '../../common/widgets/skeleton_list.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../notifications/bloc/notification_event.dart';
import '../../notifications/widgets/notification_bell_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            context.read<NotificationBloc>().add(LoadNotifications(state.user.id));
          }
        },
        child: BlocProvider(
          create: (context) => ProjectListBloc(
            context.read<ProjectRepository>(),
            connectivityService: maybeRead<ConnectivityService>(context),
          )..add(ProjectListRequested()),
          child: Builder(builder: (context) {
            final authState = context.watch<AuthBloc>().state;
            String userName = '';
            if (authState is AuthAuthenticated) {
              userName = authState.user.fullName;
              NotificationService().initialize(authState.user.id);
            }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.splitscreen_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ScrumFlow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              actions: [
                const NotificationBellWidget(),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Tooltip(
                    message: 'Hồ sơ tài khoản & Cài đặt',
                    child: InkWell(
                      onTap: () => SecuritySettingsDialog.show(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            userName.isNotEmpty
                                ? userName.substring(0, 1).toUpperCase()
                                : 'U',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: () async {
                final bloc = context.read<ProjectListBloc>()
                  ..add(ProjectListRequested());
                // Giữ vòng refresh tới khi tải xong (thành công hoặc lỗi).
                await bloc.stream.firstWhere((s) => s is! ProjectListLoading);
              },
              child: BlocBuilder<ProjectListBloc, ProjectListState>(
                builder: (context, state) {
                  if (state is ProjectListLoading || state is ProjectListInitial) {
                    return const SkeletonList(itemCount: 4, itemHeight: 96);
                  }

                  if (state is ProjectListError) {
                    return AppErrorView.fromFailure(
                      state.failure,
                      onRetry: () => context
                          .read<ProjectListBloc>()
                          .add(ProjectListRequested()),
                    );
                  }

                  final projects = (state as ProjectListLoaded).projects;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      // Greeting Hero Block
                      Text(
                        userName.isEmpty ? 'Xin chào!' : 'Xin chào, $userName 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Không gian quản lý dự án và theo dõi tiến độ Agile của bạn',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Stats Bento Overview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded,
                                        color: AppColors.primaryContainer, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tổng quan không gian làm việc',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Agile Scrum',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${projects.length}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          'Dự án tham gia',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Sprint',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Đang kích hoạt',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '100%',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        Text(
                                          'Sẵn sàng',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dự án của tôi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${projects.length} dự án',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Empty state or Projects list
                      if (projects.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Bạn chưa tham gia dự án nào',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bấm nút "Tạo project" bên dưới để khởi tạo dự án đầu tiên.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...projects.map(
                          (summary) {
                            final canManage = hasPermission(
                              summary.myRole,
                              Permission.manageProject,
                            );
                            return ProjectListTile(
                              summary: summary,
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.projectDetail,
                                arguments: summary.project.id,
                              ),
                              onDelete: canManage
                                  ? () => _confirmDeleteProject(context, summary)
                                  : null,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Tạo project',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              onPressed: () async {
                final created = await Navigator.of(context)
                    .pushNamed(AppRoutes.createProject);
                if (created == true && context.mounted) {
                  context.read<ProjectListBloc>().add(ProjectListRequested());
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    ProjectSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xoá dự án',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xoá dự án "${summary.project.name}"?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác. Toàn bộ dữ liệu Backlog, Sprint, Task và thành viên sẽ bị mất.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Xoá vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context
          .read<ProjectListBloc>()
          .add(ProjectDeleteRequested(summary.project.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🗑️ Đã xoá dự án "${summary.project.name}".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

