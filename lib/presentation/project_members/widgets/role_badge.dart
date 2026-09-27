import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';

/// Chip hiển thị vai trò thành viên theo phong cách Stitch Kinetic Sprint.
class RoleBadge extends StatelessWidget {
  final ProjectRole role;

  const RoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case ProjectRole.po:
        return AppColors.rolePO;
      case ProjectRole.sm:
        return AppColors.roleSM;
      case ProjectRole.member:
        return AppColors.roleDev;
    }
  }

  Color get _bgColor {
    switch (role) {
      case ProjectRole.po:
        return AppColors.rolePOBg;
      case ProjectRole.sm:
        return AppColors.roleSMBg;
      case ProjectRole.member:
        return AppColors.roleDevBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            role.displayName,
            style: GoogleFonts.plusJakartaSans(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
