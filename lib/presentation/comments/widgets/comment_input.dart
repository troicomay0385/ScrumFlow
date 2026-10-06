import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/comment_validator.dart';

/// Ô nhập + nút gửi bình luận. Tự xoá nội dung khi [onSend] trả về `true`.
class CommentInput extends StatefulWidget {
  final bool isSending;
  final String? errorText;
  final Future<bool> Function(String content) onSend;

  const CommentInput({
    super.key,
    required this.isSending,
    required this.onSend,
    this.errorText,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.isSending) return;
    final sent = await widget.onSend(_controller.text);
    if (sent && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('comment_input_field'),
            controller: _controller,
            enabled: !widget.isSending,
            minLines: 1,
            maxLines: 4,
            maxLength: CommentValidator.maxLength,
            textInputAction: TextInputAction.newline,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Viết bình luận...',
              hintStyle: GoogleFonts.inter(fontSize: 14),
              errorText: widget.errorText,
              errorMaxLines: 3,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            key: const Key('comment_send_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.isSending ? null : _submit,
            child: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Gửi',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
