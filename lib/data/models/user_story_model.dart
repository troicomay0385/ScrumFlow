import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserStoryModel extends Equatable {
  final String id;
  final String projectId;
  final String storyKey; // VD: US-001, US-005
  final String title;
  final String description;
  final String priority; // CAO, TB, THẤP
  final int storyPoints; // 1, 2, 3, 5, 8
  final String status; // To Do, In Progress, Done, Rejected
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeEmail;
  final List<String> tags; // Nhãn tự do, VD: ['Frontend', 'Authentication'] (US-014)
  final DateTime? deadline; // null = chưa đặt hạn (US-009 xếp cuối khi sort)
  final String? createdBy; // uid người tạo (US-010); null với dữ liệu cũ/dữ liệu mẫu
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Getter tương thích ngược cho các nơi sử dụng `dueDate`
  DateTime? get dueDate => deadline;

  const UserStoryModel({
    required this.id,
    required this.projectId,
    required this.storyKey,
    required this.title,
    required this.description,
    this.priority = 'CAO',
    this.storyPoints = 3,
    this.status = 'To Do',
    this.assigneeId,
    this.assigneeName,
    this.assigneeEmail,
    this.tags = const [],
    DateTime? deadline,
    DateTime? dueDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  }) : deadline = deadline ?? dueDate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'storyKey': storyKey,
      'title': title,
      'description': description,
      'priority': priority,
      'storyPoints': storyPoints,
      'status': status,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeEmail': assigneeEmail,
      'tags': tags,
      'deadline': deadline?.toIso8601String(),
      'dueDate': deadline?.toIso8601String(),
      // Chỉ ghi khi có giá trị: Firestore Rules so khớp `createdBy` với uid
      // người gọi, `null` tường minh (vd. dữ liệu mẫu) sẽ bị từ chối.
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserStoryModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    // Dữ liệu cũ không có `tags` (hoặc sai kiểu) → danh sách rỗng.
    List<String> parseTags(dynamic raw) {
      if (raw is! List) return const [];
      return raw.whereType<String>().toList(growable: false);
    }

    return UserStoryModel(
      id: docId ?? (map['id'] as String? ?? ''),
      projectId: map['projectId'] as String? ?? '',
      storyKey: map['storyKey'] as String? ?? 'US-000',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'CAO',
      storyPoints: (map['storyPoints'] as num?)?.toInt() ?? 3,
      status: map['status'] as String? ?? 'To Do',
      assigneeId: map['assigneeId'] as String?,
      assigneeName: map['assigneeName'] as String?,
      assigneeEmail: map['assigneeEmail'] as String?,
      tags: parseTags(map['tags']),
      deadline: parseOptionalDate(map['deadline']) ??
          parseOptionalDate(map['dueDate']),
      createdBy: map['createdBy'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserStoryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    int? storyPoints,
    String? status,
    String? assigneeId,
    String? assigneeName,
    String? assigneeEmail,
    List<String>? tags,
    DateTime? deadline,
    DateTime? dueDate,
    DateTime? updatedAt,
  }) {
    return UserStoryModel(
      id: id ?? this.id,
      projectId: projectId,
      storyKey: storyKey,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      storyPoints: storyPoints ?? this.storyPoints,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeEmail: assigneeEmail ?? this.assigneeEmail,
      tags: tags ?? this.tags,
      deadline: deadline ?? dueDate ?? this.deadline,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        storyKey,
        title,
        description,
        priority,
        storyPoints,
        status,
        assigneeId,
        assigneeName,
        assigneeEmail,
        tags,
        deadline,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
