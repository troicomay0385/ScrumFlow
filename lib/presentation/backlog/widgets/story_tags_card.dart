import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/user_story_validator.dart';
import '../bloc/story_tags_cubit.dart';
import '../bloc/story_tags_state.dart';
import 'story_tag_chip.dart';

/// Bento card "Nhãn / Tags" trên màn chi tiết User Story (US-014).
///
/// Cần [StoryTagsCubit] ở phía trên cây widget. [canEdit] = user có
/// `Permission.manageBacklog` (PO/SM); MEMBER chỉ xem.
class StoryTagsCard extends StatelessWidget {
  final bool canEdit;

  const StoryTagsCard({super.key, required this.canEdit});

  Future<void> _showAddTagDialog(BuildContext context) {
    final cubit = context.read<StoryTagsCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => _AddTagDialog(onAdd: cubit.addTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoryTagsCubit, StoryTagsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == StoryTagsStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu tag cho User Story'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == StoryTagsStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<StoryTagsCubit>();

        return Container(
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
                      Icons.sell_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nhãn / Tags',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (state.isDirty)
                    Text(
                      'Chưa lưu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tag in state.tags)
                    StoryTagChip(
                      label: tag,
                      onDeleted: canEdit && !state.isSaving
                          ? () => cubit.removeTag(tag)
                          : null,
                    ),
                  if (state.tags.isEmpty && !canEdit)
                    Text(
                      'Chưa có tag nào cho User Story này.',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  if (canEdit &&
                      state.tags.length < UserStoryValidator.maxTagsPerStory)
                    ActionChip(
                      key: const Key('storyTags_add'),
                      avatar: const Icon(Icons.add_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text(
                        'Thêm tag',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: state.isSaving
                          ? null
                          : () => _showAddTagDialog(context),
                    ),
                ],
              ),
              if (canEdit && state.isDirty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: state.isSaving ? null : cubit.discardChanges,
                      child: Text(
                        'Hoàn tác',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      key: const Key('storyTags_save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: state.isSaving ? null : cubit.save,
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        state.isSaving ? 'Đang lưu...' : 'Lưu tag',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Hộp thoại nhập 1 tag mới. [onAdd] trả về thông báo lỗi (hiện ngay dưới
/// ô nhập) hoặc `null` nếu đã thêm thành công → đóng hộp thoại.
class _AddTagDialog extends StatefulWidget {
  final String? Function(String tag) onAdd;

  const _AddTagDialog({required this.onAdd});

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.onAdd(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'Thêm tag',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.onSurface,
        ),
      ),
      content: TextField(
        key: const Key('storyTags_input'),
        controller: _controller,
        autofocus: true,
        maxLength: UserStoryValidator.maxTagLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'VD: Frontend, Authentication',
          errorText: _errorText,
          prefixIcon: const Icon(Icons.sell_outlined, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('storyTags_addConfirm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _submit,
          child: Text(
            'Thêm',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
