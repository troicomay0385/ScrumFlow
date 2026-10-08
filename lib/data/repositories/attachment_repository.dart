import '../models/attachment_model.dart';

/// Interface cho Attachment Repository — tệp đính kèm trong User Story & Task (US-047).
abstract class AttachmentRepository {
  /// Stream real-time danh sách tệp đính kèm của [target].
  Stream<List<AttachmentModel>> streamAttachments(AttachmentTarget target);

  /// Thêm 1 tệp hoặc liên kết đính kèm với tư cách user đang đăng nhập.
  Future<AttachmentModel> addAttachment({
    required AttachmentTarget target,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? fileUrl,
    bool isLink = false,
  });

  /// Xóa 1 tệp đính kèm.
  Future<void> deleteAttachment({
    required AttachmentTarget target,
    required String attachmentId,
  });
}
