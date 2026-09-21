import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import 'role_badge.dart';

/// 1 dòng thành viên trong danh sách: avatar, tên, email, role.
///
/// [onTapRole] chỉ được truyền khi user hiện tại có quyền đổi role của
/// thành viên này — nếu null, chạm vào role không có hiệu ứng gì (đã
/// tự ẩn quyền thao tác ở tầng Bloc/permission, widget chỉ phản ánh lại).
class MemberListTile extends StatelessWidget {
  final ProjectMemberDisplay member;
  final VoidCallback? onTapRole;

  const MemberListTile({super.key, required this.member, this.onTapRole});

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    final displayName = user?.fullName ?? '(Người dùng đã bị xoá)';
    final email = user?.email ?? member.userId;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          backgroundImage:
              user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user?.photoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Text(displayName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(email),
        trailing: InkWell(
          onTap: onTapRole,
          borderRadius: BorderRadius.circular(20),
          child: RoleBadge(role: member.membership.role),
        ),
      ),
    );
  }
}
