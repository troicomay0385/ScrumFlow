import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model ghi nhận kết quả Sprint Review (US-023).
class SprintReviewModel extends Equatable {
  final String id;
  final String sprintId;
  final String projectId;
  final String demoNotes;
  final String stakeholderFeedback;
  final List<String> acceptedStoryIds;
  final List<String> rejectedStoryIds;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SprintReviewModel({
    required this.id,
    required this.sprintId,
    required this.projectId,
    required this.demoNotes,
    required this.stakeholderFeedback,
    this.acceptedStoryIds = const [],
    this.rejectedStoryIds = const [],
    this.reviewedBy,
    this.reviewedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sprintId': sprintId,
      'projectId': projectId,
      'demoNotes': demoNotes,
      'stakeholderFeedback': stakeholderFeedback,
      'acceptedStoryIds': acceptedStoryIds,
      'rejectedStoryIds': rejectedStoryIds,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedByName != null) 'reviewedByName': reviewedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SprintReviewModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return SprintReviewModel(
      id: docId ?? (map['id'] as String? ?? ''),
      sprintId: map['sprintId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      demoNotes: map['demoNotes'] as String? ?? '',
      stakeholderFeedback: map['stakeholderFeedback'] as String? ?? '',
      acceptedStoryIds: (map['acceptedStoryIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      rejectedStoryIds: (map['rejectedStoryIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      reviewedBy: map['reviewedBy'] as String?,
      reviewedByName: map['reviewedByName'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  SprintReviewModel copyWith({
    String? id,
    String? sprintId,
    String? projectId,
    String? demoNotes,
    String? stakeholderFeedback,
    List<String>? acceptedStoryIds,
    List<String>? rejectedStoryIds,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SprintReviewModel(
      id: id ?? this.id,
      sprintId: sprintId ?? this.sprintId,
      projectId: projectId ?? this.projectId,
      demoNotes: demoNotes ?? this.demoNotes,
      stakeholderFeedback: stakeholderFeedback ?? this.stakeholderFeedback,
      acceptedStoryIds: acceptedStoryIds ?? this.acceptedStoryIds,
      rejectedStoryIds: rejectedStoryIds ?? this.rejectedStoryIds,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sprintId,
        projectId,
        demoNotes,
        stakeholderFeedback,
        acceptedStoryIds,
        rejectedStoryIds,
        reviewedBy,
        reviewedByName,
        createdAt,
        updatedAt,
      ];
}
