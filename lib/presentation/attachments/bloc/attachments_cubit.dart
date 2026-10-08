import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/attachment_model.dart';
import '../../../data/repositories/attachment_repository.dart';
import 'attachments_state.dart';

/// Cubit quản lý tệp đính kèm dùng chung cho User Story và Task (US-047).
class AttachmentsCubit extends Cubit<AttachmentsState> {
  final AttachmentRepository _repository;
  final AttachmentTarget target;
  final Future<FilePickerResult?> Function()? _pickFiles;
  StreamSubscription<List<AttachmentModel>>? _subscription;

  AttachmentsCubit(
    this._repository, {
    required this.target,
    this._pickFiles,
  }) : super(const AttachmentsState());

  /// Lắng nghe tệp đính kèm real-time.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(state.copyWith(status: AttachmentsStatus.loading));
    _subscription = _repository.streamAttachments(target).listen(
      (attachments) {
        if (isClosed) return;
        emit(state.copyWith(
          status: AttachmentsStatus.loaded,
          attachments: attachments,
        ));
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(state.copyWith(
          status: AttachmentsStatus.failure,
          loadError: _messageOf(error, 'Không thể tải danh sách tệp đính kèm'),
        ));
      },
    );
  }

  /// Chọn tệp từ máy và tải lên.
  Future<bool> pickAndUploadFile() async {
    if (state.isUploading) return false;
    emit(state.copyWith(isUploading: true, actionError: null));

    try {
      final result = _pickFiles != null
          ? await _pickFiles()
          : await FilePicker.platform.pickFiles(
              withData: true,
              type: FileType.any,
            );

      if (result == null || result.files.isEmpty) {
        emit(state.copyWith(isUploading: false));
        return false;
      }

      final file = result.files.first;
      final fileName = file.name;
      final fileSize = file.size;
      final fileExt = file.extension ?? 'other';

      String? fileUrl;
      if (file.bytes != null && file.bytes!.isNotEmpty && file.size <= 500 * 1024) {
        // Lưu Base64 data URI cho tệp nhỏ < 500KB để có thể xem lại trực tiếp
        final base64Data = base64Encode(file.bytes!);
        fileUrl = 'data:application/octet-stream;base64,$base64Data';
      } else if (file.path != null && file.path!.isNotEmpty) {
        fileUrl = file.path;
      }

      await _repository.addAttachment(
        target: target,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileExt,
        fileUrl: fileUrl,
        isLink: false,
      );

      if (isClosed) return true;
      emit(state.copyWith(
        isUploading: false,
        actionSuccess: 'Đã tải lên tệp "$fileName"',
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isUploading: false,
        actionError: _messageOf(e, 'Không thể đính kèm tệp'),
      ));
      return false;
    }
  }

  /// Thêm liên kết ngoài (Figma, GitHub, Google Drive, Docs...).
  Future<bool> addLink({
    required String title,
    required String url,
  }) async {
    if (state.isUploading) return false;

    final trimmedTitle = title.trim();
    var trimmedUrl = url.trim();

    if (trimmedTitle.isEmpty) {
      emit(state.copyWith(actionError: 'Tiêu đề liên kết không được để trống'));
      return false;
    }
    if (trimmedUrl.isEmpty) {
      emit(state.copyWith(actionError: 'Đường dẫn liên kết không được để trống'));
      return false;
    }

    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      trimmedUrl = 'https://$trimmedUrl';
    }

    emit(state.copyWith(isUploading: true, actionError: null));

    try {
      await _repository.addAttachment(
        target: target,
        fileName: trimmedTitle,
        fileSize: 0,
        fileType: 'link',
        fileUrl: trimmedUrl,
        isLink: true,
      );

      if (isClosed) return true;
      emit(state.copyWith(
        isUploading: false,
        actionSuccess: 'Đã thêm liên kết "$trimmedTitle"',
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isUploading: false,
        actionError: _messageOf(e, 'Không thể thêm liên kết'),
      ));
      return false;
    }
  }

  /// Xóa tệp đính kèm theo [attachmentId].
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _repository.deleteAttachment(
        target: target,
        attachmentId: attachmentId,
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        actionError: _messageOf(e, 'Không thể xóa tệp đính kèm'),
      ));
      return false;
    }
  }

  String _messageOf(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? fallback : message;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
