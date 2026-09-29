import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';

/// Chip hiển thị 1 tag của User Story (US-014) — pill nền Primary Subdued
/// theo design system Kinetic Sprint. Truyền [onDeleted] để hiện nút xoá.
class StoryTagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool compact;

  const StoryTagChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: compact ? 8 : 10,
        right: onDeleted != null ? 4 : (compact ? 8 : 10),
        top: compact ? 2 : 4,
        bottom: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sell_outlined,
              size: compact ? 11 : 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10.5 : 12,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 2),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onDeleted,
              child: Tooltip(
                message: 'Xoá tag "$label"',
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
