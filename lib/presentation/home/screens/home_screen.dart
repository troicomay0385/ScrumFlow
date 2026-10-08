import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/responsive_layout.dart';
import '../../../data/models/project_summary.dart';
import '../../../data/repositories/project_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../projects/bloc/project_list_bloc.dart';
import '../../projects/bloc/project_list_event.dart';
import '../../projects/bloc/project_list_state.dart';
import '../../projects/widgets/project_list_tile.dart';
import '../../settings/cubit/theme_cubit.dart';
import '../../settings/cubit/theme_state.dart';
import '../../settings/widgets/security_settings_dialog.dart';

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
        }
      },
      child: BlocProvider(
        create: (context) => ProjectListBloc(context.read<ProjectRepository>())
          ..add(ProjectListRequested()),
        child: Builder(builder: (context) {
          final authState = context.watch<AuthBloc>().state;
          final userName =
              authState is AuthAuthenticated ? authState.user.fullName : '';

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              actions: [
                // Nút chuyển Theme nhanh (US-030)
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    final isDark = themeState.isDark(context);
                    return IconButton(
                      tooltip: isDark ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối',
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? const Color(0xFFFBBF24) : AppColors.primaryContainer,
                      ),
                      onPressed: () => context.read<ThemeCubit>().toggleTheme(context),
                    );
                  },
                ),
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
                context.read<ProjectListBloc>().add(ProjectListRequested());
              },
              child: BlocBuilder<ProjectListBloc, ProjectListState>(
                builder: (context, state) {
                  if (state is ProjectListLoading || state is ProjectListInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProjectListError) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final projects = (state as ProjectListLoaded).projects;

                  return ResponsiveLayout(
                    mobileBuilder: (context, constraints) => _buildMobileView(
                      context: context,
                      userName: userName,
                      projects: projects,
                    ),
                    tabletBuilder: (context, constraints) => _buildTabletView(
                      context: context,
                      userName: userName,
                      projects: projects,
                      constraints: constraints,
                    ),
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

  // ── Mobile Layout (< 600px) ───────────────────────────────────
  Widget _buildMobileView({
    required BuildContext context,
    required String userName,
    required List<ProjectSummary> projects,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildGreeting(context, userName),
        const SizedBox(height: 16),
        _buildBentoStats(context, isTablet: false),
        const SizedBox(height: 20),
        _buildSectionHeader(context, projects.length),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _buildEmptyProjects(context)
        else
          ...projects.map(
            (summary) => ProjectListTile(
              summary: summary,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.projectDetail,
                arguments: summary.project.id,
              ),
            ),
          ),
      ],
    );
  }

  // ── Tablet / Desktop Layout (>= 600px) ────────────────────────
  Widget _buildTabletView({
    required BuildContext context,
    required String userName,
    required List<ProjectSummary> projects,
    required BoxConstraints constraints,
  }) {
    final crossAxisCount = constraints.maxWidth >= 1000 ? 3 : 2;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            _buildGreeting(context, userName),
            const SizedBox(height: 20),
            _buildBentoStats(context, isTablet: true),
            const SizedBox(height: 28),
            _buildSectionHeader(context, projects.length),
            const SizedBox(height: 16),
            if (projects.isEmpty)
              _buildEmptyProjects(context)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth >= 1000 ? 1.35 : 1.45,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final summary = projects[index];
                  return ProjectListTile(
                    summary: summary,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.projectDetail,
                      arguments: summary.project.id,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName.isEmpty ? 'Xin chào!' : 'Xin chào, $userName 👋',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Không gian quản lý dự án và theo dõi tiến độ Agile của bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStats(BuildContext context, {required bool isTablet}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    final itemBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                      color: Theme.of(context).colorScheme.onSurface,
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
                    color: itemBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sprint',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Đang kích hoạt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: itemBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Kanban',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Bảng tiến độ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: itemBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '100%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Text(
                        'Sẵn sàng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dự án của tôi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceContainerLow
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count dự án',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProjects(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa tham gia dự án nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bấm nút "Tạo project" bên dưới để khởi tạo dự án đầu tiên.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
