import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/sprint_repository.dart';

/// Sprint Board hiển thị các User Stories theo từng Sprint dưới dạng bảng Kanban
/// với 3 cột: To Do, In Progress, Done (US-055).
///
/// Người dùng chọn Sprint từ dropdown ở AppBar. Danh sách User Stories
/// được load theo `storyIds` của Sprint đã chọn thông qua
/// [BacklogRepository.getStoriesByIds] — KHÔNG load toàn bộ Backlog.
class TaskBoardScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  /// Sprint ID mặc định khi mở (vd. mở từ SprintDetailScreen).
  /// Nếu null → chọn Sprint đầu tiên (Active > Planned > Closed).
  final String? initialSprintId;

  const TaskBoardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialSprintId,
  });

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  /// Danh sách Sprint của project (stream real-time).
  List<SprintModel> _sprints = [];

  /// Sprint đang được chọn để xem Task Board.
  SprintModel? _selectedSprint;

  /// User Stories thuộc Sprint đang chọn.
  List<UserStoryModel> _stories = [];

  /// Đang tải dữ liệu sprint/story.
  bool _isLoading = true;

  /// Đang tải stories khi đổi sprint.
  bool _isLoadingStories = false;

  late final Stream<List<SprintModel>> _sprintStream;

  @override
  void initState() {
    super.initState();
    _sprintStream = context.read<SprintRepository>().streamSprints(widget.projectId);
    _sprintStream.listen(_onSprintsChanged);
  }

  void _onSprintsChanged(List<SprintModel> sprints) {
    if (!mounted) return;
    setState(() {
      _sprints = sprints;
      _isLoading = false;
    });

    // Tự chọn Sprint: initial > Active đầu tiên > Planned đầu tiên > sprint đầu tiên
    if (_selectedSprint == null && sprints.isNotEmpty) {
      SprintModel? target;
      if (widget.initialSprintId != null) {
        target = sprints
            .where((s) => s.id == widget.initialSprintId)
            .firstOrNull;
      }
      target ??= sprints.where((s) => s.status == 'Active').firstOrNull;
      target ??= sprints.where((s) => s.status == 'Planned').firstOrNull;
      target ??= sprints.first;
      _selectSprint(target);
    } else if (_selectedSprint != null) {
      // Refresh lại Sprint hiện tại nếu storyIds thay đổi
      final updated = sprints.where((s) => s.id == _selectedSprint!.id).firstOrNull;
      if (updated != null && updated.storyIds.length != _selectedSprint!.storyIds.length) {
        _selectSprint(updated);
      }
    }
  }

  Future<void> _selectSprint(SprintModel sprint) async {
    setState(() {
      _selectedSprint = sprint;
      _isLoadingStories = true;
    });

    try {
      final stories = await context.read<BacklogRepository>().getStoriesByIds(
            widget.projectId,
            sprint.storyIds,
          );
      if (mounted) {
        setState(() {
          _stories = stories;
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải User Stories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
              'Sprint Board',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _sprints.isEmpty
              ? _buildEmptySprints()
              : Column(
                  children: [
                    _buildSprintSelector(),
                    const Divider(height: 1, thickness: 1, color: AppColors.surfaceVariant),
                    Expanded(
                      child: _isLoadingStories
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          : _buildKanbanBoard(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptySprints() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.dashboard_customize_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có Sprint nào',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo Sprint và thêm User Stories vào Sprint để xem Task Board.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dropdown chọn Sprint ở thanh trên.
  Widget _buildSprintSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Sprint:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('taskboard_sprintDropdown'),
                  value: _selectedSprint?.id,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  items: _sprints.map((sprint) {
                    return DropdownMenuItem(
                      value: sprint.id,
                      child: Row(
                        children: [
                          _buildSprintStatusDot(sprint.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${sprint.name} (${sprint.storyIds.length} stories)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (sprintId) {
                    if (sprintId == null) return;
                    final sprint = _sprints.firstWhere((s) => s.id == sprintId);
                    _selectSprint(sprint);
                  },
                ),
              ),
            ),
          ),
          // Sprint info chip
          if (_selectedSprint != null) ...[
            const SizedBox(width: 8),
            _buildSprintStatusBadge(_selectedSprint!.status),
          ],
        ],
      ),
    );
  }

  Widget _buildSprintStatusDot(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'planned':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.outline;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSprintStatusBadge(String status) {
    Color textColor;
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'active':
        textColor = const Color(0xFF047857);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'planned':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Bảng Kanban 3 cột cuộn ngang: To Do → In Progress → Done.
  Widget _buildKanbanBoard() {
    if (_stories.isEmpty && _selectedSprint != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_kanban_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Sprint "${_selectedSprint!.name}" chưa có User Story nào.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thêm User Stories vào Sprint từ Sprint Detail hoặc Product Backlog.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final toDo = _stories.where((s) => s.status == 'To Do').toList();
    final inProgress = _stories.where((s) => s.status == 'In Progress').toList();
    final done = _stories.where((s) => s.status == 'Done').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn(
            title: 'To Do',
            stories: toDo,
            color: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
            icon: Icons.radio_button_unchecked_rounded,
          ),
          const SizedBox(width: 12),
          _buildColumn(
            title: 'In Progress',
            stories: inProgress,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            icon: Icons.timelapse_rounded,
          ),
          const SizedBox(width: 12),
          _buildColumn(
            title: 'Done',
            stories: done,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFD1FAE5),
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required List<UserStoryModel> stories,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    // Chiều rộng cột: tối thiểu 280px, responsive theo màn hình
    final columnWidth = (MediaQuery.sizeOf(context).width - 48) / 3;
    final effectiveWidth = columnWidth < 280 ? 280.0 : columnWidth;

    return SizedBox(
      width: effectiveWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cột
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stories.length}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Danh sách card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: stories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Trống',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: stories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _buildStoryCard(stories[index], color);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(UserStoryModel story, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story key + Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  story.storyKey,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              _buildPriorityBadge(story.priority),
            ],
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            story.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Bottom row: Story Points + Assignee
          Row(
            children: [
              // Story Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 10, color: Color(0xFFB45309)),
                    const SizedBox(width: 2),
                    Text(
                      '${story.storyPoints}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Tags
              if (story.tags.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: story.tags.take(2).map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const Spacer(),
              // Assignee avatar
              if (story.assigneeName != null && story.assigneeName!.isNotEmpty)
                Tooltip(
                  message: story.assigneeName!,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    child: Text(
                      story.assigneeName!.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toUpperCase()) {
      case 'CAO':
        color = AppColors.error;
        break;
      case 'TB':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        priority,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
