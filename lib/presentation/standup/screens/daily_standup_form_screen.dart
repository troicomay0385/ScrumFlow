import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../bloc/standup_bloc.dart';
import '../bloc/standup_event.dart';
import '../bloc/standup_state.dart';

class DailyStandupFormScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String sprintId;
  final String sprintName;

  const DailyStandupFormScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.sprintId,
    required this.sprintName,
  });

  @override
  State<DailyStandupFormScreen> createState() => _DailyStandupFormScreenState();
}

class _DailyStandupFormScreenState extends State<DailyStandupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yesterdayController = TextEditingController();
  final _todayController = TextEditingController();
  final _blockersController = TextEditingController();

  @override
  void dispose() {
    _yesterdayController.dispose();
    _todayController.dispose();
    _blockersController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<StandupBloc>().add(
            SubmitStandupEvent(
              userId: widget.userId,
              userName: widget.userName,
              sprintId: widget.sprintId,
              yesterday: _yesterdayController.text.trim(),
              today: _todayController.text.trim(),
              blockers: _blockersController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Ghi Daily Stand-up',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: BlocConsumer<StandupBloc, StandupState>(
        listener: (context, state) {
          if (state is StandupSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nộp báo cáo Stand-up thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is StandupSubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi nộp: ${state.error}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sprint hiện tại',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.sprintName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('1. Hôm qua bạn đã làm gì?'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _yesterdayController,
                    hintText: 'Ví dụ: Tôi đã hoàn thành API đăng nhập...',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('2. Hôm nay bạn sẽ làm gì?'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _todayController,
                    hintText: 'Ví dụ: Tôi sẽ bắt đầu làm giao diện trang chủ...',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('3. Bạn có gặp khó khăn gì không?'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _blockersController,
                    hintText: 'Ví dụ: Chưa nhận được thiết kế từ UI/UX team (nhập "Không" nếu không có)',
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: state is StandupSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state is StandupSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Nộp báo cáo',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập thông tin';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.outline,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
