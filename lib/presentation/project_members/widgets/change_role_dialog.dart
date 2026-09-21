import 'package:flutter/material.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';

/// Luồng đổi role: chọn role mới → xác nhận → gửi event cho Bloc.
///
/// Tách khỏi màn hình chính để [ProjectMembersScreen] không phình to,
/// và để dễ thay đổi UI dialog sau này mà không đụng vào business logic
/// (mọi thao tác Firestore vẫn nằm trong Bloc/Repository).
Future<void> showChangeRoleDialog({
  required BuildContext context,
  required ProjectMemberDisplay member,
  required ProjectMembersBloc bloc,
}) async {
  final selectedRole = await showDialog<ProjectRole>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text('Vai trò của ${member.user?.fullName ?? member.userId}'),
        children: ProjectRole.values.map((role) {
          final isCurrent = role == member.membership.role;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(role),
            child: Row(
              children: [
                Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(role.displayName),
              ],
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
        title: const Text('Xác nhận thay đổi vai trò'),
        content: Text(
          'Bạn có chắc muốn thay đổi vai trò của '
          '${member.user?.fullName ?? member.userId} '
          'thành ${selectedRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
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
