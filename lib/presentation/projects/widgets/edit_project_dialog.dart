import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';

/// Hộp thoại chỉnh sửa thông tin project (tên, mục tiêu hoặc mô tả).
/// Dành cho Quản trị viên / PO với phong cách Kinetic Sprint.
Future<void> showEditProjectDialog({
  required BuildContext context,
  required ProjectModel project,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _EditProjectDialog(
      project: project,
      parentContext: context,
    ),
  );
}

class _EditProjectDialog extends StatefulWidget {
  final ProjectModel project;
  final BuildContext parentContext;

  const _EditProjectDialog({
    required this.project,
    required this.parentContext,
  });

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Chỉnh sửa dự án',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tên project *',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  hintText: 'Nhập tên dự án',
                  prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Vui lòng nhập tên project'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Mục tiêu hoặc mô tả',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  hintText: 'Cập nhật mục tiêu, định hướng backlog & sprint...',
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
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
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState?.validate() != true) return;

                  setState(() => _isSubmitting = true);
                  try {
                    await widget.parentContext.read<ProjectRepository>().updateProject(
                          projectId: widget.project.id,
                          name: _nameController.text.trim(),
                          description: _descriptionController.text.trim(),
                        );

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật thông tin dự án thành công!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Lưu thay đổi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}

