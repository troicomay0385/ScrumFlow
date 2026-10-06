import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String storyId; // ID của User Story mà task này thuộc về

  /// Project chứa task. `null` với task cũ tạo trước khi có field này.
  final String? projectId;
  final String title;
  final String description;
  final String status; // 'To Do', 'In Progress', 'Done'
  final String? assigneeId;
  final String? assigneeName;

  /// Hạn hoàn thành (US-044). `null` = chưa đặt deadline.
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.storyId,
    this.projectId,
    required this.title,
    required this.description,
    this.status = 'To Do',
    this.assigneeId,
    this.assigneeName,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // Deadline không bắt buộc: thiếu field / sai kiểu → null (không crash).
    DateTime? parseOptionalDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    return TaskModel(
      id: docId ?? (map['id'] as String? ?? ''),
      storyId: map['storyId'] as String? ?? '',
      projectId: map['projectId'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'To Do',
      assigneeId: map['assigneeId'] as String?,
      assigneeName: map['assigneeName'] as String?,
      deadline: parseOptionalDate(map['deadline']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  /// [clearAssignee]/[clearDeadline] dùng để gán lại `null` (bỏ phân công,
  /// xoá deadline) vì tham số `null` nghĩa là "giữ nguyên".
  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? assigneeId,
    String? assigneeName,
    bool clearAssignee = false,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      storyId: storyId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      assigneeName:
          clearAssignee ? null : (assigneeName ?? this.assigneeName),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        storyId,
        projectId,
        title,
        description,
        status,
        assigneeId,
        assigneeName,
        deadline,
        createdAt,
        updatedAt,
      ];
}
