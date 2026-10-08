import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/sprint_review_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/sprint_review_repository.dart';

/// Hộp thoại xem và ghi nhận kết quả Sprint Review (US-023).
class SprintReviewDialog extends StatefulWidget {
  final String projectId;
  final SprintModel sprint;
  final List<UserStoryModel> stories;
  final SprintReviewRepository repository;
  final SprintReviewModel? existingReview;
  final bool canEdit;
  final String? currentUserId;
  final String? currentUserName;

  const SprintReviewDialog({
    super.key,
    required this.projectId,
    required this.sprint,
    required this.stories,
    required this.repository,
    this.existingReview,
    this.canEdit = true,
    this.currentUserId,
    this.currentUserName,
  });

  static Future<void> show({
    required BuildContext context,
    required String projectId,
    required SprintModel sprint,
    required List<UserStoryModel> stories,
    required SprintReviewRepository repository,
    SprintReviewModel? existingReview,
    bool canEdit = true,
    String? currentUserId,
    String? currentUserName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SprintReviewDialog(
        projectId: projectId,
        sprint: sprint,
        stories: stories,
        repository: repository,
        existingReview: existingReview,
        canEdit: canEdit,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }

  @override
  State<SprintReviewDialog> createState() => _SprintReviewDialogState();
}

class _SprintReviewDialogState extends State<SprintReviewDialog> {
  late final TextEditingController _demoNotesController;
  late final TextEditingController _feedbackController;

  late final Set<String> _acceptedStoryIds;
  late final Set<String> _rejectedStoryIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _demoNotesController = TextEditingController(
      text: widget.existingReview?.demoNotes ?? '',
    );
    _feedbackController = TextEditingController(
      text: widget.existingReview?.stakeholderFeedback ?? '',
    );

    _acceptedStoryIds = Set.from(
      widget.existingReview?.acceptedStoryIds ??
          widget.stories.where((s) => s.status == 'Done').map((s) => s.id),
    );
    _rejectedStoryIds = Set.from(
      widget.existingReview?.rejectedStoryIds ?? const [],
    );
  }

  @override
  void dispose() {
    _demoNotesController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_demoNotesController.text.trim().isEmpty &&
        _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tóm tắt demo hoặc ý kiến phản hồi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();

    final review = SprintReviewModel(
      id: widget.existingReview?.id ?? 'review_${now.millisecondsSinceEpoch}',
      sprintId: widget.sprint.id,
      projectId: widget.projectId,
      demoNotes: _demoNotesController.text.trim(),
      stakeholderFeedback: _feedbackController.text.trim(),
      acceptedStoryIds: _acceptedStoryIds.toList(),
      rejectedStoryIds: _rejectedStoryIds.toList(),
      reviewedBy: widget.currentUserId,
      reviewedByName: widget.currentUserName,
      createdAt: widget.existingReview?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await widget.repository.saveSprintReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('🎉 Đã ghi nhận biên bản Sprint Review thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi lưu Sprint Review: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rate_review_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biên Bản Sprint Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      widget.sprint.name,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Form body
          Expanded(
            child: ListView(
              children: [
                // 1. Tóm tắt Demo sản phẩm
                Text(
                  '1. Tóm tắt kết quả Demo',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _demoNotesController,
                  enabled: widget.canEdit && !_isSaving,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Mô tả các tính năng đã trình diễn trong buổi Sprint Demo...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Ý kiến phản hồi của các bên liên quan
                Text(
                  '2. Ý kiến phản hồi từ Khách hàng / PO',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _feedbackController,
                  enabled: widget.canEdit && !_isSaving,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhận xét từ PO hoặc Stakeholders, điểm cần cải thiện...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Đánh giá nghiệm thu từng User Story
                Text(
                  '3. Nghiệm thu User Stories (${widget.stories.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.stories.isEmpty)
                  Text(
                    'Sprint chưa có User Story nào.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  )
                else
                  ...widget.stories.map((story) {
                    final isAccepted = _acceptedStoryIds.contains(story.id);
                    final isRejected = _rejectedStoryIds.contains(story.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAccepted
                              ? AppColors.success.withValues(alpha: 0.3)
                              : isRejected
                                  ? AppColors.error.withValues(alpha: 0.3)
                                  : AppColors.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${story.storyKey}: ${story.title}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${story.storyPoints} SP • Trạng thái: ${story.status}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.canEdit) ...[
                            // Nút Chấp thuận
                            IconButton(
                              icon: Icon(
                                isAccepted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                color: isAccepted ? AppColors.success : AppColors.outline,
                                size: 22,
                              ),
                              tooltip: 'Chấp thuận nghiệm thu',
                              onPressed: () {
                                setState(() {
                                  _acceptedStoryIds.add(story.id);
                                  _rejectedStoryIds.remove(story.id);
                                });
                              },
                            ),
                            // Nút Từ chối
                            IconButton(
                              icon: Icon(
                                isRejected ? Icons.cancel_rounded : Icons.cancel_outlined,
                                color: isRejected ? AppColors.error : AppColors.outline,
                                size: 22,
                              ),
                              tooltip: 'Chưa đạt / Cần sửa',
                              onPressed: () {
                                setState(() {
                                  _rejectedStoryIds.add(story.id);
                                  _acceptedStoryIds.remove(story.id);
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          if (widget.canEdit)
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Biên Bản Sprint Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSaving ? null : _handleSave,
            ),
        ],
      ),
    );
  }
}
