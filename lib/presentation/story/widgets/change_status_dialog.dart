import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';
import '../../../domain/repositories/story_repository.dart';
import '../../../domain/usecases/story/update_story_status_usecase.dart';
import '../bloc/update_story_status_cubit.dart';

/// Hiển thị hộp thoại chọn trạng thái cho User Story (US-048).
///
/// Trả về trạng thái mới nếu thành công, hoặc `null` nếu huỷ.
Future<String?> showChangeStatusDialog({
  required BuildContext context,
  required String projectId,
  required String storyId,
  required String currentStatus,
  ProjectRole? userRole,
  UpdateStoryStatusCubit? cubit,
}) async {
  // Kiểm tra vai trò nếu được truyền vào: Chỉ PO hoặc SM mới được thao tác
  if (userRole != null &&
      userRole != ProjectRole.po &&
      userRole != ProjectRole.sm) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chỉ PO/SM mới có quyền cập nhật trạng thái'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }

  StoryRepository? repo;
  try {
    repo = context.read<StoryRepository>();
  } catch (_) {
    // Có thể chưa được cung cấp ở context hiện tại, cubit sẽ fallback về StoryRepositoryImpl mặc định
  }

  final effectiveCubit = cubit ??
      (repo != null
          ? UpdateStoryStatusCubit(useCase: UpdateStoryStatusUseCase(repo))
          : UpdateStoryStatusCubit());

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: effectiveCubit,
      child: _ChangeStatusDialogContent(
        projectId: projectId,
        storyId: storyId,
        currentStatus: currentStatus,
        parentContext: context,
      ),
    ),
  );
}

class ChangeStatusDialog extends StatelessWidget {
  final String projectId;
  final String storyId;
  final String currentStatus;
  final ProjectRole? userRole;

  const ChangeStatusDialog({
    super.key,
    required this.projectId,
    required this.storyId,
    required this.currentStatus,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return _ChangeStatusDialogContent(
      projectId: projectId,
      storyId: storyId,
      currentStatus: currentStatus,
      parentContext: context,
    );
  }
}

class _ChangeStatusDialogContent extends StatefulWidget {
  final String projectId;
  final String storyId;
  final String currentStatus;
  final BuildContext parentContext;

  const _ChangeStatusDialogContent({
    required this.projectId,
    required this.storyId,
    required this.currentStatus,
    required this.parentContext,
  });

  @override
  State<_ChangeStatusDialogContent> createState() =>
      _ChangeStatusDialogContentState();
}

class _ChangeStatusDialogContentState extends State<_ChangeStatusDialogContent> {
  late String _selectedStatus;

  static const List<_StatusOption> _options = [
    _StatusOption(
      title: 'To Do',
      description: 'Chờ thực hiện trong backlog hoặc sprint',
      icon: Icons.radio_button_unchecked_rounded,
      color: Color(0xFF64748B),
      bgColor: Color(0xFFF1F5F9),
      borderColor: Color(0xFFCBD5E1),
    ),
    _StatusOption(
      title: 'In Progress',
      description: 'Đang được thành viên nhóm phát triển',
      icon: Icons.pending_actions_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
      borderColor: Color(0xFFFDE68A),
    ),
    _StatusOption(
      title: 'Done',
      description: 'Đã hoàn thành và đáp ứng Definition of Done',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF059669),
      bgColor: Color(0xFFD1FAE5),
      borderColor: Color(0xFFA7F3D0),
    ),
    _StatusOption(
      title: 'Rejected',
      description: 'Bị từ chối hoặc không đạt nghiệm thu sprint review',
      icon: Icons.cancel_rounded,
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFEE2E2),
      borderColor: Color(0xFFFECACA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateStoryStatusCubit, UpdateStoryStatusState>(
      listener: (context, state) {
        if (state is UpdateStoryStatusSuccess) {
          Navigator.of(context).pop(state.newStatus);
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(
              content: Text(
                'Đã cập nhật trạng thái sang "${state.newStatus}" thành công',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is UpdateStoryStatusFailure) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateStoryStatusLoading;

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.published_with_changes_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cập nhật trạng thái',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chọn trạng thái mới cho User Story',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final opt in _options) ...[
                  _buildOptionItem(opt, isLoading),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: isLoading || _selectedStatus == widget.currentStatus
                  ? null
                  : () {
                      context.read<UpdateStoryStatusCubit>().updateStatus(
                            projectId: widget.projectId,
                            storyId: widget.storyId,
                            newStatus: _selectedStatus,
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Cập nhật',
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

  Widget _buildOptionItem(_StatusOption option, bool isLoading) {
    final isSelected = _selectedStatus == option.title;
    final isCurrent = widget.currentStatus == option.title;

    return InkWell(
      onTap: isLoading
          ? null
          : () {
              setState(() {
                _selectedStatus = option.title;
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? option.bgColor
              : AppColors.canvas.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? option.color : AppColors.outlineVariant,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: option.bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: option.borderColor),
              ),
              child: Icon(
                option.icon,
                color: option.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? option.color : AppColors.onSurface,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hiện tại',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? option.color : AppColors.outlineVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _StatusOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });
}
