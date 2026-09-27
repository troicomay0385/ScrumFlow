import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import 'role_badge.dart';

/// 1 dòng thành viên trong danh sách: Bento card, avatar bo tròn, tên, email, role badge.
class MemberListTile extends StatelessWidget {
  final ProjectMemberDisplay member;
  final VoidCallback? onTapRole;

  const MemberListTile({super.key, required this.member, this.onTapRole});

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    final displayName = user?.fullName ?? '(Người dùng đã bị xoá)';
    final email = user?.email ?? member.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
          backgroundImage:
              user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          child: user?.photoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          email,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: InkWell(
          onTap: onTapRole,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleBadge(role: member.membership.role),
                if (onTapRole != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

