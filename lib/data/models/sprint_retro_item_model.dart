import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RetroColumnType {
  wentWell,
  couldImprove,
  actionItem,
}

extension RetroColumnTypeX on RetroColumnType {
  String get key {
    switch (this) {
      case RetroColumnType.wentWell:
        return 'wentWell';
      case RetroColumnType.couldImprove:
        return 'couldImprove';
      case RetroColumnType.actionItem:
        return 'actionItem';
    }
  }

  String get label {
    switch (this) {
      case RetroColumnType.wentWell:
        return 'Điều làm tốt';
      case RetroColumnType.couldImprove:
        return 'Cần cải thiện';
      case RetroColumnType.actionItem:
        return 'Kế hoạch hành động';
    }
  }

  static RetroColumnType fromString(String val) {
    switch (val) {
      case 'couldImprove':
        return RetroColumnType.couldImprove;
      case 'actionItem':
        return RetroColumnType.actionItem;
      case 'wentWell':
      default:
        return RetroColumnType.wentWell;
    }
  }
}

/// Model cho 1 ý kiến trong buổi Sprint Retrospective (US-024).
class SprintRetroItemModel extends Equatable {
  final String id;
  final String sprintId;
  final String projectId;
  final RetroColumnType column;
  final String content;
  final String authorId;
  final String authorName;
  final List<String> voterIds;
  final DateTime createdAt;

  const SprintRetroItemModel({
    required this.id,
    required this.sprintId,
    required this.projectId,
    required this.column,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.voterIds = const [],
    required this.createdAt,
  });

  int get votesCount => voterIds.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sprintId': sprintId,
      'projectId': projectId,
      'column': column.key,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'voterIds': voterIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SprintRetroItemModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return SprintRetroItemModel(
      id: docId ?? (map['id'] as String? ?? ''),
      sprintId: map['sprintId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      column: RetroColumnTypeX.fromString(map['column'] as String? ?? 'wentWell'),
      content: map['content'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Thành viên',
      voterIds: (map['voterIds'] as List?)?.whereType<String>().toList() ?? const [],
      createdAt: parseDate(map['createdAt']),
    );
  }

  SprintRetroItemModel copyWith({
    String? id,
    String? sprintId,
    String? projectId,
    RetroColumnType? column,
    String? content,
    String? authorId,
    String? authorName,
    List<String>? voterIds,
    DateTime? createdAt,
  }) {
    return SprintRetroItemModel(
      id: id ?? this.id,
      sprintId: sprintId ?? this.sprintId,
      projectId: projectId ?? this.projectId,
      column: column ?? this.column,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      voterIds: voterIds ?? this.voterIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sprintId,
        projectId,
        column,
        content,
        authorId,
        authorName,
        voterIds,
        createdAt,
      ];
}
