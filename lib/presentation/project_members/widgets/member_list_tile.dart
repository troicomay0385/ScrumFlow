import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import 'role_badge.dart';

/// 1 dòng thành viên trong danh sách: Bento card, avatar bo tròn, tên, email,
/// role badge, và nút xoá thành viên (nếu có quyền).
class MemberListTile extends StatelessWidget {
  final ProjectMemberDisplay member;
  final VoidCallback? onTapRole;

  /// Callback khi PO nhấn nút xoá thành viên. `null` = ẩn nút xoá
  /// (user không có quyền hoặc đây là chính mình).
  final VoidCallback? onRemove;

  const MemberListTile({
    super.key,
    required this.member,
    this.onTapRole,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    final displayName = user?.fullName ?? '(Người dùng đã bị xoá)';
    final email = user?.email ?? member.userId;

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
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
          backgroundImage: user?.photoUrl != null
              ? NetworkImage(user!.photoUrl!)
              : null,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        // Giới hạn badge vai trò ~40% chiều rộng màn hình để tên/email
        // luôn còn chỗ hiển thị trên điện thoại nhỏ (US-055).
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.4,
              ),
              child: InkWell(
                onTap: onTapRole,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: RoleBadge(role: member.membership.role)),
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
            // Nút xoá thành viên (US-041)
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.person_remove_rounded,
                    size: 18,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Swipe-to-delete khi có quyền xoá
    if (onRemove != null) {
      return Dismissible(
        key: ValueKey(member.userId),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmRemove(context, displayName),
        onDismissed: (_) => onRemove!(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: tile,
      );
    }

    return tile;
  }

  Future<bool> _confirmRemove(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_remove_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xoá thành viên',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xoá "$name" khỏi dự án?\n\nThành viên này sẽ mất toàn bộ quyền truy cập vào dự án.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
