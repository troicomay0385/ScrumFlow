import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../bloc/backlog_bloc.dart';
import '../bloc/backlog_event.dart';
import '../bloc/backlog_state.dart';
import '../utils/backlog_view.dart';
import '../widgets/create_user_story_dialog.dart';
import '../widgets/user_story_card.dart';
import 'user_story_detail_screen.dart';

class BacklogListScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const BacklogListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BacklogBloc(repository: context.read<BacklogRepository>())
            ..add(BacklogSubscriptionRequested(projectId)),
      child: _BacklogListView(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}

class _BacklogListView extends StatefulWidget {
  final String projectId;
  final String projectName;

  const _BacklogListView({
    required this.projectId,
    required this.projectName,
  });

  @override
  State<_BacklogListView> createState() => _BacklogListViewState();
}

class _BacklogListViewState extends State<_BacklogListView> {
  /// Nhãn chip filter → giá trị status (`null` = "Tất cả").
  static const Map<String, String?> _statusFilters = {
    'Tất cả': null,
    'To Do': 'To Do',
    'In Progress': 'In Progress',
    'Done': 'Done',
  };

  /// Role real-time của user trong project — quyết định hiển thị nút tạo
  /// story / sửa tag qua `hasPermission(Permission.manageBacklog)`.
  late final Stream<ProjectRole?> _roleStream;

  @override
  void initState() {
    super.initState();
    _roleStream = context
        .read<ProjectMemberRepository>()
        .streamCurrentUserRole(widget.projectId);
  }

  Future<void> _openCreateDialog() async {
    final created = await showCreateUserStoryDialog(
      context: context,
      projectId: widget.projectId,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo ${created.storyKey}: ${created.title}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _seedMockStories(BuildContext context) {
    context.read<BacklogBloc>().add(BacklogSeedMockRequested(widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectRole?>(
      stream: _roleStream,
      builder: (context, roleSnapshot) {
        final canManageBacklog =
            hasPermission(roleSnapshot.data, Permission.manageBacklog);
        return _buildScaffold(context, canManageBacklog);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, bool canManageBacklog) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: canManageBacklog
          ? FloatingActionButton.extended(
              key: const Key('backlog_createStory'),
              onPressed: _openCreateDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Tạo User Story',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Backlog',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              widget.projectName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<BacklogBloc, BacklogState>(
            builder: (context, state) {
              final isSeeding = state is BacklogLoaded && state.isSeeding;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: isSeeding
                      ? null
                      : () {
                          _seedMockStories(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang nạp 8 User Stories mẫu và User ảo...'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: isSeeding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded,
                          color: AppColors.primary, size: 18),
                  label: Text(
                    isSeeding ? 'Đang tạo...' : 'Nạp mẫu',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt bảo mật & Vân tay',
            onPressed: () => SecuritySettingsDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<BacklogBloc, BacklogState>(
        listener: (context, state) {
          if (state is BacklogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BacklogLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is BacklogLoaded) {
            final allStories = state.stories;

            if (allStories.isEmpty) {
              return _buildEmptyState(context, canManageBacklog);
            }

            // Filter + sort đã được BacklogBloc áp dụng (US-009)
            final visibleStories = state.visibleStories;

            final totalPoints =
                allStories.fold<int>(0, (sum, s) => sum + s.storyPoints);

            return Column(
              children: [
                // Summary KPI Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_list_bulleted_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tổng cộng: ${allStories.length} User Stories',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 14, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              '$totalPoints SP',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter tabs + Sort selector
                Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusFilters(context, state),
                      const SizedBox(height: 10),
                      _buildSortSelector(context, state),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.surfaceVariant),

                // Stories List
                Expanded(
                  child: visibleStories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Không có User Story nào ở trạng thái này.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          // Chừa chỗ cho FAB "Tạo User Story" không che thẻ cuối.
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: visibleStories.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final story = visibleStories[index];
                            return UserStoryCard(
                              key: ValueKey(story.id),
                              story: story,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserStoryDetailScreen(
                                      story: story,
                                      canManageBacklog: canManageBacklog,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is BacklogError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Chưa đồng bộ được với Cloud Firestore',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn vẫn có thể kiểm thử toàn diện US-005 (Backlog) & US-006 (Chi tiết Story) với 8 User Stories mẫu và 4 User ảo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _seedMockStories(context),
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text(
                        'Nạp 8 User Stories Mẫu',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
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
  }

  Widget _buildEmptyState(BuildContext context, bool canManageBacklog) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Product Backlog đang trống',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bấm nút bên dưới để tự động nạp 8 User Stories mẫu của Sprint 1 & Sprint 2 kèm User ảo để kiểm thử tính năng.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () => _seedMockStories(context),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                'Nạp 8 User Stories Mẫu',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (canManageBacklog) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Tạo User Story đầu tiên',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context, BacklogLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.entries.map((entry) {
          final isSelected = state.statusFilter == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.canvas,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outline.withValues(alpha: 0.15),
              ),
              labelStyle: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                if (selected) {
                  context
                      .read<BacklogBloc>()
                      .add(BacklogStatusFilterChanged(entry.value));
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Dropdown "Sắp xếp theo" (US-009) — chỉ đổi thứ tự hiển thị.
  Widget _buildSortSelector(BuildContext context, BacklogLoaded state) {
    return Row(
      children: [
        const Icon(Icons.sort_rounded,
            size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          'Sắp xếp theo:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BacklogSortOption>(
              key: const Key('backlog_sortDropdown'),
              value: state.sortOption,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              items: BacklogSortOption.values
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ))
                  .toList(),
              onChanged: (option) {
                if (option != null) {
                  context.read<BacklogBloc>().add(BacklogSortChanged(option));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
