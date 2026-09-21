import 'package:flutter/material.dart';

import '../../../app/authorization/project_role.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';

/// Form thêm thành viên bằng email — chỉ gửi event cho Bloc, không tự
/// gọi Firestore/Repository.
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
            title: const Text('Thêm thành viên'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập email người dùng đã có tài khoản',
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
                    decoration: const InputDecoration(labelText: 'Vai trò'),
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
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  bloc.add(ProjectMemberAddRequested(
                    email: emailController.text.trim(),
                    role: selectedRole,
                  ));
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      );
    },
  );
}
