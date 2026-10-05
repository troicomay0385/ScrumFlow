import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String storyId; // ID của User Story mà task này thuộc về
  final String title;
  final String description;
  final String status; // 'To Do', 'In Progress', 'Done'
  final String? assigneeId;
  final String? assigneeName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.storyId,
    required this.title,
    required this.description,
    this.status = 'To Do',
    this.assigneeId,
    this.assigneeName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'title': title,
      'description': description,
      'status': status,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
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

    return TaskModel(
      id: docId ?? (map['id'] as String? ?? ''),
      storyId: map['storyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'To Do',
      assigneeId: map['assigneeId'] as String?,
      assigneeName: map['assigneeName'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? assigneeId,
    String? assigneeName,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      storyId: storyId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        storyId,
        title,
        description,
        status,
        assigneeId,
        assigneeName,
        createdAt,
        updatedAt,
      ];
}
