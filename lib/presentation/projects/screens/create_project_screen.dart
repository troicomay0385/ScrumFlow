import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/repositories/project_repository.dart';
import '../../auth/widgets/auth_button.dart';
import '../bloc/create_project_cubit.dart';
import '../bloc/create_project_state.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateProjectCubit(context.read<ProjectRepository>()),
      child: const _CreateProjectView(),
    );
  }
}

class _CreateProjectView extends StatefulWidget {
  const _CreateProjectView();

  @override
  State<_CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends State<_CreateProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<CreateProjectCubit>().submit(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Tạo dự án mới',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocListener<CreateProjectCubit, CreateProjectState>(
        listener: (context, state) {
          if (state is CreateProjectSuccess) {
            Navigator.of(context).pop(true);
          } else if (state is CreateProjectFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Bento Form Card ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Không gian Agile mới',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thiết lập thông tin dự án để bắt đầu',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tên Project
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Tên project *',
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                          hintText: 'VD: Nền tảng E-Commerce, Ứng dụng Di động...',
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
                      const SizedBox(height: 18),

                      // Mô tả / Mục tiêu
                      TextFormField(
                        controller: _descriptionController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Mục tiêu hoặc mô tả dự án',
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                          hintText:
                              'Mục tiêu của dự án, định hướng backlog & sprint...',
                          prefixIcon:
                              const Icon(Icons.description_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      // Nút Tạo Project
                      BlocBuilder<CreateProjectCubit, CreateProjectState>(
                        builder: (context, state) {
                          return AuthButton(
                            text: 'Khởi tạo Project',
                            isLoading: state is CreateProjectSubmitting,
                            onPressed: _submit,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bạn sẽ tự động nhận vai trò Product Owner (PO) cho dự án do chính bạn khởi tạo.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

