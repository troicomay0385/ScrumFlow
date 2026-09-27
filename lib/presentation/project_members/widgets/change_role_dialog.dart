import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';

/// Luồng đổi role: chọn role mới → xác nhận → gửi event cho Bloc (Kinetic Sprint style).
Future<void> showChangeRoleDialog({
  required BuildContext context,
  required ProjectMemberDisplay member,
  required ProjectMembersBloc bloc,
}) async {
  final memberName = member.user?.fullName ?? member.userId;

  final selectedRole = await showDialog<ProjectRole>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.manage_accounts_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đổi vai trò',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    memberName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        children: ProjectRole.values.map((role) {
          final isCurrent = role == member.membership.role;
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: () => Navigator.of(dialogContext).pop(role),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrent
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      role.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Hiện tại',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );

  if (selectedRole == null || selectedRole == member.membership.role) return;
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Text(
          'Xác nhận thay đổi vai trò',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn thay đổi vai trò của $memberName sang ${selectedRole.displayName}?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.4,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    bloc.add(ProjectMemberRoleChangeRequested(
      targetUserId: member.userId,
      newRole: selectedRole,
    ));
  }
}

