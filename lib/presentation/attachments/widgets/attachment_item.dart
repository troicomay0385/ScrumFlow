import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/attachment_model.dart';

/// Hiển thị 1 tệp hoặc liên kết đính kèm trong danh sách (US-047).
/// Hỗ trợ tương tác 1 chạm: Mở web link, xem trước ảnh toàn màn hình,
/// và xem thông tin chi tiết tệp tải lên từ thiết bị.
class AttachmentItemWidget extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onDelete;

  const AttachmentItemWidget({
    super.key,
    required this.attachment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeVisuals(attachment.typeEnum);
    final hasHttp = attachment.fileUrl != null && attachment.fileUrl!.startsWith('http');
    final isImage = attachment.typeEnum == AttachmentType.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleItemTap(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon theo loại tệp
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeInfo.icon,
                    color: typeInfo.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Tên tệp & Thông tin tệp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${attachment.formattedSize} • ${attachment.uploadedByName} • ${_formatDate(attachment.createdAt)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Nút Hành động: Mở link / Xem trước ảnh / Xem chi tiết tệp
                if (hasHttp)
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    color: AppColors.primary,
                    tooltip: 'Mở liên kết / Tải tệp',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _openUrl(context, attachment.fileUrl!),
                  )
                else if (isImage)
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded, size: 20),
                    color: AppColors.success,
                    tooltip: 'Xem trước hình ảnh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _handleItemTap(context),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                    color: AppColors.primary,
                    tooltip: 'Chi tiết tệp',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _showAttachmentDetails(context),
                  ),

                // Nút Xóa
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  tooltip: 'Xóa tệp đính kèm',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context) {
    final url = attachment.fileUrl;
    final isImage = attachment.typeEnum == AttachmentType.image;

    if (isImage && url != null && url.isNotEmpty) {
      _showImagePreview(context);
    } else if (url != null && url.startsWith('http')) {
      _openUrl(context, url);
    } else {
      _showAttachmentDetails(context);
    }
  }

  Widget _buildImageWidget() {
    final url = attachment.fileUrl ?? '';

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 160,
          color: AppColors.surfaceContainerLow,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.outline),
          ),
        ),
      );
    }

    if (url.startsWith('data:')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex >= 0 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        return const SizedBox(
          height: 160,
          child: Center(child: Icon(Icons.broken_image_rounded, size: 48)),
        );
      }
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    } catch (_) {}

    return Container(
      height: 160,
      color: AppColors.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.outline),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attachment.fileName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              // Image container
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: _buildImageWidget(),
              ),
              // Footer info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${attachment.formattedSize} • ${attachment.uploadedByName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (attachment.fileUrl != null && attachment.fileUrl!.startsWith('http'))
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                        label: const Text('Mở trình duyệt'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openUrl(context, attachment.fileUrl!);
                        },
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

  void _showAttachmentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final typeInfo = _typeVisuals(attachment.typeEnum);
        final hasHttpUrl = attachment.fileUrl != null && attachment.fileUrl!.startsWith('http');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeInfo.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(typeInfo.icon, color: typeInfo.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.fileName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attachment.isLink ? 'Liên kết trực tuyến' : 'Tệp tải lên từ thiết bị',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: typeInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _detailRow('Định dạng', attachment.fileType.toUpperCase()),
                    const Divider(height: 16),
                    _detailRow('Dung lượng', attachment.formattedSize),
                    const Divider(height: 16),
                    _detailRow('Người tải lên', attachment.uploadedByName),
                    const Divider(height: 16),
                    _detailRow('Thời gian', _formatDate(attachment.createdAt)),
                    if (attachment.fileUrl != null && !attachment.fileUrl!.startsWith('data:')) ...[
                      const Divider(height: 16),
                      _detailRow('Nguồn / URL', attachment.fileUrl!, isUrl: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasHttpUrl) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Mở liên kết / Tải tệp về'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openUrl(context, attachment.fileUrl!);
                  },
                ),
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tệp đã được ghi nhận vào dự án Scrumflow. Để chia sẻ tệp cho đồng nghiệp mọi lúc, hãy đính kèm liên kết Google Drive hoặc OneDrive.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isUrl = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUrl ? AppColors.primary : AppColors.onSurface,
            ),
            maxLines: isUrl ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đường dẫn không hợp lệ')),
      );
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở liên kết này')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết này')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Xóa tệp đính kèm?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${attachment.fileName}" khỏi danh sách đính kèm không?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  _TypeVisual _typeVisuals(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return const _TypeVisual(
          icon: Icons.image_rounded,
          color: AppColors.success,
        );
      case AttachmentType.pdf:
        return const _TypeVisual(
          icon: Icons.picture_as_pdf_rounded,
          color: AppColors.error,
        );
      case AttachmentType.doc:
        return const _TypeVisual(
          icon: Icons.description_rounded,
          color: AppColors.primary,
        );
      case AttachmentType.link:
        return const _TypeVisual(
          icon: Icons.link_rounded,
          color: Color(0xFF7C3AED), // Tím
        );
      case AttachmentType.archive:
        return const _TypeVisual(
          icon: Icons.folder_zip_rounded,
          color: AppColors.warning,
        );
      case AttachmentType.other:
        return const _TypeVisual(
          icon: Icons.insert_drive_file_rounded,
          color: AppColors.outline,
        );
    }
  }
}

class _TypeVisual {
  final IconData icon;
  final Color color;

  const _TypeVisual({required this.icon, required this.color});
}
