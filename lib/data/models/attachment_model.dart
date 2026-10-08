import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đối tượng được đính kèm: 1 User Story hoặc 1 Task (US-047).
class AttachmentTarget extends Equatable {
  final String projectId;
  final String? storyId;
  final String? taskId;

  const AttachmentTarget.story({
    required this.projectId,
    required String this.storyId,
  }) : taskId = null;

  const AttachmentTarget.task({
    required this.projectId,
    required String this.taskId,
  }) : storyId = null;

  bool get isTask => taskId != null;
  bool get isStory => storyId != null;

  @override
  List<Object?> get props => [projectId, storyId, taskId];
}

/// Loại tệp đính kèm.
enum AttachmentType {
  image,
  pdf,
  doc,
  link,
  archive,
  other;

  static AttachmentType fromExtension(String? ext) {
    if (ext == null || ext.isEmpty) return AttachmentType.other;
    final lower = ext.toLowerCase().replaceFirst('.', '');
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(lower)) {
      return AttachmentType.image;
    }
    if (['pdf'].contains(lower)) return AttachmentType.pdf;
    if (['doc', 'docx', 'txt', 'md', 'xls', 'xlsx', 'csv', 'ppt', 'pptx']
        .contains(lower)) {
      return AttachmentType.doc;
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(lower)) {
      return AttachmentType.archive;
    }
    if (['http', 'https', 'url', 'link'].contains(lower)) {
      return AttachmentType.link;
    }
    return AttachmentType.other;
  }
}

/// Model cho 1 tệp hoặc liên kết đính kèm (US-047).
class AttachmentModel extends Equatable {
  final String id;
  final String projectId;
  final String? storyId;
  final String? taskId;
  final String fileName;
  final int fileSize; // Số bytes (0 nếu là link)
  final String fileType; // image, pdf, doc, link, archive, other
  final String? fileUrl; // URL tải / xem hoặc Base64 data URI
  final bool isLink; // true nếu là liên kết ngoài (Figma, GitHub, Docs...)
  final String uploadedById;
  final String uploadedByName;
  final DateTime createdAt;

  const AttachmentModel({
    required this.id,
    required this.projectId,
    this.storyId,
    this.taskId,
    required this.fileName,
    this.fileSize = 0,
    required this.fileType,
    this.fileUrl,
    this.isLink = false,
    required this.uploadedById,
    required this.uploadedByName,
    required this.createdAt,
  });

  AttachmentType get typeEnum =>
      isLink ? AttachmentType.link : AttachmentType.fromExtension(fileType);

  String get formattedSize {
    if (isLink || fileSize <= 0) return 'Liên kết web';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      if (storyId != null) 'storyId': storyId,
      if (taskId != null) 'taskId': taskId,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      if (fileUrl != null) 'fileUrl': fileUrl,
      'isLink': isLink,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AttachmentModel(
      id: docId ?? (map['id'] as String? ?? ''),
      projectId: map['projectId'] as String? ?? '',
      storyId: map['storyId'] as String?,
      taskId: map['taskId'] as String?,
      fileName: map['fileName'] as String? ?? 'Untitled',
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      fileType: map['fileType'] as String? ?? 'other',
      fileUrl: map['fileUrl'] as String?,
      isLink: map['isLink'] as bool? ?? false,
      uploadedById: map['uploadedById'] as String? ?? '',
      uploadedByName: map['uploadedByName'] as String? ?? 'Thành viên',
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        storyId,
        taskId,
        fileName,
        fileSize,
        fileType,
        fileUrl,
        isLink,
        uploadedById,
        uploadedByName,
        createdAt,
      ];
}
