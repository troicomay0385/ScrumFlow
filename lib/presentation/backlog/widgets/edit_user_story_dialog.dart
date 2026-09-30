import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/user_story_priority.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../app/utils/user_story_validator.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../bloc/edit_user_story_cubit.dart';
import '../bloc/edit_user_story_state.dart';

/// Mở hộp thoại Chỉnh sửa User Story (US-011) & Gán Story Points (US-013).
/// Trả về story đã cập nhật, hoặc `null` nếu người dùng huỷ.
Future<UserStoryModel?> showEditUserStoryDialog({
  required BuildContext context,
  required String projectId,
  required UserStoryModel story,
}) {
  final repository = context.read<BacklogRepository>();
  return showDialog<UserStoryModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => EditUserStoryCubit(repository, projectId),
      child: _EditUserStoryDialog(story: story),
    ),
  );
}

class _EditUserStoryDialog extends StatefulWidget {
  final UserStoryModel story;

  const _EditUserStoryDialog({required this.story});

  @override
  State<_EditUserStoryDialog> createState() => _EditUserStoryDialogState();
}

class _EditUserStoryDialogState extends State<_EditUserStoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String? _priority;
  late int _storyPoints;
  late DateTime? _deadline;

  /// Giá trị Story Points tiêu chuẩn Fibonacci cho Scrum.
  static const List<int> _fibonacciPoints = [1, 2, 3, 5, 8, 13, 21];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story.title);
    _descriptionController =
        TextEditingController(text: widget.story.description);
    _priority = widget.story.priority;
    _storyPoints = widget.story.storyPoints;
    _deadline = widget.story.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<EditUserStoryCubit>().submit(
          original: widget.story,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          storyPoints: _storyPoints,
          deadline: _deadline,
        );
  }

  Future<void> _pickDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? today.add(const Duration(days: 7)),
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 3)),
      helpText: 'Chọn deadline',
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditUserStoryCubit, EditUserStoryState>(
      listener: (context, state) {
        if (state is EditUserStorySuccess) {
          Navigator.of(context).pop(state.story);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is EditUserStorySubmitting;
        final errorMessage =
            state is EditUserStoryFailure ? state.message : null;

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉnh sửa User Story',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      widget.story.storyKey,
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Tiêu đề ──────────────────────────────────────
                    TextFormField(
                      key: const Key('editStory_title'),
                      controller: _titleController,
                      enabled: !isSubmitting,
                      maxLength: UserStoryValidator.maxTitleLength,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDecoration(
                        label: 'Tiêu đề *',
                        hint: 'VD: Đăng nhập bằng Google',
                        icon: Icons.title_rounded,
                      ),
                      validator: UserStoryValidator.validateTitle,
                    ),
                    const SizedBox(height: 8),

                    // ── Mô tả ────────────────────────────────────────
                    TextFormField(
                      key: const Key('editStory_description'),
                      controller: _descriptionController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: _inputDecoration(
                        label: 'Mô tả',
                        hint:
                            'Là <vai trò>, tôi muốn <mục tiêu> để <lợi ích>...',
                        icon: Icons.description_outlined,
                      ),
                      validator: UserStoryValidator.validateDescription,
                    ),
                    const SizedBox(height: 16),

                    // ── Độ ưu tiên ───────────────────────────────────
                    _sectionLabel('Độ ưu tiên *'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: UserStoryPriority.values.map((value) {
                        final selected = _priority == value;
                        return ChoiceChip(
                          key: Key('editStory_priority_$value'),
                          label: Text(UserStoryPriority.displayName(value)),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.canvas,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.outline.withValues(alpha: 0.15),
                          ),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: selected
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: isSubmitting
                              ? null
                              : (_) => setState(() => _priority = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Story Points (US-013) ─────────────────────────
                    _sectionLabel('Story Points (Fibonacci) *'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fibonacciPoints.map((sp) {
                        final selected = _storyPoints == sp;
                        return ChoiceChip(
                          key: Key('editStory_sp_$sp'),
                          label: Text(
                            '$sp',
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFB45309),
                            ),
                          ),
                          selected: selected,
                          selectedColor: const Color(0xFFB45309),
                          backgroundColor: const Color(0xFFFEF3C7),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFB45309)
                                : const Color(0xFFFDE68A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: isSubmitting
                              ? null
                              : (_) => setState(() => _storyPoints = sp),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Deadline ──────────────────────────────────────
                    _sectionLabel('Deadline (không bắt buộc)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('editStory_deadline'),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isSubmitting ? null : _pickDeadline,
                            icon: const Icon(Icons.event_rounded, size: 18),
                            label: Text(
                              _deadline == null
                                  ? 'Chưa đặt deadline'
                                  : formatDateVi(_deadline!),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_deadline != null)
                          IconButton(
                            tooltip: 'Bỏ deadline',
                            onPressed: isSubmitting
                                ? null
                                : () => setState(() => _deadline = null),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                      ],
                    ),

                    // ── Error message ─────────────────────────────────
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.onErrorContainer,
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
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('editStory_submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Lưu thay đổi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
