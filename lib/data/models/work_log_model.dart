import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model ghi nhận thời gian làm việc (Work Log) cho Task (US-066).
///
/// Mỗi bản ghi gắn với 1 task, lưu số giờ đã làm, ngày làm việc, người thực hiện và ghi chú.
class WorkLogModel extends Equatable {
  final String id;
  final String taskId;
  final String projectId;
  final String userId;
  final String userName;
  final double hours;
  final String note;

  /// Ngày thực hiện công việc (chỉ lưu phần ngày YYYY-MM-DD, không tính giờ phút).
  final DateTime workDate;

  /// Thời điểm tạo bản ghi.
  final DateTime createdAt;

  const WorkLogModel({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.hours,
    this.note = '',
    required this.workDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'projectId': projectId,
      'userId': userId,
      'userName': userName,
      'hours': hours,
      'note': note,
      'workDate': Timestamp.fromDate(
        DateTime(workDate.year, workDate.month, workDate.day),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkLogModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawWorkDate = parseDate(map['workDate']);
    final cleanWorkDate =
        DateTime(rawWorkDate.year, rawWorkDate.month, rawWorkDate.day);

    double parseHours(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WorkLogModel(
      id: docId ?? (map['id'] as String? ?? ''),
      taskId: map['taskId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      hours: parseHours(map['hours']),
      note: map['note'] as String? ?? '',
      workDate: cleanWorkDate,
      createdAt: parseDate(map['createdAt']),
    );
  }

  WorkLogModel copyWith({
    String? id,
    String? taskId,
    String? projectId,
    String? userId,
    String? userName,
    double? hours,
    String? note,
    DateTime? workDate,
    DateTime? createdAt,
  }) {
    return WorkLogModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      hours: hours ?? this.hours,
      note: note ?? this.note,
      workDate: workDate != null
          ? DateTime(workDate.year, workDate.month, workDate.day)
          : this.workDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        projectId,
        userId,
        userName,
        hours,
        note,
        workDate,
        createdAt,
      ];
}
