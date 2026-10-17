import 'package:flutter/material.dart';

import '../../../app/constants/task_status.dart';

/// Màu đại diện cho từng trạng thái Task/User Story (US-065).
///
/// Đồng bộ với bảng màu trong ChangeStatusDialog:
/// - To Do: xám Slate
/// - In Progress: cam Amber
/// - Done: xanh ngọc Emerald
///
/// Hỗ trợ dark mode qua [Theme.of(context).brightness].
Color taskStatusColor(BuildContext context, String status) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final normalized = TaskStatus.normalize(status);

  switch (normalized) {
    case TaskStatus.todo:
      return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    case TaskStatus.inProgress:
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    case TaskStatus.done:
      return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    default:
      return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }
}

/// Icon đại diện cho từng trạng thái Task/User Story (US-065).
IconData taskStatusIcon(String status) {
  final normalized = TaskStatus.normalize(status);

  switch (normalized) {
    case TaskStatus.todo:
      return Icons.radio_button_unchecked_rounded;
    case TaskStatus.inProgress:
      return Icons.pending_actions_rounded;
    case TaskStatus.done:
      return Icons.check_circle_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}
