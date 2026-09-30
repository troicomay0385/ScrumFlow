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
  late final TextEditingController _searchController;

  /// Nhãn chip filter → giá trị status (`null` = "Tất cả").
  static const Map<String, String?> _statusFilters = {
    'Tất cả': null,
    'To Do': 'To Do',
    'In Progress': 'In Progress',
    'Done': 'Done',
  };

  /// Role real-time của user trong project
  late final Stream<ProjectRole?> _roleStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _roleStream = context
        .read<ProjectMemberRepository>()
        .streamCurrentUserRole(widget.projectId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showFilterBottomSheet(BuildContext context, BacklogLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String tempStatus = state.statusFilter ?? 'Tất cả';
        String tempPriority = state.priorityFilter ?? 'Tất cả';
        String tempTag = state.tagFilter ?? 'Tất cả';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F0F172A),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bộ lọc Backlog',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempStatus = 'Tất cả';
                                  tempPriority = 'Tất cả';
                                  tempTag = 'Tất cả';
                                });
                              },
                              child: Text(
                                'Đặt lại',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.surfaceVariant),

                  // Filter Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Trạng thái (Status)
                          Text(
                            'LỌC THEO TRẠNG THÁI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Tất cả',
                              'To Do',
                              'In Progress',
                              'Done',
                              'Rejected'
                            ].map((status) {
                              final isSelected = tempStatus == status;
                              return ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline
                                          .withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempStatus = status);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Section 2: Mức độ ưu tiên (Priority)
                          Text(
                            'LỌC THEO MỨC ƯU TIÊN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Tất cả', 'CAO', 'TB', 'THẤP']
                                .map((priority) {
                              final isSelected = tempPriority == priority;
                              return ChoiceChip(
                                label: Text(priority),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline
                                          .withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempPriority = priority);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Section 3: Lọc theo Tag
                          Text(
                            'LỌC THEO NHÃN (TAG)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Tất cả',
                              ...state.stories.expand((s) => s.tags).toSet()
                            ].map((tag) {
                              final isSelected = tempTag == tag;
                              return ChoiceChip(
                                label: Text(tag),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline
                                          .withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempTag = tag);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          context.read<BacklogBloc>().add(
                                BacklogStatusFilterChanged(
                                    tempStatus == 'Tất cả' ? null : tempStatus),
                              );
                          context.read<BacklogBloc>().add(
                                BacklogPriorityFilterChanged(
                                    tempPriority == 'Tất cả'
                                        ? null
                                        : tempPriority),
                              );
                          context.read<BacklogBloc>().add(
                                BacklogTagFilterChanged(
                                    tempTag == 'Tất cả' ? null : tempTag),
                              );
                          Navigator.pop(bottomSheetContext);
                        },
                        child: Text(
                          'Áp dụng bộ lọc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProjectRole?>(
      stream: _roleStream,
      builder: (context, roleSnapshot) {
        final role = roleSnapshot.data;
        final canManageBacklog = role != null &&
            hasPermission(role, Permission.manageBacklog);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Backlog',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  widget.projectName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Cài đặt bảo mật',
                icon: const Icon(Icons.security_rounded,
                    color: AppColors.onSurfaceVariant),
                onPressed: () => SecuritySettingsDialog.show(context),
              ),
              IconButton(
                tooltip: 'Dữ liệu mẫu',
                icon: const Icon(Icons.auto_fix_high_rounded,
                    color: AppColors.primary),
                onPressed: () => _seedMockStories(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: canManageBacklog
              ? FloatingActionButton.extended(
                  key: const Key('backlog_fab_create'),
                  onPressed: _openCreateDialog,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Tạo Story',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
          body: BlocBuilder<BacklogBloc, BacklogState>(
            builder: (context, state) {
              if (state is BacklogLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is BacklogError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<BacklogBloc>().add(
                                BacklogSubscriptionRequested(widget.projectId));
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is BacklogLoaded) {
                if (state.stories.isEmpty) {
                  return _buildEmptyState(context, canManageBacklog);
                }

                final totalPoints = state.stories.fold<int>(
                    0, (sum, story) => sum + story.storyPoints);

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<BacklogBloc>().add(
                        BacklogSubscriptionRequested(widget.projectId));
                  },
                  child: CustomScrollView(
                    slivers: [
                      // ── Header Summary Card & Search ─────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KPI Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'TỔNG STORIES',
                                      value: '${state.stories.length}',
                                      icon: Icons.layers_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      title: 'STORY POINTS',
                                      value: '$totalPoints',
                                      icon: Icons.bolt_rounded,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Search Bar & Filter Modal Button (US-007, US-008)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (query) {
                                        context
                                            .read<BacklogBloc>()
                                            .add(BacklogSearchChanged(query));
                                        setState(() {});
                                      },
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: AppColors.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Tìm theo mã, tiêu đề, tag, assignee...',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18),
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      context
                                                          .read<BacklogBloc>()
                                                          .add(const BacklogSearchChanged(
                                                              ''));
                                                      setState(() {});
                                                    },
                                                  )
                                                : null,
                                        filled: true,
                                        fillColor: AppColors.surface,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: AppColors.outline
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: AppColors.outline
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Button Mở Modal Bộ Lọc (US-008)
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton.filledTonal(
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              state.activeFilterCount > 0
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.15)
                                                  : AppColors.surface,
                                          foregroundColor:
                                              state.activeFilterCount > 0
                                                  ? AppColors.primary
                                                  : AppColors.onSurfaceVariant,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: state.activeFilterCount > 0
                                                  ? AppColors.primary
                                                  : AppColors.outline.withValues(
                                                      alpha: 0.15),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                        icon: const Icon(Icons.tune_rounded,
                                            size: 20),
                                        onPressed: () =>
                                            _showFilterBottomSheet(
                                                context, state),
                                      ),
                                      if (state.activeFilterCount > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${state.activeFilterCount}',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Status filter chips & Sort selector
                              _buildStatusFilters(context, state),
                              const SizedBox(height: 12),
                              _buildSortSelector(context, state),
                            ],
                          ),
                        ),
                      ),

                      // ── Backlog Stories List ────────────────────────────────
                      if (state.visibleStories.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không tìm thấy User Story nào',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thử thay đổi từ khóa tìm kiếm hoặc đặt lại các bộ lọc đang chọn.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<BacklogBloc>().add(
                                          const BacklogFilterResetRequested());
                                    },
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Đặt lại bộ lọc'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final story = state.visibleStories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: UserStoryCard(
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
                                  ),
                                );
                              },
                              childCount: state.visibleStories.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              backgroundColor: AppColors.surface,
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
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.15),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BacklogSortOption>(
                key: const Key('backlog_sortDropdown'),
                value: state.sortOption,
                borderRadius: BorderRadius.circular(14),
                isExpanded: true,
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
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
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
        ),
      ],
    );
  }
}
