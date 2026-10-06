import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../bloc/comments_cubit.dart';
import '../bloc/comments_state.dart';
import 'comment_input.dart';
import 'comment_item.dart';

/// Card "Bình luận" dùng chung cho User Story Detail (US-045) và Task
/// Detail (US-046). [target] quyết định bình luận thuộc story/task nào.
class CommentsSection extends StatelessWidget {
  final CommentTarget target;

  const CommentsSection({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommentsCubit(
        context.read<CommentRepository>(),
        target: target,
      )..start(),
      child: const _CommentsCard(),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        final cubit = context.read<CommentsCubit>();
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
              _buildHeader(state),
              const SizedBox(height: 14),
              _buildBody(state, onRetry: cubit.start),
              const SizedBox(height: 14),
              CommentInput(
                isSending: state.isSending,
                errorText: state.sendError,
                onSend: cubit.send,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(CommentsState state) {
    final count = state.comments.length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          count > 0 ? 'Bình luận ($count)' : 'Bình luận',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(CommentsState state, {required VoidCallback onRetry}) {
    switch (state.status) {
      case CommentsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case CommentsStatus.failure:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.loadError ?? 'Không thể tải bình luận',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        );
      case CommentsStatus.loaded:
        if (state.comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Chưa có bình luận nào. Hãy là người đầu tiên bình luận.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < state.comments.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              CommentItem(comment: state.comments[i]),
            ],
          ],
        );
    }
  }
}
