import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';

/// Hộp thoại chỉnh sửa thông tin project (tên, mục tiêu hoặc mô tả).
/// Chỉ dành cho Quản trị viên / PO (kiểm soát bởi permission [manageProject]).
Future<void> showEditProjectDialog({
  required BuildContext context,
  required ProjectModel project,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: project.name);
  final descriptionController = TextEditingController(text: project.description);
  bool isSubmitting = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Chỉnh sửa dự án'),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Tên project *',
                        hintText: 'Nhập tên dự án',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Vui lòng nhập tên project'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Mục tiêu hoặc mô tả',
                        hintText: 'Cập nhật mục tiêu, định hướng backlog & sprint...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() != true) return;

                        setState(() => isSubmitting = true);
                        try {
                          await context.read<ProjectRepository>().updateProject(
                                projectId: project.id,
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                              );

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cập nhật thông tin dự án thành công!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      );
    },
  );
}
