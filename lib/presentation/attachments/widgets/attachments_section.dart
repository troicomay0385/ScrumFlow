import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/attachment_model.dart';
import '../../../data/repositories/attachment_repository.dart';
import '../bloc/attachments_cubit.dart';
import '../bloc/attachments_state.dart';
import 'add_attachment_dialog.dart';
import 'attachment_item.dart';

/// Card khu vực tệp đính kèm dùng chung cho User Story và Task (US-047).
class AttachmentsSection extends StatelessWidget {
  final AttachmentTarget target;

  const AttachmentsSection({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AttachmentsCubit(
        context.read<AttachmentRepository>(),
        target: target,
      )..start(),
      child: const _AttachmentsCard(),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttachmentsCubit, AttachmentsState>(
      listener: (context, state) {
        if (state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.actionSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccess!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AttachmentsCubit>();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, state, cubit),
              if (state.isUploading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceContainerLow,
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ],
              const SizedBox(height: 14),
              _buildBody(state, cubit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AttachmentsState state,
    AttachmentsCubit cubit,
  ) {
    final count = state.attachments.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.attach_file_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            count > 0 ? 'Tệp đính kèm ($count)' : 'Tệp đính kèm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        InkWell(
          onTap: state.isUploading
              ? null
              : () => AddAttachmentBottomSheet.show(context, cubit),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Thêm tệp',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AttachmentsState state, AttachmentsCubit cubit) {
    if (state.status == AttachmentsStatus.loading &&
        state.attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (state.status == AttachmentsStatus.failure &&
        state.attachments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              state.loadError ?? 'Không thể tải tệp đính kèm',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: cubit.start,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.attachments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có tệp đính kèm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Đính kèm hình ảnh, tài liệu hoặc liên kết Figma/Docs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: state.attachments
          .map(
            (attachment) => AttachmentItemWidget(
              attachment: attachment,
              onDelete: () => cubit.deleteAttachment(attachment.id),
            ),
          )
          .toList(),
    );
  }
}
