import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../data/models/attachment_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../attachments/widgets/attachments_section.dart';
import '../../comments/widgets/comments_section.dart';
import '../../tasks/screens/task_board_screen.dart';
import '../bloc/story_tags_cubit.dart';
import '../widgets/delete_user_story_dialog.dart';
import '../widgets/edit_user_story_dialog.dart';
import '../widgets/story_tags_card.dart';

class UserStoryDetailScreen extends StatefulWidget {
  final UserStoryModel story;

  /// User hiện tại có `Permission.manageBacklog` (PO/SM) → được sửa tag.
  final bool canManageBacklog;

  const UserStoryDetailScreen({
    super.key,
    required this.story,
    this.canManageBacklog = false,
  });

  @override
  State<UserStoryDetailScreen> createState() => _UserStoryDetailScreenState();
}

class _UserStoryDetailScreenState extends State<UserStoryDetailScreen> {
  late UserStoryModel _story;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
  }

  Widget _buildPriorityBadge(String priority) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (priority.toUpperCase()) {
      case 'CAO':
      case 'HIGH':
      case 'URGENT':
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFECACA);
        break;
      case 'TB':
      case 'TRUNG BÌNH':
      case 'MEDIUM':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      default:
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            priority,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'done':
        textColor = const Color(0xFF047857);
        bgColor = const Color(0xFFD1FAE5);
        borderColor = const Color(0xFFA7F3D0);
        break;
      case 'in progress':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      default: // To Do
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final canManageBacklog = widget.canManageBacklog;

    return BlocProvider(
      create: (context) => StoryTagsCubit(
        context.read<BacklogRepository>(),
        projectId: story.projectId,
        storyId: story.id,
        initialTags: story.tags,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(
            story.storyKey,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            if (canManageBacklog) ...[
              IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Sửa User Story',
                onPressed: () async {
                  final updated = await showEditUserStoryDialog(
                    context: context,
                    projectId: story.projectId,
                    story: story,
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _story = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật User Story thành công'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                tooltip: 'Xóa User Story',
                onPressed: () async {
                  final deleted = await showDeleteUserStoryDialog(
                    context: context,
                    projectId: story.projectId,
                    story: story,
                  );
                  if (deleted == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã xóa ${story.storyKey} thành công'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.of(context).pop(); // Back to list
                  }
                },
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Header Card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            story.storyKey,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildPriorityBadge(story.priority),
                            const SizedBox(width: 8),
                            _buildStatusBadge(story.status),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      story.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Task Board Navigation Button ────────────────────────────────
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskBoardScreen(
                        storyId: story.id,
                        storyTitle: story.title,
                        projectId: story.projectId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.view_kanban_outlined),
                label: Text(
                  'Xem Task Board',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Description Bento Card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Nội dung User Story & Mô tả',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        story.description.isNotEmpty
                            ? story.description
                            : 'Chưa có mô tả chi tiết cho User Story này.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tags Bento Card (US-014) ────────────────────────────────────
              StoryTagsCard(canEdit: canManageBacklog),
              const SizedBox(height: 16),

              // ── Agile Metrics Bento Card ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            size: 18,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Thông số Agile / Scrum',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Story Points',
                            value: '${story.storyPoints} SP',
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFFB45309),
                            iconBgColor: const Color(0xFFFEF3C7),
                            isMono: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Trạng thái',
                            value: story.status,
                            icon: Icons.flag_rounded,
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            isMono: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricTile(
                      label: 'Deadline',
                      value: story.deadline != null
                          ? formatDateVi(story.deadline!)
                          : 'Chưa đặt deadline',
                      icon: Icons.event_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFFE0F2FE),
                      isMono: story.deadline != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Assignee Bento Card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Người phụ trách (Assignee)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (story.assigneeName != null &&
                        story.assigneeName!.isNotEmpty) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryContainer
                                .withValues(alpha: 0.15),
                            child: Text(
                              story.assigneeName!.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.assigneeName!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                if (story.assigneeEmail != null)
                                  Text(
                                    story.assigneeEmail!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa gán người phụ trách cho User Story này.',
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Attachments Bento Card (US-047) ────────────────────────────
              AttachmentsSection(
                target: AttachmentTarget.story(
                  projectId: story.projectId,
                  storyId: story.id,
                ),
              ),
              const SizedBox(height: 16),

              // ── Comments Bento Card (US-045) ────────────────────────────────
              CommentsSection(
                target: CommentTarget.story(
                  projectId: story.projectId,
                  storyId: story.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isMono,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBgColor,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: isMono
                      ? GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.onSurface,
                        )
                      : GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
}
