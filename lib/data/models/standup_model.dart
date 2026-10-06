import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StandupModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String sprintId;
  final DateTime createdAt;
  final String yesterday;
  final String today;
  final String blockers;

  const StandupModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sprintId,
    required this.createdAt,
    required this.yesterday,
    required this.today,
    required this.blockers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'sprintId': sprintId,
      'createdAt': createdAt.toIso8601String(),
      'yesterday': yesterday,
      'today': today,
      'blockers': blockers,
    };
  }

  factory StandupModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return StandupModel(
      id: docId ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      sprintId: map['sprintId'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      yesterday: map['yesterday'] as String? ?? '',
      today: map['today'] as String? ?? '',
      blockers: map['blockers'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory StandupModel.fromJson(Map<String, dynamic> json) => StandupModel.fromMap(json);

  StandupModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? sprintId,
    DateTime? createdAt,
    String? yesterday,
    String? today,
    String? blockers,
  }) {
    return StandupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      sprintId: sprintId ?? this.sprintId,
      createdAt: createdAt ?? this.createdAt,
      yesterday: yesterday ?? this.yesterday,
      today: today ?? this.today,
      blockers: blockers ?? this.blockers,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        sprintId,
        createdAt,
        yesterday,
        today,
        blockers,
      ];
}
