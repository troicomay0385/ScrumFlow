import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/sprint_repository.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../../sprints/widgets/move_to_sprint_dialog.dart';
import '../bloc/backlog_bloc.dart';
import '../bloc/backlog_event.dart';
import '../bloc/backlog_state.dart';
import '../utils/backlog_view.dart';
import '../widgets/compact_user_story_row.dart';
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

  /// Tập hợp ID các User Story được chọn bằng checkbox (US-053).
  final Set<String> _selectedStoryIds = {};

  /// Chế độ hiển thị: `true` = Gọn (~46px/dòng - US-052), `false` = Thẻ chi tiết.
  bool _isCompactView = true;

  /// Trang hiện tại (US-051 / US-052).
  int _currentPage = 0;

  /// Số item trên 1 trang (mặc định 10).
  final int _pageSize = 10;

  /// Role real-time của user trong project.
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



  Future<void> _handleBatchDelete(BuildContext parentContext) async {
    if (_selectedStoryIds.isEmpty) return;
    final count = _selectedStoryIds.length;
    final confirm = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận xóa $count User Story?'),
        content: Text(
          'Hành động này sẽ xóa vĩnh viễn $count User Story đã chọn khỏi Product Backlog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa hàng loạt'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final idsToDelete = List<String>.from(_selectedStoryIds);
      setState(() => _selectedStoryIds.clear());
      if (!mounted) return;
      context.read<BacklogBloc>().add(
            BacklogDeleteStoriesRequested(
              projectId: widget.projectId,
              storyIds: idsToDelete,
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa $count User Story.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleBatchMove(BuildContext parentContext) async {
    if (_selectedStoryIds.isEmpty) return;
    final targetSprintId = await MoveToSprintDialog.show(
      context: parentContext,
      projectId: widget.projectId,
      selectedCount: _selectedStoryIds.length,
    );

    if (targetSprintId != null && mounted) {
      final idsToMove = List<String>.from(_selectedStoryIds);
      setState(() => _selectedStoryIds.clear());
      try {
        if (targetSprintId != '__BACKLOG__') {
          if (!mounted) return;
          await context.read<SprintRepository>().addStoriesToSprint(
                projectId: widget.projectId,
                sprintId: targetSprintId,
                storyIds: idsToMove,
              );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã di chuyển ${idsToMove.length} User Story vào Sprint.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi di chuyển: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
          IconButton(
            icon: Icon(
              _isCompactView ? Icons.view_agenda_outlined : Icons.view_list_rounded,
              color: AppColors.primary,
            ),
            tooltip: _isCompactView ? 'Xem dạng Thẻ chi tiết' : 'Xem dạng Hàng gọn (10+ dòng)',
            onPressed: () {
              setState(() {
                _isCompactView = !_isCompactView;
              });
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

            final visibleStories = state.visibleStories;

            // Phân trang (US-051 / US-052)
            final totalPages = (visibleStories.length / _pageSize).ceil();
            final safePage = _currentPage >= totalPages
                ? (totalPages > 0 ? totalPages - 1 : 0)
                : _currentPage;
            final startIndex = safePage * _pageSize;
            final pageStories = visibleStories.isEmpty
                ? <UserStoryModel>[]
                : visibleStories
                    .skip(startIndex)
                    .take(_pageSize)
                    .toList();

            final totalPoints =
                allStories.fold<int>(0, (sum, s) => sum + s.storyPoints);

            return Column(
              children: [
                // Bulk action bar khi có mục được chọn bằng checkbox (US-053)
                if (_selectedStoryIds.isNotEmpty && canManageBacklog)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedStoryIds.length == visibleStories.length,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStoryIds
                                    .addAll(visibleStories.map((s) => s.id));
                              } else {
                                _selectedStoryIds.clear();
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          'Đã chọn ${_selectedStoryIds.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleBatchMove(context),
                          icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                          label: const Text('Di chuyển'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleBatchDelete(context),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ),

                // Summary KPI Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusFilters(context, state),
                      const SizedBox(height: 8),
                      _buildSortSelector(context, state),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.surfaceVariant),

                // Stories List (Support Compact View & Card View)
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
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: pageStories.length,
                          separatorBuilder: (_, _) => SizedBox(
                            height: _isCompactView ? 0 : 10,
                          ),
                          itemBuilder: (context, index) {
                            final story = pageStories[index];
                            final isSelected = _selectedStoryIds.contains(story.id);

                            if (_isCompactView) {
                              return CompactUserStoryRow(
                                key: ValueKey(story.id),
                                story: story,
                                isSelected: isSelected,
                                showCheckbox: canManageBacklog,
                                onSelectChanged: canManageBacklog
                                    ? (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedStoryIds.add(story.id);
                                          } else {
                                            _selectedStoryIds.remove(story.id);
                                          }
                                        });
                                      }
                                    : null,
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
                            }

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

                // Thanh Phân Trang (Pagination Controls Bar - US-051 / US-052 / US-054)
                if (visibleStories.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.only(left: 16, right: 16, top: 8, bottom: canManageBacklog ? 80 : 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trang ${safePage + 1} / ${totalPages == 0 ? 1 : totalPages} (${visibleStories.length} mục)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: safePage > 0
                                      ? () => setState(() => _currentPage = safePage - 1)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: safePage < totalPages - 1
                                      ? () => setState(() => _currentPage = safePage + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Nút "Tải thêm từ server" (server-side pagination — US-054)
                        if (state.hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: () {
                                      context.read<BacklogBloc>().add(
                                            BacklogNextPageRequested(
                                              projectId: widget.projectId,
                                            ),
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.cloud_download_outlined,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      'Tải thêm từ server',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),
                      ],
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
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
                      'Vui lòng kiểm tra kết nối mạng và thử lại sau.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
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
              'Hãy bắt đầu bằng cách bấm nút bên dưới để thêm User Story thủ công.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (canManageBacklog) ...[
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
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Tạo User Story mới',
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
                  setState(() => _currentPage = 0);
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
                  setState(() => _currentPage = 0);
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
