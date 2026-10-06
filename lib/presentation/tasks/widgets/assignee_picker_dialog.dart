import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_member_display.dart';
import '../../project_members/widgets/role_badge.dart';
import '../bloc/task_detail_cubit.dart' show memberDisplayName;

/// Kết quả chọn người phụ trách. `userId == null` = bỏ phân công.
class AssigneeSelection {
  final String? userId;
  const AssigneeSelection(this.userId);
}

/// Dialog chọn người phụ trách task (US-043) từ [members] — thành viên
/// thực tế của project. Trả về `null` nếu người dùng huỷ.
Future<AssigneeSelection?> showAssigneePickerDialog({
  required BuildContext context,
  required List<ProjectMemberDisplay> members,
  required String? currentAssigneeId,
}) {
  return showDialog<AssigneeSelection>(
    context: context,
    builder: (_) => _AssigneePickerDialog(
      members: members,
      currentAssigneeId: currentAssigneeId,
    ),
  );
}

class _AssigneePickerDialog extends StatefulWidget {
  final List<ProjectMemberDisplay> members;
  final String? currentAssigneeId;

  const _AssigneePickerDialog({
    required this.members,
    required this.currentAssigneeId,
  });

  @override
  State<_AssigneePickerDialog> createState() => _AssigneePickerDialogState();
}

class _AssigneePickerDialogState extends State<_AssigneePickerDialog> {
  late String? _selectedId = widget.currentAssigneeId;

  Widget _option({
    required Key key,
    required String? userId,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final selected = _selectedId == userId;
    return ListTile(
      key: key,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.06),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : AppColors.outline,
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
      trailing: trailing,
      onTap: () => setState(() => _selectedId = userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final changed = _selectedId != widget.currentAssigneeId;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Chọn người phụ trách',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      ),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(
        width: 380,
        child: ListView(
          shrinkWrap: true,
          children: [
            _option(
              key: const Key('assignee_option_none'),
              userId: null,
              title: 'Chưa phân công',
            ),
            for (final member in widget.members)
              _option(
                key: Key('assignee_option_${member.userId}'),
                userId: member.userId,
                title: memberDisplayName(member),
                subtitle: member.user?.email,
                trailing: RoleBadge(role: member.membership.role),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          key: const Key('assignee_save_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: changed
              ? () => Navigator.pop(context, AssigneeSelection(_selectedId))
              : null,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
