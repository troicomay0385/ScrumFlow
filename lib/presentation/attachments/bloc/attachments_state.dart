import 'package:equatable/equatable.dart';

import '../../../data/models/attachment_model.dart';

enum AttachmentsStatus { loading, loaded, failure }

/// State khu vực tệp đính kèm của 1 User Story / Task (US-047).
class AttachmentsState extends Equatable {
  final AttachmentsStatus status;
  final List<AttachmentModel> attachments;
  final String? loadError;
  final bool isUploading;
  final String? actionError;
  final String? actionSuccess;

  const AttachmentsState({
    this.status = AttachmentsStatus.loading,
    this.attachments = const [],
    this.loadError,
    this.isUploading = false,
    this.actionError,
    this.actionSuccess,
  });

  AttachmentsState copyWith({
    AttachmentsStatus? status,
    List<AttachmentModel>? attachments,
    String? loadError,
    bool? isUploading,
    String? actionError,
    String? actionSuccess,
  }) {
    return AttachmentsState(
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      loadError: loadError,
      isUploading: isUploading ?? this.isUploading,
      actionError: actionError,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
        status,
        attachments,
        loadError,
        isUploading,
        actionError,
        actionSuccess,
      ];
}
