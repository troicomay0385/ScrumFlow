import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/authorization/project_role.dart';
import '../../../app/constants/app_colors.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';

/// Form thêm thành viên bằng email — Kinetic Sprint styling.
Future<void> showAddMemberDialog({
  required BuildContext context,
  required ProjectMembersBloc bloc,
}) async {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  ProjectRole selectedRole = ProjectRole.member;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thêm thành viên',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email thành viên *',
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                      hintText: 'Nhập email người dùng',
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Vui lòng nhập email';
                      if (!email.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProjectRole>(
                    initialValue: selectedRole,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Vai trò dự án',
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: ProjectRole.values
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  bloc.add(ProjectMemberAddRequested(
                    email: emailController.text.trim(),
                    role: selectedRole,
                  ));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Thêm vào dự án',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

