import 'package:flutter/material.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';

/// Chip hiển thị role — tách riêng để đổi màu sắc/kiểu dáng sau này
/// không phải sửa lại màn hình danh sách thành viên.
class RoleBadge extends StatelessWidget {
  final ProjectRole role;

  const RoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case ProjectRole.po:
        return AppColors.primary;
      case ProjectRole.sm:
        return AppColors.secondary;
      case ProjectRole.member:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
